# Guardrail Review — Six Candidates from the First Audit

Six guardrail opportunities were proposed during the first real-world audit. This
document records the **decision and the reasoning** for each. The point is not to
automate everything — it is to put each rule at the layer where it actually holds.

## Evaluation framework

| Dimension | Question |
|---|---|
| **Impact** | How bad is the failure this would catch? |
| **Generalizability** | Does it apply to most websites, or to one project's layout? |
| **False-positive risk** | How often would it cry wolf on a healthy project? |
| **Implementation complexity** | Can it be done read-only and simply? |
| **Safety** | Can the check itself cause harm? |
| **Maintenance cost** | Will it rot, and who fixes it? |
| **Best layer** | Rule / checklist / static check / health check / pre-commit / pre-deploy / lint / recipe / playbook |

Priority favours: high impact + high generalizability + low false positives +
safe read-only detection.

> **Abstraction rule.** A guardrail must not encode one project's paths. Writing
> `git ls-files data/` into a public skill assumes every site calls it `data/`.
> The defensible form is *"runtime-generated or sensitive persistence must not be
> tracked by source control"*, with the actual paths supplied by project config.

---

## G-01 — Runtime data accidentally tracked by version control

| Dimension | Assessment |
|---|---|
| Impact | CRITICAL — lead to credential and user-data leakage |
| Generalizability | High as a *principle*; low as a literal path |
| False positives | High if paths are guessed; near-zero if user-declared |
| Complexity | Low (`git ls-files` + configured patterns) |
| Safety | Read-only |
| Maintenance | Low |

**Decision: DEFER to a config-driven check (v1.1), principle documented now.**

Rationale: the check silently becomes a false-negative machine if it guesses the
wrong directory. Doing it properly requires a project config declaring
`runtime_data_paths` / `secret_bearing_paths` — a design change, not a patch.
The detection rule is already stated in `references/security.md` and
`checklists/pre-deploy.md`; what's missing is the config surface.

Rejected alternative: hardcoding `data/` — works for one site, misleads everyone
else (worse than nothing, because it reports "clean").

---

## G-02 — Required ignore protections present

| Dimension | Assessment |
|---|---|
| Impact | CRITICAL (pairs with G-01) |
| Generalizability | High as a principle; paths are project-specific |
| False positives | Low with config |
| Complexity | Low |
| Safety | Read-only |
| Maintenance | Low |

**Decision: DEFER with G-01 — same config surface, one implementation.**

Rationale: "which paths must stay ignored" is the same question as G-01 from the
other direction. Shipping two half-checks would be worse than one complete one.
Interim guidance in `checklists/pre-deploy.md` already tells the agent to verify
`git check-ignore` on the sensitive paths.

---

## G-03 — Certificate expiry

| Dimension | Assessment |
|---|---|
| Impact | CRITICAL — a real outage occurred |
| Generalizability | Universal |
| False positives | Very low (an expiry date is unambiguous) |
| Complexity | Already implemented |
| Safety | Read-only |
| Maintenance | Low |

**Decision: IMPLEMENTED in v1.0.1 (health check) + threshold config.**

Rationale: this is the one candidate that is both universal and already
in-scope. The check now decides on absolute timestamps, reports `EXPIRED` as a
failure regardless of how recently it expired, and exposes configurable windows
(`SITEPILOT_TLS_WARN_DAYS`, `SITEPILOT_TLS_CRITICAL_HOURS`).

**Still missing, and deliberately out of scope:** *scheduling and alerting.* A
check nobody runs proves nothing. That belongs to the operator's cron/CI, not to
a read-only script. Recommended pattern documented; wiring it is a per-site
decision.

---

## G-04 — Hardcoded credential fallbacks

| Dimension | Assessment |
|---|---|
| Impact | CRITICAL (a real site ran on a literal in source) |
| Generalizability | High — the pattern shape is language-agnostic |
| False positives | Moderate: legitimate defaults like `|| "utf8"` are common |
| Complexity | Low (grep with a length threshold) |
| Safety | Read-only |
| Maintenance | Medium (patterns per language) |

**Decision: DEFER — documented pattern, no scanner in this patch.**

Rationale: a naive regex produces noise proportional to codebase size and gets
switched off within a week. A useful version needs per-language patterns plus a
"security-sensitive variable names" list — real design work. The actionable part
is already enforceable by a human or agent reading `references/security.md` §11
and running one targeted grep, which `checklists/pre-deploy.md` now names.

