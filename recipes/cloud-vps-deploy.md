# Recipe: Cloud VPS Deployment (General)

## WHEN TO USE

Single-machine cloud server (VPS/ECS class) self-hosting: code scp/rsync'd up or pulled
down, built server-side, managed by a process manager, reverse-proxied by nginx. The "manual
deployment" shape with no CI/CD pipeline.

## ASSUMPTIONS

- Single-machine deployment, no multi-machine orchestration; the server is the single point
  (the backup strategy must account for this).
- Deployment relies mostly on scripts; a backup management channel may exist (cloud vendor
  OpenAPI assistants, etc.).

## COMMON FAILURE MODES

1. **Deploy scripts hardcode server paths and runtime versions**: switch machines or bump Node
   once and the script dies, in wildly varied ways. Hardcoded environment info is a trap —
   parameterize, or mark the applicable scope in the file header. [REAL]
2. **No backup channel when the SSH port is blocked**: after security-group changes, port
   changes, or tightened network policies, 22 is unreachable and the whole deploy chain
   collapses. Real experience: during an SSH blockout, deployment was completed via a
   cloud-assistant OpenAPI channel — **deploy channels need a Plan B**, with backup-channel
   credentials also read from config files, never landing in the repo. [REAL]
3. **Bandwidth is the hard ceiling on load speed**: outbound bandwidth of a few Mbps leaves the
   CPU idle but pages slow — measure the bottleneck before optimizing; when bandwidth-bound,
   optimizing images beats upgrading the CPU. Upgrading specs without measuring is waste.
   [REAL]
4. **Small memory/disk filled by build artifacts and log accumulation**: build directories,
   logs, and backups not cleaned; disk water level slowly climbs until the service dies in
   bizarre ways. The deployment process must include a server-side cleanup checklist. [REAL]
5. **Whole site unavailable during the build gap**: in-place `mv .next && build` gives
   site-wide 502/404s in strings during build. Build and run must be separated + atomic switch.
   [REAL]
6. **Bulk transfers fail silently**: bulk scp fails without errors, same-named files overwrite
   each other in staging directories, landed content differs from expectations — single-file
   transfer + two-way verification, or stream-packed transfer in one shot. [REAL]

## SAFE WORKFLOW

1. **Parameterize scripts**: server address, paths, versions, app names all parameterized;
   whatever cannot be parameterized gets its applicable environment in the file header.
2. **Backup deploy channel**: prepare a Plan B (cloud-assistant OpenAPI, etc.), credentials
   read from config files, never into the repo; confirm the backup channel works periodically —
   do not wait for the primary to die to discover the backup is dead too.
3. **Atomic deployment**: build in a new directory → verify artifacts (BUILD_ID/checksums) →
   second-level switch (rename/symlink) → restart/reload. Keep the old build throughout.
4. **Deployment includes server-side cleanup**: keep only N old builds, log rotation, backups
   cleaned per retention policy, no leftover old processes holding ports.
5. **No data mixed into the deployment package**: abort if data files are found in the package
   (data goes through independent controlled sync, see the node-json-store recipe).
6. **Post-deploy probes carry real client characteristics** (browser UA), or the application's
   own middleware blocks them and deployment failure is misdiagnosed. [REAL]
7. Execute in off-peak; operations with a 502 window (restarts) get advance notice or rolling
   execution.

## VERIFICATION

- **Deployment success ≠ production success**: probe stats of non-200 counts (evidence of "no
  gap", not just deploy command exit code 0). [REAL]
- Semantic verification: key page content, API current data, auth state, write path really
  persists.
- Server-side: disk water level, logs being written, restart counts normal, no port residue.
- Bandwidth/loading: key page load times within expectations (when slow, measure bandwidth
  first, do not change code first).

## ROLLBACK

- Switch back to the old build directory → restart → semantic verification (seconds).
- Old build lost: restore from a whole-site snapshot + replay the deploy.
- The rollback point must be created and verified **before** the change — "no old build kept
  before the change" is the most common rollback failure cause.

## LESSONS LEARNED

- Manual deployment reliability = parameterization + atomic switch + dual channels + cleanup
  checklist; all four before "repeatable safe deployment".
- Between "deploy command succeeded" and "production is healthy" stand: cache, processes,
  ports, data sync, middleware — every layer has fooled someone. See core SKILL §8.