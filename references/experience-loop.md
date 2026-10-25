# The Self-Improving Experience Loop

> **Solves:** how SitePilot gets smarter every time you operate a website —
> without ever leaking private data upstream automatically.
> Load this at the end of any non-trivial task, and whenever an incident,
> near miss, or user correction happens.

SitePilot is not a static checklist that rots. It is a **Website Operations
Learning System**: every operation can produce a validated lesson that makes
the next operation safer.

```
USE → ENCOUNTER PROBLEM → DETECT LESSON → CAPTURE EVIDENCE → ROOT CAUSE
→ GENERALIZE → CLASSIFY → PRIVACY REVIEW → STORE LOCALLY
→ UPDATE RELEVANT GUIDANCE → VERIFY → (OPTIONALLY, WITH APPROVAL) CONTRIBUTE
→ FUTURE AGENTS AVOID THE SAME MISTAKE
```

**Every incident should make the next incident less likely.**
**Learn once, prevent forever.**

---

## 1. Two-Layer Experience System

| Layer | What it is | Where it lives | Upstream? |
|---|---|---|---|
| **Layer 1 — Local Site Knowledge** | This website's quirks: special deploy path, server limits, historical compatibility logic, tables/pages that must not be touched, known third-party issues | Project's `.sitepilot/` | **No** — private by default |
| **Layer 2 — Generalized Experience** | Lessons with cross-project value, generalized and anonymized | SitePilot core (rules / references / checklists / playbooks / recipes / automation) | Yes — via approved contribution only |

Local experience makes SitePilot an expert **about this website**. Only
generalized, anonymized, validated lessons may ever reach the public skill.

---

## 2. Lesson Capture Triggers

Do **not** write a lesson for every routine task. Capture a **Lesson
Candidate** only when at least one of these occurred:

| # | Trigger |
|---|---|
| 1 | **Incident** — a real production failure |
| 2 | **Near miss** — almost caused an incident, caught in time |
| 3 | **Failed attempt** — an approach that did not work |
| 4 | **Wrong assumption** — the agent assumed something false about infra, code, or behavior |
| 5 | **Unexpected behavior** — the system behaved differently than expected |
| 6 | **Rollback** — the change had to be reverted |
| 7 | **Security finding** — a new vulnerability or exposure |
| 8 | **Data integrity issue** — corruption, drift, silent truncation |
| 9 | **Silent failure** — looked successful, wasn't |
| 10 | **Repeated problem** — something that already happened before |
| 11 | **User correction** — the user explicitly said the agent's judgment or action was wrong |
| 12 | **Better method found** — a clearly superior approach than current guidance |

---

## 3. Lesson Status Lifecycle

One incident ≠ one universal rule. Lessons mature through states — and they
can also be **wrong**:

```
                    ┌──────────── CORRECTED ────────────┐
                    │                                   │
CANDIDATE → CONFIRMED LOCAL → GENERALIZABLE → PROMOTED ─┴─→ CHALLENGED
                                                              │
                                          ┌───────────────────┼───────────────────┐
                                     CORRECTED           SUPERSEDED           RETIRED
```

| Status | Meaning | Allowed use |
|---|---|---|
| **CANDIDATE** | Just captured, unverified | Informational only; do not act on it alone |
| **CONFIRMED LOCAL** | Verified true for this project | Guide work on this project |
| **GENERALIZABLE** | Reason to believe other websites are affected | Propose for upstream; may inform advice with stated confidence |
| **PROMOTED** | Accepted into SitePilot core | Enforced as a rule / checklist / playbook / recipe / check |
| **CHALLENGED** | New evidence disputes it; under review | Demote: mention with an explicit caveat, never enforce |
| **CORRECTED** | The lesson was directionally right but badly worded or over-broad; a corrected version replaces it | Use the corrected version; keep the original for history |
| **SUPERSEDED** | A newer lesson contradicts it and wins | **Never** use as active guidance; point to the superseding ID |
| **RETIRED** | No longer applicable (feature removed, stack changed, risk obsolete) | Never use; keep for history |

This prevents an agent from learning a **wrong rule from one coincidence**.

