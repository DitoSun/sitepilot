# Checklist — Pre-Deploy

> Deploy = HIGH-risk action. If any item cannot be confirmed → **STOP → REPORT** (SKILL.md §7).
> Evidence markers: [REAL] real incident experience · [DERIVED] inferred from real evidence · [GENERAL] general best practice.

## A. Environment & Backup

- [ ] Confirm the current environment is production / staging / local from evidence (config files / dashboard / env vars) — never from guesswork. [REAL]
- [ ] Confirm which copy is authoritative: the live database / live data files are authoritative; local copies are usually stale snapshots. [REAL]
- [ ] Data and config touched by this change are backed up, and restorability has been verified with the actual restore tooling — not just packaged. [REAL]
- [ ] Keep the last working build artifact and data snapshot as a rollback point; record: path + switch command + what counts as successful recovery. [REAL]
- [ ] The backup artifact lands outside any git repo; packages containing sensitive data never enter version control. [REAL]
- [ ] Two backup tiers: change-level (change name + timestamp) + whole-site disaster-recovery level; check size composition after excluding regenerable directories. [REAL]
- [ ] The rollback point's "verification method" must be specific to commands / steps, not just the words "backup exists". [REAL]

## B. Code & Config

- [ ] `git status` to see the workspace; `git add` only the specific files for this change — never `git add -A` / `git add data/`. [REAL]
- [ ] `git grep` scan for secret patterns (token / secret / password / authorization code / PAT), confirm none added; stop immediately if found. [REAL]
- [ ] Confirm no data files are mixed into the deploy package (the deploy pipeline has a "data mixed in = abort" check, or verify item by item manually). [REAL]
- [ ] Confirm `.gitignore` protection has not regressed: `git ls-files` to check data / env files are untracked; ignore-rule changes must be paired with `git rm --cached`. [REAL]
- [ ] Deployment method = the project's real deployment method (read scripts / pipelines); never invent a new one; confirm scripts with hardcoded environment paths still apply. [REAL]
- [ ] Confirm this deploy does not sweep in "undeployed refactors / uncommitted fixes" — undeployed work needs a loss-prevention mechanism (branch / tag / list). [REAL]
- [ ] Commit messages state "what changed + why"; ban content-free auto-commits — history is the incident postmortem timeline. [REAL]
- [ ] Check diff size: understand the cause of an unexpected large diff (e.g., whole-file reformat) before committing. [REAL]

## C. Server Side

- [ ] Disable / clean up dangerous old cron jobs and old automation scripts — especially any "auto commit+push" backup script: deleting locally does not mean it stopped remotely. [REAL]
- [ ] Confirm all required environment variable **names** are present (check names only, never print values); a secret with a hardcoded fallback default counts as unconfigured. [REAL]
- [ ] Confirm process manager and port state: no leftover old processes holding ports, new version listens on the expected port. [REAL]
- [ ] Confirm server logs are being written (access log / error log non-empty) — without logs, post-deploy verification and monitoring have no foundation. [REAL]
- [ ] Confirm deploy channels are usable (try main channel + backup channel once each), to avoid panic operations when a channel is temporarily down. [DERIVED]

## D. Build

- [ ] Clear the field before building: stop the dev server / old build processes to avoid output-directory contention causing false errors. [REAL]
- [ ] The only success criterion for a build is exit code 0; treat stderr warnings as warnings, not background noise. [REAL]
- [ ] Separate build output from the runtime directory, switch atomically (where feasible), to avoid whole-site unavailability during builds. [DERIVED]
- [ ] Spot-check the artifact manifest after building: key artifacts present, no abnormal size spikes — spikes usually mean something that shouldn't ship got mixed in. [REAL]

## E. Verification Plan (write it down before acting)

- [ ] Write down how to test: which pages / APIs / paths, what content is expected — not just 200.
- [ ] Write down how to recover: which build / snapshot to roll back to, who executes, how success is confirmed.
- [ ] Write down what must "not change" (regression surface).
- [ ] Scheduled tasks / automation: the success criterion is the business semantics of the return code, not "HTTP responded". [REAL]
- [ ] Probe scripts carry a real client fingerprint (UA etc.), otherwise they test against your own defenses and misread it as an outage. [REAL]
- [ ] Write down rollback trigger conditions: under what circumstances to abandon the fix and roll back directly, no on-the-spot hesitation. [REAL]

---

**Any item that cannot be confirmed → STOP → REPORT → proceed only after confirmation.**
