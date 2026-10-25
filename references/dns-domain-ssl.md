# DNS / Domain / SSL — SitePilot Reference

> **Solves:** how to change DNS and verify certificates without taking the site
> down or chasing phantom code bugs. Load with `checklists/dns-change.md`.
>
> **Evidence notice: [GENERAL] limited first-party evidence.** The DNS and SSL
> procedures in §1–§3 are general best practice — the source project had almost
> no first-party DNS/SSL operations (one fact only: certificates were issued via
> a hosting panel and their expiry date needed a ledger). Do not present these
> as incident-derived. The only [REAL] first-party items are §4 and §5.

## 1. Before changing DNS [GENERAL]

DNS changes are HIGH risk (SKILL.md §5) and a Stop Condition when TTL or
current records are unknown (SKILL.md §7.8).

| Step | Action |
|---|---|
| 1. Identify the provider | Which DNS provider / hosting panel is authoritative? Evidence, not assumption |
| 2. Export current records | Save every existing record (A / AAAA / CNAME / MX / TXT…) before touching anything |
| 3. Check TTLs | Know the propagation delay you are committing to; consider lowering TTL *in advance* of the change |
| 4. Write the rollback first | The exact old records, ready to restore |
| 5. Change | Minimal edit; do not "clean up" unrelated records in the same change |
| 6. Verify globally | After the change, verify resolution from multiple vantage points, not just your own network |

## 2. Verifying resolution [GENERAL]

| Check | How |
|---|---|
| Record correctness | Resolved values match intent, from multiple resolvers / locations |
| No split-brain | Old and new values are not both "live" in a way that breaks TLS or mail |
| HTTPS still works | Certificate, redirects, and site behavior after propagation (see §3) |
| Email paths intact | If MX / SPF / DKIM records exist, they still resolve |

## 3. SSL checks [GENERAL]

| Check | Detail |
|---|---|
| Expiry | Days remaining; renewal must happen *before* the expiry date, not on it |
| Hostname coverage | Certificate covers every hostname actually served (bare domain and subdomains) |
| Chain | Full chain presented; no missing intermediate |
| HTTP → HTTPS | Plain HTTP redirects to HTTPS, with no redirect loop |
| Renewal method | How renewal happens — panel auto-renew, ACME client, manual? Document it |

## 3b. Decide expiry on absolute timestamps, never on derived days [REAL]

Comparing timestamps via an integer day count silently erases the most
important state there is — "already expired".

Real bug, real output:

```
remaining_seconds = -5218        # certificate expired 87 minutes ago
days = -5218 / 86400 = 0         # integer division truncates toward zero
→ "certificate expires in 0 days" → WARNING → overall PASS
```

The certificate was dead. The check said "0 days". Every browser was already
blocking the site.

Correct order of operations — always in this sequence:

```
1. read expiry timestamp (epoch)        expiry_ts
2. read now (epoch)                     now_ts
3. DECIDE:  expiry_ts <= now_ts  →  EXPIRED (fail)
            else compare seconds to thresholds
4. only then format seconds → hours → days for humans
```

State model that follows from it:

| State | Condition | Verdict |
|---|---|---|
| `EXPIRED` | `expiry_ts <= now_ts` | FAIL — no grace, no rounding |
| `NOT_YET_VALID` | `not_before > now_ts` | FAIL |
| `CRITICAL` | remaining < 24h (configurable) | FAIL or CRITICAL — renewal is overdue in practice |
| `WARNING` | remaining < renewal window (e.g. 21d) | WARN |
| `HEALTHY` | remaining >= window | PASS |

This is not a TLS-specific trick. The general rule:

> **Compare absolute timestamps before deriving human-readable durations.**
> A rounded duration is a display artifact, never a decision input. (EXP-113)

The same bug class hides in: session/token TTL checks, "days since last
backup", retry-window math, subscription expiry, and cache-age comparisons.
Anywhere the code computes `(a - b) / 86400` and then compares to `0`, a
sub-day negative value becomes zero.

## 3c. Certificate renewed ≠ certificate served [REAL]

Renewing a certificate on disk does not mean visitors receive it. Between the
new file and the browser sit several layers that each cache or terminate TLS:

```
certificate file renewed
  → does the running process need a reload/restart?
  → is a reverse proxy terminating TLS?
  → is a CDN terminating TLS (and still holding the old cert)?
  → is there a load balancer with its own copy?
  → are there multiple nodes, some not yet updated?
  → is an old process still bound to :443?
  → does DNS point somewhere unexpected?
  → what certificate does the PUBLIC endpoint actually present?
```

The only proof is the certificate a user receives, read from outside:

```bash
openssl s_client -servername <host> -connect <host>:443 </dev/null 2>/dev/null   | openssl x509 -noout -subject -dates -fingerprint -sha256
```

Repeat the sample a few times (different connections can hit different nodes)
and compare fingerprints — identical fingerprints mean one consistent
certificate is being served; differing fingerprints mean an inconsistent
fleet.

> Verify the certificate from the user's path, not only from the server
> filesystem. (EXP-118)

## 4. Certificate expiry ledger [REAL for the practice / GENERAL for mechanics]

The one first-party fact: certificates were issued through a hosting panel, and
the expiry date needed explicit tracking. An expired certificate is a full
outage for HTTPS users.

| Rule | Detail |
|---|---|
| Ledger entry per certificate | Domain, issuer, issue date, expiry date, renewal method, owner |
| Alert ahead of expiry | Reminder well before the date — not on the day |

## 5. "The site is down" is not automatically a code bug [GENERAL]

Before editing code, walk the layers (SKILL troubleshooting model): DNS → TLS
→ CDN / WAF → reverse proxy → server → runtime → app. A site that "won't open"
is at least as likely to be DNS, certificate, or proxy as application code.

| Symptom | Check first |
|---|---|
| Not resolving | DNS records / provider status |
| Resolves, TLS error | Certificate expiry, chain, hostname coverage |
| Works for you, not for users | CDN / WAF, proxy, propagation |
| 5xx everywhere | Server / runtime layer before app code |

## 6. CDN invalidates remote_addr-based IP logic [REAL]

A first-party warning from the source project: once a CDN fronts the site, any
logic based on the direct connection's remote address (real client IP, per-IP
rate limits, IP-based audit) silently breaks — the origin sees the CDN's
addresses, not the client's.

| Rule | Detail |
|---|---|
| Re-derive client IP | After CDN onboarding, re-align the IP extraction chain end-to-end (see `security.md` §6) |
| Re-test every IP-dependent feature | Rate limits, lockouts, logs, analytics — verify with real requests through the CDN |
| Update the ledger | Record the CDN in the infrastructure ledger so future debugging starts from truth |

---

## Agent Quick Check

1. DNS change? Provider confirmed, all current records saved, TTL known, rollback written before editing.
2. Post-change resolution verified from multiple vantage points; HTTPS and redirects re-verified.
3. Certificate ledger current (expiry, coverage, renewal method) with an alert ahead of expiry.
4. "Site down" diagnosis started at the layers (DNS / TLS / CDN / proxy / server), not at the code.
5. After any CDN change: client-IP extraction and every IP-dependent feature re-tested and re-documented.
