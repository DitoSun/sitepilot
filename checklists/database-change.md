# Checklist — Database / Data File Change

> Scope: SQL databases, JSON / CSV data files, anything "written into".
> DELETE / DROP / TRUNCATE / migration / bulk UPDATE are all rated **HIGH at minimum**; potentially irreversible ones are CRITICAL. [REAL]

## Nine-Step Process (in order — skipping steps is forbidden)

- [ ] **1. Confirm environment**: use evidence to confirm this is production / staging / local, never guess.
- [ ] **2. Confirm target**: which database / which file; which copy is authoritative — the live one wins, local copies are usually stale snapshots. [REAL]
- [ ] **3. Estimate impact**: blast radius — how many rows / files / user-visible surfaces are affected; write it down.
- [ ] **4. Backup**: back up target data before the change; keep both a change-level rollback backup and a full-database snapshot. [REAL]
- [ ] **5. Verify restorability**: actually restore once to a temporary location with the restore tooling, check record counts and structure — byte-identical ≠ structurally sound. [REAL]
- [ ] **6. Prepare rollback**: write down which backup / migration version to roll back to, how to execute, what counts as success.
- [ ] **7. SELECT preview first**: any DELETE / UPDATE first runs a SELECT with the same conditions, count the affected rows, and execute only after aligning with expectations. [REAL]
- [ ] **8. Use transactions where possible**: wrap what can be wrapped; migration scripts must state the down / rollback path.
- [ ] **9. Post-change verification**: record counts, key-field sampling, write-then-read-back, and whether pages / APIs depending on this data are normal.
- [ ] **9b. Business flow verification**: run the full business flow that depends on this data, not just query the database — a 200 API with wrong data is a silent failure. [REAL]
- [ ] **9c. Call-site scan**: before changing data, grep the code for all references to this file / table, confirm no call sites are missed. [REAL]

## Additional Terms for Destructive Operations

- [ ] DELETE / UPDATE conditions precise to a single intent; wide conditions must be manually confirmed for affected row counts before executing — deleting by id once wiped out a whole batch. [REAL]
- [ ] Before UPDATE, confirm the selectivity of the WHERE condition (count with an equivalent SELECT or execution plan) to avoid "thought it changed 1 row, actually changed the whole table". [DERIVED]
- [ ] Ban human "let's try it": do not test commands against production data, experiments only touch local copies. [REAL]
- [ ] Add a sanity check before bulk writes: a sudden count drop (below a safe ratio) directly rejects the write. [REAL]
- [ ] Read-modify-write concurrency: serialize writes with a mutex queue / lock to avoid lost updates; queues must not be nested (deadlock). [DERIVED]
- [ ] Execute large batch changes in batches, verify each batch before continuing, to avoid a one-shot full write corrupting everything with no way back. [DERIVED]
- [ ] Change windows avoid peak hours; someone is on watch during the window; do not leave immediately after the change. [GENERAL]
- [ ] Rehearse the change script once on a local copy / isomorphic environment before production. [REAL]
- [ ] Data import (third-party / xlsx / csv): cross-compare multiple sources and declare the authoritative source; verify row/column integrity after parsing. [REAL]

## Special Terms for JSON Data Files

- [ ] Atomic write: write `.tmp` first, then `rename`; never truncate-rewrite the original file — non-atomic writes once caused intermittent failures. [REAL]
- [ ] Snapshot the old version before writing; keep N copies per retention policy to prevent disk pile-up. [REAL]
- [ ] Explicitly declare "which copy is authoritative" and document it; data files mixed into the deploy package abort the deploy. [REAL]
- [ ] Re-verify a while after the change, to prevent a racing write from overwriting the fix back to the old value. [DERIVED]
- [ ] Backups and transfers of sensitive data files (user tables / sessions) are handled as sensitive data: no git, no public locations, packages treated as sensitive assets. [REAL]
- [ ] Confirm implicit dependencies before changing: clearing session / cache files will cause users to be "invalidated for no reason"; think through these knock-on effects in advance. [REAL]
- [ ] When multiple processes / entry points write the same file, confirm lock or queue protection, otherwise the mutex terms are meaningless. [REAL]

## Naming & Contracts

- [ ] Before changing fields / naming, confirm the naming contract on both data and code sides (data names not matching code names cause "no data"-style silent errors). [REAL]
- [ ] Keep serialization format and sort keys stable to avoid whole-file reformatting creating giant diffs. [REAL]
- [ ] Confirm uniqueness semantics before using business IDs as keys — batch-number / suffix-type fields must not be used as unique keys (the same trap hit twice in 17 days). [REAL]

---

**Cannot confirm environment / authoritative copy / backup restorable / impact surface → STOP → REPORT.**
