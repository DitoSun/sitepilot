# Playbook — HTTP 500 Errors

> Iron rule: read the log timeline first, then classify. Restarting / changing code without reading logs is forbidden. [REAL]

## TRIAGE

- [ ] Scope of the 500s: all pages / specific endpoints / specific users / specific time window?
- [ ] Is the response body a framework default error page or a custom error page? (A custom page means the app layer has caught it)
- [ ] When did it start: compare log times against the last deploy / restart / config change.

## LOCATE LAYER — Classify First, Then Locate

**Type A: 500 on startup (missing config, fail-closed)** [REAL]
- [ ] Signature: 500s as soon as the process starts; logs point to "missing config / secret not set".
- [ ] Check: are all required environment variable **names** present (check names only, never print values).
- [ ] Check: any secret falling back to a hardcoded default — running production on a fallback secret equals having no secret. [REAL]
- [ ] Direction: after filling in config, explicitly restart; confirm the fail-closed behavior matches expectations (refusing service when config is missing beats fail-open). [REAL]

**Type B: 500s appearing at runtime (dependency failure)** [REAL]
- [ ] Signature: previously healthy, 500s starting at some moment; logs point to data reads / external calls / timeouts.
- [ ] Check: database / data files readable and complete; upstream API / SMTP / third-party service status; whether the connection pool is exhausted.

**Type C: old vs new client noise** [REAL]
- [ ] Distinguish by log mtime vs restart time: errors with pre-restart timestamps are old client / old tab noise, not new-code bugs.

**Type D: data / file corruption** [REAL]
- [ ] Data file structure validation (parseable, record counts normal, key fields present); when corruption is suspected, snapshot the scene first, then restore from backup and verify.

## ASSESS IMPACT

- [ ] Whole core path down (CRITICAL) or edge features (HIGH)? Is it growing? What shape is the error-rate curve?

## MITIGATE / RECOVER

- [ ] Missing config → first confirm the new config is "readable by the code and has a place to be set", then fill in config and restart (the reverse order locks you out). [REAL]
- [ ] Deploy-introduced → evaluate rolling back to the previous build.
- [ ] Data corruption → restore from backup, three-step verification (two-way md5 → structure / record counts → key-field sampling). [REAL]

## Rollback Triggers

- [ ] Core features 500 / auth fully failing / data anomalies → roll back to restore service first, then investigate root cause. [REAL]

## VERIFY

- [ ] Semantic verification: homepage content correct, key API record counts and freshness normal, anonymous rejected / login succeeds / logout invalidates.

## INVESTIGATE

- [ ] Root-cause chain of "why": why was config missing? Why no startup check? Why didn't monitoring catch it?
- [ ] Scan the whole site for the same pattern: which other config items / data read points have the same hazard.

## LEARN

- [ ] Write "missing config fail-closed + explicit startup check" into rules; add automated health checks and alerts.
