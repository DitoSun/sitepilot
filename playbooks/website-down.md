# Playbook — Website Down

> Iron rule: **locate the fault layer first, then touch the system.** Do not start by restarting the server / reinstalling / changing code. [REAL]
> Layer order: USER/CLIENT → DNS → TLS → CDN/WAF → reverse proxy → server → runtime → app → API → cache → data → external dependencies.

## TRIAGE — Qualify in 30 Seconds

- [ ] Is it just you, or is everyone? Switch network / switch device / cross-confirm with monitoring.
- [ ] Which symptom: connection refused / timeout / DNS resolution failure / 5xx / abnormal redirect? The symptom determines the entry layer.
- [ ] What changed in the last 24h (deploy / config / DNS / certificate / dependency upgrade)? Change is the prime suspect.

## LOCATE LAYER — Outside-in, read-only checks per layer

| # | Layer | Read-only check approach (adjust to the actual stack) |
|---|---|---|
| 1 | USER/CLIENT | Incognito window + hard refresh; check console; count concurrent requests; rule out old-tab noise (mtime vs restart time) |
| 2 | DNS | Query multiple public DNS servers for results and TTL; confirm NS not changed; compare local vs public results |
| 3 | TLS | Read-only view of the certificate chain, expiry date, SAN list; confirm hostname match |
| 4 | CDN/WAF | Origin fetch status; whether WAF is false-blocking (your own probe getting 403'd by your own defenses has really happened) |
| 5 | Reverse proxy | Config and error logs; whether access_log is writing; whether real_ip config was broken by upstream changes |
| 6 | Server | Process alive / port listening / disk full / memory tight / abnormal restart counts |
| 7 | Runtime | Runtime version and process manager state; logs show any start-crash loop |
| 8 | App | App error log timeline; whether the last deploy's build artifacts landed completely |
| 9 | API | curl the backend API directly and measure latency — "page stuck ≠ API slow"; measure the server side before checking the client |
| 10 | Cache | Whether static pages / pre-renders solidified bad data; whether a cache stampede dragged down upstream |
| 11 | Data | Data files / database readable, record counts normal, no locks, no racing half-writes |
| 12 | External deps | Upstream API / mail / third-party service status; any fallback source |

## ASSESS IMPACT

- [ ] Whole site down or partial features down? Logged-in users or guests? Is it growing? Any risk of data loss?

## MITIGATE / RECOVER

- [ ] Deploy-caused → switch back to the last working build (the rollback point must pre-exist).
- [ ] Data-caused → restore from snapshot and verify (md5 → structure / record counts → sampled fields).
- [ ] External dependency failure → switch to the fallback source, or explicitly signal "data stale", never leave a silent failure.
- [ ] Resources saturated → rate-limit / degrade core paths first, then clean up and scale out.
- [ ] Principle: restore service first, then analyze root cause; sunk cost is not a reason to keep hammering at a fix. [REAL]

## VERIFY

- [ ] Semantic verification: key page content correct, API record counts normal, auth triple test passes. [REAL]
- [ ] Re-test from multiple locations / networks to rule out single-point misjudgment.

## INVESTIGATE

- [ ] Align the timeline (log mtime vs restart time) to locate the triggering change.
- [ ] Classic trap self-check (all have really happened):
  - [ ] "Changed but not taking effect": leftover old process holds the port, new service gets EADDRINUSE, traffic goes to old code. [REAL]
  - [ ] After going on CDN, all real-IP decisions / rate limiting based on remote_addr stop working. [REAL]
  - [ ] No inventory, no alerts before certificate expiry. [GENERAL]
  - [ ] Reverse proxy logs not enabled — zero evidence during troubleshooting. [REAL]

## LEARN

- [ ] Mini Postmortem + Lesson Candidate.
- [ ] Upgrade detectable checks (resolution, certificate expiry, port, process) to automated checks / alerts.
