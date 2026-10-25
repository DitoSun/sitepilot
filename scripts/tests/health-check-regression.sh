#!/usr/bin/env bash
#
# SitePilot — health-check regression suite
#
# Purpose: prove that site-health-check.sh fails when it should fail.
#
# WHY THIS EXISTS (EXP-112): v1.0.0 of the health check reported PASS for an
# unreachable site and for an expired certificate. Happy-path testing could
# never have caught that. A check that has not demonstrated that its failure
# paths fail cannot be trusted, so this suite tests the negative paths first.
#
# What it covers
#   HTTP matrix : 200 / 301 / 404 / 500 / DNS failure / connection refused /
#                 timeout / TLS handshake failure / no HTTP response
#   TLS matrix  : long-valid / renewal window / <24h / expired 1s /
#                 expired hours / expired days / no certificate /
#                 hostname mismatch
#   Guard rails : printed verdict must agree with the process exit code
#
# Everything runs against local throwaway servers and generated certificates.
# No external network access is required, and nothing outside a temp dir is
# touched.
#
# Usage: ./health-check-regression.sh [--verbose]
# Exit:  0 = all cases passed, 1 = at least one case failed

set -u

HERE=$(cd "$(dirname "$0")" && pwd)
CHECKER="$HERE/../site-health-check.sh"
VERBOSE=0
[ "${1:-}" = "--verbose" ] && VERBOSE=1

[ -x "$CHECKER" ] || { echo "ERROR: checker not found/executable: $CHECKER" >&2; exit 1; }

PY=$(command -v python3 2>/dev/null || command -v python 2>/dev/null || true)
command -v openssl >/dev/null 2>&1 || { echo "ERROR: openssl required" >&2; exit 1; }

# Randomise the port range per run: leftover fixture processes from an
# interrupted run must never silently shadow this run's fixtures.
PORT_BASE=$(( 20000 + ($$ % 8000) ))
WORK=$(mktemp -d 2>/dev/null || echo "/tmp/sitepilot-regression.$$")
mkdir -p "$WORK"
PIDS=""
cleanup() {
  for p in $PIDS; do kill "$p" 2>/dev/null || true; done
  rm -rf "$WORK" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

PASSED=0; FAILED=0; SKIPPED=0
RESULTS=""

note() { [ "$VERBOSE" -eq 1 ] && printf '    %s\n' "$1"; return 0; }

wait_ready() {
  # wait_ready <port> — block until the port accepts TCP, max ~6s.
  local port=$1 i=0
  while [ "$i" -lt 30 ]; do
    if (exec 3<>"/dev/tcp/127.0.0.1/${port}") 2>/dev/null; then exec 3>&- 2>/dev/null; return 0; fi
    sleep 0.2; i=$((i+1))
  done
  return 1
}

record_result() {
  # record_result <case> <ok|fail|skip> <detail>
  case "$2" in
    ok)   PASSED=$((PASSED+1));  RESULTS="${RESULTS}OK    | $1 | $3\n" ;;
    fail) FAILED=$((FAILED+1));  RESULTS="${RESULTS}FAIL  | $1 | $3\n" ;;
    skip) SKIPPED=$((SKIPPED+1));RESULTS="${RESULTS}SKIP  | $1 | $3\n" ;;
  esac
  printf '  [%-4s] %-42s %s\n' "$(printf '%s' "$2" | tr 'a-z' 'A-Z')" "$1" "$3"
}

