# Example: "Help me deploy the new version"

> Demonstrates: atomic deployment + semantic verification. Core SKILL §4 change
> workflow + `checklists/pre-deploy.md` + `checklists/post-deploy.md` +
> `references/deployment.md` + `recipes/cloud-vps-deploy.md`.

---

**User**: Help me deploy the new version.

## How SitePilot Thinks

Deployment is a HIGH operation (deployment infrastructure is in the risk model).
**Deployment success ≠ production success** — exit code 0, build OK, deploy OK prove
nothing. First find the project's **real** deployment method (do not guess, do not invent),
confirm the rollback point, then execute.

## What to Load

- `checklists/pre-deploy.md` (pre-deploy checklist)
- `references/deployment.md` (atomic deployment, server-side cleanup)
- After detecting the stack, stack on the matching recipe (nextjs-selfhost /
  nginx-reverse-proxy / pm2-process-manager / cloud-vps-deploy)
- `checklists/post-deploy.md` (post-deploy checklist)

## Reasoning Process

```
1. INSPECT      Find the real deploy mechanism: deploy script? CI? manual
                scp? Does the script hardcode paths/versions (dead on env
                change)?
2. ASSESS RISK  HIGH: impact analysis + backup + rollback plan +
                verification plan.
3. PLAN         Rollback point first: keep the old build/data snapshot,
                verify it exists.
4. LOCAL VERIFY Run the stack's real checks (lint/typecheck/test/build);
                clear the field before building (stop dev/old processes);
                success standard = exit code 0.
5. PRE-DEPLOY   git grep scan for secrets; confirm the deploy package mixes
                in no data files; no sensitive material enters the package.
6. DEPLOY       Atomic deployment: build in a new directory → verify
                artifacts → second-level switch → restart/reload. Keep the
                old build throughout.
                Server-side cleanup checklist: keep N old builds, log
                rotation, backup policy, leftover process check.
7. VERIFY       Probes carry a browser UA (otherwise blocked by your own
                middleware with 403 and misdiagnosed).
```

## Key Decision Points

1. **Build and run separated**: do not `mv artifacts && build` in place — the whole site is 502
   during build. Build in a new directory + atomic switch, compressing the unavailability
   window to seconds. [REAL]
2. **restart's inherent 502 window**: single-instance restarts always have brief
   unavailability; either off-peak + notice, or dual-instance rolling. After the deploy,
   produce evidence of "no gap" (probe stats of non-200 counts), not just "the command
   succeeded". [REAL]
3. **Do not probe into your own defenses**: background health checks carry no browser UA, get
   403 from anti-scraping middleware, and deploy failure is misdiagnosed. [REAL]
4. **Data does not travel with code**: a deploy package mixing in data files is the precursor
   to overwriting production with stale data. Data goes through independent controlled sync
   (see node-json-store recipe). [REAL]

## How to Verify (production semantic verification, not just 200)

- Key pages contain expected content after hard refresh (rule out browser cache faking "no
  effect"). [REAL]
- Dynamic endpoints return **current** data (not a stale snapshot frozen at build).
- Auth state, write path really working (counters actually move).
- Logs: no large-scale new errors (align mtime vs restart time first, rule out old-tab noise).
- Server: disk water level, restart counts normal, access_log being written.
- All of the above passing is what counts as "deployment complete".

## Lesson Review

Deployment is a lesson hotspot: gaps, cache faking, probes blocked, cleanup misses… any
surprise (even if nothing broke in the end) goes into `.sitepilot/lessons/`. Special note:
**cron jobs/deploy scripts must verify business semantics** — "ran" is not "succeeded".
[REAL]