#!/usr/bin/env bash
#
# SitePilot — site-health-check.sh
# Read-only website health check. SAFE BY DEFAULT.
#
# This script NEVER: modifies data, writes files, restarts services, sends
# credentials, or logs cookie/header values. It only issues GET/HEAD requests
# and local TLS inspection, then prints a verdict.
#
# Usage:
#   ./site-health-check.sh <url> [options]
#
# Options:
#   --path /a,/b        Critical paths (comma-separated). Default: /
#   --timeout N         Per-request timeout, seconds (default: 10)
#   --user-agent S      Override User-Agent
#   --no-tls            Skip TLS certificate inspection
#   --json              Emit machine-readable JSON instead of text
#   -h, --help          Show this help
#
# Exit codes:
#   0  PASS          — no failures, no warnings
#   3  PASS + WARN   — no failures, but at least one warning
#   1  FAIL          — at least one failing check
#   2  usage error
#
# DESIGN INVARIANTS (do not break these — see EXP-112, EXP-113):
#   1. Transport failure is NEVER a PASS. A missing/invalid HTTP response is
#      reported as transport failure, never as a status-code verdict.
#   2. curl's exit status and the HTTP status are kept as SEPARATE values.
#      They are never concatenated or mixed into one string.
#   3. TLS expiry is decided by comparing absolute epoch timestamps FIRST.
#      Human-readable durations are derived afterwards, never used to decide.
#   4. The printed verdict and the process exit code must always agree.
#
# Any change to this script must keep
# `scripts/tests/health-check-regression.sh` passing — including its
# negative-path cases. A check that has not demonstrated that its failure
# paths fail cannot be trusted.

set -u

VERSION="1.0.1"
UA_DEFAULT="Mozilla/5.0 (compatible; SitePilot-HealthCheck/${VERSION}; +https://github.com/sitepilot)"
TIMEOUT=10
CHECK_TLS=1
JSON=0
CRITICAL_PATHS="/"
TARGET=""

# TLS thresholds (overridable — do not hardcode judgment into the code path)
TLS_WARN_DAYS="${SITEPILOT_TLS_WARN_DAYS:-21}"
TLS_CRITICAL_HOURS="${SITEPILOT_TLS_CRITICAL_HOURS:-24}"

FAILS=0
CRITS=0
WARNS=0
JSON_ITEMS=""

record() {
  # record <STATUS> <section> <message>
  local st=$1 sec=$2 msg=$3
  case "$st" in
    FAIL) FAILS=$((FAILS+1)) ;;
    CRITICAL) CRITS=$((CRITS+1)) ;;
    WARN) WARNS=$((WARNS+1)) ;;
  esac
  if [ "$JSON" -eq 1 ]; then
    local e_msg e_sec
    e_msg=$(printf '%s' "$msg" | sed 's/\\/\\\\/g; s/"/\\"/g')
    e_sec=$(printf '%s' "$sec" | sed 's/\\/\\\\/g; s/"/\\"/g')
    JSON_ITEMS="${JSON_ITEMS}${JSON_ITEMS:+,}{\"section\":\"$e_sec\",\"status\":\"$st\",\"message\":\"$e_msg\"}"
  else
    printf '  [%-8s] %s\n' "$st" "$msg"
  fi
}

section() { [ "$JSON" -eq 1 ] || printf '\n[%s] %s\n' "$1" "$2"; }
note()    { [ "$JSON" -eq 1 ] || printf '  [INFO    ] %s\n' "$1"; }

usage() { sed -n '/^# Usage:/,/^#   2  usage error/p' "$0" | sed 's/^# \{0,1\}//'; exit 2; }

while [ $# -gt 0 ]; do
  case "$1" in
    --path)       CRITICAL_PATHS="${2:-/}"; shift 2 ;;
    --timeout)    TIMEOUT="${2:-10}"; shift 2 ;;
    --user-agent) UA_DEFAULT="${2:-$UA_DEFAULT}"; shift 2 ;;
    --no-tls)     CHECK_TLS=0; shift ;;
    --json)       JSON=1; shift ;;
    -h|--help)    usage ;;
    -*)           echo "Unknown option: $1" >&2; usage ;;
    *)            [ -z "$TARGET" ] && TARGET="$1"; shift ;;
  esac
