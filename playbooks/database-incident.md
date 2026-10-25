# Playbook — Database / Data Incident

> Scenarios: data corruption / accidental deletion / inconsistency / overwrite / sync divergence. [REAL]
> Iron rule: stop the bleeding first, recover second, investigate last. Directly "trying things" against production data during an incident is forbidden. [REAL]

## TRIAGE

- [ ] What is the symptom: sudden record-count drop? Key fields wrong? API errors? Users seeing old data / data gone?
- [ ] Is it still worsening — is there write traffic still polluting the data?
- [ ] What changed recently: deploy / data script / manual file edit / sync task?

## LOCATE LAYER — Locate the Data Layer

- [ ] Confirm which copy is authoritative: the live one wins, local copies are usually stale snapshots — across multiple machines, declare the authoritative one before acting. [REAL]
- [ ] When multiple copies disagree: compare record counts and key fields file by file / table by table, confirm which is newest and most complete. [REAL]
- [ ] Trace the pollution chain, four classic root causes:
  - [ ] Deploy package overwrote data files. [REAL]
  - [ ] Multi-writer divergence (multiple processes / multiple machines each writing their own, then overwriting each other). [REAL]
  - [ ] Half-writes or regressions from racing / non-atomic writes. [REAL]
  - [ ] Wide-condition misoperation (deleting by id actually wiping a whole batch). [REAL]

## ASSESS IMPACT

- [ ] How many records / user-visible surfaces are affected? Is there a backup? Irreversible loss without a backup = CRITICAL: **STOP → REPORT → proceed only with explicit confirmation**. [REAL]

## MITIGATE — Stop the Bleeding First

- [ ] Stop writes: pause related write endpoints / scheduled tasks / sync scripts, isolate the fault source. [REAL]
- [ ] Freeze the scene: snapshot the current (even if broken) data before talking about recovery — the scene is the investigation evidence. [REAL]

## RECOVER — Restore from Backup with Three-Step Verification

- [ ] Select the recovery source: change-level backup first, whole-site snapshot as fallback. [REAL]
- [ ] Three-step verification, none optional: two-way md5 → structure / record-count check → key-field sampling. [REAL]
- [ ] Multi-copy scenario: restore against the live authoritative copy; re-sync local copies (compare before landing, streaming bulk transfer, per-file verification, full-tree comparison after install). [REAL]

## VERIFY — Semantic Verification

- [ ] Record counts back in the expected range; key-field sampling correct; all pages / APIs depending on this data normal. [REAL]
- [ ] Re-verify a while later, to prevent a racing write from overwriting the fix back to the old value. [DERIVED]

## INVESTIGATE

- [ ] Root-cause classification: wide-condition deletion / non-atomic write / multi-writer divergence / deploy overwrite / sync direction reversed?
- [ ] Scan the whole site for the same write paths: which other endpoints / scripts have the same problem. [REAL]

## LEARN — Write Protections & Prevention Upgrades

- [ ] Deletes / bulk writes: same-condition SELECT preview + affected-row confirmation + sudden-count-drop write rejection. [REAL]
- [ ] JSON files: atomic write (tmp + rename) + pre-write snapshot + retention policy. [REAL]
- [ ] Multi-writer scenarios: single-writer principle (only the server writes), or mutex queue serialization (queues must not be nested — deadlock). [REAL]
- [ ] Add a confirmation dialog for destructive operations in admin. [REAL]
- [ ] Upgrade preventive measures to automated checks / write guardrails, not just documentation. [REAL]
