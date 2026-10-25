# Database & Data Safety — SitePilot Reference

> **Solves:** how to protect yourself before any write to a database / data
> files — the nine-step procedure, blast-radius previews, transactions and
> write protection, plus the inherent cost of "using JSON files as a database".

Source: EXP-010~022 (data safety & consistency). Risk levels follow SKILL.md §5 and stop conditions SKILL.md §7 — not reinvented here.

---

## 1. The nine-step data procedure

| Step | Requirement |
|---|---|
| 1. Confirm the environment | Which am I connected to — production / staging / local? Can't answer → stop (SKILL.md §7.1) |
| 2. Confirm the target | Which database / which data file? Which copy is authoritative? (§7.2) |
| 3. Estimate the impact | Blast radius: how many rows / how many users / which features |
| 4. Back up | HIGH/CRITICAL: back up first (see backup-recovery.md) |
| 5. Verify restorability | A backup not verified restorable = no backup |
| 6. Prepare the rollback | Write and verify the rollback statement / snapshot first |
| 7. SELECT first | Before executing, use an identical-condition SELECT to preview the blast radius |
| 8. Use transactions where possible | Wrap writes in a transaction where possible so failure rolls back as a whole |
| 9. Verify after the change | Semantic verification: record counts, field values, related features (see production-verification.md) |

## 2. Risk levels: deletes & bulk operations all start at HIGH

| Operation | Level | Detail |
|---|---|---|
| DELETE / DROP / TRUNCATE | HIGH at minimum; CRITICAL when irreversible or wide blast radius | For CRITICAL, the agent must not execute silently by default — must stop and report (SKILL.md §5) |
| migration / schema change | HIGH | Design bundled with the data migration plan; validate boundary data first |
| bulk UPDATE | HIGH | Condition width determines the blast radius |
| Single precise UPDATE | MEDIUM | Still needs backup and verification |
| Read-only SELECT | LOW | Watch timeouts and load on large tables |

Stacked delete/bulk operations are handled at the higher level; when unsure, level up.

## 3. Delete safety

| Rule | Detail | Source |
|---|---|---|
| Preview with identical conditions before deleting | Incident: deleting by id actually wiped an entire batch (over a hundred rows in one go) — condition width didn't match intent. Before executing, you must SELECT the rows to be deleted with identical conditions and confirm | [REAL] EXP-020 |
| Conditions precise to a single row, or forced bulk confirmation | Delete endpoints either have unique conditions or explicitly require "confirm deleting N rows" | [REAL] EXP-020 |
| Secondary confirmation for admin destructive operations | A protection dialog added after a misdelete; all admin-surface deletes should have one | [REAL] EXP-019 |

## 4. The cost of using JSON files as a database

Database-less sites commonly store data in files. Every cost below maps to a real incident:

| Cost | Incident shape | Countermeasure |
|---|---|---|
| Multi-writer divergence | Local/server/backup each writing their own; sync inevitably conflicts, hundreds of entries merged by hand | Single writer (only the server writes), or move to real storage with merge semantics [REAL] EXP-010 |
| Non-atomic write race | Crashes mid-write; intermittently reads a corrupt file | Write to a temp file first, then rename (atomic write, tmp+rename); for intermittent failures give users a "refresh" way out, and the copy must not imply "content has been taken down" [REAL] EXP-011 |
| Read-modify-write lost update | Under concurrency, the later write overwrites the earlier | Serialize with a mutex queue; queues must not nest (deadlock); write the "why" into comments [REAL] EXP-012 |
| Misdelete with no fallback | A script mistakenly deletes user data | Write protection: refuse writes on sudden count drops (e.g. halved) [REAL] EXP-013 |
| Writes leave no trace | You break it and don't know what it was before | Auto-snapshot before writing (keep N copies per file) [REAL] EXP-014 |
| Recovering via version history = incident signal | Data corruption recovered via version control | Version control is the last line of defense, but "needing it to recover" is itself an incident [REAL] EXP-018 |
| Two sources of truth | Redundant snapshots out of sync with the primary store; stale data still displayed | Redundant data must be either derived or synced [REAL] EXP-021 |

Backup as the unified entry point of the write layer: new write points (new features, new endpoints) are the easiest to miss when wiring up backups and snapshots — check every time a new write point is added.

## 5. Authoritative copy & sync health check

| Rule | Detail | Source |
|---|---|---|
| Production data is authoritative | Local copies are usually stale snapshots; experiments touch local only, and back up before experimenting | [REAL] EXP-016 |
| Declare the authoritative copy explicitly and write it into docs | For multi-machine work, "which copy is authoritative" must be a documented consensus | [REAL] EXP-016 |
| Separate data/code deploys must come with a sync health check | Incident: local and production counts inconsistent, users couldn't see new content. You need a per-file comparison tool (decidable by exit code), plus a deploy-package guard against data riding along | [REAL] EXP-015 |
| Keep data-change serialization stable | One reformat/reorder creates a giant diff; bulk data changes are committed separately with provenance recorded | [REAL] EXP-017 |

## Do not assume the direction of divergence [REAL]

The reflexive assumption is "local/dev copy is older, production is ahead."
It is wrong often enough to be dangerous.

A real case: the local user table held **more** rows than production
(7,539 vs ~6,447). Anyone acting on "local is a subset, I can top production
up" would have pushed test records and resurrected deleted accounts into the
authoritative store.

Before any reconciliation, establish — from evidence, not expectation:

| Question | Why it matters |
|---|---|
| Which store is the source of truth? | Determines which side may be written |
| What is the write path? Who writes, from where? | Multiple writers explain divergence better than "staleness" |
| What do timestamps say? | Direction of travel, if timestamps are trustworthy |
| Which side is more complete, and in which dimension? | "More rows" ≠ "more correct"; rows can be test data |
| Is there a replication direction already? | A reverse sync may be undoing your work |

Then choose: forward-apply, back-apply, merge with an explicit rule, or **do
nothing and investigate**. "Do nothing" is a legitimate outcome.

Never reconcile by row count alone. Counts can match while content differs,
and can differ while both sides are correct for their purpose.

> When two sources disagree, establish source of truth, write path, timestamps,
> completeness, and replication direction — before choosing a direction.
> (EXP-116)

## Agent Quick Check

- Do I know which data I am modifying? Is it the authoritative copy? (Can't answer → stop)
- Before delete/bulk operations, did I preview the blast radius with an identical-condition SELECT?
- Backup done? Verified restorable? Rollback plan written?
- Do concurrent writes have atomicity and mutual exclusion? Are new write points wired to backup/snapshot?
- After the change, did I verify record counts and business behavior, or only see "the endpoint didn't error"?
