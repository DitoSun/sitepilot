# Security — SitePilot Reference

> **Solves:** how to handle credentials, identity, IP extraction, locking,
> normalization, and sessions so a "security fix" does not become the next
> incident. Load with SKILL.md §7 Stop Conditions. Most items here are HIGH
> risk; auth-system failure is CRITICAL — do not act silently.

## 1. Credentials have three forgotten surfaces [REAL]

Everyone remembers code constants — and forgets the rest (L2):

| Surface | Real trap |
|---|---|
| Code & config | Credential hardcoded as a "temporary" default value, pushed to a public repo (EXP-002) |
| Git config | Plaintext PAT/token embedded in `.git/config` (EXP-004) |
| Server runtime | cron jobs, old startup scripts, and superseded builds still running with old credentials / old code (EXP-004/007) |

**Rule:** the audit checklist covers all three. "Fixed locally" ≠ "fixed in
production" — old server scripts keep old behavior alive (EXP-007).

## 2. A fallback secret is no secret [REAL]

Multiple services fell back to hardcoded default secrets; production actually
ran on the fallback for a long time (EXP-005).

| Rule | Detail |
|---|---|
| No hardcoded credential defaults | Missing config must not silently resolve to a built-in value |
| Fail closed | Missing secret → explicit startup check / error — fail-closed beats fail-open |

## 3. Rotation: leaked means rotated [REAL]

| Rule | Detail |
|---|---|
| Credential in git / history / logs = treat as leaked → rotate (EXP-002/004) | Assume compromise; rotation is the only remedy |
| Confirm the new value has somewhere to be configured **before** rotating the old one (EXP-009) | Rotating an admin password before the code can read the new value locks everyone out |

## 4. Secret handling rules [REAL]

1. Never write secrets into git — code, config, or commit messages.
2. Found a secret (code / history / logs)? → **Do not copy it. Do not
   propagate it.** Report its *type* and *location* only, and recommend
   rotation as leaked (L2, EXP-002/004).
3. Reports list variable **names**, never values.
4. Backup packages are sensitive data by default — their destination must
   never be inside a VCS (EXP-006).

## 5. Server-side identity comes only from the server-side session [REAL]

| Anti-pattern | Real consequence | Rule |
|---|---|---|
| Trusting `userId` / `username` self-reported in the request body | Account-takeover chain: any user could edit others' profiles and bind others' emails (EXP-048) | Write endpoints derive identity **only** from the server-side session |
| UGC endpoints (comments, collections, notifications) open to anonymous writes | Anyone could post as anyone (EXP-049) | UGC write endpoints require a session by default |
| Guessing which methods to lock by HTTP verb | A "write-looking" POST was actually a logged-in feature (price reports); the admin actions were on PATCH/DELETE — locking by verb would have cut a real feature (EXP-054) | **Before adding auth, grep the callers and learn each method's true semantics; lock by least privilege, not by method name** |
| Keeping a "self-reported userId fallback" during a trust-boundary upgrade | A pragmatic dual track is acceptable, but the fallback must never lower the trust level (EXP-055) | Dual-track OK for migration; document the boundary in comments — fallback never lowers the water line |

Security fixes must ship together with their migration story (e.g. smooth
re-login UX) — a fix that sits undeployed protects no one (EXP-031/050).

## 6. Client IP extraction: one definition, globally [REAL]

A real incident: code read the **leftmost** X-Forwarded-For segment while the
proxy preserved the client-forged value on the left → copy counters could be
inflated infinitely; rate limiting was theater (EXP-052, L9).

| Rule | Detail |
|---|---|
| XFF first segment is forgeable | "Leftmost XFF" = letting the client choose its own IP |
| Proxy layer overwrites | The reverse proxy overwrites `x-real-ip` from the connection's remote address — unforgeable |
| App layer fallback | If XFF must be used as fallback, take the **last** segment |
| Both layers aligned | Proxy and application must agree; write the definition into comments and keep it identical everywhere |
| Fix the class | After fixing, grep the whole project — copies of the helper exist in more places than you remember |

## 7. Lockout and rate limiting are per-account or per-IP — never global [REAL]

Login-failure lockout implemented as one global counter: an attacker could
lock out **every** user at once (EXP-053).

| Rule | Detail |
|---|---|
| Dimension | Lockout / rate-limit state keyed by account and/or IP |
| Never global shared state | One counter for all users is a denial-of-service button |

## 8. Normalization must be symmetric [REAL]

Login compared a lowercased input against a stored, never-normalized username:
a large share of accounts containing uppercase letters could never log in, and
accounts without a bound email were locked out entirely (EXP-056, L10).

| Rule | Detail |
|---|---|
| Same side, both directions | Storage and query use the identical normalization rule |
| Order matters | Fix: exact match first, then case-insensitive fallback — reversed order breaks on accounts differing only by case (many such groups existed) |
| Validate with boundary data | Before touching order-sensitive logic, test against the real edge cases |

