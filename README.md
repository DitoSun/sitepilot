# SitePilot

**Give your AI coding agents production instincts.**

An open-source **Website Operations Skill** for AI agents — 118 lessons drawn
from one real production website's incident history and from SitePilot's own
first dogfooding run.

> Your agent already knows how to write code.
> SitePilot teaches it what can go wrong after the code is written.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Skill](https://img.shields.io/badge/type-AI%20Agent%20Skill-blue)](SKILL.md)

---

## What

SitePilot is an operating layer, not a tutorial. Before an agent touches
anything, it has to answer:

- What must I check before I act?
- What am I never allowed to guess?
- How risky is this change?
- When must I stop and ask?
- How do I prove the site *actually* works?

It works on any stack — personal blog, corporate site, content site, SaaS, API
service, self-hosted or cloud-deployed. The core stays stack-neutral;
stack-specific traps live in `recipes/` and load only after the agent detects
what it is looking at.

## Why?

AI coding agents are great at building websites. Production is different.

| What looks fine | What is actually happening |
|---|---|
| The deploy succeeded | The website is broken |
| The endpoint returns HTTP 200 | Data is silently truncated, cached or soft-degraded |
| "We have backups" | Nothing was ever restored from them |
| `.gitignore` contains the rule | The sensitive files are still tracked |
| "We copied the existing auth pattern" | The existing pattern was the vulnerability |

Each of these is cheap to prevent and expensive to discover. SitePilot gives
agents operational judgment **before** they touch production.

## Quick Start

No build step, no dependencies — a folder of Markdown plus one shell script.

```bash
git clone https://github.com/DitoSun/sitepilot.git
```

Then point your coding agent at `SKILL.md`:

| Agent | How |
|---|---|
| Claude Code / Codex / Cursor | Copy or symlink `SKILL.md` into your agent's skills directory, or reference the repo path in your project instructions |
| Any agent with file access | Add to your project's agent instructions: `Follow <path>/sitepilot/SKILL.md and load the referenced modules as needed` |
| CI / automation | `bash scripts/site-health-check.sh <url> --json` (read-only; exit `0` pass, `3` pass-with-warnings, `1` fail) |

The bundled health checker is itself tested on its failure paths:

```bash
bash scripts/tests/health-check-regression.sh
```

Both scripts carry the executable bit in the repository, so `./scripts/...` also
works on Unix-like systems; `bash scripts/...` additionally works where that bit
is not preserved (some Windows and archive-extraction paths).

## Try It

Then just talk to your agent:

> My website is down. Find the cause safely. Don't make destructive changes until you understand which layer is failing.

> Review this deployment before I push it to production.

> Find the highest-risk operational problems in this website and explain what should be fixed first.

## Learned in the Wild

SitePilot's first real production run found an expired TLS certificate — and then
exposed a flaw in SitePilot's **own** health checker.

The checker could report success under failure conditions:

- a target that could not be reached at all was reported **healthy**
- an expired certificate was rounded into a **non-failing** state

Neither was findable by happy-path testing, because on a healthy site the output
is correct.

Rather than quietly patching it, the failure went through the loop the skill is
built around:

```
Incident → Root Cause → Lesson → Generalization
→ Fix → Negative-path Tests → Stronger Skill
```

That run produced 7 new learned-in-the-wild experiences and a 20-case regression
suite proving the failure paths fail — expired 1 second ago, expired 3 hours ago,
expired 5 days ago, wrong hostname, no certificate served, connection refused,
DNS failure, timeout, TLS handshake failure — plus an assertion that the printed
verdict always agrees with the process exit code.

It also produced the two principles this project is least likely to trade away:

> A check that has not demonstrated that its failure paths fail cannot be trusted.

> Monitoring software that converts failure into success creates false
> confidence, and may be more dangerous than having no check at all.

And a lesson about lessons: an earlier operational note said *"new admin endpoints
must copy the existing convention from production code."* Three endpoints followed
it faithfully — and the existing convention turned out to be the vulnerability.
Lessons can be wrong, so they now carry a status (`CHALLENGED` / `CORRECTED` /
`SUPERSEDED` / `RETIRED`) and can be corrected without erasing history.

### The experience base

Two different cuts of the same body of knowledge — both accurate, and not meant
to be added together:

| Axis | Figure |
|---|---|
| **Origin** | 111 seeded from the incident history of **one** real production website, plus 7 learned through live dogfooding — **118 total** |
| **Evidence** | 116 grounded in real operations, 2 explicitly marked as general practice |

> **118 lessons, each labeled by evidence: 116 grounded in real operations,
> 2 explicitly marked as general practice.**

Every lesson is tagged `[REAL]`, `[DERIVED]` or `[GENERAL]`, and mapped to the
rule, reference, checklist, playbook, recipe or automated check that enforces it
(`docs/experience-mapping.md`).

The intent is **depth before breadth**: long-horizon extraction from one site's
real incident history, rather than assembling a generic operations checklist off
the internet.

## Core Principles

**Detect before acting.
Backup before risking.
Verify after deploying.
Rollback before making incidents worse.
Learn once, prevent forever.**

---

## How

SitePilot wraps every task in a discipline:

```
UNDERSTAND → INSPECT → ASSESS RISK → PLAN → BACKUP IF NEEDED
→ IMPLEMENT MINIMAL CHANGE → LOCAL VERIFY → DEPLOY
→ PRODUCTION VERIFY → MONITOR → DOCUMENT LESSON
```

plus a risk model (LOW → CRITICAL), explicit **stop conditions**, and a
**self-improving experience loop** that turns every incident into a rule, a
checklist item, a playbook path, or an automated check.

**SitePilot learns from operations** — structured knowledge evolution, not
model training: lessons are captured locally, generalized carefully, and only
contributed upstream with explicit approval.

## Use

Talk to your agent normally. SitePilot routes automatically:

| You say | SitePilot loads |
|---|---|
| "Deploy the new version" | `checklists/pre-deploy.md` + `references/deployment.md` |
| "The site is down" | `playbooks/website-down.md` (12-layer triage) |
| "Change these rows in the database" | `checklists/database-change.md` (SELECT-preview first) |
| "I'm changing the domain" | `checklists/dns-change.md` + risk confirmation |
| "Check our SEO" | `checklists/seo-change.md` + `references/seo.md` |
| "It's slow" | `playbooks/performance-incident.md` |
| "We leaked an API key" | `references/security.md` |

### Example — the difference it makes

> **You:** "Just deployed — the new articles endpoint returns 200 but users
> say they can't see new articles."

Without SitePilot, an agent typically concludes "the API works, must be a
frontend bug" and starts editing UI code.

With SitePilot, the agent:
1. Recognizes **200 ≠ correct** (SKILL.md §8 — silent degradation is worse than an error)
2. Checks record counts and freshness on the endpoint → finds a truncated/stale result set
3. Traces the real cause (expired token → soft-degraded response path)
4. Verifies semantically after the fix, and captures a **Lesson Candidate** locally

## Safety

SitePilot is designed for production:

- **Stop conditions**: 13 explicit conditions where the agent must stop, report, and ask — instead of improvising
- **Never guess infrastructure**: detect → confirm → act
- **Reversible first**: rollback points created and verified before risky changes
- **Read-only automation**: the bundled script only performs GET/HEAD requests and local TLS inspection — no writes, no restarts, no secret logging
- **Itself tested on failure paths**: `bash scripts/tests/health-check-regression.sh` proves the health check *fails* when it should — unreachable host, expired certificate, timeout, hostname mismatch. A check that has only ever passed is not evidence of anything
- **Lessons, not secrets**: credentials, tokens, user data, and private infrastructure never enter the skill or its outputs
- **Evidence honesty**: every rule is marked `[REAL]` (from a real incident), `[DERIVED]`, or `[GENERAL]` (general best practice) — we never dress general advice up as battle scars

## Contribute

The most valuable contribution is **your incident**. SitePilot's knowledge
base grows through a structured loop:

```
Incident → Evidence → Root Cause → Lesson → Generalization
→ Classification → Privacy Review → Contribution
```

See [CONTRIBUTING.md](CONTRIBUTING.md) for the lesson template and the review
criteria. Community lessons are merged only when they describe a real,
reproducible problem with a root cause — not one-off coincidences.

## Repository layout

```
SKILL.md                  core operating layer (start here)
references/               16 deep-dive domain guides
checklists/               6 executable pre/during/post checklists
playbooks/                7 step-by-step incident playbooks
recipes/                  stack-specific traps (Next.js, nginx, pm2, …)
examples/                 worked agent-reasoning walkthroughs
scripts/                  read-only safety automation
scripts/tests/            negative-path regression suite for the automation
templates/                .sitepilot/ local experience store templates
docs/                     validation reports
```

## License

[MIT](LICENSE) — use it, fork it, make your agents safer.

---

*Every incident should make the next incident less likely. Learn once, prevent forever.*
