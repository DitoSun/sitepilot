# Content Operations — SitePilot Reference

> **Solves:** how to run content as production data — lifecycle, deletion
> discipline, imports, and the operating loop that keeps a site's operations
> honest. Load with the SKILL.md §4 change workflow.

## 1. Content is production data [REAL]

Editorial content (pages, posts, entries, metadata) is not "just files" —
changing it is a data change. Apply the same discipline as any data file:
backup before risky edits, semantic verification after publish, and a change
log entry.

## 2. Content lifecycle [DERIVED]

```
CREATE → EDIT → PUBLISH → VERIFY → UPDATE → ARCHIVE → DELETE
```

| Stage | Discipline |
|---|---|
| CREATE / EDIT | Draft ≠ live; know which environment you are editing |
| PUBLISH | Activate through the project's real mechanism |
| VERIFY | Visit the real production page; check expected content, not just HTTP 200 (SKILL.md §8) |
| UPDATE | Corrections are changes too — log them |
| ARCHIVE | Prefer archive over delete for anything with inbound links or history |
| DELETE | The most dangerous stage — see §3 |

## 3. Before deleting public content [DERIVED / REAL]

Deleting a public page is rarely just "removing content":

| Consideration | Why |
|---|---|
| SEO weight | The URL may hold accumulated search weight — 301 it, don't 404 it (see `seo.md`) |
| Inbound links | External sites may link to it; a 404 wastes that equity |
| User collections | Users may have bookmarked / favorited the content — deletion breaks their data silently |
| Redirect target | Decide where the URL should point (usually the parent / section) |
| Historical value | Outdated but still true? Prefer update / archive over delete |

**Deletion mechanics (real lessons):**

| Trap | Real consequence | Rule |
|---|---|---|
| A "delete by ID" whose condition actually matched a whole batch | One action removed an entire batch of records | Deletion conditions must be exact (single item), or force an explicit bulk confirmation |
| Deleting without preview | Blast radius unknown | Run an equivalent SELECT first to preview the exact affected set (EXP-020) |
| Destructive admin actions with no confirmation | Accidental clicks became data loss | All destructive admin operations require a confirmation step (EXP-019) |

## 4. Third-party data import [REAL]

Importing from external sources produced three inconsistent versions of one
table (spreadsheet vs. old export vs. live data) (EXP-096).

| Rule | Detail |
|---|---|
| Multi-source comparison | Before import, compare every available source and reconcile |
| Declare the authority | Explicitly state which source wins, and record that decision |
| Duplicate rules | Predefine how conflicts / duplicates resolve (e.g. keep the entry with the strongest metric) |
| Import = data change | Backup + verify counts after import; never import straight into production without preview |

## 5. The operating loop: four steps [REAL]

A working small-site operations loop (EXP-091):

```
idea pool → todo → change log → data review
```

| Step | Discipline |
|---|---|
| Idea pool | Every idea gets captured; nothing lives only in someone's head |
| Todo | Priorities and owners; the pool becomes a plan |
| Change log | Every change recorded with timestamp |
| Data review | Periodically check outcomes — the loop only closes if conclusions are drawn |

## 6. The change log records "why", not just "what" [REAL]

A real change log kept dozens of timeline entries, each with what changed
**and why** — including product decisions in the owner's own words (EXP-092).

| Rule | Detail |
|---|---|
| Why > what | "Changed X" is reconstructable from git; "why we chose X" is not |
| Decisions get recorded | Product / priority decisions are written down to prevent re-litigating the same question |
| Timeline | Timestamps make the log usable as an incident timeline |

## 7. Operational configuration hot-reloads [REAL]

Operational parameters (moderation word lists, quota thresholds) shipped as
code changes: each tuning round meant a redeploy; a word list was expanded
several times in a single day (EXP-098/102).

| Rule | Detail |
|---|---|
| Hot-update operational config | Word lists, thresholds, quotas live in reloadable config / data, not code |
| Decouple from releases | Operational tuning must not wait for a deploy cycle |
| Audit the changes | Hot config still gets change-logged — hot ≠ untracked |

---

## Counters and stats: dedup from day one [REAL]

Counters (views, copies, likes) designed without deduplication get polluted
the moment they ship; backfilling dedup later leaves historical values
untrustworthy forever. Design the dedup rule (per-user? per-IP+item?) before
the first counter ships, and treat historical numbers as approximations
unless provenance exists. (EXP-100)

## AI/LLM-powered site features [REAL]

If the site itself exposes an LLM feature (assistant, search, generation),
three lessons from production:

| Lesson | Practice |
|---|---|
| Input normalization | Domain terms the model does not know (product codes, nicknames, internal names) must be mapped to canonical forms *before* the model sees them; a missing alias table produces confident, wrong answers |
| Knowledge injection order | Inject the most relevant/most-used items first; cap per-entity counts so the long tail is not truncated away |
| Context budget | Compress or truncate long conversations deliberately (e.g. summarize turns beyond N) to control cost and latency |

(EXP-105, EXP-106)

## External data imports need validation [REAL]

Third-party files (xlsx/csv exports) are frequently malformed in ways parsers
silently accept — an unclosed quote in a preamble can make a CSV reader swallow
rows and drop an entire column. After any import: verify row/column counts
against the source, spot-check values, and declare which source is
authoritative when copies disagree. (EXP-109)

## Agent Quick Check

1. Content change treated as a data change: backup (if risky) + production semantic verify after publish?
2. Deleting public content? SEO redirect, inbound links, user collections, redirect target, and historical value all considered; deletion conditions exact or bulk-confirmed; equivalent SELECT preview run.
3. Import from third parties? Multi-source comparison done, authority declared, duplicate rule predefined, counts verified after.
4. Operating loop running: idea pool → todo → change log → data review?
5. Change log entries carry the "why"; operational config (word lists, thresholds) hot-updatable and still change-logged?
