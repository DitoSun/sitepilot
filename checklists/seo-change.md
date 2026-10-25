# Checklist — SEO / GEO Change

> Publicly exposed and potentially indexed URLs are a **long-term contract**, not an internal implementation detail. [REAL]
> Fake metadata is worse than none. [REAL]

## A. Changing URLs (structure / path / ID rules)

- [ ] Four-piece sync, none optional: **301 redirect + canonical + sitemap + internal links**. [REAL]
- [ ] Check all old links: find every old URL from logs / index data / internal links, verify each redirects to the new address. [REAL]
- [ ] Use 302 for temporary migration, 301 only for permanent migration — do not use them backwards. [REAL]
- [ ] Retired pages 301 back to the parent directory, leaving no 404 orphan pages. [REAL]
- [ ] Data model / ID rule changes (adding prefixes, renaming keys) also get permanent redirects to transfer weight; do not just change the new and ignore the old. [REAL]
- [ ] Record key pages' index / ranking baselines before and after the change, for post-impact assessment. [GENERAL]
- [ ] Check 404 monitoring / logs after the change: confirm no old URLs are missing redirects. [REAL]

## B. Sitemap & Metadata

- [ ] Sitemap semantics are real: `lastmod` only written when a real data timestamp exists; omit it if unavailable — fake lastmod triggers search engine trust mechanisms that get the field ignored entirely. [REAL]
- [ ] URL encoding consistent site-wide: the same encodeURIComponent rules; sample-test after generation (including non-ASCII URLs). [REAL]
- [ ] title / description / H1 change in sync with the actual page content — do not just check whether the code changed. [DERIVED]
- [ ] Structured data matches actual rendered content: verify by really running against the live page, do not trust comments. [REAL]

## C. Search Engine Submission

- [ ] After submission, verify business semantics: parse the real result in the response body, not "HTTP 200 / there are logs". [REAL]
- [ ] Be able to discover dead submission endpoints (deprecated / revamped) — a script that "ran for months with zero successes" must be taken down and rebuilt. [REAL]
- [ ] Rotate submissions per the platform's daily quota; record each URL's last submission time. [REAL]
- [ ] canonical points to self, and site-wide protocol / domain variants are unified (www vs non-www, http vs https — pick exactly one set). [DERIVED]
- [ ] Before submitting, confirm the sitemap is fetchable and format-valid (sample-test, including non-ASCII URLs). [REAL]

## D. Anti-Bot Rules (the step most likely to hurt SEO)

- [ ] Never use broad patterns like `/bot/i`, `/spider/i`, `/crawler/i` in UA blacklists — they kill AI crawlers and legitimate crawlers alike, closing the entire AI search channel to your site. [REAL]
- [ ] Rule order: whitelist first (allow known legitimate crawlers), then blacklist (list only specific tool names, no wildcards); robots blocks likewise list specific tool names. [REAL]
- [ ] robots and llms.txt align with real routes: assets for AI are dynamically generated with a sane revalidate; no stale descriptions misleading AI after features are retired. [REAL]
- [ ] Anti-bot vs experience balance: tiered rate limiting, leave a door for legitimate crawlers, degrade without blocking indexing, do not hurt visitors. [REAL]
- [ ] Do not self-call your own HTTP endpoints for stats in middleware / the request chain — it slows every crawler request by seconds, dropping crawl frequency. [REAL]
- [ ] When blocking specific malicious UAs, keep a revert switch so you can recover quickly after false positives. [DERIVED]

## E. Post-Change Verification

- [ ] Sample-test old URLs' redirect chains (status code + landing point correct). [REAL]
- [ ] New URLs tested to return 200 with complete content; logs confirm crawlers (search engines + AI crawlers) are still fetching normally. [REAL]

## F. Wrap-Up

- [ ] URL changes sync-update every on-site entry point: navigation, breadcrumbs, footer, admin links — old URLs should appear only in the redirect table. [REAL]
- [ ] Retiring a feature also clears its data residue and stale docs; stale docs are worse than no docs. [REAL]
- [ ] Archive this change's URL mapping table (old → new) for later troubleshooting and webmaster-platform reconciliation. [REAL]
- [ ] Confirm robots and llms.txt's actual response content matches the post-change routes (read the live real response, do not trust local files). [REAL]
