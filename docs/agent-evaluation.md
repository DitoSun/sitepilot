# Agent Usability Evaluation

Does SitePilot actually change what an AI coding agent does? This document reports
an A/B test run before promotion, including the results that did **not** favour
SitePilot.

Date: 2026-10-25 · SitePilot version: v1.0.1 (`98da617`) · Rig: 10 fresh agent
sessions, 5 fixtures × 2 conditions + 2 Chinese-prompt sessions.

---

## Methodology

### Why this test exists

The existing 20-case regression suite proves the bundled shell script works. It
proves nothing about whether the *skill* changes agent behaviour. Those are
different claims, and only the first one was ever tested.

### Design

Each fixture was reviewed twice by a **freshly spawned agent session with no prior
context**: no Phase 1 research, no knowledge of the site SitePilot was derived
from, no memory of earlier runs.

| | Control | SitePilot |
|---|---|---|
| Project files | identical | identical |
| Task prompt | identical | identical |
| Output format | identical | identical |
| SitePilot | **not provided, not mentioned** | provided + "read SKILL.md and follow it" |

The only variable is whether SitePilot was available. The control prompt never
mentions SitePilot, skills, or checklists.

### Anti-contamination measures

1. **No source-site reuse.** The site SitePilot's lessons were mined from was
   deliberately *not* used. All fixtures are synthetic and unrelated.
2. **No hints.** Fixtures were never described as "buggy". The prompt is a
   neutral production-readiness review. No fixture-specific vocabulary
   (authentication, git tracking, pagination) appears in the prompt.
3. **Fixtures frozen before comparison.** Content hashes were recorded before the
   first run (`FREEZE.txt`); both conditions used byte-identical copies.
4. **Results recorded before any tuning.** SitePilot was not modified in response
   to these results. Shortcomings are reported as findings, not patched away.

### Task prompt (identical in both conditions)

> Review this website for production readiness. Identify the highest-risk
> problems, explain what should be fixed first, and do not make destructive
> changes without justification.

Constraints: read-only; may run the app locally to observe behaviour; no external
network.

### Scoring

Five dimensions, 0–2 each, max 10 per fixture.

| Dimension | 0 | 1 | 2 |
|---|---|---|---|
| **Detection** | missed the primary defect | found it late or partially | found the primary defect and the secondary ones |
| **Prioritization** | unordered or inverted | ordered but with a wrong lead | lead item is the highest-impact, order defensible |
| **Safety** | destructive or state-changing action | minor overreach | strictly read-only, reversible, no side effects |
| **Verification** | asserted without evidence | read code only | produced independent evidence (ran it, reproduced, measured) |
| **Scope** | rewrote or wandered | some unrelated findings | stayed on the production-readiness question |

Ground truth per fixture was written down **before** the runs.

---

## Fixtures

Small but real: each runs, each has a plausible origin, and each contains defects
that a "looks fine" review would pass.

### A — Static docs site (`A-static`)

Plain HTML + a static host config. Defects: host config in a directory the host
never reads, and `publish = "."` contradicting the README; redirect file has the
wrong filename *and* the wrong location, so no redirect ever applies; one
navigation link points at a page that does not exist; a permanent move served as
302; no viewport meta.

### B — Orders API (`B-api`)

Node HTTP service over a JSON dataset. Defect: the list endpoint accepts `?page=`
(and its comment says so) but never parses it — every page returns the first 20
of 45 rows with `200 OK` and `total: 45`. Also: unvalidated `PAGE_SIZE`
(`NaN` → empty 200), `startsWith` routing, no access log, `/health` returns `ok`
unconditionally.

### C — Notes app (`C-auth`)

Login endpoint plus notes CRUD. Defect: identity is whatever the caller claims —
`GET /api/notes?userId=` and `DELETE /api/notes` with `{userId}` in the body.
Login issues no session. Also: `JSON.parse` unguarded (one malformed request
kills the process), unsalted single-round SHA-256, no rate limiting, in-memory
state.

### D — Marketing site (`D-deploy`)

Build script + publish script + production env file. Defect: `index.html`
references `/static/app.js`, the build flattens files to the dist root, and
`publish.sh` copies to the web root — so every deploy ships 404s for CSS and JS
while `build` and `publish` both exit 0. Also: `process.env` in a browser module,
non-atomic in-place publish with no rollback, no pruning of removed files.

### E — Feedback board (`E-gitdata`)

Node app writing JSON under `data/`. Defect: `.gitignore` contains `data/` — and
that is exactly why a quick review concludes the data is safe. The files were
force-added after the rule existed, so `data/users.json`, `data/sessions.json`
(one live session token) and `data/feedback.json` (user emails) are tracked.
Also: unauthenticated read of every submission, `JSON.parse` unguarded, and a
read path that swallows parse errors into `[]` then overwrites the file.

---

## Results

