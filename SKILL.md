---
name: sitepilot
description: >-
  Website Operations OS for AI Agents. Use this skill whenever an agent must
  understand, modify, deploy, verify, troubleshoot, secure, back up, or operate
  a website — especially a production website. Enforces risk assessment,
  backup-before-risk, stop conditions, semantic production verification,
  fix-one-scan-class, and a self-improving local experience loop.
  Triggers: deploy / release, website down, 500 errors, bad deployment,
  database or data changes, DNS or domain changes, SSL issues, SEO checks,
  performance problems, backup and recovery, security review, incident
  response, rollback, "check my website", "fix my site".
---

# SitePilot — Website Operations OS for AI Agents

> Built from real-world website operations incidents. Generalized for every stack.
> **Learn locally. Generalize carefully. Contribute explicitly. Prevent globally.**

---

## 1. WHO AM I

You are operating a website with SitePilot loaded. SitePilot is not a tutorial —
it is an operating layer that tells you **what to check before you act, what you
must never guess, when to stop, and how to prove the site actually works**.

SitePilot was built from a real production website's incident history
(user-data leaks through automated git pushes, silent data degradation, a
security fix that sat undeployed for a month, and dozens of smaller traps).
Every rule here traces back to a real lesson. Rules are marked:

- **[REAL]** — from a real incident or verified practice
- **[DERIVED]** — inferred from real evidence, not directly executed
- **[GENERAL]** — general best practice, limited first-party evidence

Never present a [GENERAL] rule as if it came from incident experience.

---

## 2. WHEN TO USE SITEPILOT

Load the matching module **before acting**, not after:

| The task sounds like… | Load |
|---|---|
| "Change X on the site" / "Fix this bug" | This file → Universal Change Workflow (§4) |
| "Deploy" / "Release" / "Push to production" | `checklists/pre-deploy.md` + `references/deployment.md` |
| "It's deployed — did it work?" | `checklists/post-deploy.md` + `references/production-verification.md` |
| "The site is down" / "500 errors" / "Not loading" | `playbooks/website-down.md` or `playbooks/http-500-errors.md` |
| "Change the database / data files" | `checklists/database-change.md` + `references/database-safety.md` |
| "Change DNS / domain / SSL" | `checklists/dns-change.md` + `references/dns-domain-ssl.md` |
| "Check / fix SEO" | `checklists/seo-change.md` + `references/seo.md` |
| "Site is slow" | `playbooks/performance-incident.md` + `references/performance.md` |
| "Back up" / "Restore" / "We lost data" | `references/backup-recovery.md` |
| "Is this secure?" / "We leaked a key" | `references/security.md` |
| "Something broke in production" | `playbooks/` + `references/incident-response.md` |
| "Roll back" | `references/rollback.md` |
| Unknown stack encountered | `recipes/README.md` → detect stack → matching recipe |
| Just finished an incident / learned something new | `references/experience-loop.md` |

### 2.1 Baseline first-pass — do this BEFORE loading any reference

Loading a reference narrows attention to what that reference covers. Do a short,
unguided scan first, then load the module.

| Baseline question | Why it comes first |
|---|---|
| **Exposure** — who can reach this? | A reachable surface is a risk surface, whatever the module says |
| **Authentication** — who is allowed to call it? | The most commonly missed question; no reference prompts it unless you look |
| **Authorization** — can caller A act on B's data? | Auth ≠ authz; a valid session says nothing about scope |
| **Input trust** — which values come from the client? | Body, query, header, cookie, localStorage — none are identity |
| **Destructive capability** — what can this code delete or overwrite? | Determines the blast radius before you know the bug |
| **Data sensitivity** — what is stored here, and who is in it? | Changes severity by an order of magnitude |
| **Persistence** — where does state live, and is it the authoritative copy? | Explains divergence and rollback limits |
| **External dependencies** — what breaks if they do? | Explains symptoms that look like local bugs |
| **Deployment/runtime boundary** — what is actually running, and from which artifact? | Distinguishes "code is wrong" from "something else is serving" |

Only after this pass, load the domain modules for whatever the task touches. The
baseline is not a substitute for them — it is what stops them from becoming your
entire field of view.

### 2.2 Every endpoint gets six questions

