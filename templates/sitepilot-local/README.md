# SitePilot Local Store Templates

Copy this folder into any website project you operate as `.sitepilot/`:

```bash
cp -r templates/sitepilot-local /path/to/your-project/.sitepilot
```

Then fill in `context.md` first — it is what makes an AI agent operating your
site actually **know your site** instead of guessing.

| File | Purpose | Update when |
|---|---|---|
| `context.md` | Authoritative facts about this website (stack, deploy path, data stores, special limits, forbidden zones) | anything structural changes |
| `lessons/` | Confirmed local lessons (one file each, schema in `lesson-template.md`) | a Lesson Capture Trigger fires |
| `incidents/` | Incident records + mini postmortems | any HIGH/CRITICAL incident |
| `decisions/` | Important ops/architecture decisions and why | a non-obvious decision is made |
| `config.md` | Local preferences (risk tolerance, verification depth) | your preferences change |

**Boundary: remember the lesson, forget the secret.** Never store credentials,
tokens, user data, env values, private IPs, or internal URLs here. See
`../references/experience-loop.md` §5.
