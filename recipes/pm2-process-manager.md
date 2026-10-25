# Recipe: pm2 Process Management

## WHEN TO USE

Using pm2 to manage Node application processes (`pm2 start` / `ecosystem.config.js`), the
most common process management approach in self-hosted deployment.

## ASSUMPTIONS

- Single-machine deployment; pm2 runs as a daemon (`pm2 startup` configured).
- The application is a long-running HTTP service (`next start`, custom server, etc.).

## COMMON FAILURE MODES

1. **restart has an inherent 502 window**: on single-instance `pm2 restart`, the old process
   dies first and the new one is not ready; requests hit a closing port — every restart shows
   502s for minutes. Either accept the window (off-peak restart + notify), or go dual-instance
   rolling restarts for zero downtime (the latter unverified in first-party practice). [REAL]
2. **Restart counts are a stability signal, yet often ignored**: processes silently crash and
   pm2 auto-restarts them; the surface "service is fine", but restart counts keep climbing
   (e.g. hundreds long-term), discovered only at handover. Restart frequency/crash counts must
   be on the monitoring checklist. [REAL]
3. **restart does not pick up changed environment variables**: `pm2 restart` by default reuses
   the startup snapshot. After changing `.env` or export, run `pm2 restart --update-env`, or "I
   changed the config, why no effect". [REAL]
4. **Logs not rotated, disk filled**: pm2 default logs grow unbounded, compounded by
   application logs; small-disk machines fill up after months — the service dies in bizarre
   ways. pm2-logrotate or an equivalent must be configured. [REAL]
5. **Old builds not cleaned up**: repeated in-place build/restart fills the disk with
   artifacts; the old build cannot be found at rollback. [REAL]

## SAFE WORKFLOW

1. Build in a separate new directory (build and run separated), verify, then switch + restart;
   never build in place in the running directory. [REAL]
2. Before restart confirm: new build in place, old build retained (rollback point),
   verification script ready.
3. Restart with `--update-env` (if env vars changed); dual instances can rolling-restart one by
   one, compressing the 502 window to the minimum.
4. Run semantic verification immediately after restart (see below), not just `pm2 status`
   showing online.
5. Keep the last N builds, configure a cleanup policy (artifacts + logs).
6. Routine inspection: restart count deltas, log volume, disk water level.

## VERIFICATION

- `pm2 status`: online, no abnormal growth in restart counts.
- `pm2 logs`: no new errors — **align the timeline first** (log mtime vs restart time);
  old-client/old-tab noise is not a new-code bug. [REAL]
- Semantic verification: really visit production key paths (hard refresh to rule out cache);
  APIs return current data, not stale cache.
- Environment variables really in effect (e.g. read back non-sensitive config from the
  application endpoint).
- Disk: artifact and log volumes within expectations.

## ROLLBACK

- Switch back to the retained old build directory → restart → semantic verification. Rollback
  is also a change.
- If the old build is lost, restore from the deployment package/backup before restarting.
- Rollback decisions must be fast: core pages 5xx or auth failing at scale → restore service
  first, then analyze root cause (core SKILL rollback philosophy).

## LESSONS LEARNED

- pm2's "auto-restart" is a double-edged sword: it makes crashes invisible. Monitoring must
  watch **restart count deltas**, not process existence.
- For any "changed but no effect", first check the config loading mechanism (`--update-env`),
  the process's actual listening port, and cache, before suspecting code — see
  `references/troubleshooting.md`.
