# SitePilot

**Give your AI coding agents production instincts.**

> Your agent already knows how to write code.
> SitePilot teaches it what can go wrong after the code is written.

SitePilot is an open-source Website Operations Skill that teaches AI coding
agents how to safely deploy, verify, troubleshoot, and operate real websites.

**118 lessons · 20 negative-path tests · MIT licensed**

English | [简体中文](README.zh-CN.md)

---

## What

SitePilot gives coding agents the operational judgment they usually lack around
production. Before an agent touches anything, it has to answer:

- What must I check before acting?
- What am I never allowed to guess?
- How risky is this change?
- When must I stop and ask?
- How do I prove production actually works?

**The core is stack-agnostic.** Stack-specific lessons live in `recipes/`, which
the agent loads only after it has identified what it is looking at.

## Why

| Looks like success | What it actually proves |
|---|---|
| Deployment succeeded | ≠ production works |
| HTTP 200 | ≠ business semantics are correct |
| A backup exists | ≠ the backup is restorable |
| `.gitignore` contains the rule | ≠ sensitive tracked files are protected |
| The existing auth pattern | ≠ a secure auth pattern |

Each of these is cheap to prevent and expensive to discover.

## Quick Start

No build step, no dependencies — a folder of Markdown plus one shell script.

```bash
git clone https://github.com/DitoSun/sitepilot.git
```

Tell your coding agent:

> **Read `sitepilot/SKILL.md` and use SitePilot for this website.**

That is the whole installation. `SKILL.md` routes to the module a given task
needs; the agent does not have to read the references, playbooks or docs up front.

## Try It

### Troubleshooting

> My website is down. Find the cause safely. Don't make destructive changes until you understand which layer is failing.

### Deployment

> Review this deployment before I push it to production.

### Audit

> Find the highest-risk operational problems in this website and explain what should be fixed first.

## Learned in the Wild

SitePilot's first real production run found an expired TLS certificate — and then
exposed a flaw in SitePilot's **own** health checker, which could report success
under failure conditions.

Rather than quietly patching it, the failure went through the loop the skill is
built around:

```
Incident → Root Cause → Lesson → Generalization
→ Fix → Negative-path Tests → Stronger Skill
```

The experience base grew from 111 to **118**, and the checker now ships with a
20-case negative-path regression suite that proves the failure paths fail.
Details: [`docs/validation.md`](docs/validation.md).

## Lessons Can Be Wrong

An earlier lesson said new admin endpoints should copy the existing auth pattern
from production code. Three endpoints did — and the existing pattern turned out
to be the vulnerability.

So lessons carry a status — `CHALLENGED`, `CORRECTED`, `SUPERSEDED`, `RETIRED` —
and are corrected without erasing history. A lesson that says *"copy what already
exists"* is a red flag unless it also says *"after verifying that what exists is
correct."*

## Experience Base

Two different cuts of the same body of knowledge. They are **not** two pools to
be added together.

**Origin**

```
111  seeded from one production website's incident history
  7  learned through live dogfooding
───
118  total
```

**Evidence**

```
116  grounded in real operations
  2  explicitly marked GENERAL (general practice, no first-party evidence)
───
118  total
```

Evidence strength is marked `[REAL]` / `[DERIVED]` / `[GENERAL]` at rule level
throughout `references/`. The lesson-to-enforcement-point map is in
[`docs/experience-mapping.md`](docs/experience-mapping.md); the seven
learned-in-the-wild lessons carry their provenance in
[`docs/experience-log.md`](docs/experience-log.md).

The intent is **depth before breadth**: long-horizon extraction from a site
actually operated over time, rather than assembling a generic operations
checklist off the internet.

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
