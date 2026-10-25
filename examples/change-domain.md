# Example: "I want to change domain"

> Demonstrates: dns-change checklist + high-risk confirmation. Core SKILL §7
> stop conditions + §5 risk model + `checklists/dns-change.md` +
> `references/dns-domain-ssl.md`.

---

**User**: I want to change domain, please operate it for me.

## How SitePilot Thinks

DNS changes are HIGH (DNS/CDN are in the risk model) and carry stop conditions: TTL unconfirmed,
current records unconfirmed, rollback path unverified — hit any one and STOP → REPORT → ASK. **Not
a "figure it out as we go" operation**: resolution has a propagation cycle; mistakes are not
recoverable in seconds. Survey completely first, trade the plan for user confirmation, then act.

## What to Load

- `checklists/dns-change.md` (DNS change checklist)
- `references/dns-domain-ssl.md` (marked: insufficient evidence, mostly general practice)
- `references/seo.md` (URL contract quartet — a domain change is a site-wide URL change)

## Reasoning Process

```
1. UNDERSTAND   Why change? Brand? Acquisition? Only the main domain or the
                whole site? Changing domain ≠ changing DNS only: every site
                URL changes.
2. INSPECT      Current DNS provider (confirm from evidence, do not guess);
                export and save all existing records; check TTL — do not act
                with TTL unconfirmed; certificate situation (the new domain
                needs a cert issued; the old cert's expiry date goes into
                the ledger).
3. ASSESS RISK  HIGH/CRITICAL: affects all users and all indexing.
                Stop-condition check: unknown TTL/current records → stop.
4. PLAN         Lower TTL in advance (shrink TTL before the switch to shorten
                the propagation window); keep the old domain + site-wide 301
                to the new domain (public URLs are a long-term contract,
                indexing authority transfers via 301); dual certificate
                coverage; rollback = change back to the old records (old
                records fully exported).
5. CONFIRM      Hand the plan, blast radius, and rollback path to the user
                for explicit confirmation. Product trade-offs (e.g. whether
                the old domain is kept permanently) are user decisions, not
                agent decisions.
6. EXECUTE      Execute per the checklist, recording each step (the change
                log records "why").
7. VERIFY       Verify resolution from multiple global locations; HTTPS chain
                complete; old-domain 301 site-wide in effect (sample deep
                URLs); submit the change in search engine webmaster
                platforms.
```

## Key Decision Points

1. **TTL is a hidden time bomb**: switching records with unknown TTL makes the propagation window
   uncontrollable and rollback equally slow. Check, lower, then switch. [Stop condition 8]
2. **A domain change is an SEO event, not just technical**: site-wide 301 + canonical + sitemap +
   internal links must be in sync; missing one is a large loss of indexing authority. [REAL
   principle]
3. **The old domain must not be dropped**: keep its 301 for at least one full indexing cycle;
   retiring it directly = years of accumulated entrances become 404s.
4. **Credentials and ledger**: new-domain certs, DNS provider access — record names/locations only,
   never values; found secrets are never copied or propagated. [REAL]
5. **Be upfront about thin first-party evidence**: DNS/SSL first-hand experience is limited; the plan
   is general best practice, marked — never disguised as combat experience.

## How to Verify

- Resolution from multiple locations (regions/carriers) returns the new address; the old domain
  still resolves and 301s to the matching new-domain page (sample deep URLs, not just the homepage).
- New-domain HTTPS certificate chain complete, HTTP→HTTPS redirect correct.
- In-site absolute links/resource references still hardcoding the old domain (grep the whole
  project).
- After the webmaster-platform submission, watch indexing and traffic data (by week, not by hour).

## Lesson Review

A domain change is low-frequency, high-risk, and high Lesson value: measured propagation windows,
missed hardcoded references, verification blind spots — all into `.sitepilot/lessons/`. Any
"nearly forgot" item (e.g. a hardcoded old domain) upgrades to a mandatory dns-change checklist
item. **For a once-in-a-lifetime operation like a domain change, the checklist left for next time
is the most valuable thing.**