done

[ -z "$TARGET" ] && { echo "ERROR: target URL required" >&2; usage; }
command -v curl >/dev/null 2>&1 || { echo "ERROR: curl is required" >&2; exit 2; }

TARGET="${TARGET%/}"
case "$TARGET" in http://*|https://*) ;; *) TARGET="https://$TARGET" ;; esac
SCHEME=$(printf '%s' "$TARGET" | sed -E 's#^(https?)://.*#\1#')
HOSTPORT=$(printf '%s' "$TARGET" | sed -E 's#^https?://##; s#/.*$##')
HOST=${HOSTPORT%%:*}
PORT=${HOSTPORT##*:}
[ "$PORT" = "$HOSTPORT" ] && PORT=443
[ -z "$HOST" ] && HOST="$HOSTPORT"

# ---------------------------------------------------------------------------
# probe — the ONLY place that talks to the network for HTTP status.
# Sets: P_EXIT (curl exit status), P_CODE (3-digit HTTP status or empty),
#       P_ERR  (human-readable transport failure reason when applicable)
# ---------------------------------------------------------------------------
P_EXIT=0; P_CODE=""; P_ERR=""
probe() {
  local url=$1 ua=$2
  local raw

  raw=$(curl -sS -o /dev/null -w '%{http_code}' \
          --max-time "$TIMEOUT" -A "$ua" "$url" 2>/dev/null)
  P_EXIT=$?

  raw=$(printf '%s' "$raw" | tr -d '[:space:]')
  P_ERR=""

  # A valid HTTP status is EXACTLY three digits. Anything else means we never
  # received a usable response — that is a transport failure, not a status.
  case "$raw" in
    [0-9][0-9][0-9]) P_CODE="$raw" ;;
    *)               P_CODE="" ;;
  esac

  # "000" is curl's placeholder for "no response" — it is NOT a status code.
  if [ "$P_CODE" = "000" ]; then P_CODE=""; fi

  if [ "$P_EXIT" -ne 0 ] || [ -z "$P_CODE" ]; then
    case "$P_EXIT" in
      0)  P_ERR="no valid HTTP response received" ;;
      6)  P_ERR="DNS resolution failed" ;;
      7)  P_ERR="connection refused / host unreachable" ;;
      28) P_ERR="timeout after ${TIMEOUT}s" ;;
      35) P_ERR="TLS handshake failed" ;;
      52) P_ERR="empty reply from server" ;;
      56) P_ERR="network receive failure" ;;
      60) P_ERR="TLS certificate verification failed" ;;
      *)  P_ERR="transport error (curl exit ${P_EXIT})" ;;
    esac
  fi
}

if [ "$JSON" -eq 0 ]; then
  echo "==============================================================="
  echo " SitePilot read-only health check — ${TARGET}"
  echo " $(date -u '+%Y-%m-%dT%H:%M:%SZ')  (timeout ${TIMEOUT}s, ua: ${UA_DEFAULT%%/*})"
  echo "==============================================================="
  echo " NOTE: status codes alone do not prove the site works."
  echo "       Interpret results semantically (SKILL.md section 8)."
fi

# ---------- 1. Transport & HTTP status ----------
section 1 "Transport & HTTP status"
probe "$TARGET" "$UA_DEFAULT"

if [ -n "$P_ERR" ]; then
  record FAIL "transport" "No usable HTTP response from ${TARGET}: ${P_ERR}"
elif [ "$P_CODE" -ge 500 ]; then
  record FAIL "http" "Homepage returned HTTP ${P_CODE} (server error)"
elif [ "$P_CODE" -ge 400 ]; then
  if [ "$P_CODE" = "403" ] || [ "$P_CODE" = "429" ]; then
    record FAIL "http" "Homepage returned HTTP ${P_CODE} — the site is reachable but is refusing this client"
    note "Possible bot protection / WAF / anti-crawler rule. This may be a real user-facing block, or a rule aimed at non-browser clients."
    note "SitePilot does not attempt to bypass site protections. Confirm with --user-agent if a browser-like client should be allowed."
  else
    record FAIL "http" "Homepage returned HTTP ${P_CODE} (client error)"
  fi
