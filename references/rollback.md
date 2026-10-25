# Rollback — SitePilot Reference

> **Solves:** when to roll back instead of continuing to fix, how to create and
> verify a rollback point, and what to do after rolling back — core insight:
> sometimes the best fix is a rollback.

Source: §12 rollback philosophy + EXP-015/018/023/025/029/038/058/087.

---

## 1. Rollback triggers

If any one is met, evaluate rollback (that is "evaluate rollback", not "try fixing again"):

| Trigger | Corresponding incident |
|---|---|
| Core pages 5xx / widespread failure | Build gap window causing strings of 502s |
| Auth failure / mass session drops | Session store cleared/reset |
| Widespread API failure or data anomalies | Data out of sync, new content all invisible |
| Data corruption | Bulk data written bad |
| Mass JS errors | Distinguish new from old noise first before deciding (old-tab noise does not trigger rollback) |
| Key features broken after deploy | Soft degradation made "all new content disappear" |

Source: all [REAL].

## 2. Rollback decision principles

| Rule | Detail | Source |
|---|---|---|
| Sunk cost is not a reason | Don't insist on continuing the fix because "we already started"; restore service first, analyze root cause after | [REAL] §12 |
| Decide fast | Every extra minute is another minute of user loss; rollback decisions are made in minutes — no perfectionism during an incident | [DERIVED] §12 |
| Distinguish new from old noise first | For mass JS errors, first judge by timeline whether it is old-client noise or a new-code problem, then decide whether to roll back | [REAL] EXP-029 |
| Rollback is also a change | After a rollback, run production verification + observation the same way (see production-verification.md) | [REAL] §12 |

## 3. Roll back or fix forward

| Scenario | Choice |
|---|---|
| Root cause unknown, or the fix requires major changes | Roll back |
| Root cause clear, fix is small, impact controllable | May fix forward, but set an observation deadline — when it expires, roll back |
| Data already corrupted | Stop writes first + preserve the scene, then recover from backup (see incident-response.md) |
| Config-class error | Revert to the old config first — that is the fastest rollback |
| Fix involves a "security vs UX" trade-off | Stop and report — that is a user decision |

Source: [DERIVED] §12 (the decision framework is derived; all triggers are real incidents).

## 4. Rollback points: creation & verification

| Rule | Detail | Source |
|---|---|---|
| Create before the change | Rollback points must be created and verified before the change: previous build artifacts, data snapshot, git tag | [REAL] §12 |
| Verify restorability | A backup not verified restorable = no rollback point (three-step verification in backup-recovery.md) | [REAL] EXP-087 |
| When data is forward-compatible, code is the main rollback point | With incremental new-field changes, data files usually need no rollback; rolling back the code is enough | [REAL] §12 |
| Confirm data compatibility before rollback | Before rolling code back to the old version, confirm the old version can correctly read the current data structure | [DERIVED] §12 |

## 5. Rollback execution & verification

| Step | Action |
|---|---|
| 1 | Execute the rollback: restore the previous build artifacts / data snapshot / git tag |
| 2 | Semantically verify production: content, record counts, auth state, critical path |
| 3 | Watch error rate, restart count, and logs for a while |
| 4 | Record the incident and the rollback decision (change log + Mini Postmortem) |
| 5 | Then re-enter the INVESTIGATE → FIX → LEARN phases |

## Agent Quick Check

- Are rollback trigger conditions already met? (core 5xx / auth failure / data anomaly / key-feature failure)
- Am I insisting on continuing the fix because there is evidence it can be fixed, or because of sunk cost?
- Was the rollback point created and verified before the change?
- After the rollback, did I do semantic production verification, not just "the service is up"?
- Is the rolled-back code version compatible with the current data?
