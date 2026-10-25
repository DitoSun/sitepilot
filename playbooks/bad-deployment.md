# Playbook — Bad Deployment

> **Deploy success ≠ production success.** Exit code 0 only proves the command finished, not that production is healthy. [REAL]

## TRIAGE

- [ ] What are the symptoms: 5xx / features failing / data anomalies / page still old / style broken?
- [ ] Time relation to the last change: log mtime vs deploy completion / restart time.
- [ ] Impact surface: core features? Auth? Data? Is it growing?
- [ ] Confirm whether relevant parties (users / owners) have been notified — incidents are not silent, but do not exaggerate the impact. [DERIVED]

## LOCATE LAYER — First Determine "Is It Deploy-Caused"

- [ ] Review the deploy checklist: did the build really succeed, did files land completely (was transfer verification done), did the process really load the new code.
- [ ] Check whether server-side environment variables were reset / lost with the deploy (the classic form of "fixed locally, not live remotely"). [REAL]
- [ ] Check whether data files were rolled back to an old version, causing an "all new data gone" style of user-visible failure. [REAL]
- [ ] Go through the classic traps one by one (all have really happened):
  - [ ] Leftover old process holds the port, new version never started, traffic goes to old code — looks like "changed for ages with no effect". [REAL]
  - [ ] Browser / server cache shows you the old page — hard refresh / ignoreCache before concluding. [REAL]
  - [ ] Server-side old scripts / cron still running (deleting locally ≠ stopping remotely). [REAL]
  - [ ] Deploy package overwrote data files (a desync incident of separate data/code deployment). [REAL]
  - [ ] Build artifact residue (cache directories / type artifacts) causes runtime behavior to diverge from source. [REAL]
  - [ ] Automated probes blocked into 403s by your own anti-bot rules, misread as an outage. [REAL]

## ASSESS IMPACT — The Rollback Decision

- [ ] Any one met → **prioritize rollback**, do not drag on while fixing: core features failing / auth broken / data anomalies / large-scale 5xx. [REAL]
- [ ] Session store cleared / rolled back causing mass logouts → trigger rollback directly. [REAL]
- [ ] Only a localized non-critical defect with a clear root cause → hotfix allowed, but the full verification process still applies.
- [ ] Rollback decisions must be fast: restore service first, then analyze root cause. [REAL]

## MITIGATE / RECOVER

- [ ] Use pre-created, verified rollback points: last working build / data snapshot / git tag.
- [ ] When data files are forward-compatible (purely additive fields), roll back the code mainly; when structurally incompatible, roll back code and data together. [DERIVED]
- [ ] Preserve the incident scene (bad build / logs / snapshots) for investigation; do not rush to clean up and destroy evidence. [REAL]
- [ ] Do not persist in fixing because "we already started" — sunk cost is not a reason. [REAL]

## VERIFY (post-rollback verification is still required — a rollback is also a change)

- [ ] Full semantic verification: key page content, API record counts and freshness, auth triple test, write-path persistence, no unexpected redirects. [REAL]
- [ ] Watch error rates / restart counts / logs for several minutes, compare with the pre-incident baseline.
- [ ] After rollback, walk the mobile critical path too — a rollback is also a change; verification standards do not drop. [REAL]

## INVESTIGATE

- [ ] Distinguish "new-code bug" from "old client / old tab noise" (timeline alignment). [REAL]
- [ ] Focus on the four classic root causes: build artifact residue, cache, server-side old scripts, data files overwritten by the deploy package.
- [ ] After fixing the root cause, scan the whole site for the same pattern / call sites. [REAL]
- [ ] Check whether deploy scripts hardcode environment info (paths / version numbers), causing failure when switching environments. [REAL]

## LEARN

- [ ] Write "rollback point creation + verification" into the deploy process as a pre-step.
- [ ] Upgrade this change's traps into pre-deploy / post-deploy checklist items or automated checks.
- [ ] Solidify "post-deploy semantic verification" as a mandatory process step; skipping it for any reason is not allowed. [REAL]
- [ ] If this was a failed security-fix deploy: the fix must be co-designed with the migration plan; no long-running "afraid to ship" debt. [REAL]