else
  record PASS "http" "Homepage reachable — HTTP ${P_CODE}"
fi

# ---------- 2. Redirect chain ----------
section 2 "Redirect chain (homepage)"
if [ -z "$P_ERR" ]; then
  # Headers captured from stdout (curl -D -) — no temp file, so no chance of a
  # stray command's output corrupting --json mode.
  CHAIN_HDRS=$(curl -sS -o /dev/null -D - -L --max-redirs 5 --max-time "$TIMEOUT" \
    -A "$UA_DEFAULT" "$TARGET" 2>/dev/null || true)
  HOPS=$(printf '%s\n' "$CHAIN_HDRS" | grep -ci '^HTTP/' || true)
  LOCS=$(printf '%s\n' "$CHAIN_HDRS" | grep -i '^location:' | sed -E 's/^[Ll]ocation: *//' | tr -d '\r' || true)
  if [ "${HOPS:-0}" -le 1 ]; then
    record PASS "redirect" "No redirect chain (direct response)"
  else
    record PASS "redirect" "Redirect chain observed (${HOPS} hops) — verify the final destination is intended"
    if printf '%s' "$LOCS" | grep -qi '^http://'; then
      record WARN "redirect" "Chain contains an http:// hop — the final hop should be https"
    fi
  fi
else
  record WARN "redirect" "Redirect chain not checked (no usable HTTP response)"
fi

# ---------- 3. Response timing ----------
section 3 "Response timing"
if [ -z "$P_ERR" ]; then
  T_HOME=$(curl -sS -o /dev/null -w '%{time_total}' --max-time "$TIMEOUT" \
    -A "$UA_DEFAULT" "$TARGET" 2>/dev/null || echo "0")
  case "$T_HOME" in ''|*[!0-9.]*) T_HOME=0 ;; esac
  T_MS=$(awk -v t="$T_HOME" 'BEGIN{printf "%d", t*1000}' 2>/dev/null || echo 0)
  if [ "${T_MS:-0}" -ge 5000 ]; then
    record WARN "timing" "Homepage took ${T_MS}ms (slow — see playbooks/performance-incident.md)"
  elif [ "${T_MS:-0}" -ge 2000 ]; then
    record WARN "timing" "Homepage took ${T_MS}ms (acceptable but worth watching)"
  else
    record PASS "timing" "Homepage responded in ${T_MS}ms"
  fi
else
  record WARN "timing" "Timing not measured (no usable HTTP response)"
fi

# ---------- 4. TLS certificate ----------
section 4 "TLS certificate"
if [ "$CHECK_TLS" -eq 0 ]; then
  note "TLS check skipped (--no-tls)"
elif [ "$SCHEME" != "https" ]; then
  note "Target is http:// — TLS not applicable"
elif ! command -v openssl >/dev/null 2>&1; then
  record WARN "tls" "openssl unavailable — certificate expiry NOT verified"