For any API route, handler, action, or form — *regardless of whether a
security reference is loaded*:

1. **Who can call it?** Anonymous? Any logged-in user? An admin?
2. **Which methods are accepted?** And what happens on the ones you did not intend?
3. **What data does it return?** Whose data? Fields you would not print aloud?
4. **What can it modify or destroy?** Is that reversible?
5. **What identity does it trust?** A session, or a value the caller supplied?
6. **What happens on invalid input?** Error, crash, silent empty result, or worse?

This is minimum attack-surface awareness, not a compliance checklist. A public
endpoint is not automatically a vulnerability — but "it is public on purpose"
must be a *conclusion you reached*, not an assumption you never tested.

---

## 3. CORE PRINCIPLES (non-negotiable)

1. **Real experience first.** Detect before acting. Never guess production
   infrastructure: database, CDN, server, deploy platform, DNS provider,
   monitoring — DETECT → CONFIRM → ACT, never GUESS → ACT. **[REAL]**
2. **Read before write. Search before create.** Comments and docs can lie or
   rot; verify against real code and real data. **[REAL]**
3. **Smallest safe change.** Fix the reported problem. Do not refactor the
   neighborhood because you noticed something. **[REAL]**
4. **Reversible first.** Create and *verify* a rollback point before any risky
   change. Prefer reversible actions. **[REAL]**
5. **Backup before risking.** A backup that cannot be restored is not a backup. **[REAL]**
6. **Runtime data must never flow through Git.** No `git add data/`, no
   auto-commit-and-push from application code, ever. Backups are file snapshots;
   sync is a controlled process. **[REAL]**
7. **Deployment success ≠ production success.** Exit code 0, build OK, deploy
   OK prove nothing. Verify the real production site. **[REAL]**
8. **Verify semantics, not only transport success.** HTTP 200 can still mean
   "data silently truncated", "stale cache", "soft-degraded". Check expected
   content, record counts, critical fields, auth state, business behavior. **[REAL]**
9. **Silent degradation is worse than an explicit error.** Never design or
   accept a failure path that returns success-shaped responses with wrong data. **[REAL]**
10. **Fix one instance, scan the class.** After fixing a root cause, search the
    whole project for the same pattern — then re-scope before fixing more. **[REAL]**
11. **Stop when uncertainty becomes dangerous.** See §7. **[REAL]**
12. **Learn once, prevent forever.** Every incident becomes a rule, checklist
    item, playbook path, or automated check — see §9. **[REAL]**
13. **Remember the lesson, forget the secret.** Never copy credentials, tokens,
    user data, IPs, or private infrastructure into any output. **[REAL]**
14. **Existing code is evidence, not proof of correctness.** Read before write
    and search before create prevent duplicate work — they do not certify the
    existing implementation. Before reusing a pattern, verify its assumptions;
    for auth, identity, secrets, and any security control, never copy by
    example. **[REAL]**
15. **A check that has not demonstrated its failure paths cannot be trusted.**
    If you write or rely on an automated check, prove that it fails when it
    should fail — and that its printed verdict matches its exit code.
    Monitoring must be monitored. **[REAL]**
16. **Verify from the user's path.** Local, server-side, and public-path checks
    answer different questions. A renewed certificate, a running process, or a
    passing localhost request proves nothing about what a visitor receives.
    **[REAL]**
17. **References are prompts for investigation, not boundaries of it.** The
    checklists and references in this skill are starting points, not a closed
    world. Never let the module you loaded define the whole problem space: a
    session reading only `monitoring.md` will find monitoring problems and miss
    that the endpoint has no authentication. **The skill must expand your
    attention, not replace it.** When you notice you have produced only findings
    that map to the reference you loaded, stop and ask what that reference does
    not cover. **[REAL]**

---

## 4. THE UNIVERSAL CHANGE WORKFLOW

Every website change follows this. Do not skip steps because the task "looks
small".

```
UNDERSTAND → INSPECT → ASSESS RISK → PLAN → BACKUP IF NEEDED
→ IMPLEMENT MINIMAL CHANGE → LOCAL VERIFY → DEPLOY
→ PRODUCTION VERIFY → MONITOR → DOCUMENT LESSON
```

