# SitePilot v1.0.1 — First Public Release

**Website Operations OS for AI Agents**

> Built from real-world website operations incidents. Generalized for every stack.

---

## What this is

SitePilot is an open-source **skill for AI coding agents**. It does not teach an
agent about websites in general — it gives the agent a discipline for operating
one safely: what to check before acting, what it must never guess, how risky a
change is, when to stop and ask, and how to prove that production actually works
rather than merely responding.

It works with any stack. The core is deliberately stack-neutral; stack-specific
traps live in `recipes/` and are loaded only after the agent detects what it is
looking at.

## Why it exists

Agents are good at writing code and bad at operating production systems. The
failure modes are not exotic — they are repetitive, and they are expensive:

| Failure | What it looks like |
|---|---|
| Guessing infrastructure | "I'll just restart it" — on the wrong environment |
| Trusting exit codes | Deploy succeeded → site is broken |
| Believing HTTP 200 | Data silently truncated, cache stale, API soft-degraded |
| Treating URLs as internal detail | Organic traffic dies after a "simple" rename |
| Trusting client-reported identity | Account takeover via a `userId` in the request body |
| Backing up without restoring | "We have backups" (that were never verified) |
| Fixing the symptom | The same defect ships again three times |
| Learning nothing | The same incident recurs next quarter |

Every rule in this release traces back to something that actually happened.

## What's inside

### 118 experiences, all traceable

- **111 seeded lessons** mined from a production website's real incident
  history — git history, operations handover documents, code and configuration
  traces, and a personal operations knowledge base. Generalized, classified, and
  mapped: every lesson points at the rule, reference, checklist, playbook, recipe
  or automated check that enforces it (`docs/experience-mapping.md`).
- **7 learned in the wild** after v1.0.0 shipped (EXP-112 … EXP-118): the skill
  was used on a real site, and its own tooling failed in ways that produced new
  permanent lessons (`docs/experience-log.md`).

### Progressive Disclosure

`SKILL.md` is short on purpose — philosophy, change workflow, risk model, stop
conditions, routing. Detail lives in 16 references, 6 checklists, 7 playbooks
and stack recipes, loaded only when relevant. An agent with a 2,000-token budget
still gets the decision layer right.

### Risk Model

Four levels with a required action set per level. Anything touching user data,
authentication, DNS, production config, URLs, or bulk data edits starts at HIGH
and needs impact analysis + backup + rollback plan + verification plan. Anything
that could cause irreversible loss is CRITICAL, and an agent may not act on it
silently.

### Stop Conditions

Eleven-plus explicit conditions where the correct behaviour is
**STOP → REPORT → ASK**, not improvisation: unknown environment, unverified
backup, unknown blast radius, irreversible deletion, discovered secrets, no
rollback path, growing incident, and more.

An agent's maturity is knowing when not to continue.

### Playbooks

Seven step-by-step responses, each written as TRIAGE → LOCATE LAYER → ASSESS
IMPACT → MITIGATE → RECOVER → VERIFY → INVESTIGATE → LEARN:

website-down · http-500-errors · bad-deployment · database-incident ·
dns-incident · ssl-incident · performance-incident

### Checklists

Six executable pre/during/post lists — not "check the site works", but
"critical pages return their expected content, the authenticated flow rejects
anonymous write attempts, the write actually persisted". Covers pre-deploy,
post-deploy, database changes, SEO changes, DNS changes, and incident response.

### Safe read-only health checker

`scripts/site-health-check.sh` performs GET/HEAD requests and local TLS
inspection only. No writes, no restarts, no secret logging, timeouts on
everything, and an exit-code contract (`0` pass / `3` pass-with-warnings /
`1` fail / `2` usage) that always agrees with the printed verdict.

**And it is tested on its own failure paths.** `scripts/tests/health-check-regression.sh`
runs 20 cases against locally generated fixtures — no external network needed —
covering 200/301/404/500, DNS failure, connection refused, timeout, TLS
handshake failure, certificates expired 1 second / 3 hours / 5 days ago,
hostname mismatch, and missing certificates. A check that has only ever passed
is not evidence of anything.

### Local Site Knowledge

Each operated project gets a `.sitepilot/` store: authoritative facts about
*that* site (real deploy mechanism, which data copy is authoritative, which
paths must never be touched, known quirks), plus local lessons, incidents and
decisions. The agent loads core knowledge, then local knowledge — general
intelligence plus local experience.

Local knowledge stays local. It is never published.

### Experience Feedback Loop

Operations produce lessons, not just changelogs. Twelve capture triggers
(incident, near miss, failed attempt, wrong assumption, silent failure, user
correction, and others) feed a lifecycle:
`CANDIDATE → CONFIRMED LOCAL → GENERALIZABLE → PROMOTED`.

A lesson is not "learned" until it changes behaviour — a rule, a checklist item,
a playbook path, a recipe note, or an automated check. Lessons that only sit in
a file prevent nothing.

### Lesson Supersession

New in this release: **lessons can be wrong.**

`CHALLENGED → CORRECTED / SUPERSEDED / RETIRED`, with a reason, a successor ID,
and a required propagation fix. A superseded lesson is never deleted — you can
always answer "why does SitePilot behave differently than it used to?"

A lesson that says *"copy what already exists"* is a red flag unless it also
says *"after verifying that what exists is correct."*

### Privacy model

> **Extract lessons, not secrets.**

- No credentials, tokens, user data, private IPs, internal URLs, or private
  project identifiers anywhere in this repository.
- Secrets found during an audit are reported as a type and location, never
  copied. They are treated as leaked and flagged for rotation.
- The local store explicitly forbids secrets: record *"a credential was exposed
  and needed rotation"*, never the credential.
- Upstream contribution of a local lesson requires explicit user approval and an
  anonymization pass. Nothing uploads itself.
- Evidence provenance is labelled honestly throughout: `[REAL]` (real incident),
  `[DERIVED]` (inferred from real evidence), `[GENERAL]` (general best practice,
  limited first-party evidence). We do not dress general advice up as battle
  scars.

---

## Who it's for

Developers and agents operating any website: personal blogs, corporate sites,
content sites, SaaS, API services — self-hosted or cloud-deployed, any stack.

## Install

```bash
git clone https://github.com/<you>/sitepilot.git
```

Point your agent at `SKILL.md`, or reference the path in your project's agent
instructions. No build step, no dependencies.

## Known limits

Honest ones, by design:

- **No scheduling or alerting.** The health check is a tool, not a monitor. A
  check nobody runs proves nothing — wire it into cron/CI and make it notify.
- **Thin first-party evidence** on DNS management, SSL configuration mechanics,
  CDN, containerization, CI/CD pipelines, database migrations, and load testing.
  Those references say so, and mark their guidance as general practice.
- **No payment/billing operations guidance.**
- The regression suite cannot exercise "clean PASS with a trusted certificate"
  offline (self-signed fixtures are rejected); that path is verified manually
  and labelled as such rather than claimed.

See `docs/validation.md` for what was verified, how, and what was not.

## License

MIT.

---

*Every incident should make the next incident less likely. Learn once, prevent forever.*
