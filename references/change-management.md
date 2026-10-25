# Change Management — SitePilot Reference

> **Solves:** how any website change stays "right, minimal, and explainable" —
> completion criteria for every workflow step, the smallest safe change, commit
> discipline, decommission cleanup, and the operations loop. Prevents
> opportunistic refactors, information-free commits, and residue left behind by
> retired features.

Source: EXP-090~098 (change management & engineering habits) primarily; workflow-step experience is cross-referenced per table row. Risk levels and stop conditions follow SKILL.md §5/§7 — not reinvented here.

---

## 1. The Universal Change Workflow, in detail

SKILL.md §4 defines the eleven-step workflow; this file adds "what counts as done" for each step:

| Step | Done when | Common failure |
|---|---|---|
| UNDERSTAND | Restate, in your own words, the problem the user actually wants solved — then act | Treating "the page hangs" as "the API is slow" and changing the API directly (EXP-037) |
| INSPECT | Have read the relevant code, config, git history, and docs; when docs have rotted, code + history are authoritative | Trusting rotten docs over code (EXP-097) |
| ASSESS RISK | Level per SKILL.md §5; if unsure, level up; multiple small changes shipped together start at HIGH | Skipping the leveling because "it's just one line" |
| PLAN | Write down what changes, what must NOT change, how to test, and how to recover | Writing down only "what changes" |
| BACKUP IF NEEDED | HIGH/CRITICAL: back up first and verify restorability (see backup-recovery.md) | Backed up, but never verified the restore works (EXP-087) |
| IMPLEMENT MINIMAL CHANGE | The diff contains only the lines needed to solve the problem | Opportunistically refactoring half the project (EXP-090) |
| LOCAL VERIFY | Run the checks the real stack supports; never dirty production data; clear the ground before building | Assuming a build command must exist (EXP-027) |
| DEPLOY | Use the project's real deployment method — never guess, never invent (see deployment.md) | Deploy script hardcoded for another environment (EXP-034) |
| PRODUCTION VERIFY | Semantic verification (see production-verification.md) | Only looking at exit code 0 (L4) |
| MONITOR | Watch error rate, restart count, and logs | Declaring done the moment the deploy finishes (EXP-080/082) |
| DOCUMENT LESSON | If there was a lesson, put it in the experience pool and land it as a rule / checklist / automation | Lessons left only in the chat log (L12/L13) |

## 2. Smallest safe change & scope control

| Rule | Detail | Source |
|---|---|---|
| Smallest safe change | Fixing one button does not get to refactor half the project; the smaller the diff, the easier the rollback and the cheaper the postmortem | [REAL] EXP-090 |
| Don't delete compatibility code that "looks useless" | Check history and callers first; information-free history makes a misdelete untraceable | [REAL] EXP-097 |
| Fixes must not stall | Security fixes must be designed together with the migration plan; "afraid to deploy" zeroes the fix's value | [REAL] EXP-031 |
| Unshipped refactors need loss protection | Local-but-unshipped changes can be wiped by reverse sync; protect with branch / tag / checklist | [REAL] EXP-032 |
| Operational config gets hot updates | Ongoing operations items (review word lists, quota thresholds) should not require a code release for every adjustment | [REAL] EXP-098 |

## 3. Commit discipline

| Rule | Detail | Source |
|---|---|---|
| No `git add -A` / `git add data/` | Read `git status` first, then stage files explicitly; sensitive data and code must be committed separately | [REAL] EXP-093 |
| Runtime code never performs git writes | Auto commit+push is an incident-grade design; backup = file snapshot, sync = controlled process | [REAL] EXP-001 |
| Auto-commits must carry readable messages | "auto backup"-style information-free commits turn git log into a postmortem ruin — the incident timeline's value drops to zero, and recovery ends up depending on reflog | [REAL] EXP-094 |
| Data changes committed separately, with provenance | When data is code, bulk data changes must be traceable; keep serialization format and sort keys stable to avoid giant diffs | [REAL] EXP-017 |
| Credentials never hardcoded as fallback defaults | git grep for key patterns before release; once credentials land in the repo, treat them as leaked and rotate | [REAL] EXP-002 |
| ignore-rule changes must come with `git rm --cached` | .gitignore has no effect on tracked files; after changing, verify with `git ls-files`; data directories need a poka-yoke assertion | [REAL] EXP-003 |

## 4. Decommissioning & repository hygiene

| Rule | Detail | Source |
|---|---|---|
| Decommissioning cleans data residue too | Data files, cron jobs, and endpoints left behind by a retired feature are seeds for the next incident | [REAL] EXP-097 |
| Stale docs are worse than no docs | Rotting docs actively mislead later readers (including agents); update docs together with code changes, otherwise delete them | [REAL] EXP-097 |
| Periodic repository sweep | Clean out assistant workspace files and old backup directories that drifted into the source root | [REAL] EXP-097 |
| Incident annotation culture | Annotating every workaround with "root cause + data + why the reverse must not be done" is the highest-leverage way to prevent repeating the pitfall | [REAL] EXP-095 |

## 5. The four-step operations workflow

| Stage | Action | Source |
|---|---|---|
| Idea pool | All ideas go into the pool first; no immediate implementation | [REAL] EXP-091 |
| Backlog | Pick from the idea pool by priority; define acceptance criteria | [REAL] EXP-091 |
| Change log | Every change records "what changed + why"; product decisions keep the original words to prevent churn | [REAL] EXP-092 |
| Data review | Feed data conclusions back into the idea pool, closing the loop | [REAL] EXP-091 |

## Agent Quick Check

- Are there "while I'm here" lines in this diff? If so, split them into a separate commit.
- Before committing, did you confirm file by file: no `git add -A`, no data files mixed into the commit?
- When decommissioning a feature: data residue, related cron jobs, and stale docs all cleaned up?
- Does the change log record "why", or only "what changed"?
- If this task had a lesson, has it landed in at least one of: rule / checklist / automation?