## 9. Verification codes, sessions, key rotation [REAL]

| Item | Failure | Rule |
|---|---|---|
| Verification codes | Few digits + non-cryptographic randomness + plaintext in a file | Cryptographic randomness + hashed storage + rate limiting (EXP-057) |
| Sessions | Session store in a plain file — wiped or lost on restart = "random logouts" | Session storage must carry a persistence guarantee; file-as-session has none (EXP-058) |
| Key rotation | Rotating the secret invalidates all issued tokens at once | Design rotation **with** the invalidation strategy: automatic re-issue on failure, or a grace period (EXP-051) |

---

## 10. Existing code is evidence, not proof of correctness [REAL]

A real pattern: a project's own operational notes said *"new admin endpoints
must copy the existing cookie convention used in production."* Three endpoints
were written that way — faithfully copying a convention that turned out to be
the vulnerability itself (a fixed cookie value compared as a session check).

`Read before write` and `Search before create` prevent duplicate work. They do
**not** imply that the existing implementation is safe. Separate the two ideas:

| Goal | Correct action |
|---|---|
| Don't reinvent a feature | Find and reuse the existing implementation |
| Don't inherit a vulnerability | Review the existing implementation's security properties **before** copying it |

Rules:

1. **Reuse the pattern only after validating its assumptions.** What does it
   assume about trust, input, storage, and identity? Are those assumptions
   still true here?
2. **Never copy security-sensitive code by example.** For authentication,
   authorization, identity, secrets, database access, trust boundaries, and
   any security control: read the implementation, state what it actually
   verifies, and only then reuse — or better, extract one shared module and
   delete the copies.
3. **"The site has always worked this way" is not a security argument.**
   Working ≠ secure. A bypassed check works perfectly for everyone.
4. **Count the copies.** If the same check exists in 3+ files, the copies are
   drifting, and at least one is probably wrong. One implementation, imported.
5. **Existing code is also a signal about the team's intent** — but intent is
   not implementation. Verify what the code *does*, not what it was meant to do.

> Reuse patterns only after validating their assumptions and security
> properties. (EXP-114)

## 11. Security-sensitive fallbacks must fail closed [REAL]

A fallback is a resilience technique. In security-sensitive paths it is
usually a hazard, because it converts "misconfigured" into "silently running
on a guess."

The dangerous shape:

```js
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || "some-literal";
```

If the variable is not set, the system does **not** fail — it accepts a
password that lives in the source code, in git history, and in every clone.
It looks healthy. It even logs in. That is worse than an outage.

Use this decision rule:

| Situation | Correct behavior |
|---|---|
| Non-security default (timeout, page size, locale, retry count) | A sensible fallback is fine |
| Security-sensitive value (password, key, token, secret, signing key, admin credential) | **Fail closed.** Refuse to start the feature, or refuse the operation, with a loud, explicit error |
| Security-sensitive value with an "obviously local" default | Still fail closed — "just for dev" defaults ship to production |
| Degraded-but-safe mode exists (e.g. disable the feature, not the check) | Prefer disabling the protected capability over weakening the check |

Two supporting practices:

- **Check configuration at startup, not at first use.** A missing admin
  credential should fail at boot with a clear message, not at 3am on first
  login attempt.
- **Do not let the error message reveal the expected value.** Report the
  missing variable name, never a default.

Not every fallback is dangerous. The rule is narrower than "all fallbacks are
bad": *if the fallback supplies a secret or bypasses a security decision, it
must fail closed instead.* (EXP-115)

## 12. History rewrites must be verified, not assumed [REAL]

After rewriting git history to purge leaked data (`filter-repo` /
`filter-branch`), verify what was actually removed with a full tree listing
(`git ls-tree -r <ref>`) — a rewrite that targeted "large files" can leave
other sensitive files (personal notes, configs, smaller data files) in place,
pushed and public. Removed from the index ≠ removed from every clone.
(EXP-008)

## 13. Anti-scraping is graded, not absolute [REAL]

A mature anti-scrape posture is layered (UA screening → browser fingerprints
→ signed tokens → tiered rate limits) with the philosophy of making scraping
*uneconomical*, not impossible. Always leave a door for legitimate crawlers —
see `references/seo.md` §5. UI-level tricks (disabling text selection, hiding
copy buttons) are speed bumps, never security boundaries; do not treat them
as controls in a risk assessment. (EXP-099, EXP-101)

## Agent Quick Check

1. Credential audit covered all three surfaces — code/config, git config, server cron/old scripts?
2. No hardcoded credential defaults anywhere; missing secret fails closed at startup?
3. Found a secret? Not copied, not propagated — type + location reported, rotation recommended; rotation target has a configured home first?
4. Every write endpoint takes identity from the server session only; new auth rules verified against grepped call sites, not method names?
5. IP extraction definition aligned across proxy + app layers; lockout / rate limits per-account or per-IP; normalization symmetric on both storage and query sides.
