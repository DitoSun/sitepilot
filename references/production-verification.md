# Production Verification — SitePilot Reference

> **Solves:** after a deploy or change, how to prove "production really is
> healthy" instead of fooling yourself with exit code 0 — core principle:
> deployment success ≠ production success; verify semantics, not just transport
> success.

Source: L4 / L5 / L14 and EXP-025/029/038/069/082. The DoD definition quotes SKILL.md §10 directly — not reinvented here.

---

## 1. Core principles

| Principle | Detail | Source |
|---|---|---|
| Deploy success ≠ production success | Command exit code 0, build OK, deploy script finished — these only prove "the action completed", not "the effect happened" | [REAL] L4 |
| Verify semantics, not just transport success | HTTP 200 can mean: stale data from cache, a truncated soft-degraded result, a degraded page | [REAL] L4/L5 |
| "200 but wrong data" is an incident | Soft degradation returns 200 + truncated data; the frontend never notices, it never self-heals — more dangerous than a 500 | [REAL] EXP-038 |
| Having logs ≠ having success | A scheduled job's success criterion is the business semantics of the return, not "there was a response" | [REAL] L14 |
| Monitoring that silently fails is worse than no monitoring | It exports wrong conclusions (e.g. believing "no crawlers came", when IPs from multiple sources were actually crawling) | [REAL] EXP-082 |

## 2. Semantic verification checklist

After any deploy/change, confirm item by item (choose by the change's blast radius — not everything every time):

| Verify | How | What fake success it catches |
|---|---|---|
| Expected content | Critical pages show the expected real content (new copy / new data / new feature entry) | Cache returning the old page (EXP-025) |
| Record counts | Key lists/endpoints return record counts matching production data | Soft-degradation truncation (EXP-038) |
| Critical fields | Spot-check field values against the data source | Data names mismatching code names, "no data" displayed |
| Auth state | Login flow works; protected endpoints reject anonymous | Session store failure, token policy change |
| Business behavior | Write path really persists; counters really move | "Submitted successfully" but nothing persisted |
| No unexpected redirects | No 301/302 sending users somewhere unexpected | URL change missing redirects |
| No new console errors | No mass JS errors, no resource 404s; rule out known noise errors first | Noise like a missing favicon obscuring judgment |
| Mobile critical path | Actually visit on mobile and exercise the touch path | Only testing desktop |
| Deploy-process stats | Non-200 count during the switch (proves no gap window) | The inherent window of a single-instance restart |

## 3. Ruling out cache illusions

| Rule | Detail | Source |
|---|---|---|
| Hard-refresh before concluding | The first move for "the change didn't take effect" is hard-refresh / re-visit with a cache-bust param, not editing code — this once nearly deleted code that was never broken | [REAL] EXP-025 |
| Distinguish the cache layers | Browser cache, static pre-rendered artifacts, reverse-proxy/CDN cache — rule out layer by layer | [REAL] EXP-025 |
| Old-tab noise judged by timeline | Errors after a redeploy: align log time vs service restart time first; old-client noise is not a new bug | [REAL] EXP-029 |

## 4. Semantic verification for scheduled jobs & automation

| Rule | Detail | Source |
|---|---|---|
| Parse the business semantics of the response | An external API's 200 can be spinning on empty: one submission endpoint was long deprecated, spinning on 302s daily for months before anyone noticed | [REAL] L14 |
| Daily "success" in logs ≠ real success | Case: submitted content was malformed, the only thing "indexed" was the sitemap itself — zero real success for months | [REAL] EXP-069 |
| Verification logic must detect silent death | Third-party endpoints get deprecated/reworked; success criteria must follow business semantics, not the transport layer | [REAL] L14 |

## 5. Definition of Done (quotes SKILL.md §10)

```
Implemented + tested + built + deployed
+ production verified (semantics, not just status)
+ regression checked + monitored
+ lesson captured if there was anything to learn
```

"The code is written" is not done. "The deploy succeeded" is not done.

## Local verification must not touch production data [REAL]

When verifying behavior locally, isolate writes: intercept the client's
network layer (record URLs, return fixture responses) so the frontend flow is
exercised without persisting anything into real data files. Verifying "does
the button work" by clicking it against live data is how test artifacts become
production incidents. (EXP-110)

## Agent Quick Check

- Did I actually visit the production site, or only look at build/deploy output?
- Did I verify "content, record counts, critical fields, auth state, business behavior", or only HTTP 200?
- Was the "didn't take effect" conclusion made only after hard-refresh / ruling out caches?
- For scheduled jobs, did I verify business success, or only see "there are logs / there is a response"?
- If this change had anything unexpected (even if recovered), did it go into a Mini Postmortem?
