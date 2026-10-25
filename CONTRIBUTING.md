# Contributing to SitePilot

The most valuable contribution is not code — it is **a lesson from a real
incident**. SitePilot's knowledge base only stays useful if every rule traces
back to something that actually happened.

## What we accept

| Type | Examples |
|---|---|
| **Lesson / incident case** | A reproducible failure mode with a root cause |
| **Checklist improvement** | A check that would have caught a real problem |
| **Playbook path** | A new failure route in an existing playbook |
| **Stack recipe** | Traps specific to a stack we don't cover yet |
| **Automation** | A read-only check that detects a known failure mode |
| **Docs fix** | Anything wrong, stale, or unclear |

## The contribution loop

```
Incident → Evidence → Root Cause → Lesson → Generalization
→ Classification → Privacy Review → Contribution
```

## Submitting a lesson

Use this template (mirrors `templates/sitepilot-local/lesson-template.md`):

```markdown
## Problem
## Context
## Root Cause
## Wrong Approach / Failed Attempts
## Correct Solution
## Generalized Lesson
(the stack-neutral version — what should every website do differently)
## Applicability
Universal | Most Websites | Specific Stack: ___ 
## Evidence Type
REAL-WORLD INCIDENT | DERIVED LESSON | GENERAL BEST PRACTICE
## Confidence
HIGH | MEDIUM | LOW
## Suggested Skill Change
(core rule / reference / checklist / playbook / recipe / automation)
## Privacy Check
- [ ] No credentials, tokens, cookies, or secrets
- [ ] No user data or database contents
- [ ] No private IPs, internal URLs, or infrastructure details
- [ ] No private project identifiers (anonymize "project X")
```

Open an Issue (or PR if you also propose the exact wording). Include the
Privacy Check — submissions without it will be asked to add it.

## Review criteria for lessons

1. Real problem description (not a hypothetical)?
2. Root cause, not just a symptom?
3. Reproducible pattern, not a one-off coincidence?
4. Not a duplicate of an existing rule?
5. Generalizable without the private context?
6. Free of private information?
7. Correct destination: core rule / reference / checklist / playbook / recipe?
8. Detectable by automation (bonus — prevention beats documentation)?

## Evidence honesty

Every rule carries provenance: `[REAL]` (real incident), `[DERIVED]`
(inferred from real evidence), `[GENERAL]` (general best practice, limited
first-party evidence). Please keep this honest — it is SitePilot's credibility.

## What we will not merge

- Lessons whose only evidence is "it seemed like a good idea"
- Personal preference presented as universal truth
- Anything containing secrets, user data, or private infrastructure
- Automated bulk rewrites that change wording without adding evidence

## Development

- No build step. Markdown + one bash script.
- `scripts/site-health-check.sh` must stay **read-only**: GET/HEAD requests,
  local TLS inspection, timeouts, no secret logging, no side effects. Run
  `bash -n scripts/site-health-check.sh` before submitting changes.
- Keep SKILL.md short and strong. Detailed knowledge belongs in
  `references/` (Progressive Disclosure).
