#!/usr/bin/env bash
#
# SitePilot — site-health-check.sh
# Read-only website health check. SAFE BY DEFAULT.
#
# This script NEVER: modifies data, writes files, restarts services, sends
# credentials, or logs cookies/headers values. It only performs GET/HEAD
# requests and local TLS inspection, then prints a report.
#
# Usage:
#   ./site-health-check.sh https://example.com [options]
#
# Options:
#   --path /a,/b     Critical paths to check (comma-separated). Default: /
#   --timeout N      Per-request timeout in seconds (default: 10)
#   --user-agent S   User-Agent to send (default: SitePilot-HealthCheck/1.0)
#   --no-tls         Skip TLS certificate inspection
#   -h, --help       Show this help
#
# Exit codes: 0 = all checks passed, 1 = at least one FAIL, 2 = usage error

set -u

VERSION="1.0.0"
UA_DEFAULT="SitePilot-HealthCheck/${VERSION}"
TIMEOUT=10
CHECK_TLS=1
CRITICAL_PATHS="/"
TARGET=""

pass() { printf '  [PASS] %s\n' "$1"; }
warn() { printf '  [WARN] %s\n' "$1"; WARNINGS=$((WARNINGS+1)); }
fail() { printf '  [FAIL] %s\n' "$1"; FAILURES=$((FAILURES+1)); }
info() { printf '  [INFO] %s\n' "$1"; }
FAILURES=0
WARNINGS=0

usage() { sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'; exit 2; }

while [ $# -gt 0 ]; do
  case "$1" in
    --path) CRITICAL_PATHS="${2:-/}"; shift 2 ;;
    --timeout) TIMEOUT="${2:-10}"; shift 2 ;;
    --user-agent) UA_DEFAULT="${2:-$UA_DEFAULT}"; shift 2 ;;
    --no-tls) CHECK_TLS=0; shift ;;
    -h|--help) usage ;;
    -*) echo "Unknown option: $1" >&2; usage ;;
    *) [ -z "$TARGET" ] && TARGET="$1"; shift ;;
  esac
done

[ -z "$TARGET" ] && { echo "ERROR: target URL required" >&2; usage; }
command -v curl >/dev/null 2>&1 || { echo "ERROR: curl is required" >&2; exit 2; }

TARGET="${TARGET%/}"
case "$TARGET" in http://*|https://*) ;; *) TARGET="https://$TARGET" ;; esac
SCHEME=$(printf '%s' "$TARGET" | cut -d/ -f3 --complement 2>/dev/null || true)
HOST=$(printf '%s' "$TARGET" | sed -E 's#^https?://##; s#/.*$##')

echo "==============================================================="
echo " SitePilot read-only health check — ${TARGET}"
echo " $(date -u '+%Y-%m-%dT%H:%M:%SZ')  (timeout ${TIMEOUT}s per request)"
echo "==============================================================="
echo " NOTE: status codes alone do not prove the site works."
echo "       Interpret results semantically (SKILL.md section 8)."

# ---------- 1. Connectivity & status ----------
echo
echo "[1] Connectivity & HTTP status"
CODE=$(curl -sS -o /dev/null -w '%{http_code}' --max-time "$TIMEOUT" \
  -A "$UA_DEFAULT" "$TARGET" 2>/dev/null || echo "000")
if [ "$CODE" = "000" ]; then
  fail "No response from ${TARGET} (connection failed or timed out)"
elif [ "$CODE" -ge 500 ]; then
  fail "Homepage returned HTTP ${CODE} (server error)"
elif [ "$CODE" -ge 400 ]; then
  fail "Homepage returned HTTP ${CODE} (client error — check WAF/UA rules)"
else
  pass "Homepage reachable — HTTP ${CODE}"
fi

# ---------- 2. Redirect chain ----------
echo
echo "[2] Redirect chain (homepage)"
if command -v mktemp >/dev/null 2>&1; then
  RHDR=$(mktemp)
  curl -sS -o /dev/null -D "$RHDR" -L --max-redirs 5 --max-time "$TIMEOUT" \
    -A "$UA_DEFAULT" "$TARGET" >/dev/null 2>&1 || true
  HOPS=$(grep -c -i '^HTTP/' "$RHDR" 2>/dev/null || echo 0)
  LOCS=$(grep -i '^location:' "$RHDR" 2>/dev/null | sed -E 's/^[Ll]ocation: *//' | tr -d '\r' || true)
  rm -f "$RHDR"
  if [ "${HOPS:-0}" -le 1 ]; then
    pass "No redirect chain (direct response)"
  else
    info "Redirect chain (${HOPS} hops):"
    printf '%s\n' "$LOCS" | sed 's/^/         -> /'
    if printf '%s' "$LOCS" | grep -qi '^http://'; then
      warn "Chain contains an http:// hop — ensure final hop is https"
    fi
  fi
else
  info "mktemp unavailable — skipped"
fi

# ---------- 3. Response timing ----------
echo
echo "[3] Response timing"
T_HOME=$(curl -sS -o /dev/null -w '%{time_total}' --max-time "$TIMEOUT" \
  -A "$UA_DEFAULT" "$TARGET" 2>/dev/null || echo "0")
