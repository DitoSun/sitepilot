# Backup & Recovery — SitePilot Reference

> **Solves:** what makes a backup count — two backup levels, packaging only
> the non-reproducible parts, the three-step verification, pulling backups
> local, and restore drills; core insight: a backup that cannot be restored is
> not a reliable backup.

Source: EXP-084~089 (backup & recovery) + EXP-014 (write-layer backup entry point) + EXP-006 (sensitive-data handling in backup packages).

---

## 1. Core principles

| Rule | Detail | Source |
|---|---|---|
| A backup that cannot be restored is not a reliable backup | The definition of a backup includes "restore tooling + restore drills", not just "a package was made" | [GENERAL] EXP-089 (no corresponding practice, explicitly marked) |
| "Packaged" ≠ "backed up" | Packaged but not verified, not pulled local, never test-restored = not backed up | [REAL] EXP-087/088 |
| Treat backup packages as sensitive data | Packages containing env files and user data must never land in any git repository | [REAL] EXP-006/088 |

## 2. Two backup levels

| Level | Covers | Requirement |
|---|---|---|
| Single-change rollback backup | Rolling back one specific change | Create a directory by "change name + timestamp", preserving the original directory structure |
| Whole-site disaster recovery snapshot | The server is lost entirely | Package the whole site, only the non-reproducible parts (next section) |

Source: [REAL] EXP-084. With only whole-site snapshots as your backup, rolling back a single change becomes very hard.

## 3. Package only the non-reproducible parts

| Rule | Detail | Source |
|---|---|---|
| Exclude reproducible artifacts | Exclude dependency directories, build artifacts, version history, old backup directories — the non-reproducible part of a whole-site package may be a small fraction (case: most of a whole-site package's volume was reproducible build garbage) | [REAL] EXP-085 |
| Verify exclude patterns' match results | Incident: an exclude pattern was missing a wildcard, so it never matched timestamp-suffixed build artifacts; build garbage nearly doubled the package size | [REAL] EXP-086 |
| Check volume composition after packaging | Don't assume the exclude list is correct; when volume looks abnormal, inspect composition before uploading | [REAL] EXP-086 |
| Pair retention policy with disk water-level monitoring | Backups/logs piling up without limit will crowd out the disk; retention counts need an upper bound | [DERIVED] EXP-083 |

## 4. Three-step verification (all three required)

| Step | Verifies | Catches |
|---|---|---|
| 1. Two-way md5 | Local and remote backup packages byte-for-byte identical | Transfer corruption |
| 2. gzip -t (or equivalent integrity test) | Archive structure intact | Same byte count ≠ intact structure |
| 3. Entry-count check | Entry count inside the package matches expectations | Missing files / extra files |

Source: [REAL] EXP-087.

## 5. Storage & restore drills

| Rule | Detail | Source |
|---|---|---|
| Must be pulled local | A backup left only on the server = no backup (the server itself is a single point of failure) | [REAL] EXP-088 |
| Packages with env/user data stay out of git | Before a backup package lands, check whether it falls inside any version-control scope | [REAL] EXP-088 |
| Restore drills are part of the backup definition | Periodically run a real restore; a backup that has never been drilled is treated as "unverified" | [GENERAL] EXP-089 |
| Backup as the unified entry point of the write layer | Auto-snapshot before data writes is the unified mechanism; every new write point must be checked for wiring (one feature was the last one not connected to backups) | [REAL] EXP-014 |

## Agent Quick Check

- Have I verified this backup can be restored? (three-step verification + restore drill)
- Does the backup package cover only the non-reproducible parts? Have you looked at the volume composition?
- Has the backup been pulled local? Does its landing spot fall inside any git repository?
- Are new write points (new features / new endpoints) wired to the backup/snapshot mechanism?
- Does the backup retention policy have an upper bound? Is anyone watching the disk water level?
