# Example: "Help me check SEO"

> Demonstrates: SEO checks use `references/seo.md` +
> `checklists/seo-change.md`. Principles: fake metadata is worse than none;
> public URLs are a long-term contract.

---

**User**: Help me check SEO.

## How SitePilot Thinks

"Check SEO" must first ask: **check what, for whom** — debugging "indexing dropped", or a routine
checkup? Different goals mean different check items. Two core iron laws: ① metadata **fake data is
worse than none** (lastmod written as "now" across the board makes engines ignore the entire
field); ② public URLs are a long-term contract; changes need the redirect quartet. The check is
read-only and can be done boldly; pass the seo-change checklist before proposing changes.

## What to Load

- `references/seo.md` (URL contract quartet, sitemap semantics, submission job verification, AI
  crawlers)
- `checklists/seo-change.md` (SEO-related change checklist)
- `scripts/site-health-check.sh` (read-only health check: status codes/redirect
  chains/robots/sitemap)

## Reasoning Process

```
Read-only checks (can be done boldly):
1. Key page status codes and redirect chains: any 404s, any redirect loops,
   do retired pages 301 to the parent
2. robots.txt: any accidental blocks (never use wildcards in UA blacklists —
   /bot/i would block GPTBot/ClaudeBot together, closing the whole AI search
   channel)
3. sitemap.xml: are URLs percent-encoded (URLs with Chinese left unencoded
   may be skipped wholesale by strict crawlers); is lastmod real (uniform
   new Date() = fake data)
4. canonical and URL structure: do historically renamed URLs have a 301 to
   catch them
5. Titles/descriptions: are key pages missing or duplicated
6. Assets for AI (llms.txt class): aligned with real routes, any stale
   content
7. Log side: is access_log being written (the foundation of SEO monitoring);
   crawler access records
```

## Key Decision Points

1. **Finding a problem ≠ fixing it immediately**: SEO changes start at MEDIUM (changing URL
   architecture is HIGH). URL changes must sync the quartet: 301 + canonical + sitemap + internal
   links — missing one is lost authority. [REAL]
2. **Fake data cleanup takes resolve**: fake lastmod makes search engines ignore the entire field —
   "no real timestamp, write nothing" beats writing fake for indexing. [REAL]
3. **Submission-class jobs verify business semantics**: for the cron job submitting sitemaps, "has
   logs" is not "has success" — wrong parameters once meant daily success yet nothing indexed. Parse
   the business semantics of return codes. [REAL]
4. **Anti-scraping vs SEO balance**: block UAs by specific list, not wildcards; fallbacks (e.g.
   rate-limit slicing) must not keep legitimate crawlers out of indexing. [REAL]

## How to Verify

- After changes: redirect chains curl-tested (old URL → 301 → new content, ending in 200).
- sitemap sampled for real (**including non-ASCII URLs**) parses normally.
- After robots changes: legitimate crawler and AI crawler UAs not in the block list.
- Key pages show new title/description/canonical after hard refresh.
- Submission jobs: cross-check console indexing data for several consecutive days, not just script
  logs.

## Lesson Review

SEO checks often dig up "chronic conditions" (fake lastmod, unencoded, dead links) — high-value
Lessons: write into `.sitepilot/lessons/`, and upgrade "this class of metadata must not be faked"
to a checklist item. URL contract findings involving historical structure changes also enter the
change log (record "why", not just "what").