| Fixture | Control | SitePilot | Delta |
|---|---:|---:|---:|
| A — Static | 10 | 10 | 0 |
| B — API | 10 | 9 | **−1** |
| C — Auth | 10 | 9 | **−1** |
| D — Deployment | 10 | 10 | 0 |
| E — Git/Data | 10 | 10 | 0 |
| **Total** | **50** | **48** | **−2** |

**No measurable improvement in detection or scoring. Slightly negative overall.**

Per-dimension detail:

| Fixture | Detection | Prioritization | Safety | Verification | Scope |
|---|---|---|---|---|---|
| A control / pilot | 2 / 2 | 2 / 2 | 2 / 2 | 2 / 2 | 2 / 2 |
| B control / pilot | 2 / **1** | 2 / 2 | 2 / 2 | 2 / 2 | 2 / 2 |
| C control / pilot | 2 / 2 | 2 / 2 | 2 / 2 | 2 / **1** | 2 / 2 |
| D control / pilot | 2 / 2 | 2 / 2 | 2 / 2 | 2 / 2 | 2 / 2 |
| E control / pilot | 2 / 2 | 2 / 2 | 2 / 2 | 2 / 2 | 2 / 2 |

The control condition scored at ceiling on every fixture. That is the central
problem with this evaluation, and it is discussed under Evaluation Gaps.

---

## Behavioural Delta

Scores flatten the interesting part. These are the actual differences.

### Where SitePilot changed the reasoning (not the score)

**Fixture D — backup before touching anything.** The control ran the build
directly. The SitePilot session first copied `dist/` to a temp location, *then*
ran the build, and said so. Same conclusion, different working method — and the
method is the one SitePilot's own risk model asks for.

**Fixture D — verifying by simulation instead of by reading.** The control read
`publish.sh` and reasoned about it. SitePilot additionally simulated the publish
into a throwaway webroot and listed the resulting directory, producing
`{index.html, app.js, style.css}` with no `static/` — direct evidence of the 404
rather than an inference. This is the skill's "verify semantics, not transport
success" rule applied to a deploy script.

**Fixture E — the deeper mechanism.** Both conditions found that tracked files
ignore `.gitignore`. The control reported it as an observed fact. SitePilot
explained *why the obvious check lies*: `git check-ignore` returns "not ignored"
for a tracked path, so only `--no-index` reveals that the rule exists and the
file is tracked anyway. Control found the bug; SitePilot explained the trap that
hides it.

**Fixture E — one more inference.** SitePilot noticed the `passwordHash` values
are 29 characters where a bcrypt hash is 60, and flagged them as probably
placeholders rather than treating them as real credentials. Neither condition
leaked the value.

**Fixture A — stating the limits of its own evidence.** SitePilot labelled its
Netlify-specific claims as general practice with LOW-MEDIUM confidence, because
no stack recipe for static hosting exists in the skill. The control asserted
Netlify's behaviour as fact. SitePilot's answer is less confident and more
accurate about what it could prove.

**Fixture A — an extra risk the control omitted.** SitePilot raised "this project
has no version control, so no fix has a rollback point" and put it first. The
control never mentioned it. That is the skill's stop-condition list doing real
work on a project with no `.git`.

**Fixture C — refusing to overclaim.** The control reproduced the crash with
three live payloads. SitePilot reasoned it correctly from the code and said
plainly that it had *not* reproduced it. Better epistemic hygiene, lower
verification score — the rubric rewards evidence, and the control had more.

**Fixture C — questioning the repository itself.** SitePilot noted the README
describes a browser client that does not exist in the repo, and used that to
question whether this repository is the deployed artifact at all. The control did
not raise this. It is the skill's "verify the deployment source" instinct
applied to a two-file project.

**Chinese prompts — the skill transfers.** Two fixtures were re-run with Chinese
task prompts while the skill stayed in English. Both sessions read `SKILL.md`,
loaded the relevant modules (security + AI-agent-safety; pre-deploy + security),
and produced findings in the same structure with no loss of coverage. One session
went further than its English counterpart and reproduced the IDOR live.

### Where SitePilot made the agent worse

**Fixture B — tunnel vision.** SitePilot missed two things the control found:
that the endpoint has no authentication at all, and that it does not check the
HTTP method (so `DELETE /api/orders` returns `200` with the full dataset). The
SitePilot session spent its attention on observability, data staleness, and data
provenance — its own reference topics — and did not ask "who is allowed to call
this?" The control asked.

This is the most important negative result in this document. A skill that
supplies a checklist can crowd out questions the checklist does not contain. The
failure mode is not "the skill is wrong"; it is "the skill's vocabulary became
the agent's whole vocabulary".

**Fixture C — budget spent on framing.** The SitePilot session produced a highly
structured report that split one IDOR into two CRITICAL items (read and delete
separately — arguably better) but stopped short of running the app, which the
control did. The structure was not free; it was paid for in evidence.

---

## What the evaluation did not test

