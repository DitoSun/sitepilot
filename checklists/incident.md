# Checklist — Incident Response

> Priority order in a production incident: ① reduce impact ② restore service ③ prevent data loss ④ then analyze root cause. [REAL]
> **No large refactors during an incident.** Restore first, fix root cause later. [REAL]

## 1. MITIGATE — Stop the Bleeding First

- [ ] Assess the impact surface and spread trend: error-rate curve, affected scope, whether it is growing. [REAL]
- [ ] Degrade or stop the fault source / leak source: stop dangerous cron, stop old automation scripts, rate-limit, remove faulted nodes. [REAL]
- [ ] Assess rollback (see triggers below): restore service first, then discuss fix plans. [REAL]

## 2. STABILIZE — Prevent Spread

- [ ] Preserve the scene: freeze logs, data snapshots, and current config first — the investigation hasn't started, do not destroy evidence first. [REAL]
- [ ] Do not touch unrelated parts, do not "while I'm at it" fix other problems, avoiding secondary incidents. [REAL]
- [ ] If it is a data incident: stop writes / isolate first, then recover. [REAL]

## 3. RECOVER — Restore

- [ ] Roll back first when possible (last working build / data snapshot / git tag); restore data from backup and verify. [REAL]
- [ ] After rollback, production verification + observation is still required — a rollback is also a change. [REAL]

## 4. VERIFY — Verify (semantics, not just status codes)

- [ ] Key pages return expected content; key API record counts and freshness normal; auth triple test passes. [REAL]
- [ ] Confirm no silent failures like "200 but data truncated / stale". [REAL]
- [ ] Re-test from multiple locations / networks to rule out single-point misjudgment. [DERIVED]

## 5. INVESTIGATE — Investigate

- [ ] Align the timeline: log mtime vs service restart time, distinguish new bugs from old client noise. [REAL]
- [ ] Root-cause questions go to "why", not stopping at "what happened". [REAL]
- [ ] Check "changed locally ≠ changed remotely": are server-side old scripts / old processes still running. [REAL]

## 6. FIX — Fix

- [ ] Fix the root cause, and scan the whole site for the same pattern / all call sites — fixing only the reported instance leaves several others to keep polluting. [REAL]
- [ ] Fixes go through the full process too: local verify → deploy → production verify. [REAL]
- [ ] Distill into a general rule ("this field type cannot be a unique key"), not "that bug is fixed". [REAL]

## 7. LEARN — Postmortem

- [ ] Write a Mini Postmortem: timeline, impact, root cause, handling, gaps. [REAL]
- [ ] Create a Lesson Candidate and turn it into a **behavior change**: rule / checklist item / playbook path / automated check. [REAL]
- [ ] Recurrence rule: the same problem appearing a second time = the previous lesson failed; escalate defenses: documentation → checklist → automation → guardrail. [REAL]

## Rollback Triggers (any one met = prioritize evaluating rollback)

- [ ] Core pages 5xx or large-scale failures. [REAL]
- [ ] Auth failure / sessions mass-invalidated. [REAL]
- [ ] API mass failures or data anomalies (sudden count drops / key fields wrong). [REAL]
- [ ] Data corruption. [REAL]
- [ ] Key features failing after deploy (e.g., soft degradation causing "all new data gone"). [REAL]
- [ ] Massive JS errors (distinguish new vs old noise before deciding). [REAL]
