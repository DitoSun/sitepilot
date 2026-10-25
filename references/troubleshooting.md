# Layered Troubleshooting — SitePilot Reference

> **Solves:** when the site misbehaves, how to avoid flailing at the code —
> locate the failing layer before touching anything, measure instead of
> guessing, and keep "hung ≠ slow API" and "change didn't take effect ≠ the
> code is wrong" straight.

Source: EXP-036~047 (troubleshooting methodology); the layered model follows the SKILL.md §10 approach; this file gives each layer's inspection means and measurement discipline.

---

## 1. The layered troubleshooting model

Locate the failing layer before changing the system. Work layer by layer, ruling each out with read-only means first:

| Layer | Inspection means | Real cases |
|---|---|---|
| USER/CLIENT | Hard-refresh to rule out cache; check console; count concurrent requests; old-tab noise judged by timeline | Cache serving stale pages; old-tab errors; thousands of records rendered at once starving connections; favicon noise |
| DNS | Whether resolution took effect, TTL, multi-region resolution consistency | No first-party evidence; treat as general practice |
| TLS/HTTPS | Certificate validity, certificate chain, HTTP→HTTPS redirect | One fact only: "certificates need an inventory + expiry monitoring" |
| CDN/WAF | Whether origin-IP detection is invalidated | Explicit warning: after putting a CDN in front, all real-IP detection based on remote_addr is invalidated |
| Reverse proxy | Config, whether access_log is being written, compression coverage, real_ip basis | Navigation payload left uncompressed; 0-byte logs for months; two layers of inconsistent IP basis |
| SERVER | Processes / ports / disk / memory / restart count | Leftover old process squatting the port; hundreds of restarts; disk water level running high |
| RUNTIME | Runtime version, process manager, logs | — |
| APPLICATION | App logs, error reporting, build artifacts | Data frozen by pre-rendering; residual types in the artifact directory |
| API | curl the endpoint directly to measure latency; distinguish transport-layer 403 from business 403 | Endpoint innocent at the millisecond level; soft-degraded 200 |
| CACHE | Cache layer, static pages, browser cache | Page still old after deploy |
| DATABASE/DATA | Data-file consistency, sync status, counts | Local and production counts inconsistent; new content all invisible |
| EXTERNAL | Upstream data sources, mail service, third-party APIs | Upstream failure unnoticed; dual-source redundancy added afterward |

The DNS / TLS / CDN layers have no first-party evidence in this project; they are marked [GENERAL] general practice — never pass them off as experience when using them.

## 2. Measurement discipline

| Rule | Detail | Source |
|---|---|---|
| "Hung ≠ slow API" | First curl to measure the server side and rule it out, then check the client connection/render layer. Case: an admin operation hung every time and was misreported as "slow API" — actually thousands of records rendered in one unpaginated batch, image requests starved HTTP/1.1's 6 same-origin connections (queued for thousands of rounds), while the server endpoint measured in the milliseconds, completely innocent | [REAL] EXP-037 |
| Measure end-to-end before guessing | Any performance/hang conclusion needs measurement numbers behind it; never skip measurement and guess | [REAL] EXP-037 |
| Large lists must paginate + lazy-load | For "the page hangs", count concurrent requests first; lists load by page + media lazy-loading | [REAL] EXP-059 |
| "Change didn't take effect" — check process/port/cache first | A leftover old process squats the port; curl hits old code, which looks like "I changed it for ages and nothing happened" | [REAL] EXP-045 |
| Comments are not evidence | Code claiming to block a pattern didn't actually block it; verification must run against real data | [REAL] EXP-039 |
| Check timestamps first for errors | When you can't tell a new bug from old noise, align log time vs service restart time first | [REAL] EXP-040 |
| Clear noise errors first | A site-wide missing favicon pollutes the console and obstructs debugging; clear noise before locating the real problem | [REAL] EXP-046 |
| Fix one, scan the class | After fixing the root cause, scan the whole site for same-pattern call sites (once, a utility function had multiple copies and only half were fixed) | [REAL] EXP-041 |
| Sink pitfalls into rules | The same pitfall was hit twice in 17 days; sink the general rule "this kind of field cannot be a unique key", not "that bug is fixed" | [REAL] EXP-042 |

## 3. Silent errors in data & naming

| Rule | Detail | Source |
|---|---|---|
| Data-name/code-name mismatches don't error | The page shows "no data" and search returns 0 without erroring; the naming contract must be validated — the correct pattern is providing a fallback display field | [REAL] EXP-043 |
| Random-string fields cannot do substring search | That is equal to fishing at random; matching rules use equality, fuzzy match only for inputs known to be incomplete | [REAL] EXP-044 |
| External-dependency degradation must be explicit to users | Upstream failure needs a fallback source + an explicit "data is stale" notice on the page; silent is not allowed | [REAL] EXP-047 |

## 4. Troubleshooting output

Every time troubleshooting ends, three things must be left behind besides the fix itself:

| Output | Requirement |
|---|---|
| Timeline | Key timestamps from discovery → localization → recovery (facts established after aligning log time vs restart time) |
| Root cause | Chase down to the mechanism layer, never stop at the symptom layer; "operator error" is not a root cause |
| Prevention | Land in at least one of: rule / checklist / playbook / automation (SKILL.md §9) |

## Agent Quick Check

- Am I still guessing the bottleneck without measuring? Get the curl result / logs / process state out first.
- Did the "slow API" conclusion first rule out client rendering and the connection layer?
- Did "change didn't take effect" check process/port/cache first, rather than editing code first?
- Were errors timeline-aligned first (new bug vs old noise)?
- After fixing the root cause, did you scan the whole site for same-pattern call sites?
