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

## Agent Quick Check

1. Access log confirmed growing (bytes / lines), rotation configured — before trusting any other metric?
2. Restart / crash counts on the dashboard and baselined; timelines aligned after every deploy?
3. Every collector surfaces its own failures; at least one independent cross-check exists?
4. Each metric maps to a decision ("are users affected?" / "was the deploy good?"); nothing collected "just in case"?
5. Retention rules paired with disk-watermark alerts; aggregates kept after truncation?