### Lessons themselves can be wrong

A lesson is guidance backed by evidence — **not immutable truth**. The
clearest real example: a past lesson said *"new admin endpoints must copy the
existing cookie convention from current production code."* An audit later
found the existing convention was itself the vulnerability — the lesson had
been faithfully teaching the bug forward for months, and three new endpoints
had copied it (see EXP-114).

Two things follow:

1. **A lesson that says "copy what exists" is a red flag** unless it also says
   "after verifying that what exists is correct."
2. **Corrections must be as durable as the original.** If a wrong lesson can
   only be fixed by editing a file nobody re-reads, it will keep propagating.
   Give it a status, a reason, and a successor.

### Knowledge should be correctable without erasing history

Never delete a superseded lesson. Record it as `SUPERSEDED`, with:

- **Reason** — what the new evidence showed
- **Superseded By** — the lesson/EXP ID that replaced it
- **Date** — when it was superseded

This is how anyone can later answer *"why does SitePilot behave differently
than it used to?"* — a question that erased history can never answer.

### Conflicting lessons: resolve, do not pick at random

When two active lessons conflict, compare:

| Dimension | Question |
|---|---|
| Evidence | Which one is backed by stronger, more direct evidence? |
| Recency | Which reflects the current system (not a previous architecture)? |
| Scope | Which one actually covers this situation? |
| Confidence | HIGH / MEDIUM / LOW — and why? |
| Security implications | Which choice is safer if wrong? |
| Supersession status | Is one already superseded or retired? |

If the conflict cannot be resolved with evidence: **do not silently choose.**
Treat the guidance as `CHALLENGED`, apply the safer reading for the current
action, and record the open question.

### Local lessons expire too

`.sitepilot/` lessons are not permanent truth either. Server migrations, deploy
mechanism changes, auth rewrites, and CDN changes all invalidate local facts.
Local lesson statuses use the same vocabulary:

| Status | Meaning |
|---|---|
| `ACTIVE` | Currently true; safe to rely on |
| `CHALLENGED` | Something contradicts it; verify before relying |
| `SUPERSEDED` | Replaced by a newer local lesson |
| `RETIRED` | No longer applicable |

Any task that observes behavior contradicting an `ACTIVE` local lesson must
flip it to `CHALLENGED` and record the observation — that is the whole point
of having a lifecycle.

---

## 4. Lesson Record Schema

Every lesson (local or promoted) uses this structure. Template:
`templates/sitepilot-local/lesson-template.md`.

```
ID                     unique, e.g. L-2026-001 or EXP-xxx when promoted
Date                   when captured
Project                local only — stripped in any public version
Trigger                which capture trigger fired (§2)
Problem                what went wrong / what was learned
Context                under what conditions
Symptoms               what was observed
Expected Behavior      what should have happened
Actual Behavior        what actually happened
Impact                 what it affected
Risk Level             LOW / MEDIUM / HIGH / CRITICAL
Root Cause             the real "why", not the symptom
Wrong Assumption       what was believed that was false
Failed Attempts        what was tried and did not work
Correct Solution       what actually worked
Verification           how the fix was proven (semantics, not status codes)
Rollback               how it was / could be reverted
Generalized Lesson     the stack-neutral version of the lesson
Applicability          Universal / Most Websites / Specific Stack / This Project
Evidence               why this lesson is believed (file, log, command output — no secrets)
Confidence             HIGH / MEDIUM / LOW
Privacy Status         CLEAN / NEEDS REVIEW (contains private details?)
Status                 CANDIDATE / CONFIRMED LOCAL / GENERALIZABLE / PROMOTED
                       / CHALLENGED / CORRECTED / SUPERSEDED / RETIRED
Superseded By          (when SUPERSEDED/CORRECTED) the ID that replaced it
Superseded Reason      (when SUPERSEDED/CORRECTED) what the new evidence showed
Related Rules          SKILL.md sections this affects
Related Playbooks      playbooks to update
Related Checklists     checklists to update
Related Recipes        recipes to update
```

---

## 5. The Local Lessons Store (`.sitepilot/`)

Each operated project gets a local SitePilot store. Initialize from
`templates/sitepilot-local/`.

