# Experience Log — Post-v1.0.0 Additions

Entries here are **append-only**. EXP-001 … EXP-111 were mined during Phase 1
and live in `docs/experience-mapping.md`. Everything from **EXP-112** onward was
learned after v1.0.0 was released — mostly by SitePilot failing at its own job
during the first real-world dogfooding run.

Provenance vocabulary:

| Marker | Meaning |
|---|---|
| `REAL-WORLD DOGFOODING` | SitePilot's own defect, found by operating a real site |
| `LOCAL INCIDENT` | Observation from a specific production website |
| `DERIVED FROM INCIDENT` | Inferred from a real incident, not directly executed |
| `GENERAL BEST PRACTICE` | General engineering knowledge, limited first-party evidence |

---

## EXP-112 — A health check must prove that its failure paths fail

- **Provenance:** REAL-WORLD DOGFOODING (SitePilot's own bug)
- **Date:** 2026-10-25
- **Source incident:** SitePilot v1.0.0 health check returned `PASS` for a site
  that could not be reached at all, and for a certificate that had expired 87
  minutes earlier.
- **Problem:** Two independent silent false-pass bugs shipped in the only
  automated tool the skill provides.
- **Root causes:**
  1. `curl`'s `000` "no response" placeholder plus a `|| echo "000"` fallback
     concatenated into the string `"000000"`, which matched neither the
     equality check (`= "000"`) nor the numeric failure branches, so execution
     fell through to the PASS branch.
  2. Expiry was decided from an integer day count (`(end - now) / 86400`),
     which truncates a negative sub-day value to `0` — "expired" became
     "expires today".
- **Why testing missed it:** every test exercised a healthy site, where the
  output is correct. The failure branches were never executed.
- **Generalized lesson:** A check that has not demonstrated its failure paths
  cannot be trusted. For every failure branch, construct an input that must
  trigger it and assert the *verdict* and the *exit code*.
- **Sharper form:** Monitoring software that converts failure into success
  creates false confidence, and may be more dangerous than no check at all.
- **Applicability:** Universal
- **Confidence:** HIGH (two reproducible bugs, both fixed and regression-tested)
- **Landed in:** `SKILL.md` §3.15 · `references/monitoring.md`
  ("Monitoring must be monitored") · `scripts/tests/health-check-regression.sh`

---

## EXP-113 — Compare absolute timestamps before deriving human-readable durations

- **Provenance:** REAL-WORLD DOGFOODING (SitePilot's own bug)
- **Date:** 2026-10-25
- **Source incident:** Certificate expired 5,218 seconds earlier; the check
  computed `-5218 / 86400 = 0` days and reported "expires in 0 days".
- **Root cause:** A rounded duration was used as a **decision input** instead
  of a display artifact.
- **Generalized lesson:** Decide on absolute timestamps; format afterwards.
  Any `(a - b) / 86400` comparison against `0` erases the entire "already
  expired" state.
- **Where else this hides:** token/session TTL checks, "days since last
  backup", retry windows, subscription expiry, cache-age math.
- **Applicability:** Universal
- **Confidence:** HIGH
- **Landed in:** `references/dns-domain-ssl.md` §3b (+ state model) ·
  regression cases "expired 1s / 3h / 5d"

---

## EXP-114 — Existing code is evidence, not proof of correctness

- **Provenance:** REAL-WORLD DOGFOODING (found by audit; guidance defect)
- **Date:** 2026-10-25
- **Source incident:** A project's own operational notes instructed *"new admin
  endpoints must copy the existing cookie convention used in production."*
  Three endpoints followed it faithfully. The existing convention **was** the
  vulnerability: a fixed cookie value compared as a session check.
- **Root cause:** The lesson conflated two different goals — "don't reinvent"
  and "the existing implementation is safe". Only the first is true.
- **Generalized lesson:** `Read before write` and `Search before create` prevent
  duplicate work; they do not certify correctness. Reuse a pattern only after
  validating its assumptions. For authentication, authorization, identity,
  secrets, data access, and trust boundaries: never copy by example — extract
  one shared module instead.
- **Extra lesson about lessons:** a lesson that says "copy what exists" is a red
  flag unless it also says "after verifying that what exists is correct".
  A wrong lesson, faithfully followed, propagates the defect indefinitely.
- **Applicability:** Universal (all security-sensitive code)
- **Confidence:** HIGH
- **Landed in:** `SKILL.md` §3.14 · `references/security.md` §10 ·
  `references/experience-loop.md` §3 (supersession mechanism)

---

## EXP-115 — Security-sensitive fallbacks must fail closed

- **Provenance:** REAL-WORLD DOGFOODING
- **Date:** 2026-10-25
- **Source incident:** Admin login used
  `process.env.ADMIN_PASSWORD || "<hardcoded literal>"`, and the variable was
  **not configured** — so production was silently accepting a password that
  lives in source, in git history, and in every clone. The system looked
  healthy and even logged in.
- **Root cause:** A resilience pattern (fallback to a default) applied to a
  security decision. Misconfiguration became silent success instead of loud
  failure.
- **Generalized lesson:** If a fallback supplies a secret or bypasses a security
  decision, it must fail closed. Non-security defaults (timeouts, page sizes)
  are fine to fall back.
- **Boundary — this is not "all fallbacks are bad":** the rule applies to
  values whose absence must be *visible*, not to ordinary operational defaults.
- **Supporting practices:** validate configuration at startup, not at first
  use; report the missing variable *name*, never a default value.
- **Applicability:** Universal
- **Confidence:** HIGH
- **Landed in:** `references/security.md` §11

---

## EXP-116 — Do not assume the direction of data divergence

- **Provenance:** LOCAL INCIDENT (production site audit)
- **Date:** 2026-10-25
- **Source incident:** The local user table held **more** rows than production
  (7,539 vs ~6,447) — the opposite of the reflexive "local is a stale, smaller
  copy" assumption.
- **Root cause:** Divergence direction was assumed from experience rather than
  established from evidence (write path, timestamps, replication direction).
- **Generalized lesson:** Before reconciling two sources, establish source of
  truth, write path, timestamps, completeness per dimension, and replication
  direction. Then choose a direction — or choose to investigate instead.
- **Why it matters:** acting on the wrong assumption pushes test data and
  resurrected deletions into the authoritative store.
- **Applicability:** Most Websites
- **Confidence:** MEDIUM (single observed case, high impact)
- **Landed in:** `references/database-safety.md`

---

## EXP-117 — Health is path-dependent

- **Provenance:** LOCAL INCIDENT (production site audit)
- **Date:** 2026-10-25
- **Source incident:** From the operator's workstation every request to the
  production domain failed, because the local network layer rewrote DNS to a
  reserved range and routed traffic to a local proxy. The production site was
  healthy the whole time.
- **Root cause:** A check result was interpreted without its vantage point.
- **Generalized lesson:** A check result is only valid for the network position
  it ran from. Server-local, LAN, external, through-CDN, and through-public-DNS
  are different questions. When the vantage point is suspect, the answer is
  "unknown", not "down".
- **Applicability:** Most Websites
- **Confidence:** HIGH (reproducible)
- **Landed in:** `references/monitoring.md` ("Health is path-dependent") ·
  `references/production-verification.md`

---

## EXP-118 — "Renewed" is not "served": verify TLS from the user's path

- **Provenance:** REAL-WORLD DOGFOODING (recovery verification)
- **Date:** 2026-10-25
- **Source incident:** After a certificate renewal, the meaningful question was
  not "is the file new?" but "what certificate do visitors receive?". Several
  layers can keep serving the old one: an unreloaded proxy, a CDN with its own
  certificate, a load balancer, a second node, a stale process on :443, or DNS
  pointing elsewhere.
- **Root cause:** Recovery was about to be judged by an internal fact (file
  timestamp) instead of the user-visible outcome.
- **Generalized lesson:** Action completed ≠ recovery verified. Read the served
  certificate from outside, over the public hostname, sample several times, and
  compare fingerprints. Then confirm the user-visible outcome (no browser
  warning, future expiry, HTTP→HTTPS redirect intact).
- **Corollary observed in the same incident:** a local `openssl s_client` can
  report an untrusted chain (`code 20`) purely because the *local* trust store
  lags a new root — so chain readings from one machine are not authoritative.
- **Applicability:** Universal (any TLS-terminating layer)
- **Confidence:** HIGH
- **Landed in:** `references/dns-domain-ssl.md` §3c ·
  `playbooks/ssl-incident.md` (renewed-but-not-served branch) ·
  `SKILL.md` §3.16

---

## Summary of additions

| ID | Title | Provenance | Applicability |
|---|---|---|---|
| EXP-112 | A health check must prove its failure paths fail | DOGFOODING | Universal |
| EXP-113 | Compare absolute timestamps before deriving durations | DOGFOODING | Universal |
| EXP-114 | Existing code is evidence, not proof of correctness | DOGFOODING | Universal |
| EXP-115 | Security-sensitive fallbacks must fail closed | DOGFOODING | Universal |
| EXP-116 | Do not assume the direction of data divergence | LOCAL INCIDENT | Most Websites |
| EXP-117 | Health is path-dependent | LOCAL INCIDENT | Most Websites |
| EXP-118 | "Renewed" is not "served" | DOGFOODING | Universal |
