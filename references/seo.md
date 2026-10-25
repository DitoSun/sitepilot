# SEO / GEO Operations — SitePilot Reference

> **Solves:** how to change URLs, generate sitemaps, set crawler policy, and
> automate search-engine submissions without silently destroying organic reach.
> Load with `checklists/seo-change.md`. URL architecture changes are HIGH risk
> (SKILL.md §5); crawler-policy mistakes can close an entire channel unnoticed.

## 1. Public URLs are a long-term contract [REAL]

Once a URL is public it may be indexed, bookmarked, and linked from outside.
Treat every public URL as a stable interface, not an implementation detail.
A route rename or an ID-scheme change without redirects silently 404s every
inbound link and forfeits accumulated weight (EXP-067/073).

**The four-piece bundle — all four, shipped together with the change [REAL]:**

| Piece | What it does |
|---|---|
| 301 redirect | Moves old → new for crawlers and users |
| canonical | Declares the authoritative URL of the new page |
| sitemap | Regenerated with the new URLs |
| internal links | Every internal reference updated; nothing points at the old path |

Changing the ID rule / data model so that old URLs break **is** a URL change —
same bundle, no exceptions.

## 2. Redirect policy [REAL]

| Rule | Detail |
|---|---|
| Temporary → 302, permanent → 301 | Never 301 a temporary move; never leave a permanent move at 302 (EXP-077) |
| Retired page → 301 to parent | A discontinued page 301s back to its section/parent — deleting it leaves a 404 that leaks equity (EXP-077) |
| Seasonal / versioned content | Old season or version directory 301s to the new one; keep the chain short |
| Verify the chain after deploy | curl the old URL: expect 301 → final 200, no loops, no chains longer than needed |

## 3. Sitemap: fake metadata is worse than none [REAL]

| Trap | Consequence | Rule |
|---|---|---|
| `lastmod` hardcoded to generation time | Every fetch claims the whole site just changed; search engines distrust the field and may ignore it entirely (EXP-068) | Write `lastmod` only with a real content timestamp; if unknown, omit the field |
| Inconsistent URL encoding | Non-ASCII URLs encoded in one generator but not another; strict crawlers may skip the entire sitemap (EXP-075) | One encoding rule site-wide; sample-test the generated sitemap, including non-ASCII URLs |

After any sitemap change, fetch it and inspect a sample — "returns 200" proves
nothing about correctness.

## 4. Submission automation: verify business semantics, not HTTP 200 [REAL]

A real incident: a submission script "ran for months with zero success" while
logging success daily (EXP-069, L14).

| Failure mode | What actually happened | Rule |
|---|---|---|
| Wrong payload shape | The API expects a newline-separated URL list; the script sent the sitemap address itself — "success: 1" meant only the sitemap got submitted | Read the API contract; judge the response by its business meaning |
| Dead endpoint | A ping endpoint deprecated years earlier kept answering 302; the script span on empty | Third-party APIs change; submission logic must detect silent death |
| No quota control | Daily quotas exhausted mid-run | Rotate submissions within the daily quota; record last-submitted time per URL |

**A log line saying "success" is not success.** Parse the response body; treat
"ran without errors" as "not yet verified".

## 5. Crawler policy: whitelist first, blacklist last [REAL]

A real incident: a UA blacklist using generic patterns (`/bot/i`, `/spider/i`,
`/crawler/i`) 403'd every AI crawler (GPTBot, ClaudeBot, DoubaoBot,
PetalBot…) — the entire AI-search channel was closed to the site, discovered
only when users reported "AI search can't find us" (EXP-070).

| Rule | Detail |
|---|---|
| No generic UA patterns | Never match `/bot/i`, `/spider/i`, `/crawler/i` — they hit legitimate search and AI crawlers |
| Whitelist → then blacklist | Allow known-good crawlers explicitly; block by exact tool name, never wildcards |
| robots.txt blocks by name | List concrete tools you intend to block; broad wildcards also catch search engines |
| Re-test after every rule change | A new blacklist entry can silently 403 a crawler you needed — probe with real UAs before and after |

## 6. Anti-scrape vs. SEO balance [REAL]

Anti-scraping and crawlability are not opposites — design them together
(EXP-079):

| Principle | Implementation |
|---|---|
| Tiered rate limits | Page tier / normal API tier / heavy API tier / search-engine quota multiplier — each with its own limit |
| Leave a door for real crawlers | Legitimate search and AI crawlers get quota headroom, not a 403 |
| Degrade without blocking indexing | Soft-degrade heavy endpoints (smaller slices) while still returning truthful totals — never hide the site from crawlers |
| Philosophy | Not "block 100%", but "make scraping uneconomical" |

Soft degradation must stay **explicit and observable** — a 200 with silently
truncated data is an incident (SKILL.md §3.9, EXP-038).

## 7. AI-facing assets (llms.txt and friends) [REAL]

Assets aimed at AI agents rot as fast as the site changes. A static file still
describing a removed feature actively misleads AI answers about you (EXP-074).

| Rule | Detail |
|---|---|
| Generate dynamically | Derive from the real route table / real data, not hand-written text |
| Align with reality | Descriptions and counts must match what the routes actually return today |
| Revalidate | Set a sensible revalidation so the asset tracks real changes |

## 8. Crawl statistics: read logs, don't self-call [REAL]

To learn which AI crawlers visit you, analyze access logs — never make the
middleware call its own HTTP endpoint. A real incident: the self-call added
seconds to every AI-crawl request (crawl frequency dropped) and failed
silently besides (EXP-071). Log analysis is cheaper and truthful — and it
depends on logs actually being written (`monitoring.md` §1).

---

## Agent Quick Check

1. URL change? → 301 + canonical + sitemap + internal links shipped together; old URL verified 301 → 200 with no loop.
2. Sitemap regenerated? → `lastmod` real or omitted; encoding consistent; sample fetched and inspected (including non-ASCII URLs).
3. Submission cron? → response body parsed for business success; per-URL last-submitted tracked; daily quota respected.
4. Crawler rules changed? → whitelist intact; blacklist matches exact tool names only; AI crawlers probed and getting 200.
5. Anti-scrape changes? → tiers unchanged for legitimate crawlers; degradation explicit, observable, and never blocking indexing.
