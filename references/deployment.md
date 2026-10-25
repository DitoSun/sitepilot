# Deployment — SitePilot Reference

> **Solves:** how to ship changes to production safely and prove they landed —
> pre-deploy checks, atomic deploys with build/run separation, transfer
> verification, server-side cleanup, and deploy-channel redundancy. Eliminates
> three classes of deploy accidents: "site-wide 502 during the build gap
> window", "shipped a broken package", and "an old process still serving the
> old code".

Source: EXP-023~035 (deployment & release) primarily; cross-references EXP-007/015/022/080/108. Executable versions: `checklists/pre-deploy.md` and `checklists/post-deploy.md`.

---

## 1. Pre-deploy checks

| Check | Requirement | Source |
|---|---|---|
| Server-side cleanup | The deploy checklist must include the server side: old cron jobs, old scripts, old build artifacts, old env vars. "Changed locally" ≠ "changed in production" — you deleted a piece of logic locally, but the server's old scheduled script is still running | [REAL] EXP-007 |
| Data must not ride in the deploy package | When data and code deploy separately, abort the deploy if a data directory is detected in the package | [REAL] EXP-015 |
| Rollback point ready | Before the change, create and verify a rollback point: previous build artifacts, data snapshot, git tag | [REAL] §12 |
| Probes carry real client signatures | Deploy-time auto-probes must send a browser UA, otherwise your own anti-scrape/WAF rules 403 them and it gets misdiagnosed as a deploy failure | [REAL] EXP-033 |
| Confirm the authoritative copy | For multi-machine work, first confirm "which copy is authoritative"; unshipped refactors need loss protection (branch/tag) | [REAL] EXP-032 |

## 2. Atomic deploy: build/run separation

| Step | Requirement | Source |
|---|---|---|
| 1. Build in a new directory | Build output goes to a brand-new directory; never overwrite the running build artifacts | [REAL] EXP-023 |
| 2. Verify the build artifacts | After the build, verify the artifact identifier (e.g. BUILD_ID) exists and is correct | [REAL] EXP-023 |
| 3. Second-level switch | Replace the old artifacts with a directory switch (rename-class operation); the whole process completes in seconds | [REAL] EXP-023 |
| 4. Restart & probe | Probe immediately after restarting the process; count non-200s during the switch as evidence of "no gap window" | [REAL] EXP-023 |
| 5. Clean up old artifacts | Keep one rollback-capable old version, clean the rest — prevent disk pile-up | [DERIVED] EXP-023 |

Anti-pattern: in-place "move the old artifacts away, then build" — the whole site 502s during the 90~150s build.

## 3. The inherent window of a single-instance restart

| Rule | Detail | Source |
|---|---|---|
| restart has an inherent unavailability window | During a single-instance restart the service is necessarily briefly unavailable (all 502s in the audit period fell within restart minutes) | [DERIVED] EXP-024 |
| Zero downtime requires rolling deploys | Rolling restarts with two or more instances are the only true zero-gap; if you can't, accept the window and tell users | [DERIVED] EXP-024 |
| Restart count is a stability signal | The process manager's restart count itself belongs on the monitoring list | [REAL] EXP-080 |

## 4. Transfer verification

| Rule | Detail | Source |
|---|---|---|
| Per-file transfer + two-way verification | Bulk copy once failed silently; after switching to per-file transfer, do two-way md5 comparison | [REAL] EXP-026 |
| Normalize CRLF for text, never for binaries | For text, strip CR before computing md5; for binaries, always use raw-byte md5 (CR is an ordinary byte — deleting it fabricates false agreement) | [REAL] EXP-108 |
| Same-named files never share a staging directory | Multiple same-named files transferred into one staging directory overwrite each other — this once caused a silent mis-transfer | [REAL] EXP-026 |
| Bulk transfers prefer streamed packaging | One tar stream for the whole transfer: more reliable and faster than per-file copy | [REAL] EXP-030 |

## 5. Build & artifact pitfalls

| Rule | Detail | Source |
|---|---|---|
| Clear the ground before building | Stop the dev server / old build processes first; the only success criterion for a build is exit code 0 | [REAL] EXP-027 |
| Deleting a route must clear residual type artifacts | After deleting a route directory, residual types in the framework's artifact directory break the build (this pitfall was hit twice) | [REAL] EXP-028 |
| Endpoints that read runtime data must not be statically prerendered | Parameter-less GETs may be frozen by build-time pre-rendering; endpoints that need runtime data must explicitly declare dynamic, with a "do not delete" comment and the reason | [REAL] EXP-022 |

## 6. Judging post-deploy noise

| Rule | Detail | Source |
|---|---|---|
| Align the timeline before reading errors | When logs flood with errors after a redeploy, first check log time vs service restart time: anything before the restart is old-client noise | [REAL] EXP-029 |
| Old-tab noise is not a new bug | Client calls from a user's stale page erroring on the new server does not mean the new code is broken | [REAL] EXP-029 |

## 7. Reverse sync (production → local)

Sync-class operations must produce a "byte-for-byte identical" evidence chain. Six steps:

| Step | Action |
|---|---|
| 1. Compare | Compare the manifest first to determine what to sync |
| 2. Stream-pull | Pull in bulk via tar stream, not per-file copy |
| 3. Per-file verification | After landing, verify each file with md5 |
| 4. Clear orphans | Before deleting extra local files, grep imports to confirm nothing references them |
| 5. Re-compare after install | After everything is installed, run a whole-tree comparison again |
| 6. Produce evidence | Output the "all files byte-for-byte identical" comparison result |

Source: [REAL] EXP-030.

## 8. Deploy scripts & channels

| Rule | Detail | Source |
|---|---|---|
| Parameterize deploy scripts | Scripts with hardcoded server paths and runtime absolute paths break on any environment change; the applicable scope must be labeled | [REAL] EXP-034 |
| Deploy channel Plan B | When the primary channel (SSH) is unavailable, a backup channel must exist; backup-channel credentials are also read from config files, never committed | [REAL] EXP-035 |
| Bundle the fix with the migration | Fixes involving UX decisions like "users are forced to re-login" must be decided together with the migration plan before shipping — no indefinite "afraid to deploy" | [REAL] EXP-031 |

## Agent Quick Check

- Does the deploy checklist include server-side cleanup (cron / old scripts / old builds / env vars), not just file transfer?
- Does the build write to a new directory and only switch after verification passes? Were non-200s during the switch counted?
- Was the transfer two-way verified? Did binary files use raw md5 (no `tr`)?
- Were post-deploy errors timeline-aligned first, with old-client noise ruled out?
- Do the deploy script's paths hardcode another environment? Is there a Plan B when the primary channel is down?