# ---------------------------------------------------------------------------
# Servers
# ---------------------------------------------------------------------------
start_http_server() {
  # start_http_server <port> <status> [healthy]
  # "healthy" additionally sends the security headers and serves
  # robots.txt / sitemap.xml, so a fully clean PASS is testable.
  local port=$1 status=$2 mode=${3:-plain}
  "$PY" - "$port" "$status" "$mode" >/dev/null 2>&1 <<'PYSRV' &
import http.server, sys
port = int(sys.argv[1]); status = int(sys.argv[2]); mode = sys.argv[3]
SEC = {
    'X-Content-Type-Options': 'nosniff',
    'X-Frame-Options': 'DENY',
    'Referrer-Policy': 'strict-origin-when-cross-origin',
    'Strict-Transport-Security': 'max-age=31536000',
    'Content-Security-Policy': "default-src 'self'",
}
class H(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        code = status
        if mode == 'healthy' and self.path in ('/robots.txt', '/sitemap.xml', '/'):
            code = 200
        self.send_response(code)
        self.send_header('Content-Type', 'text/plain')
        if code in (301, 302):
            self.send_header('Location', '/elsewhere')
        if mode == 'healthy':
            for k, v in SEC.items():
                self.send_header(k, v)
        self.end_headers()
        self.wfile.write(b'SitePilot fixture body')
    def log_message(self, *a): pass
http.server.HTTPServer(('127.0.0.1', port), H).serve_forever()
PYSRV
  PIDS="$PIDS $!"
  wait_ready "$port" || { echo "  [SETUP] fixture on :$port did not come up" >&2; return 1; }
  return 0
}

start_tls_server() {
  # start_tls_server <port> <cert> <key>
  local port=$1 cert=$2 key=$3
  "$PY" - "$port" "$cert" "$key" >/dev/null 2>&1 <<'PYSRV' &
import http.server, ssl, sys
port = int(sys.argv[1]); cert = sys.argv[2]; key = sys.argv[3]
class H(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200); self.send_header('Content-Type','text/plain')
        self.end_headers(); self.wfile.write(b'OK')
    def log_message(self, *a): pass
httpd = http.server.HTTPServer(('127.0.0.1', port), H)
ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
ctx.load_cert_chain(cert, key)
httpd.socket = ctx.wrap_socket(httpd.socket, server_side=True)
httpd.serve_forever()
PYSRV
  PIDS="$PIDS $!"
  wait_ready "$port" || { echo "  [SETUP] TLS fixture on :$port did not come up" >&2; return 1; }
  return 0
}

start_blackhole() {
  # accepts TCP but never answers -> exercises the timeout path
  local port=$1
  "$PY" - "$port" >/dev/null 2>&1 <<'PYSRV' &
import socket, sys, time
s = socket.socket(); s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
s.bind(('127.0.0.1', int(sys.argv[1]))); s.listen(5)
conns = []
while True:
    c, _ = s.accept(); conns.append(c)   # accept, never respond
PYSRV
  PIDS="$PIDS $!"
  wait_ready "$port" || { echo "  [SETUP] blackhole on :$port did not come up" >&2; return 1; }
  return 0
}

# ---------------------------------------------------------------------------
# Certificates
# ---------------------------------------------------------------------------
utc_offset() { date -u -d "@$(( $(date -u +%s) + $1 ))" '+%Y%m%d%H%M%SZ' 2>/dev/null; }

gen_cert() {
  # gen_cert <file-base> <not_before_ts> <not_after_ts> <CN> [san]
  local base=$1 nb=$2 na=$3 cn=$4 san=${5:-}
  local args=(-x509 -newkey rsa:2048 -nodes -keyout "${base}.key" -out "${base}.pem"
              -subj "/CN=${cn}" -not_before "$nb" -not_after "$na")
  [ -n "$san" ] && args+=(-addext "subjectAltName=${san}")
  openssl req "${args[@]}" >/dev/null 2>&1
  [ -f "${base}.pem" ]
}

echo "==============================================================="
echo " SitePilot health-check regression suite"
echo " checker: $CHECKER"
echo "==============================================================="

# ---------------------------------------------------------------------------
# HTTP matrix
# ---------------------------------------------------------------------------
echo
echo "[HTTP matrix]"

run_case() {
  # run_case <case> <url> <expected_exit> <expected_result> <must_grep> [must_not_grep] [extra args...]
  local name=$1 url=$2 want_exit=$3 want_result=$4 must=$5 not=${6:-}
  shift 6 2>/dev/null || shift 5
  local out rc ok=1 detail=""

  out=$("$CHECKER" "$url" --timeout 4 "$@" 2>&1); rc=$?

  [ "$rc" = "$want_exit" ] || { ok=0; detail="exit=$rc want=$want_exit"; }
  if [ -n "$want_result" ]; then
    printf '%s' "$out" | grep -q "RESULT: ${want_result}" \
      || { ok=0; detail="${detail:+$detail; }result!=${want_result}"; }
  fi
  if [ -n "$must" ] && ! printf '%s' "$out" | grep -qiE "$must"; then
    ok=0; detail="${detail:+$detail; }missing:${must}"
  fi
  if [ -n "$not" ] && printf '%s' "$out" | grep -qiE "$not"; then
    ok=0; detail="${detail:+$detail; }forbidden:${not}"
  fi

  if [ "$VERBOSE" -eq 1 ]; then printf '%s\n' "$out" | sed 's/^/      | /'; fi
  if [ "$ok" -eq 1 ]; then record_result "$name" ok "exit=$rc"
  else record_result "$name" fail "$detail"; fi
}

# 9100 = fully healthy fixture (all security headers + crawler assets) -> clean PASS
start_http_server $((PORT_BASE+0)) 200 healthy
start_http_server $((PORT_BASE+1)) 200
start_http_server $((PORT_BASE+2)) 301
start_http_server $((PORT_BASE+3)) 404
start_http_server $((PORT_BASE+4)) 500

# Forbidden patterns use "[FAIL" / "RESULT: FAIL" rather than "FAIL", because
# "0 failure(s)" in the summary would otherwise match a bare /FAIL/.
run_case "Healthy site -> clean PASS"  "http://127.0.0.1:$((PORT_BASE+0))" 0 "PASS"          "HTTP 200"           "\[FAIL"     --no-tls
run_case "HTTP 200 w/o headers -> WARN" "http://127.0.0.1:$((PORT_BASE+1))" 3 "PASS WITH WARNINGS" "HTTP 200"      "\[FAIL"     --no-tls
run_case "HTTP 301 -> PASS+WARN"       "http://127.0.0.1:$((PORT_BASE+2))" 3 "PASS WITH WARNINGS" "HTTP 301"       "\[FAIL"     --no-tls
run_case "HTTP 404 -> FAIL"            "http://127.0.0.1:$((PORT_BASE+3))" 1 "FAIL"            "HTTP 404"           ""           --no-tls
run_case "HTTP 500 -> FAIL"            "http://127.0.0.1:$((PORT_BASE+4))" 1 "FAIL"            "HTTP 500"           ""           --no-tls

# DNS failure (RFC 2606 .invalid TLD never resolves)
run_case "DNS failure -> FAIL"         "https://sitepilot-regression.invalid" 1 "FAIL" "DNS|transport|usable" "Homepage reachable" --no-tls

# Connection refused (closed port)
run_case "Connection refused -> FAIL"  "http://127.0.0.1:$((PORT_BASE+99))" 1 "FAIL"           "refused|transport|usable" "Homepage reachable" --no-tls

# Timeout (accepts, never answers)
start_blackhole $((PORT_BASE+5))
run_case "Timeout -> FAIL"             "http://127.0.0.1:$((PORT_BASE+5))" 1 "FAIL"           "timeout|transport|usable" "Homepage reachable" --no-tls --timeout 3

# TLS handshake failure (https against a plain HTTP port)
run_case "TLS handshake fail -> FAIL"  "https://127.0.0.1:$((PORT_BASE+1))" 1 "FAIL"          "TLS|transport|usable" "Homepage reachable" --timeout 3

# ---------------------------------------------------------------------------
# TLS matrix
# ---------------------------------------------------------------------------
echo
echo "[TLS matrix]"

NA90=$(utc_offset 7776000)      # +90d
NA10D=$(utc_offset 864000)      # +10d  -> renewal window (default 21d)
NA2H=$(utc_offset 7200)         # +2h   -> critical (<24h)
NA_EXP1S=$(utc_offset -1)       # -1s   -> expired by ~1 second
NA_EXP3H=$(utc_offset -10800)   # -3h
NA_EXP5D=$(utc_offset -432000)  # -5d
NB_PAST=$(utc_offset -8640000)

SAN="IP:127.0.0.1,DNS:localhost"

gen_cert "$WORK/c-valid"     "$NB_PAST" "$NA90"     "localhost" "$SAN" && note "cert valid"
gen_cert "$WORK/c-warn"      "$NB_PAST" "$NA10D"    "localhost" "$SAN" && note "cert warn"
gen_cert "$WORK/c-crit"      "$NB_PAST" "$NA2H"     "localhost" "$SAN" && note "cert crit"
gen_cert "$WORK/c-exp1s"     "$NB_PAST" "$NA_EXP1S" "localhost" "$SAN" && note "cert expired 1s"
gen_cert "$WORK/c-exp3h"     "$NB_PAST" "$NA_EXP3H" "localhost" "$SAN" && note "cert expired 3h"
gen_cert "$WORK/c-exp5d"     "$NB_PAST" "$NA_EXP5D" "localhost" "$SAN" && note "cert expired 5d"
gen_cert "$WORK/c-wronghost" "$NB_PAST" "$NA90"     "not-this-host.invalid" "" && note "cert wrong host"

if [ -f "$WORK/c-valid.pem" ]; then
  start_tls_server $((PORT_BASE+10)) "$WORK/c-valid.pem"     "$WORK/c-valid.key"
  start_tls_server $((PORT_BASE+11)) "$WORK/c-warn.pem"      "$WORK/c-warn.key"
  start_tls_server $((PORT_BASE+12)) "$WORK/c-crit.pem"      "$WORK/c-crit.key"
  start_tls_server $((PORT_BASE+13)) "$WORK/c-exp1s.pem"     "$WORK/c-exp1s.key"
  start_tls_server $((PORT_BASE+14)) "$WORK/c-exp3h.pem"     "$WORK/c-exp3h.key"
  start_tls_server $((PORT_BASE+15)) "$WORK/c-exp5d.pem"     "$WORK/c-exp5d.key"
  start_tls_server $((PORT_BASE+16)) "$WORK/c-wronghost.pem" "$WORK/c-wronghost.key"

  # NOTE (honest limitation): these fixtures are self-signed, so curl refuses the
  # chain and the TRANSPORT check legitimately fails -> overall FAIL regardless of
  # the certificate dates. What these cases prove is the TLS *date classification*,
  # which is the bug being guarded. A clean overall PASS with a trusted certificate
  # is NOT automated here; it was verified manually on a real site
  # (see docs/validation.md).
  run_case "TLS long-valid dates -> not EXPIRED"   "https://127.0.0.1:$((PORT_BASE+10))" 1 "FAIL" "Certificate valid for 8[0-9] more days" "EXPIRED" --timeout 4
  run_case "TLS renewal window -> WARN not EXPIRED" "https://127.0.0.1:$((PORT_BASE+11))" 1 "FAIL" "renewal window" "EXPIRED" --timeout 4
  run_case "TLS <24h -> CRITICAL"          "https://127.0.0.1:$((PORT_BASE+12))" 1 "FAIL"               "expires in 1h"             "" --timeout 4
  run_case "TLS expired 1s -> FAIL"        "https://127.0.0.1:$((PORT_BASE+13))" 1 "FAIL"               "EXPIRED [0-9]+s ago"       "0 days" --timeout 4
  run_case "TLS expired 3h -> FAIL"        "https://127.0.0.1:$((PORT_BASE+14))" 1 "FAIL"               "EXPIRED 2h|EXPIRED 3h"     "0 days" --timeout 4
  run_case "TLS expired 5d -> FAIL"        "https://127.0.0.1:$((PORT_BASE+15))" 1 "FAIL"               "EXPIRED 4d|EXPIRED 5d"     "0 days" --timeout 4
  run_case "TLS hostname mismatch -> FAIL" "https://127.0.0.1:$((PORT_BASE+16))" 1 "FAIL"               "does NOT match"            "" --timeout 4
else
  for c in "TLS long-valid" "TLS renewal window" "TLS <24h" "TLS expired 1s" "TLS expired 3h" "TLS expired 5d" "TLS hostname mismatch"; do
    record_result "$c" skip "certificate generation unsupported on this openssl"
  done
fi

# No certificate served (plain HTTP port addressed as https) already covered
run_case "TLS no certificate -> FAIL" "https://127.0.0.1:$((PORT_BASE+1))" 1 "FAIL" "certificate|transport|usable" "" --timeout 3

# ---------------------------------------------------------------------------
# Verdict / exit-code agreement
# ---------------------------------------------------------------------------
echo
echo "[Verdict integrity]"

agree_ok=1; agree_detail=""
for pair in "http://127.0.0.1:$((PORT_BASE+0)):0:PASS" \
            "http://127.0.0.1:$((PORT_BASE+4)):1:FAIL" \
            "http://127.0.0.1:$((PORT_BASE+1)):3:PASS WITH WARNINGS"; do
  url=$(printf '%s' "$pair" | cut -d: -f1-3)
  want_exit=$(printf '%s' "$pair" | awk -F: '{print $(NF-1)}')
  want_res=$(printf '%s' "$pair" | awk -F: '{print $NF}')
  out=$("$CHECKER" "$url" --timeout 4 --no-tls 2>&1); rc=$?
  if [ "$rc" != "$want_exit" ] || ! printf '%s' "$out" | grep -q "RESULT: ${want_res}"; then
    agree_ok=0; agree_detail="${agree_detail}${url}(exit=$rc,want=$want_exit) "
  fi
done
[ "$agree_ok" -eq 1 ] && record_result "verdict agrees with exit code" ok "3 spot checks" \
                      || record_result "verdict agrees with exit code" fail "$agree_detail"

# JSON mode must still honour the exit code
outj=$("$CHECKER" "http://127.0.0.1:$((PORT_BASE+4))" --timeout 4 --no-tls --json 2>&1); rcj=$?
if [ "$rcj" = "1" ] && printf '%s' "$outj" | grep -q '"result":"FAIL"'; then
  record_result "JSON mode keeps FAIL exit code" ok "exit=1"
else
  record_result "JSON mode keeps FAIL exit code" fail "exit=$rcj"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo
echo "==============================================================="
printf '%b' "$RESULTS"
echo "---------------------------------------------------------------"
echo " PASSED: $PASSED   FAILED: $FAILED   SKIPPED: $SKIPPED"
if [ "$FAILED" -gt 0 ]; then
  echo " RESULT: REGRESSION SUITE FAILED"
  echo "==============================================================="
  exit 1
fi
echo " RESULT: ALL CASES PASSED"
echo "==============================================================="
exit 0