```
.sitepilot/
├── context.md          # this website's special knowledge (authoritative facts)
├── lessons/            # confirmed local lessons (one file per lesson)
├── incidents/          # incident records + mini postmortems
├── decisions/          # important architecture/ops decisions and why
└── config.md           # local preferences (risk tolerance, verification depth)
```

**Agent startup order for a known project:**
1. Load SitePilot core (SKILL.md + relevant module)
2. Load `.sitepilot/context.md` — *this is what makes the agent dangerous-in-a-good-way: it knows your site*
3. Check `.sitepilot/lessons/` for anything related to the current task

### Local store boundaries — Remember the lesson, forget the secret

`.sitepilot/` must **never** contain:

- secrets, passwords, tokens, cookies, API keys
- user personal data or database dumps
- environment variable **values** (names are fine)
- SSH credentials, private IPs, internal URLs
- anything from private notes/knowledge bases

Record *"an SMTP credential was exposed and had to be rotated"* — never the
credential. If a lesson cannot be written without the secret, it does not
belong in the store.

---

## 6. Lesson Review (end of every non-trivial task)

A deliberately lightweight gate. The agent asks:

> Did this task involve any §2 trigger?

- **No** → write nothing. Do not manufacture records.
- **Yes** → create a Lesson Candidate in `.sitepilot/lessons/`, fill the
  schema, set Status=CANDIDATE.

Then classify immediately: is this LOCAL-only, or plausibly GENERALIZABLE?

---

## 7. Mini Postmortem (mandatory for HIGH/CRITICAL)

For any HIGH/CRITICAL incident — or any rollback, security issue, data loss,
authentication failure, or production outage — run a mini postmortem
(`templates/sitepilot-local/incident-template.md`):

1. **WHAT HAPPENED** — facts, no blame
2. **WHY** — root cause chain
3. **IMPACT** — who/what was affected, for how long
4. **HOW RECOVERED** — exact recovery path
5. **WHY EXISTING SAFEGUARDS FAILED** — the most important section
6. **WHAT WOULD HAVE PREVENTED IT**
7. **WHAT SITEPILOT SHOULD LEARN** — then decide the behavior change:

| Change | When |
|---|---|
| Update a core rule | the lesson changes how every task should run |
| Update a reference | new domain knowledge |
| Add a checklist item | a pre-flight check would have caught it |
| Extend a playbook | new failure path |
| Add a recipe note | stack-specific trap |
| Add an automated read-only check | it can be detected mechanically |

---

## 8. Lessons Must Change Behavior

A lesson that only sits in a file prevents nothing. Value ladder:

```
"We wrote it down"  <  "The agent is told to watch for it"
<  "It's a checklist item"  <  "It's a playbook path"
<  "It is automatically detected and blocked"   ← best
```

Prefer pushing lessons **from documentation toward prevention**. Every
automated check must still be SAFE BY DEFAULT (read-only, timeout, no secret
logging, no destructive side effects).

---

## 8b. Correcting a Wrong Lesson

When new evidence contradicts an active lesson:

1. **Always check existing active guidance before acting on it.** "The skill
   says so" is not evidence — the skill may be behind reality.
2. **Verify against reality**, not against other documentation. Run it, read
   the code, observe the behavior.
3. **Write a correction record** — do not overwrite the original text:

```
ID               LC-<n>  (lesson correction)
Corrects         <original lesson ID / EXP-ID>
Date             YYYY-MM-DD
New Evidence     what was observed, and how
Why Old Was Wrong the specific faulty assumption
Corrected Guidance the wording that should replace it
Status           CORRECTED | SUPERSEDED
Supersedes Scope which parts are replaced (all? one clause?)
Propagation      where the wrong guidance had already been copied
```

4. **Mark the original** `SUPERSEDED` (or `CORRECTED` if the intent survives
   but the wording was dangerous), and keep it in place.
5. **Fix the propagation.** A wrong lesson usually already spread. Search for
   copies (other files, other projects, other endpoints) and correct each —
   `Fix one instance, scan the class` applies to lessons too.
