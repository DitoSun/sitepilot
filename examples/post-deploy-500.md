# Example: "The site is 500 right after deploying"

> Demonstrates: bad-deployment playbook + rollback decision. Core SKILL §11
> incident response + §12 rollback philosophy + `playbooks/bad-deployment.md`
> + `references/rollback.md`.

---

**User**: The site is 500 right after deploying, what do I do?

## How SitePilot Thinks

Production incident, priority order: **restore service first, then analyze the root cause**.
Iron law: no large refactors during an incident. "Right after deploying" is a strong signal
— most likely a new-build/new-config problem, the old build is still there, and **rollback
is the fastest recovery path**. But spend 60 seconds first confirming "is it caused by the
deploy", do not roll back an unrelated incident by mistake.

## What to Load

- `playbooks/bad-deployment.md` (post-deploy failure playbook)
- `references/rollback.md` (rollback triggers and principles)
- `references/incident-response.md` (MITIGATE→LEARN six phases)

## Reasoning Process

```
1. TRIAGE       Is the 500 site-wide or partial? Static pages also 500 →
                process/reverse-proxy layer; only dynamic endpoints 500 →
                application layer. Measure with curl first, do not guess.
2. ALIGN        Log mtime vs deploy/restart time: were errors generated after
   TIMELINE     the restart, or pre-restart old noise? (old-tab Server Action
                errors are not a new bug) [REAL]
3. FAST         Last few lines of app logs; process state; is the disk full
   EVIDENCE     (log/build artifact accumulation kills services in bizarre
                ways); are environment variables in effect (restarted without
                --update-env = running on stale config) [REAL]
4. DECIDE       Rollback or hotfix?
                 - Core pages 5xx / large-scale failure / auth failure / data
                   anomaly → rollback trigger hit, assess rollback [REAL]
                 - Minimal impact with a clear root cause (e.g. one config
                   item) → hotfix possible, but a rollback point must be
                   prepared in sync
5. EXECUTE      Rollback: switch back to the old build → restart → semantic
                verification. With the old build present, this is a
                seconds-level operation. Do not insist on continuing because
                "I already started fixing" — sunk cost is not a reason.
```

## Key Decision Points

1. **Restore first, analyze after**: only after MITIGATE → STABILIZE → RECOVER comes
   INVESTIGATE. The most expensive mistake when the user is anxious is "heads-down bug fixing
   without restoring service".
2. **Rollback is also a change**: after switching back to the old build, semantic verification
   + observation are mandatory; do not "declare done once switched". [REAL]
3. **No large refactors during incidents**: only stop-loss actions. Fixes and refactors
   separate; refactors go through the normal change workflow. [REAL]
4. **Do not be led astray by old noise**: after a redeploy, align mtime first when logs flood
   with errors; treating old-client errors as a new bug and changing code = changing the wrong
   place during an incident. [REAL]
5. **If the old build is also lost**: the deployment discipline has a hole (no rollback point
   kept) — that itself is the systemic problem to fix; restore from a whole-site snapshot
   first, then patch the discipline.

## How to Verify

- After rollback/fix: key pages hard-refresh 200 + contain expected content; auth state
  normal; write path really persists; APIs return current data.
- Server: restart counts stop climbing, no new log errors, disk water level normal.
- Observe for a sustained period (error rate, user feedback channel) before closing.
- Report back: root cause (down to "why"), what was done, verification results, follow-up
  anti-recurrence actions.

## Lesson Review

Incidents always have Lessons. This one settles at minimum: whether the rollback point
existed beforehand (if not → upgrade "keep the old build" to a mandatory deploy checklist
item); whether the root cause is a recurrence of a known trap (recurrence = the earlier
lesson failed; escalate per documentation→checklist→automation→guardrail). All into
`.sitepilot/lessons/` and update the matching checklists/playbooks — **a lesson counts as
learned only when it changes behavior**.