Note: this is a case where **a checklist beats a half-tested scanner**.

---

## G-05 — Duplicated IP-extraction implementations

| Dimension | Assessment |
|---|---|
| Impact | HIGH (spoofable limits, spoofable audit trail) |
| Generalizability | Low as a static check — depends on language, framework, file layout |
| False positives | High (any `getClientIP`-shaped function in a test fixture) |
| Complexity | Medium-High |
| Safety | Read-only |
| Maintenance | High |

**Decision: DEFER to project lint / recipe guidance.**

Rationale: detecting "the same concept implemented N times, and one of them is
wrong" is semantic analysis, not grep. The durable fix is architectural — one
module, imported — which the guidance already mandates (`references/security.md`
§6). A public skill should not ship a detector it cannot make reliable.

Best layer here is the **project**: a lint rule banning local redefinitions of
`getClientIP`. SitePilot's job is to state the rule and the reason.

---

## G-06 — Fixed-value authentication comparison

| Dimension | Assessment |
|---|---|
| Impact | CRITICAL (complete admin bypass) |
| Generalizability | Low-Medium — the shape is recognisable but framework-dependent |
| False positives | Moderate (`cookie.value === "dark"` for theme prefs is fine) |
| Complexity | Medium |
| Safety | Read-only |
| Maintenance | Medium |

**Decision: DEFER to project lint + security review; rule stated in v1.0.1.**

Rationale: the pattern is only a vulnerability *in a security context*. A static
detector without semantic context either floods or misses. What generalises is
the principle — *never compare a session against a constant* — which is now in
`references/security.md` §5 and §10.

---

## Summary

| # | Candidate | Priority | Best layer | Decision |
|---|---|---|---|---|
| G-01 | Runtime data tracked by VCS | P1 | config-driven static check | DEFER (v1.1, needs config surface) |
| G-02 | Required ignore protections | P1 | same as G-01 | DEFER (merge with G-01) |
| G-03 | Certificate expiry | P0 | health check + scheduler | **IMPLEMENTED** (v1.0.1) |
| G-04 | Hardcoded credential fallbacks | P1 | pre-commit / checklist | DEFER (documented; checklist now names it) |
| G-05 | Duplicated IP extraction | P2 | project lint | DEFER (guidance only) |
| G-06 | Fixed-value auth comparison | P1 | project lint | DEFER (guidance only) |

**Shipped this patch: 1 of 6. Deferred with a named layer and reason: 5.**

### Why so few

Because a guardrail that guesses wrong is worse than a checklist that states the
rule. Every deferred item above failed on one of two criteria: it needs a
configuration surface that does not exist yet (G-01/G-02), or it needs semantic
understanding that a portable static check cannot supply reliably (G-04/G-05/G-06).

`Validated knowledge density` applies to automation too: **one proven check beats
six noisy ones.**

### A note on monitoring (follow-up, deliberately not built here)

A health check only becomes monitoring when it is **executed and it delivers an
alert**. `cron → log file` is not monitoring — nobody reads the log, which
reproduces the original problem in a new costume.

When wiring SitePilot's checker into a real site later, the shape should be:

```
scheduled check
  → healthy:                stay silent
  → warning/failure threshold reached
  → notification            (channel chosen per environment)
  → the actionable evidence (which check failed, what it saw, where it ran)
```

Two things this implies, both already supported by v1.0.1 but easy to get wrong:

- The alert must carry the **vantage point** — a failure from a server-local
  check and a failure from the public path are different findings (EXP-117).
- The alert must fire on **repeated** warnings, not only on hard failures;
  a certificate inside its renewal window is exactly the case where a quiet
  warning is worth more than a later outage (EXP-118).

Scheduling and alerting are per-environment decisions, so they are not shipped
in a read-only skill. Recorded here so the gap is visible rather than forgotten.

### Roadmap (not in this patch)

1. Project config contract (`sitepilot.config`): `runtime_data_paths`,
   `secret_bearing_paths`, `critical_paths`, TLS thresholds.
2. G-01 / G-02 as one config-driven read-only check, with a self-test proving it
   flags a deliberately tracked fixture.
3. Optional pre-commit hook template wiring that check in.
