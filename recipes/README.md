# SitePilot Recipes — Stack-Specific Experience

> The core `SKILL.md` stays stack-neutral; this directory loads per stack.
> Detect the stack first, then read the matching recipe.

---

## 1. Positioning

SitePilot's knowledge has two layers:

- **Core layer (SKILL.md + references/ + checklists/ + playbooks/)**: stack-agnostic universal
  rules — backup first, semantic verification, layered troubleshooting, stop conditions.
  Applies to any website.
- **Recipe layer (this directory)**: stack-specific traps and safe operating procedures.
  Universal rules from the core layer fail in unexpected ways on concrete stacks — this
  directory holds those "concrete" cases.

Load order: **core SKILL.md → detect stack → matching recipe → act**. Recipes never repeat
core rules; they only add "what the core rule concretely means on this stack".

## 2. How to Detect the Stack

**DETECT → CONFIRM → ACT, never GUESS → ACT.** [REAL]

Judge by evidence files, not by the user's verbal description:

| Evidence file | Inference | Matching recipe |
|---|---|---|
| `package.json` (contains a `next` dependency) | Node / Next.js | `nextjs-selfhost.md` |
| `package.json` (no framework, `data/*.json` as storage) | Node + JSON file store | `node-json-store.md` |
| `requirements.txt` / `pyproject.toml` | Python (Django/Flask/FastAPI) | None yet, see §4 |
| `composer.json` | PHP (Laravel, etc.) | None yet, see §4 |
| `Dockerfile` / `docker-compose.yml` | Containerized deployment | None yet, see §4 |
| `go.mod` / `Cargo.toml` / `Gemfile` / `pom.xml` | Go / Rust / Ruby / Java | None yet, see §4 |
| `wp-config.php` / `wp-content/` | WordPress | None yet, see §4 |
| nginx config + any stack above | Reverse proxy in front | Also read `nginx-reverse-proxy.md` |
| `ecosystem.config.js` or pm2 processes | pm2-managed Node | Also read `pm2-process-manager.md` |
| Single-VPS self-hosting + deploy scripts | Cloud VPS deployment pattern | Also read `cloud-vps-deploy.md` |
| Local Windows dev/ops | Windows environment traps | Also read `windows-dev-environment.md` |

Detection is **additive**: a Next.js site typically matches four recipes at once —
nextjs-selfhost + nginx-reverse-proxy + pm2-process-manager + cloud-vps-deploy. Load all of
them; miss one and you miss a class of traps.

## 3. Standard Recipe Structure

Every recipe follows this seven-section structure; missing a section means incomplete:

1. **WHEN TO USE** — which stack and deployment shape this file is for.
2. **ASSUMPTIONS** — the environment this recipe assumes; if unmet, its conclusions may not
   hold.
3. **COMMON FAILURE MODES** — traps actually stepped on, each with a root cause.
4. **SAFE WORKFLOW** — safe operating order, ready to follow.
5. **VERIFICATION** — how to prove the action really took effect (semantics, not exit codes).
6. **ROLLBACK** — how to get back to a known-good state when things go wrong.
7. **LESSONS LEARNED** — abstracted universal lessons, cross-referenced with the core SKILL.

The marking system matches the core:

- **[REAL]** — from a real incident or verified first-party practice
- **[DERIVED]** — inferred from real evidence, not directly executed
- **[GENERAL]** — general best practice, limited first-party evidence

## 4. What to Do When No Recipe Exists for Your Stack

Handle it honestly; do not pretend to know:

1. **The core SKILL.md applies fully** — backup, verification, rollback, and stop conditions do
   not depend on the stack.
2. Run "local verification" for your stack (its own lint / test / build / smoke); the standard
   is **semantic verification**, not command exit codes. [GENERAL]
3. Record stack-specific findings in your project's local experience store
   (`.sitepilot/lessons/`), distilled through the Lesson Review process.
4. Tell the user explicitly: **"recipe evidence for this stack is insufficient; the following
   advice is general practice, confidence LOW"** — never disguise common sense as combat
   experience. [GENERAL]
5. Encourage contribution: hit a new trap → anonymize per the CONTRIBUTING template → submit;
   after community validation it becomes an official recipe. SitePilot's coverage depends on
   contributors.

## 5. Existing Recipes

| File | Coverage | Primary evidence strength |
|---|---|---|
| `nextjs-selfhost.md` | Next.js App Router self-hosting | Mostly REAL |
| `node-json-store.md` | Node + JSON file store | Mostly REAL |
| `nginx-reverse-proxy.md` | nginx reverse proxy | Mostly REAL |
| `pm2-process-manager.md` | pm2 process management | REAL + DERIVED |
| `cloud-vps-deploy.md` | Single-machine VPS deployment | REAL + GENERAL |
| `windows-dev-environment.md` | Windows local dev/ops | Mostly REAL |

---

*Learn locally. Generalize carefully. Contribute explicitly. Prevent globally.*
