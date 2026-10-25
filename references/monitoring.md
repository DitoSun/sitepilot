# Monitoring & Observability — SitePilot Reference

> **Solves:** what to monitor (and what not to), so you can answer "are real
> users actually affected?" — and so the monitoring itself cannot lie to you.
> Load with `playbooks/` and SKILL.md §8 verification semantics.

## 1. Server logs come before any monitoring [REAL]

A production vhost ran for months with an empty access log (0 bytes): crawler
behavior, traffic, and incidents were all invisible — the foundation of every
monitoring story was missing (EXP-076).

| Rule | Detail |
|---|---|
| First act on any server | Confirm logs are actually being written — file size grows, lines appear |
| Not just "configured" | A log directive that exists ≠ a log file that grows — check the file itself |
| Rotation from day one | Logs without rotation become a disk incident |

Without access logs you cannot answer "who was affected?", "when did it
start?", or "did the crawlers come?" — incident and SEO work both lose their
evidence base.

## 2. Restart frequency and crash counts are stability signals [REAL]

A process manager showed a restart count in the hundreds (roughly one crash
every few days, sustained for months) — discovered only during a handover
audit (EXP-080).

| Rule | Detail |
|---|---|
| Put restart / crash counts on the monitoring list | A rising count is an incident you have not had yet |
| Restarts have a cost window | Each restart carries a brief unavailability window; zero-downtime needs rolling restarts (EXP-024) |
| Align timelines | Log mtime vs. restart time — separates new bugs from old-client noise (EXP-029/040) |

## 3. A lightweight three-layer setup is enough to start [REAL]

A small site runs on three self-built layers plus one freshness check
(EXP-081):

| Layer | Content | Retention discipline |
|---|---|---|
| Operation log | Administrative / mutation actions | Cap the entry count (order of ~10k) + aggregate statistics |
| Frontend error reports | Client-side errors | Cap (order of ~500 entries); keep the aggregate |
| Login audit | Auth events (success / failure / lockout) | Cap (order of ~100 entries) |
| Data freshness check | Daily: is critical data still fresh? | Scripted check + alert when stale |

Truncation is a feature: unbounded logs on a small disk are a future incident.
But keep the aggregates after truncation — trends outlive raw entries.

## 4. Silently failing monitoring is worse than no monitoring [REAL]

A bot-logging hook failed silently (a platform `waitUntil` that never ran
under self-hosting). The conclusion drawn — "AI crawlers never visit us" — was
false: dozens of independent crawler IPs were in the access logs all along
(EXP-082).

| Rule | Detail |
|---|---|
| Monitor the monitor | Every collector must surface its own failures — a dead pipeline must look dead |
| Cross-check with an independent source | Log analysis vs. app-level counters: disagreement means one of them is lying |
| A wrong conclusion is the worst output | No monitoring → "unknown". Silent failure → "confidently wrong" |

## 5. Monitor what tells you whether users are affected [REAL]

Prefer metrics that answer an operational question over metrics that exist for
their own sake:

| Question | Useful signal |
|---|---|
| Are users affected right now? | Error rate on critical paths, auth failures, data freshness check |
| Was the deploy good? | Error rate / restarts in the minutes after deploy; semantic checks (SKILL.md §8) |
| Is the host healthy? | Disk watermark, memory, restart counts |
| Is the data still right? | Record counts / freshness vs. expectations |

Not monitored: vanity counters that no decision depends on. Monitoring for
monitoring's sake is a cost, not a safety net.

## 6. Retention policies need a disk watermark [DERIVED]

Backups capped per file, logs truncated — yet the disk still ran at a high
fill ratio and memory was tight on a small host (EXP-083).

| Rule | Detail |
|---|---|
| Retention + watermark together | Every retention rule pairs with a disk-usage alert threshold |
| Small hosts, small margins | On constrained machines, also watch build-artifact accumulation |

---

## Periodic full-site sweeps [REAL]

Beyond uptime checks, run a periodic automated sweep of the whole site with a
real browser engine (headless browser or equivalent): crawl key routes, assert
expected content, collect console errors, and check standard assets (favicon
at all conventional paths, manifest, OG images). A missing favicon looks
trivial until its 404s pollute the console of every page and mask real errors
during debugging. Sweeps are read-only. (EXP-111)

## Monitoring must be monitored [REAL]

A health check that has never demonstrated its failure paths is not evidence
of health — it is evidence that the check ran.

The real case: a read-only health-check script shipped with two silent
false-pass bugs.

| Bug | Root cause | What it reported |
|---|---|---|
| Unreachable site reported healthy | `curl`'s `000` placeholder plus a `|| echo "000"` fallback concatenated into `"000000"`, which matched no failure branch | `[PASS] Homepage reachable — HTTP 000000` |
| Certificate expired 87 minutes ago reported healthy | Expiry decided from **integer days**: `(end - now) / 86400` on `-5218` seconds truncates to `0` | `[WARN] expires in 0 days` → overall PASS |

Both are the same disease: **a check that can only pass**. Happy-path testing
cannot find them, because on a healthy site the output is correct.

Rules for any automated check you write or trust:

1. **Test the failure paths first.** For every FAIL branch, construct an input
   that must trigger it, and assert it does. Assert the *verdict*, not just the
   text.
2. **Assert the exit code too.** A script that prints `FAIL` and exits `0` is
   broken; automate the exit-code assertion.
3. **Never treat a placeholder as a value.** `000`, `""`, `null`, `N/A` are
   absence markers. Validate shape (e.g. exactly three digits) and route
   anything else to the transport-failure branch.
4. **Never merge two signals into one string.** Transport status and HTTP
   status have different meanings; keep them in separate variables.
5. **Decide on absolutes, format afterwards** (see EXP-113). Do not derive a
   pass/fail decision from a rounded human-readable duration.
6. **Prefer FEWER checks that are proven** over many that were never tested on
   failing input.

> Monitoring software that converts failure into success creates false
> confidence, and may be more dangerous than having no check at all. (EXP-112)

## Health is path-dependent [REAL]

The same site can be healthy and unreachable at the same time — depending on
where the check ran.

```
server-local  ≠  LAN  ≠  external network  ≠  through CDN  ≠  through public DNS
```

A real audit produced a false alarm: from the operator's machine every request
failed, because the local network layer rewrote DNS to a reserved address and
sent traffic to a local proxy. The production site was fine. An hour earlier,
the opposite error was also possible — assuming "it works from my machine"
means it works for users.

Rules:

1. **Every check result carries its vantage point.** Record where it ran.
2. **Server-local checks answer a different question** than public-path checks.
   `curl localhost:3000` proves the app is up; it says nothing about DNS, TLS,
   CDN, or the public endpoint.
3. **When a check fails, confirm the failure from a second vantage point**
   before acting — a broken local network looks identical to an outage.
4. **Verify the public path from outside** for anything user-facing: TLS
   certificate, redirects, cache behaviour, auth flows.
5. **When the vantage point itself is suspect**, the result is
   "unknown", not "down". Say so explicitly.

> Health is path-dependent: "which check ran, from where?" belongs in every
> conclusion. (EXP-117)

## Agent Quick Check

1. Access log confirmed growing (bytes / lines), rotation configured — before trusting any other metric?
2. Restart / crash counts on the dashboard and baselined; timelines aligned after every deploy?
3. Every collector surfaces its own failures; at least one independent cross-check exists?
4. Each metric maps to a decision ("are users affected?" / "was the deploy good?"); nothing collected "just in case"?
5. Retention rules paired with disk-watermark alerts; aggregates kept after truncation?
