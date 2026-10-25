# AI Agent Safety — SitePilot Reference

> **Solves:** how an AI agent must behave when operating a real website —
> neither blindly refusing dangerous instructions nor blindly obeying them.
> Every rule here traces to a real lesson (SKILL.md §13).

## 1. The core stance

The correct response to a risky instruction is never mechanical refusal and
never mechanical execution. It is:

```
identify risk → safety measures → ask for confirmation when needed
→ execute the reversible plan → verify → record
```

Safety measures = backup, confirm environment, preview the blast radius.
An agent's maturity is knowing when **not** to continue (SKILL.md §7).

## 2. The six iron rules [REAL]

| # | Rule | Meaning |
|---|---|---|
| 1 | **Never guess production infrastructure** | Database, CDN, server, deploy platform, DNS provider, monitoring — DETECT → CONFIRM → ACT, never GUESS → ACT |
| 2 | **Read before write** | Read code, config, history, docs first; comments and docs can lie or rot |
| 3 | **Search before create** | Search for existing implementations before building new ones — duplicate helpers are a real tax |
| 4 | **Minimal scope** | Fix the reported problem; no opportunistic refactors |
| 5 | **Reversible first** | Prefer reversible actions; create *and verify* a rollback point before risky changes |
| 6 | **Verify reality** | Command success / build success / deploy success prove nothing; verify the real production site semantically |

## 3. Dangerous instructions: the correct response pattern

| Dangerous instruction | Wrong response | Correct response |
|---|---|---|
| "Just delete this data from the database" | Execute DELETE | Confirm environment + target store → equivalent SELECT to preview the exact affected set → backup → ask for confirmation → execute → verify (EXP-020) |
| "Skip the backup, just change it" | Obey | Explain backup cost vs. risk; for HIGH / CRITICAL work insist on a backup or get explicit confirmation (EXP-087) |
| "The site is down, just try some commands" | Try random things | Follow the layered model; run **read-only diagnostics only**; stop-report before any write (SKILL.md §7 / §10) |
| "Print the production environment variables" | Print them | Print variable **names only**, never values; found a secret → don't copy, don't propagate (see §4) |
| "Just switch the DNS" | Change it | Confirm provider + current records + TTL → save old records → define rollback → verify global resolution after (see `dns-domain-ssl.md`) |
| "Commit the user data to the repo to sync it" | Do it | **CRITICAL — refuse.** Runtime never touches git; data never flows through VCS (L1). Offer a file-snapshot backup + controlled sync instead |

The pattern is always: **identify risk → safety measures → confirm when needed
→ reversible execution → verify → record.**

## 4. Secret handling rules [REAL]

1. Never write secrets into git — code, config, or commit messages.
2. Found a secret (code / history / logs)? → **Do not copy it. Do not
   propagate it.** Report type + location only; recommend rotation as leaked
   (L2).
3. Reports contain variable names, never values.
4. Backup packages are sensitive data by default — never land them inside a
   VCS.

## 5. Hard stop conditions [REAL]

STOP → REPORT → ASK when any of these holds: environment unconfirmed ·
authoritative data store unknown · no verified backup · blast radius
unknowable · irreversible deletion possible · secret found · no verified
rollback · DNS change with unknown TTL / records · auth changes with
user-visible trade-offs · incident actively growing · mass user impact
possible · local / remote state disagreement. Full list: SKILL.md §7.

## 6. After every non-trivial task [REAL]

Run the Lesson Review (SKILL.md §9): incident, near miss, failed attempt,
wrong assumption, rollback, security finding, silent failure, repeated
problem, user correction, better method → write a Lesson Candidate to
`.sitepilot/lessons/`. A lesson is not learned until it changes behavior.

---

## Agent Quick Check

1. For any risky instruction: did I identify the risk and take safety measures before acting — instead of refusing or obeying reflexively?
2. Infrastructure claims (database, CDN, deploy, DNS) confirmed from evidence — DETECT → CONFIRM → ACT?
3. Read the code and searched for existing implementations before writing or creating anything?
4. Rollback point created *and verified* before risky changes; blast radius estimated?
5. Secrets: never in git, never copied or propagated, reported by type + location only; production env output shows names, never values?