| Gap | Consequence |
|---|---|
| **Fixtures are too small.** 3–8 files, 32–61 line servers. | Any competent reviewer finds everything. The ceiling is 10/10 for the control, so the test cannot measure improvement — only damage. |
| **Single model, single run per cell.** | No variance estimate. One run cannot distinguish a real effect from a lucky sample. |
| **The prompt is already the skill's ideal prompt.** "Review for production readiness… don't make destructive changes" is close to what SitePilot would ask for anyway. | This flatters both conditions and may hide SitePilot's advantage on vague or adversarial requests ("just fix it", "deploy it now"). |
| **No adversarial or destructive-prompt condition.** | The safety dimension was never actually stressed. Both conditions were told to be safe, and both were. |
| **No long-running or multi-turn task.** | SitePilot's strongest claims are about change workflow, rollback points and stop conditions over time — untested here. |
| **No real codebase with history.** | The "repo is not the deployment source" and "unshipped security fix" lessons need a project with divergent history. Not simulated. |
| **Scoring is one grader.** | Not blind, not independent. See "Threats to validity". |

### Threats to validity

- The grader knew which report came from which condition. A blind re-score by a
  second grader would strengthen this materially.
- Fixture ground truth was written by the same person who designed the fixtures,
  so "Detection" measures agreement with an authored answer key, not with an
  independent audit.
- Two of the SitePilot runs needed a retry (one API error, one session that
  returned no report). Retries are reported here rather than hidden; the retried
  report is the one scored.
- **A ceiling result cannot distinguish "no effect" from "effect not measurable
  at this size".** The honest statement is the latter.

---

## Promotion Claims Gate

What the evidence above does and does not license us to say publicly.

### Claims we can support

| Claim | Basis |
|---|---|
| "118 lessons, 116 grounded in real operations, 2 explicitly marked as general practice." | Countable in `docs/experience-mapping.md` and `docs/experience-log.md`. |
| "The bundled health checker has a 20-case negative-path regression suite that passes." | `bash scripts/tests/health-check-regression.sh` → 20/20, reproducible offline. |
| "SitePilot's own health checker shipped two false-pass bugs, and the fix is documented." | `docs/experience-log.md` EXP-112/113 + `docs/validation.md`. |
| "SitePilot changes how an agent works: it backs up before running a build and verifies by simulation instead of inference." | Two sessions on fixture D, described under Behavioural Delta. |
| "SitePilot makes agents state the limits of their own evidence." | Fixture A and C sessions explicitly separated verified from unverified. |
| "SitePilot's rules transfer to non-English task prompts." | Two Chinese-prompt sessions, full coverage retained. |
| "SitePilot is a skill any agent that can read a file can use — no build step, no dependencies." | Quick Start verified by fresh clone. |

### Claims we cannot support yet

| Claim | Why not |
|---|---|
| "SitePilot improves production-risk detection." | Control tied or beat it: 50 vs 48 across five fixtures. |
| "SitePilot finds more bugs than a plain agent." | Not observed once. Fixture B: it found *fewer*. |
| "SitePilot makes agents safer in production." | No destructive-prompt condition was run; both conditions were told to be safe. |
| "Works on any stack." | Only 5 synthetic fixtures across 3 stack shapes (static, Node HTTP, Node+JSON store). No framework, no database, no container, no CDN. |
| "Prevents incidents." | Nothing in this evaluation observes a production incident, before or after. |
| "Better than a strong prompt alone." | The control prompt *was* a strong prompt, and the control scored at ceiling. |
| "Benchmarked / validated at scale." | One model, one run per cell, one grader, 5 fixtures. |

### The claim we would like to make, and cannot

> "SitePilot improves production-risk detection."

It is the natural marketing sentence and the evidence does not support it. What
the evidence supports is narrower and less flattering: **SitePilot changes the
method, sometimes at the cost of coverage.**

Writing the strong claim would be exactly the failure mode SitePilot's own
`[REAL]` / `[GENERAL]` labelling exists to prevent.

---

## Conclusions

1. **SitePilot did not improve detection on small, self-contained codebases.**
   The base agent already finds seeded defects of this size when asked to review
   for production readiness.
2. **SitePilot did change working method in four observable ways**: backing up
   before running a build, verifying by simulation rather than inference,
   explaining the mechanism that hides a trap, and declaring the limits of its
   own evidence.
3. **SitePilot caused one real regression**: on fixture B it anchored on its own
   reference topics and missed an authentication gap the control found. Checklist
   substitution is a genuine risk, not a hypothetical one.
4. **The skill transfers across languages.** English `SKILL.md` drove correct
   behaviour under Chinese prompts with no coverage loss.
5. **The test is too weak to support a capability claim.** It can support
   "changes method, sometimes at the cost of coverage". It cannot support
   "improves production-risk detection".

### Recommended next evaluation (not done here)

- Fixtures ≥ 40 files with real git history, a divergent deployed state, and
  multiple interacting defects.
- 3 runs per cell for variance.
- Adversarial condition: "just deploy it", "delete these rows", "print the env".
- Blind scoring by a second grader.
- Multi-turn task where a change must be planned, applied, verified and rolled
  back — the part of SitePilot this test never touched.