T_HOME_MS=$(awk -v t="$T_HOME" 'BEGIN{printf "%d", t*1000}')
if [ "$T_HOME_MS" -ge 5000 ]; then
  warn "Homepage TTFB+transfer ${T_HOME_MS}ms (slow — see playbooks/performance-incident.md)"
elif [ "$T_HOME_MS" -ge 2000 ]; then
  warn "Homepage ${T_HOME_MS}ms (acceptable but watch it)"
else
  pass "Homepage responded in ${T_HOME_MS}ms"
fi

# ---------- 4. TLS ----------
echo
echo "[4] TLS certificate"
if [ "$CHECK_TLS" -eq 1 ] && command -v openssl >/dev/null 2>&1; then
  case "$TARGET" in
    https://*)
      CERT=$(echo | openssl s_client -servername "$HOST" -connect "${HOST}:443" 2>/dev/null || true)
      ENDDATE=$(printf '%s' "$CERT" | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2 || true)
      if [ -z "$ENDDATE" ]; then
        warn "Could not read certificate for ${HOST}:443"
      else
        END_EPOCH=$(date -d "$ENDDATE" +%s 2>/dev/null || echo 0)
        NOW_EPOCH=$(date +%s)
        DAYS=$(( (END_EPOCH - NOW_EPOCH) / 86400 ))
        if [ "$DAYS" -lt 0 ]; then
          fail "Certificate EXPIRED ${DAYS} days ago (${ENDDATE})"
        elif [ "$DAYS" -lt 14 ]; then
          warn "Certificate expires in ${DAYS} days (${ENDDATE})"
        else
          pass "Certificate valid for ${DAYS} more days (expires ${ENDDATE})"
        fi
      fi
      ;;
    *) info "Target is http:// — TLS not applicable" ;;
  esac
else
  info "TLS check skipped (--no-tls or openssl unavailable)"
fi

# ---------- 5. Security headers ----------
echo
echo "[5] Security headers (homepage)"
HDRS=$(curl -sS -D - -o /dev/null --max-time "$TIMEOUT" -A "$UA_DEFAULT" "$TARGET" 2>/dev/null || true)
check_header() {
  if printf '%s' "$HDRS" | grep -qi "^$1:"; then
    pass "Present: $1"
  else
    case "$1" in
      Strict-Transport-Security|Content-Security-Policy)
        warn "Missing: $1" ;;
      *) info "Missing: $1 (recommended)" ;;
    esac
  fi
}
for h in X-Content-Type-Options X-Frame-Options Referrer-Policy \
         Strict-Transport-Security Content-Security-Policy; do
  check_header "$h"
done

# ---------- 6. robots.txt & sitemap.xml ----------
echo
echo "[6] Crawler assets"
for asset in robots.txt sitemap.xml; do
  C=$(curl -sS -o /dev/null -w '%{http_code}' --max-time "$TIMEOUT" \
    -A "$UA_DEFAULT" "${TARGET}/${asset}" 2>/dev/null || echo "000")
  case "$C" in
    200) pass "${asset} reachable (HTTP 200)" ;;
    000) warn "${asset} unreachable (timeout/connection error)" ;;
    *) warn "${asset} returned HTTP ${C}" ;;
  esac
done

# ---------- 7. Critical paths ----------
echo
echo "[7] Critical paths (semantic check required)"
IFS=',' read -ra PATHS <<< "$CRITICAL_PATHS"
for p in "${PATHS[@]}"; do
  p=$(printf '%s' "$p" | sed 's/^ *//; s/ *$//')
  [ -z "$p" ] && p="/"
  case "$p" in /*) ;; *) p="/$p" ;; esac
  C=$(curl -sS -o /dev/null -w '%{http_code}' --max-time "$TIMEOUT" \
    -A "$UA_DEFAULT" "${TARGET}${p}" 2>/dev/null || echo "000")
  T=$(curl -sS -o /dev/null -w '%{time_total}' --max-time "$TIMEOUT" \
    -A "$UA_DEFAULT" "${TARGET}${p}" 2>/dev/null || echo "0")
  T_MS=$(awk -v t="$T" 'BEGIN{printf "%d", t*1000}')
  if [ "$C" = "000" ]; then
    fail "${p} — no response"
  elif [ "$C" -ge 400 ]; then
    fail "${p} — HTTP ${C}"
  else
    pass "${p} — HTTP ${C} (${T_MS}ms). VERIFY CONTENT, not just status."
  fi
done

# ---------- Summary ----------
echo
echo "==============================================================="
echo " Summary: ${FAILURES} failure(s), ${WARNINGS} warning(s)"
if [ "$FAILURES" -gt 0 ]; then
  echo " RESULT: FAIL — do not ship or declare the site healthy."
  echo " Next: playbooks/website-down.md or the matching playbook."
  echo "==============================================================="
  exit 1
fi
echo " RESULT: PASS (transport level). Remember: HTTP 200 is not"
echo " proof of correctness — verify semantics (SKILL.md section 8)."
echo "==============================================================="
exit 0
