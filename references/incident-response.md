# Incident Response — SitePilot Reference

> **Solves:** what to do first while a production incident is happening —
> reduce impact, restore service, prevent data loss, and only then chase root
> cause; and how a Mini Postmortem turns one incident into permanent prevention
> afterward.

Source: §11 incident-response model + EXP-007/018/040/041/042/087/088. For specific failure scenarios, use together with `playbooks/`.

---

## 1. Six-phase response

In a production incident, the priority goals are not "find the prettiest fix", but: ① reduce impact ② restore service ③ prevent data loss ④ only then analyze root cause.

| Phase | Action | Source |
|---|---|---|
| MITIGATE | Stop the bleeding first: shut the leak source (the cron job / old script pushing data), degrade, rate-limit | [REAL] EXP-007 |
| STABILIZE | Prevent spread: don't touch unrelated parts; preserve the scene (logs / snapshots — the scene is the evidence) | [REAL] EXP-018 |
| RECOVER | If you can roll back, roll back first (see rollback.md); restore data from backup and verify | [REAL] EXP-087/088 |
| INVESTIGATE | Align the timeline (log time vs restart time); chase the root cause to the "why", never stop at "what happened" | [REAL] EXP-040/042 |
| FIX | Fix the root cause + scan the whole site for call sites + sink the rule | [REAL] EXP-041 |
| LEARN | Incident annotations + lessons into the pool + checklist updates | [REAL] L12/L13 |

**Iron rule: never run a large refactor during a production incident.** Fix and migration plans may be designed together, but during an incident you only stop the bleeding.

## 2. Stop conditions during an incident

During an incident, the SKILL.md §7 stop conditions still apply to the following actions:

- When you cannot confirm which copy of the data is authoritative, write no data at all
- When no backup exists or it is unverified as restorable, perform no destructive operations
- When the incident is still growing, mitigate first and report second; do not dig deep before stopping the bleeding
- "Security vs UX" trade-offs (e.g. forcing everyone to re-login) are user decisions, not agent decisions

## 3. Mini Postmortem template

Fill in after every incident (or serious near miss):

```markdown
## WHAT happened
(fact timeline, no speculation; every entry timestamped)

## WHY it happened
(root cause, chased to the mechanism layer; "operator error" is not an acceptable answer)

## IMPACT
(blast radius: which features / how many users / how long; use coarse magnitudes, never identifiable data)

## HOW it was recovered
(recovery actions and time cost; whether a rollback was taken)

## WHY the existing safeguards failed
(why existing monitoring/checks didn't stop it — the most valuable question of all)

## WHAT would prevent recurrence
(concrete prevention measures; at least one of the four categories below)

## WHAT TO LEARN
- Update rule?        → which rule to change
- Update checklist?   → which checklist to add to
- Update playbook?    → which troubleshooting path to change
- Update automation?  → what automated check to add
```

**A lesson that changed no behavior (rule / checklist / playbook / automation) was never learned.** (SKILL.md §9: a lesson is not "learned" until it changes behavior.)

## Agent Quick Check

- Am I doing "stop the bleeding" or "digging for root cause" right now? Is the order right?
- Is the scene (logs / snapshots) preserved? Are recovery actions traceable?
- Did an opportunistic refactor show up during the incident? Stop.
- Did you answer the postmortem's "WHY safeguards failed"?
- Has this lesson already landed in at least one of: rule / checklist / playbook / automation?