| Step | What you must do |
|---|---|
| **UNDERSTAND** | Restate the user's actual problem before acting. "Site is slow" may be a client-rendering problem, not an API problem. |
| **INSPECT** | Read project structure, existing implementation, config, git history, docs. Reuse what exists. |
| **ASSESS RISK** | Classify LOW / MEDIUM / HIGH / CRITICAL (§5). Uncertain → assume higher. |
| **PLAN** | Write down: what changes, what must NOT change, how to test, how to recover. |
| **BACKUP IF NEEDED** | HIGH/CRITICAL: backup first (database/data files, config, previous build), and verify the backup is restorable. |
| **IMPLEMENT MINIMAL CHANGE** | Smallest change that solves the problem. No opportunistic refactors. |
| **LOCAL VERIFY** | Run the checks the stack actually supports (lint / typecheck / tests / build / smoke). Never assume `npm run build`. Never test against production data. |
| **DEPLOY** | Use the project's real deployment method. Never invent one. |
| **PRODUCTION VERIFY** | Really visit the production site. Hard-refresh past caches. Check semantics, not just status codes. |
| **MONITOR** | Watch logs, error rates, restart counts after the change. |
| **DOCUMENT LESSON** | Run the Lesson Review (§9). |

---

## 5. RISK MODEL

| Level | Examples | Required before acting |
|---|---|---|
| **LOW** | Copy, small UI, non-critical static content | Normal testing; still verify production |
| **MEDIUM** | Component logic, API behavior, dependencies, SEO metadata, cache behavior | Full verification + regression check |
| **HIGH** | Database/data changes, auth, DNS, CDN, production config, env vars, URL architecture, deployment infra, bulk data edits, user data, security | Impact analysis + backup + rollback plan + verification plan — all four |
| **CRITICAL** | Irreversible data loss, full-site outage, mass user impact, secret leakage, auth system failure | **Do not act silently.** Stop, report, get explicit confirmation |

Multiple small changes shipped together = at least HIGH. When unsure, level up.

---

## 6. NEVER GUESS PRODUCTION INFRASTRUCTURE

Before touching anything, answer from evidence (files, configs, dashboards,
git history — never from assumption):

- Which environment am I in? (production / staging / local)
- Which database / data store is authoritative? (the live one — local copies
  are usually stale snapshots)
- How is this site deployed? (script? CI? manual? — find the real mechanism)
- What serves it? (reverse proxy? CDN? process manager? versions?)
- Where are logs? (if access logs are empty, monitoring has no foundation)
- What are the credentials/config names — **names only, never values**?

If you cannot answer these from evidence: **STOP → REPORT → ASK**. **[REAL]**

---

## 7. STOP CONDITIONS

STOP → REPORT → ASK FOR CONFIRMATION when any of these is true:

1. You cannot confirm which environment you are modifying.
2. You cannot confirm the target database / data store, or which copy is authoritative.
3. No backup exists, or the backup has not been verified as restorable.
4. You cannot estimate the blast radius.
5. The action may irreversibly delete data.
6. You found a secret in code, config, git history, or logs — stop propagating it.
7. No verified rollback path exists.
8. DNS changes with unknown TTL / unknown current records.
9. Auth/permission changes with product-impacting trade-offs (e.g. forcing
   re-login) — these are user decisions, not agent decisions.
10. A production incident is actively growing.
11. The change may affect a large number of real users.
12. Local and remote state disagree and you cannot tell which is authoritative.
13. `.gitignore` protection appears to have regressed (data/env files newly trackable).

An agent's maturity is knowing when **not** to continue.

---

## 8. VERIFY SEMANTICS, NOT ONLY TRANSPORT SUCCESS

After any deploy or change, check **meaning**, not just reachability:

- Expected content present on critical pages (not just HTTP 200)
- Expected record counts / data freshness (stale cache returns 200 with old data)
- Expected critical fields (soft-degraded APIs may return truncated result sets with 200)
- Expected auth state (logged-in flows, protected endpoints reject anonymous)
- Expected business behavior (write path actually persists; counters move)
- No unexpected redirects; no obvious console errors; mobile critical path checked
- Hard-refresh / cache-bust before concluding "the change didn't take effect"

**A 200 response with silently wrong data is an incident, not a success.**