else
  CERT=$(echo | openssl s_client -servername "$HOST" -connect "${HOST}:${PORT}" 2>/dev/null || true)
  END_DATE=$(printf '%s' "$CERT" | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2 || true)
  BEG_DATE=$(printf '%s' "$CERT" | openssl x509 -noout -startdate 2>/dev/null | cut -d= -f2 || true)

  if [ -z "$END_DATE" ]; then
    record FAIL "tls" "Could not read a certificate from ${HOST}:${PORT} (handshake failed or no certificate served)"
  else
    END_EPOCH=$(date -u -d "$END_DATE" +%s 2>/dev/null || echo "")
    NOW_EPOCH=$(date -u +%s)

    if [ -z "$END_EPOCH" ]; then
      record WARN "tls" "Certificate expiry unreadable ('${END_DATE}') — expiry NOT verified"
    else
      # INVARIANT: decide on absolute timestamps first. Never on derived days.
      REMAIN=$(( END_EPOCH - NOW_EPOCH ))

      if [ "$END_EPOCH" -le "$NOW_EPOCH" ]; then
        EXPIRED_FOR=$(( -(REMAIN) ))
        if [ "$EXPIRED_FOR" -lt 3600 ]; then
          record FAIL "tls" "Certificate EXPIRED ${EXPIRED_FOR}s ago (notAfter ${END_DATE})"
        elif [ "$EXPIRED_FOR" -lt 86400 ]; then
          record FAIL "tls" "Certificate EXPIRED $((EXPIRED_FOR/3600))h ago (notAfter ${END_DATE})"
        else
          record FAIL "tls" "Certificate EXPIRED $((EXPIRED_FOR/86400))d ago (notAfter ${END_DATE})"
        fi
      elif [ "$REMAIN" -lt $((TLS_CRITICAL_HOURS * 3600)) ]; then
        record CRITICAL "tls" "Certificate expires in $((REMAIN/3600))h${REMAIN:+$(( (REMAIN%3600)/60 ))}m — renew now (notAfter ${END_DATE})"
      elif [ "$REMAIN" -lt $((TLS_WARN_DAYS * 86400)) ]; then
        record WARN "tls" "Certificate expires in $((REMAIN/86400))d — inside renewal window (notAfter ${END_DATE})"
      else
        record PASS "tls" "Certificate valid for $((REMAIN/86400)) more days (notAfter ${END_DATE})"
      fi

      # Not-yet-valid is its own failure mode
      if [ -n "$BEG_DATE" ]; then
        BEG_EPOCH=$(date -u -d "$BEG_DATE" +%s 2>/dev/null || echo "")
        if [ -n "$BEG_EPOCH" ] && [ "$BEG_EPOCH" -gt "$NOW_EPOCH" ]; then
          record FAIL "tls" "Certificate is NOT YET VALID (notBefore ${BEG_DATE})"
        fi
      fi

      # Hostname match (independent of chain trust)
      CHK=$(printf '%s' "$CERT" | openssl x509 -noout -checkhost "$HOST" 2>/dev/null || true)
      case "$CHK" in
        *"does match"*) record PASS "tls" "Certificate hostname matches ${HOST}" ;;
        *"does NOT match"*) record FAIL "tls" "Certificate hostname does NOT match ${HOST}" ;;
        *) note "Hostname match not verified (openssl -checkhost unavailable)" ;;
      esac

      # Chain trust. Two different situations can produce an "untrusted chain"
      # reading, and they must not be conflated:
      #   (a) the TARGET serves a chain that genuinely does not validate
      #   (b) THIS MACHINE's openssl trust store is behind the system bundle
      # Evidence to tell them apart is already available: curl verified the
      # chain against the system CA bundle during the probe. If curl trusts it
      # and openssl does not, the discrepancy is local to the checker.
      VERIFY=$(printf '%s' "$CERT" | grep -E '^Verify return code' | head -1 || true)
      case "$VERIFY" in
        *"code: 0"*|"") : ;;
        *)
          # Evidence rule: if the request completed successfully, the system CA
          # bundle DID accept this chain, so a disagreement can only be local to
          # this machine's openssl store. If the request failed at the TLS layer,
          # the target is the more likely cause.
          if [ "$P_EXIT" -eq 0 ] && [ -n "$P_CODE" ]; then
            record WARN "tls-environment" "CHECKER ENVIRONMENT trust issue, NOT a target certificate problem: this machine's openssl trust store cannot validate the chain (${VERIFY#*: }), yet the request completed successfully against the system CA bundle. Check from another network or update this machine's CA bundle — do not conclude the site's chain is broken."
          else
            record WARN "tls" "Chain did not validate (${VERIFY#*: }) and the request did not complete either — treat as a target-side TLS/chain issue and confirm from an external network."
          fi
          ;;
      esac
    fi
  fi
fi

