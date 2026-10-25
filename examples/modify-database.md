# Example: "Change this data in the database"

> Demonstrates: the nine-step data change + SELECT preview. Core SKILL §5 risk
> model + `checklists/database-change.md` + `references/database-safety.md`.

---

**User**: Change this data in the database. (attached: a batch of ids and the values to change)

## How SitePilot Thinks

Data changes start at HIGH: mistakes are irreversible, they affect real users, and the "delete by id
deletes the whole batch" trap is real. **Confirm environment and target first, then SELECT-preview
the blast radius, then back up, then act.** The more the user rushes, the less you may skip steps.

## What to Load

- `checklists/database-change.md` (data change checklist)
- `references/database-safety.md` (nine-step data operations, SELECT first, write protection)
- If the data is JSON files: `recipes/node-json-store.md` (snapshot/atomic write/sanity check)

## Reasoning Process (nine steps)

```
1. UNDERSTAND   Restate: which records, changed to what, why. The user says
                "this data" — read the full list first, confirm no ambiguity
                (exactly which is "this").
2. INSPECT      Which database? Which copy is authoritative? (local copies
                are usually stale snapshots — production vs local count
                mismatches are normal; confirm before acting)
3. ASSESS RISK  Bulk data modification = HIGH: impact analysis + backup +
                rollback plan + verification plan; missing any one is not an
                option. May touch large numbers of real users → CRITICAL,
                stop and report.
4. PLAN         State clearly: WHERE condition, which fields change, what
                must not change, how to verify.
5. BACKUP       Back up the target database/data files; confirm the backup
                is restorable (three-step check).
6. SELECT       First SELECT with the **same condition**, showing the user
   PREVIEW      the hit count and samples.
7. EXECUTE      Conditions precise to single rows; bulk operations in small
                steps per batch; JSON storage goes through atomic write +
                pre-write snapshot + sanity check (refuse on count plummet).
8. VERIFY       Re-check the hit records: fields are the new values,
                neighboring records that must not change are untouched.
9. MONITOR      Watch subsequent errors and data freshness.
```

## Key Decision Points

1. **Wide conditions are the disaster zone**: once "delete by id" deleted an entire batch (condition
   width != intent). DELETE/UPDATE WHERE must be precise to the intended scope, or force batch
   confirmation. [REAL]
2. **SELECT preview is a hard gate**: do not act until the user confirms the blast radius. Counts
   differing from expectations (e.g. 500 matched instead of 5) → stop.
3. **ids may not be unique keys**: business ids (batch numbers, suffix classes) collide often —
   locating by a non-unique key equals "randomly picking records to change". Confirm key uniqueness
   first. [REAL]
4. **Normalization symmetry**: matching by name/case uses the same-side rules in storage and query,
   otherwise "changed but no effect" or false matches. [REAL]
5. JSON storage: **re-verify a while after** changes (against concurrent-write overwrites); when data
   files are forward-compatible (fields only added), the rollback point is mainly the code. [REAL]

## How to Verify

- SELECT re-verification: all hit records are new values; boundary records (should-not-change)
  untouched.
- Count reconciliation: counts match before and after (except deliberate adds/deletes).
- App-layer smoke: key pages/endpoints using this data return correct content.
- If JSON files: snapshots generated, sync health-check tool shows no divergence.

## Lesson Review

Data tasks almost always distill something: newly discovered key semantics, new misdiagnosis
patterns, real errors caught by the preview flow. Write into `.sitepilot/lessons/`; if the same
problem appears twice (same trap hit twice), upgrade the lesson to a checklist or guardrail —
**recurrence = escalate**.