And verify from where the user stands: `localhost` up ≠ public endpoint correct;
certificate file renewed ≠ certificate served. When local and public disagree,
public wins — and the difference is a finding. **[REAL]**

---

## 9. THE SELF-IMPROVING EXPERIENCE LOOP

SitePilot learns from operations. Full mechanism: `references/experience-loop.md`.

**After every non-trivial task, run Lesson Review:**

Did this task involve any of: a real incident · a near miss · a failed
attempt · a wrong assumption about infrastructure/code/behavior · unexpected
behavior · a rollback · a security finding · a data integrity issue · a silent
failure · a repeated problem · a user correction · a better method found?

- **No** → write nothing.
- **Yes** → create a **Lesson Candidate** in the project's local store
  (`.sitepilot/lessons/`), using the schema in `references/experience-loop.md`.

**Lesson lifecycle:** `CANDIDATE → CONFIRMED LOCAL → GENERALIZABLE → PROMOTED`

- Local lessons make SitePilot increasingly expert **about this website**.
- Only generalized, anonymized, validated lessons may be contributed upstream —
  **never automatically, only with explicit user approval**.
- A lesson is not "learned" until it changes behavior: a rule, a checklist item,
  a playbook path, a recipe note, or an automated check. Lessons that only sit
  in a file prevent nothing.

**Recurrence rule:** if a problem repeats, the earlier lesson failed to prevent
it. Escalate it: documentation → checklist → automation → guardrail.

**Lessons can be wrong.** Guidance in this skill is evidence-backed, not
truth. Statuses `CHALLENGED` / `CORRECTED` / `SUPERSEDED` / `RETIRED` exist so a
bad lesson can be corrected **without erasing history** — never delete a
superseded lesson, mark it and point to its successor. If reality contradicts
an active lesson, the lesson loses: record the contradiction, mark the lesson,
and fix everywhere the old wording had already propagated. Full mechanism:
`references/experience-loop.md` §3 and §8b. 

---

## 10. DEFINITION OF DONE

A website task is done only when ALL are true:

```
Implemented + tested + built + deployed
+ production verified (semantics, not just status, from the user's path)
+ regression checked + monitored
+ any new automated check proven to fail on failing input
+ lesson captured if there was anything to learn
```

"The code is written" is not done. "The deploy succeeded" is not done.

---

## 11. ROUTING TABLE

| Need | File |
|---|---|
| Change discipline, commit hygiene, scope control | `references/change-management.md` |
| Deploying safely, atomic deploys, server-side cleanup | `references/deployment.md` |
| Proving production actually works | `references/production-verification.md` |
| Diagnosing any website problem | `references/troubleshooting.md` |
| Responding to incidents, mini postmortems | `references/incident-response.md` |
| Deciding/executing rollback | `references/rollback.md` |
| Database & data-file safety | `references/database-safety.md` |
| Backup & recovery | `references/backup-recovery.md` |
| SEO / GEO operations | `references/seo.md` |
| Security, secrets, auth boundaries | `references/security.md` |
| Performance analysis | `references/performance.md` |
| Monitoring & observability | `references/monitoring.md` |
| DNS / domain / SSL | `references/dns-domain-ssl.md` |
| Content operations | `references/content-operations.md` |
| AI-agent-specific safety rules | `references/ai-agent-safety.md` |
| Learning from operations (local experience loop) | `references/experience-loop.md` |
| Executable pre/post checks | `checklists/` |
| Step-by-step failure response | `playbooks/` |
| Stack-specific traps | `recipes/` |
| Worked examples of agent reasoning | `examples/` |
| Read-only site health check | `scripts/site-health-check.sh` |
| Proving the health check actually fails when it should | `scripts/tests/health-check-regression.sh` |
| Starting a local experience store | `templates/sitepilot-local/` |

---

## 12. EVIDENCE HONESTY

- **[REAL]** = from a real incident or verified first-party practice
- **[DERIVED]** = inferred from real evidence, not directly executed
- **[GENERAL]** = general best practice, limited first-party evidence

Confidence: HIGH (multi-source/verified) · MEDIUM (single-project verified) ·
LOW (reasonable inference). Never state LOW-confidence guidance as fact.

---

*SitePilot v1 — Lessons, not secrets. Learn locally. Generalize carefully.
Contribute explicitly. Prevent globally.*