# ---------- 5. Security headers ----------
section 5 "Security headers (homepage)"
if [ -z "$P_ERR" ]; then
  HDRS=$(curl -sS -D - -o /dev/null --max-time "$TIMEOUT" -A "$UA_DEFAULT" "$TARGET" 2>/dev/null || true)
  for h in X-Content-Type-Options X-Frame-Options Referrer-Policy \
           Strict-Transport-Security Content-Security-Policy; do
    if printf '%s' "$HDRS" | grep -qi "^$h:"; then
      record PASS "headers" "Present: $h"
    else
      case "$h" in
        Strict-Transport-Security|Content-Security-Policy)
          record WARN "headers" "Missing: $h" ;;
        *)
          note "Missing: $h (recommended)" ;;
      esac
    fi
  done
else
  record WARN "headers" "Security headers not checked (no usable HTTP response)"
fi

# ---------- 6. Crawler assets ----------
section 6 "Crawler assets"
if [ -z "$P_ERR" ]; then
  for asset in robots.txt sitemap.xml; do
    probe "${TARGET}/${asset}" "$UA_DEFAULT"
    if [ -n "$P_ERR" ]; then
      record WARN "crawler" "${asset}: no usable response (${P_ERR})"
    elif [ "$P_CODE" = "200" ]; then
      record PASS "crawler" "${asset} reachable (HTTP 200)"
    else
      record WARN "crawler" "${asset} returned HTTP ${P_CODE}"
    fi
  done
else
  record WARN "crawler" "Crawler assets not checked (no usable HTTP response)"
fi

# ---------- 7. Critical paths ----------
section 7 "Critical paths (semantic check required)"
IFS=',' read -ra PATHS <<< "$CRITICAL_PATHS"
for p in "${PATHS[@]}"; do
  p=$(printf '%s' "$p" | sed 's/^ *//; s/ *$//')
  [ -z "$p" ] && p="/"
  case "$p" in /*) ;; *) p="/$p" ;; esac

  probe "${TARGET}${p}" "$UA_DEFAULT"
  if [ -n "$P_ERR" ]; then
    record FAIL "path" "${p} — no usable HTTP response (${P_ERR})"
  elif [ "$P_CODE" -ge 500 ]; then
    record FAIL "path" "${p} — HTTP ${P_CODE}"
  elif [ "$P_CODE" -ge 400 ]; then
    record FAIL "path" "${p} — HTTP ${P_CODE}"
  else
    record PASS "path" "${p} — HTTP ${P_CODE}. VERIFY CONTENT, not just status."
  fi
done

# ---------- Verdict ----------
# INVARIANT: printed verdict and exit code must agree.
if [ "$FAILS" -gt 0 ] || [ "$CRITS" -gt 0 ]; then
  RESULT="FAIL"; EXIT=1
elif [ "$WARNS" -gt 0 ]; then
  RESULT="PASS_WITH_WARNINGS"; EXIT=3
else
  RESULT="PASS"; EXIT=0
fi

if [ "$JSON" -eq 1 ]; then
  printf '{"tool":"sitepilot-site-health-check","version":"%s","target":"%s","checked_at":"%s","result":"%s","exit_code":%s,"failures":%s,"critical":%s,"warnings":%s,"checks":[%s]}\n' \
    "$VERSION" "$TARGET" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$RESULT" "$EXIT" "$FAILS" "$CRITS" "$WARNS" "$JSON_ITEMS"
else
  echo
  echo "==============================================================="
  echo " Summary: ${FAILS} failure(s), ${CRITS} critical, ${WARNS} warning(s)"
  case "$RESULT" in
    FAIL)
      echo " RESULT: FAIL — do not declare the site healthy."
      echo " Next: playbooks/website-down.md, or the matching playbook."
      ;;
    PASS_WITH_WARNINGS)
      echo " RESULT: PASS WITH WARNINGS — reachable, but review each warning above."
      echo " (Exit code 3 distinguishes this from a clean pass.)"
      ;;
    PASS)
      echo " RESULT: PASS (transport level). HTTP 200 is still not proof"
      echo " of correctness — verify semantics (SKILL.md section 8)."
      ;;
  esac
  echo "==============================================================="
fi

exit "$EXIT"
