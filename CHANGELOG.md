# Changelog

All notable changes to SitePilot are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/).

## [1.0.0] - 2026-10-25

### Added
- **SitePilot v1 — initial public release.**
- Core `SKILL.md`: Universal Change Workflow, 4-level Risk Model,
  13 Stop Conditions, "Never guess production infrastructure",
  "Verify semantics, not only transport success", "Fix one instance, scan
  the class", Definition of Done.
- **Self-Improving Experience Loop** (`references/experience-loop.md`):
  two-layer experience system (Local Site Knowledge + Generalized
  Experience), 12 Lesson Capture Triggers, lesson status lifecycle
  (CANDIDATE → CONFIRMED LOCAL → GENERALIZABLE → PROMOTED), lesson record
  schema, `.sitepilot/` local store with templates, mandatory mini
  postmortem for HIGH/CRITICAL incidents, recurrence detection, lesson
  effectiveness review, explicit-approval-only upstream contribution,
  experience provenance and confidence levels, community merge criteria,
  knowledge promotion model.
- 16 references: change-management, deployment, production-verification,
  troubleshooting, incident-response, rollback, database-safety,
  backup-recovery, seo, security, performance, monitoring,
  dns-domain-ssl, content-operations, ai-agent-safety, experience-loop.
- 6 checklists: pre-deploy, post-deploy, database-change, seo-change,
  dns-change, incident.
- 7 playbooks: website-down, http-500-errors, bad-deployment,
  database-incident, dns-incident, ssl-incident, performance-incident.
- 6 stack recipes + recipe loader guide: nextjs-selfhost, node-json-store,
  nginx-reverse-proxy, pm2-process-manager, cloud-vps-deploy,
  windows-dev-environment.
- 6 worked examples of agent reasoning.
- `scripts/site-health-check.sh`: read-only health check (connectivity,
  redirect chain, timing, TLS expiry, security headers, crawler assets,
  critical paths). Safe by default: GET/HEAD only, timeouts, no secret
  logging, no side effects.
- `templates/sitepilot-local/`: local experience store templates
  (context, lesson, incident, decision, config).
- Evidence honesty system: every rule marked `[REAL]` / `[DERIVED]` /
  `[GENERAL]` with confidence levels.

### Knowledge base
- 111 deduplicated lessons mined from a real production website's incident
  history (git history, ops handover documents, code traces, and a personal
  operations knowledge base), generalized and classified for stack-neutral
  use. See `docs/validation.md` for coverage and validation results.

[1.0.0]: https://github.com/<you>/sitepilot/releases/tag/v1.0.0