6. **Add a regression check** if the wrong lesson can be detected mechanically.

> The most dangerous lesson is one that is confidently worded, widely copied,
> and subtly wrong. Corrections exist for exactly that case.

---

## 9. Recurrence Detection

Before treating any problem as new, search `.sitepilot/lessons/` **and**
SitePilot's existing guidance for the same pattern.

- **Not found** → proceed as a new lesson.
- **Found** → mark the new occurrence **RECURRENCE** and raise severity. A
  repeated problem means the earlier lesson failed to become a safeguard.
  Ask: *why didn't the existing rule prevent this?* Then escalate the
  safeguard: documentation → checklist → automation → hard guardrail.

---

## 10. Lesson Effectiveness Review

When a task touches an area covered by an existing lesson, check whether the
lesson actually helped:

- It helped → keep, maybe raise confidence.
- It did not → the rule's wording, its loading path, or the missing guardrail
  is too weak. Improve it.

```
LESSON → RULE → REAL USE → EFFECTIVENESS → IMPROVE
```

---

## 11. Local → Upstream Contribution (explicit approval only)

When a local lesson reaches **GENERALIZABLE**, SitePilot may *propose*
contributing it upstream. The flow is mandatory:

```
GENERALIZE → ANONYMIZE → PRIVACY CHECK → USER REVIEW → CONTRIBUTE
```

SitePilot generates a standard **Contribution Package** (see
`CONTRIBUTING.md`): Problem · Context · Root Cause · Failed Approach ·
Correct Solution · Generalized Lesson · Applicability · Evidence Type ·
Suggested Skill Change · Privacy Check. The user reviews and submits it as an
Issue or PR.

**Absolute rules:**

- SitePilot **never** auto-uploads local incidents to any remote.
- SitePilot **never** sends code, logs, paths, domains, user data,
  infrastructure details, or private notes anywhere.
- Local learning may be automatic. **Public contribution requires explicit
  user approval.**

---

## 12. Experience Provenance & Confidence

Every rule in SitePilot carries its origin:

| Provenance | Meaning |
|---|---|
| REAL-WORLD INCIDENT | from a verified first-party incident or practice |
| COMMUNITY INCIDENT | contributed and reviewed by the community |
| DERIVED LESSON | inferred from real evidence, not directly executed |
| GENERAL BEST PRACTICE | general engineering knowledge, limited first-party evidence |

Confidence: **HIGH** (multi-source or verified) · **MEDIUM** (single-project
verified) · **LOW** (reasonable inference). Never state LOW-confidence
guidance as fact, and never dress GENERAL practice up as incident experience.
This honesty is SitePilot's credibility.

---

## 13. Community Lesson Merge Criteria

Community-submitted lessons are not merged into core rules automatically.
Reviewers check:

1. Is there a real problem description (not a hypothetical)?
2. Is there a root cause, not just a symptom?
3. Is it a one-off coincidence or a reproducible pattern?
4. Does a duplicate lesson already exist?
5. Can it be generalized without the private context?
6. Is it free of private information?
7. Does it belong in core, a recipe, or a playbook?
8. Can it be detected automatically?

Rejected or niche lessons may still live in `recipes/` or community notes.
The goal is a knowledge base that stays coherent — not a pile of
contradictory personal anecdotes.

---

## 14. Knowledge Promotion Model

```
LOCAL CANDIDATE → LOCAL CONFIRMED → GENERALIZED → COMMUNITY REVIEW
→ SITEPILOT KNOWLEDGE → CHECKLIST / PLAYBOOK / RULE → AUTOMATED GUARDRAIL
```

Each step up demands more evidence. The top of the ladder — automated
prevention — is where lessons finally stop repeating.

---

## Agent Quick Check

- [ ] Did any §2 trigger fire this task? If yes: Lesson Candidate exists.
- [ ] Is the lesson free of secrets? (lesson, not secret)
- [ ] Status set correctly (CANDIDATE until verified)?
- [ ] Did the lesson change a rule / checklist / playbook / recipe / check?
- [ ] If recurring: was the earlier safeguard escalated?
- [ ] Any upstream proposal anonymized and awaiting explicit user approval?
