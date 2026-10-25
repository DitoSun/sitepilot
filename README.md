# SitePilot

### Website Operations OS for AI Agents

> Built from real-world website operations incidents. Generalized for every stack.
> **Learn locally. Generalize carefully. Contribute explicitly. Prevent globally.**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Skill](https://img.shields.io/badge/type-AI%20Agent%20Skill-blue)](SKILL.md)

---

## What

SitePilot is an open-source **AI Agent skill** that teaches any coding agent to
operate a website safely — personal blog, corporate site, content site, SaaS,
API service, self-hosted or cloud-deployed, any stack.

It is not a tutorial. It is an operating layer that answers, before the agent
touches anything:

- What must I check before I act?
- What am I never allowed to guess?
- How risky is this change?
- When must I stop and ask?
- How do I prove the site *actually* works?
- What do I do when production is on fire?
- How do I make sure this never happens again?

## Why

AI agents are good at writing code and bad at operating production systems.
The failure modes are predictable and expensive:

| Agent failure | What it looks like |
|---|---|
| Guessing infrastructure | "I'll just restart the DB" — on the wrong environment |
| Trusting exit codes | Deploy succeeded → site is broken |
| Believing HTTP 200 | Data silently truncated, cache stale, soft-degraded API |
| Treating URLs as internal detail | Organic traffic dies after a "simple" URL change |
| Trusting client-reported identity | Account takeover via `userId` in the request body |
| Backing up without restoring | "We have backups" (that were never verified) |
| Fixing one instance | The same bug ships three more times |
| Learning nothing | The same incident happens again next quarter |

Every rule in SitePilot traces back to a **real incident** from operating a
production website — including user data leaked through automated git pushes,
a security fix that sat undeployed for a month, and a "harmless" API
degradation that silently hid new content from every user.

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

## Install

SitePilot is a skill folder — no build step, no dependencies.

```bash
git clone https://github.com/<you>/sitepilot.git
```

Then point your agent at it:

| Agent | How |
|---|---|
| Claude Code / Codex / Cursor | Copy or symlink `SKILL.md` into your agent's skills directory, or reference the repo path in your project instructions |
| Any agent with file access | Add to your project's agent instructions: `Follow C:/path/to/sitepilot/SKILL.md and load the referenced modules as needed` |
| CI / automation | Call `scripts/site-health-check.sh <url>` directly (read-only) |

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
templates/                .sitepilot/ local experience store templates
docs/                     validation reports
```

## License

[MIT](LICENSE) — use it, fork it, make your agents safer.

---

*Every incident should make the next incident less likely. Learn once, prevent forever.*
