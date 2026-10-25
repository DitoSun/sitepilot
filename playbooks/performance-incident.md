# Playbook — Performance Incident

> Iron rule: **measure first, guess later.** Optimization without measurement is gambling. [REAL]

## TRIAGE

- [ ] Restate the problem: is "slow" slow first screen / janky interactions / slow API / slow full chain? The user's own words may be a misjudgment — cases of "slow API" actually being a client-side problem have really happened. [REAL]
- [ ] When did it start, which pages / paths / user groups are affected.
- [ ] Recent changes: deploy / data growth / new features / upstream changes.

## LOCATE LAYER — Locate by Layer, Measure End-to-End First

| Layer | Measurement approach |
|---|---|
| Client rendering | Count concurrent requests; large lists rendered unpaginated all at once; image / asset sizes |
| Network / bandwidth | Whether egress bandwidth is a hard cap; transferred size vs compressed size |
| CDN / reverse proxy | Whether compression covers the actual content types; cache hit rate; origin latency |
| Server | CPU / memory / disk IO; when bandwidth is saturated, optimizing transfer beats upgrading CPU |
| App | API timing; synchronous blocking operations on the request chain; full-fetch cost |
| Data | Query / read latency; data file size and parsing overhead |
| External deps | Upstream API latency; timeout and fallback strategy |

- [ ] Measure end-to-end (what the user actually waits) before measuring server-side API timing — if the two differ greatly, the problem is in the middle layer. [REAL]
- [ ] "Stuck ≠ slow API": curl the API directly to measure the server; if the server is innocent, check client connections / rendering. [REAL]

## ASSESS IMPACT

- [ ] Impact scope and severity (all users / specific paths / specific devices).
- [ ] Is it worsening (gradually slower each week due to data growth vs a sudden change).

## MITIGATE / RECOVER — Classic Pattern Quick Reference

- [ ] Unpaginated large list + missing lazy loading → paginate + lazy load (img requests starving same-domain connections was a real root cause). [REAL]
- [ ] Compression not covering the actual content types (only HTML compressed, prefetch payloads / xml sent raw) → add compression per actual response type, verify transferred size. [REAL]
- [ ] Synchronous blocking on the request chain (e.g., running external commands synchronously) → move off the chain or make async. [REAL]
- [ ] Cache invalidation storm (mass simultaneous origin fetches) → expiry jitter / prewarming / origin rate limiting. [DERIVED]
- [ ] Image optimization pipeline blocking business → disable optimization to preserve availability first, then fix separately. [REAL]
- [ ] High-frequency polling hogging quota → dedicated rate-limit bucket, isolated from normal APIs. [REAL]

## Fix Discipline

- [ ] Change only one layer at a time; after the change, measure and verify with the same method, then decide whether to touch the next layer. [DERIVED]
- [ ] Validate boundary values with real data distribution, not vibes (a filter cap once locked real data out of the list). [REAL]

## Rollback Triggers

- [ ] An optimization change introduces functional errors / data inconsistency → immediately roll back that layer's change. [DERIVED]

## VERIFY

- [ ] Re-measure the same metric after optimizing (same environment, same method), compare before/after data, do not go by feel.
- [ ] Semantic regression: functionality and data still correct — performance changes most easily break boundary values. [REAL]

## INVESTIGATE

- [ ] Record the bottleneck layer and quantified data, forming a "performance profile of this site" for future comparison.

## LEARN

- [ ] Bring critical-path timing into monitoring; upgrade compression coverage checks, boundary-value validation, and large-list detection to automated checks.
