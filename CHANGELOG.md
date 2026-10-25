# Changelog

All notable changes to SitePilot are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/).

## [Unreleased]

Post-release **packaging and documentation** fix. No functional, behavioural or
knowledge-base change — the v1.0.1 release and its tag are unchanged.

### Fixed
- **Shell scripts now carry the executable bit in git.** `scripts/site-health-check.sh`
  and `scripts/tests/health-check-regression.sh` were committed as `100644`, so a
  fresh clone could not run `./scripts/...` (only `bash scripts/...`). Both are
  now `100755`. File contents are byte-identical to v1.0.1.

### Changed
- **README invocation examples use `bash scripts/...`**, which works regardless of
  whether the executable bit survives (Windows checkouts, archive extraction).
  The `./scripts/...` form is documented as also valid on Unix-like systems.
- **`docs/validation.md`**: corrected the regression-suite assertion count
  (19 → 20) to match the shipped suite, and listed its composition.

> This entry is under `Unreleased` on purpose: v1.0.1 does **not** contain these
> changes, and its release notes are left as published.

## [1.0.1] - 2026-10-25

The first patch learned in the wild: SitePilot's own health check gave two
false "healthy" verdicts during its first real-world dogfooding run.

### Fixed
- **False PASS when no HTTP response was received.** `curl`'s `000`
  "no response" placeholder combined with a `|| echo "000"` fallback produced
  `"000000"`, which matched no failure branch — an unreachable site was
  reported as `[PASS] Homepage reachable`. Transport status and HTTP status are
  now tracked as separate values, transport failure is never a status verdict,
  and only a well-formed three-digit status reaches the HTTP classification.
- **Expired certificates misclassified due to duration rounding.** Expiry was
  decided from an integer day count, so `-5218` seconds truncated to `0` days
  and a certificate that had been expired for 87 minutes was reported as
  "expires in 0 days" — and passed. Expiry is now decided by comparing absolute
  epoch timestamps; durations are derived afterwards for display only.
- **Overall aggregation and exit codes.** A failing check can no longer be
  reported as "all checks passed": the printed verdict and the process exit
  code are now derived from one place and always agree
  (`0` pass, `3` pass-with-warnings, `1` fail, `2` usage error).
- **TLS inspection assumed port 443.** Non-standard ports produced a
  misleading "could not read certificate" reason. Host and port are now parsed
  from the target URL.
- **Chain failure could be misattributed to the target.** An untrusted-chain
  reading was reported as a generic local warning, which a reader could take to
  mean "the site's certificate chain is broken". The distinction is now made
  explicitly, using evidence already available at that point:
  - request completed, but openssl could not validate → **`tls-environment`**:
    a checker-environment trust issue, explicitly *not* a target problem.
  - request did not complete either → **`tls`**: a target-side TLS/chain issue.
  (`%{ssl_verify_result}` is deliberately not used as the signal: it reads `0`
  even when no response was produced.)

### Added
- **Negative-path regression suite** (`scripts/tests/health-check-regression.sh`).
  Covers the HTTP matrix (200 / 301 / 404 / 500 / DNS failure / connection
  refused / timeout / TLS handshake failure / no response) and the TLS matrix
  (long-valid / renewal window / <24h / expired 1s / expired hours / expired
  days / no certificate / hostname mismatch), plus verdict↔exit-code agreement
  and JSON-mode exit codes. Fixtures are generated locally; no external network
  access required.
- **Lesson correction and supersession.** Lesson lifecycle extended with
  `CHALLENGED` / `CORRECTED` / `SUPERSEDED` / `RETIRED`. A wrong lesson is now
  marked, never deleted, and carries its reason and successor. Local
  `.sitepilot/` lessons gain `ACTIVE` / `CHALLENGED` / `SUPERSEDED` / `RETIRED`.
  Conflict resolution rules added (`references/experience-loop.md` §3, §8b).
- **"Existing code is evidence, not proof of correctness"** as a core principle
  and a security reference section, prompted by a real case where an
  operational lesson taught a vulnerability forward.
- **"Security-sensitive fallbacks must fail closed"** — with the explicit
  boundary that ordinary non-security defaults may still fall back.
- **"Renewed certificate, but visitors still get the old one"** troubleshooting
  path in `playbooks/ssl-incident.md`, plus certificate-served verification
  guidance in `references/dns-domain-ssl.md`.
- **"Health is path-dependent"** guidance in `references/monitoring.md` and
  `references/production-verification.md`.
- **Data-divergence direction** guidance in `references/database-safety.md`.
- `--json` output for automation integration (opt-in, minimal).

### Changed
- Default `User-Agent` is now an honest browser-class string; `--user-agent`
  overrides it. A `403`/`429` is reported as a real refusal with a note about
  possible bot protection — the tool never attempts to bypass site protections.
- TLS chain-trust readings are reported as warnings, not failures: a local
  trust store can lag a newly issued root, which is not a site defect.
- `SKILL.md` core principles extended (14-16) and Definition of Done now
  requires that any new automated check is proven to fail on failing input.
- `docs/experience-mapping.md` appended with EXP-112…EXP-118 (append-only;
  EXP-001…EXP-111 unchanged).

### Lessons
- EXP-112 A health check must prove that its failure paths fail
- EXP-113 Compare absolute timestamps before deriving durations
- EXP-114 Existing code is evidence, not proof of correctness
- EXP-115 Security-sensitive fallbacks must fail closed
- EXP-116 Do not assume the direction of data divergence
- EXP-117 Health is path-dependent
- EXP-118 "Renewed" is not "served": verify TLS from the user's path

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

[1.0.1]: https://github.com/<you>/sitepilot/releases/tag/v1.0.1
[1.0.0]: https://github.com/<you>/sitepilot/releases/tag/v1.0.0
