# Checklist — Post-Deploy Verification

> **Deploy success ≠ production success.** Exit code 0, build OK, deploy OK prove nothing. [REAL]
> **HTTP 200 ≠ business correctness.** A 200 can also mean stale cache, soft degradation, data truncation. [REAL]

## A. Transport & Process

- [ ] Deploy channel verification passed: after files land, do a two-way checksum (e.g., md5 comparison) — do not just check that the transfer command reported no error — batch transfers have silently failed before. [REAL]
- [ ] Process has restarted, and the startup log is error-free; fail-closed startup failures must be explicitly visible — no "started but half-broken" states. [REAL]
- [ ] The process actually loaded the new code (check build ID / version marker), not an old process holding the port. [REAL]
- [ ] Cache layer refreshed / invalidated as expected (CDN / reverse proxy / app cache); do not let old responses keep serving. [DERIVED]
- [ ] Scheduled tasks / cron running as expected: not reset by the deploy, logs show normal executions. [REAL]
- [ ] Backup tasks still running normally after the deploy — deploys often break backup scripts as a side effect; do not wait for an incident to discover it. [REAL]

## B. Semantic Verification (core — testing only for 200 is forbidden)

- [ ] Homepage and key pages return **expected content**: check key copy / data / components page by page, not just status codes. [REAL]
- [ ] Key APIs' record counts and data freshness match expectations — a sudden count drop / stale data = silent failure, treat as an incident. [REAL]
- [ ] Auth flow triple test: anonymous access to protected endpoints rejected; login succeeds; old session invalidated after logout. [REAL]
- [ ] Writes truly persist: run a full write path, confirm data actually lands and can be read back. [REAL]
- [ ] No unexpected redirects: redirect chains on key URLs match expectations (temporary 302 / permanent 301 not mixed up). [REAL]
- [ ] Walk the mobile critical path: do not test only the desktop homepage. [REAL]
- [ ] No obvious errors in the browser console — first clear known noise (e.g., missing favicon) to avoid interfering with real problem localization. [REAL]
- [ ] After writes are verified, run an external-dependency smoke: actually invoke email sending / upstream API / third-party services once (with a test account). [REAL]
- [ ] SEO smoke: sitemap / robots / key pages accessible, not accidentally blocked, crawl logs show normal fetching. [REAL]
- [ ] Performance smoke: key page load times compared with pre-deploy, no order-of-magnitude regression. [DERIVED]
- [ ] Spot-test historical data pages / archive pages: old content still accessible — rollback / overwrite incidents often strike here. [DERIVED]

## C. Cache Exclusion (mandatory before concluding "the change didn't take effect")

- [ ] Hard-refresh / use the ignoreCache parameter / switch to an incognito window, then judge "the change didn't take effect". [REAL]
- [ ] Only touch code after ruling out server cache and solidified static pre-renders still not matching expectations — code that wasn't broken was nearly changed before. [REAL]

## D. Monitoring Watch

- [ ] Watch error rates / error reports for several minutes, compare with the pre-deploy baseline. [REAL]
- [ ] Check process restart counts: abnormal restarts after deploy mean it's not fixed; restart frequency is itself a stability signal. [REAL]
- [ ] Read through the logs from this period, distinguish "new code bug" from "old client / old tab noise" (log mtime vs restart time). [REAL]
- [ ] New features ship with monitoring / log visibility — no "go live = go blind". [REAL]

## E. Wrap-Up

- [ ] Update the changelog: record "what changed + why", not just actions — decision traces prevent flip-flopping. [REAL]
- [ ] Run Lesson Review: any incidents / near misses / wrong assumptions / better methods this time? If so, write to the local experience store and turn it into a behavior change. [REAL]
- [ ] If this was a security fix rollout: confirm the fix is actually live in production (verify behavior change with a read-only probe) — no long-running "fixed but afraid to ship" debt. [REAL]
- [ ] Clean up temp files and debug toggles created this time; do not carry debug residue into production. [REAL]

---

**Core warning: a 200 response with silently truncated data is an incident, not a success.** [REAL]
