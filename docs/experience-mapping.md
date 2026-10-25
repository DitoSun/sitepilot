# Experience Mapping — Lessons → Skill Components

SitePilot's rules are not invented advice. They are distilled from **111
deduplicated lessons** mined from a real production website's incident
history (git history, an operations handover document, code and config traces,
and a personal operations knowledge base), then generalized and classified.

Lesson IDs (`EXP-001` … `EXP-111`) are stable references used across the
project. The table below shows where each lesson lives in the skill. Private
evidence (commit hashes, file paths, project details) is deliberately excluded
from this public repository — **lessons, not secrets**.

Legend: **S** = SKILL.md rule · **R** = reference · **C** = checklist ·
**P** = playbook · **RC** = recipe · **E** = example · **A** = automation.

| Lesson | Domain | Implemented in |
|---|---|---|
| EXP-001 | Runtime data must never flow through Git | S §3.6, R security, C pre-deploy, RC node-json-store |
| EXP-002 | Hardcoded credential fallbacks | R security, C pre-deploy |
| EXP-003 | `.gitignore` does not protect tracked files | C pre-deploy, R security |
| EXP-004 | Forgotten credential surfaces (git config, cron, old scripts) | R security, C pre-deploy, R deployment |
| EXP-005 | Fallback secrets are no secrets | R security |
| EXP-006 | Backups contain env/user data — keep out of git | R backup-recovery |
| EXP-007 | Server-side leftovers defeat local fixes | R deployment, C pre-deploy, P bad-deployment |
| EXP-008 | Verify history rewrites actually removed data | R security |
| EXP-009 | Rotate credentials only after the new value has a home | R security |
| EXP-010 | Multi-writer data files diverge | R database-safety, RC node-json-store |
| EXP-011 | Non-atomic writes cause intermittent failures | R database-safety, RC node-json-store |
| EXP-012 | Read-modify-write races need serialization | R database-safety, RC node-json-store |
| EXP-013 | Sanity checks before destructive writes | R database-safety, C database-change |
| EXP-014 | Snapshot-before-write at the write layer | R database-safety, R backup-recovery |
| EXP-015 | Split data/code deploys need a sync checker | R deployment, R database-safety, C pre-deploy |
| EXP-016 | The live copy is authoritative | S §6, R database-safety, C database-change |
| EXP-017 | Stable serialization avoids giant diffs | RC node-json-store |
| EXP-018 | Data corruption recovered from VCS is still an incident | R database-safety, P database-incident |
| EXP-019 | Destructive admin actions need confirmation | R content-operations |
| EXP-020 | Wide-condition deletes delete batches | R database-safety, C database-change, P database-incident |
| EXP-021 | Redundant snapshots drift from truth | R database-safety, RC node-json-store |
| EXP-022 | Static pre-rendering freezes runtime data | RC nextjs-selfhost |
| EXP-023 | Build windows cause outages → atomic deploys | R deployment, RC cloud-vps-deploy, C pre-deploy |
| EXP-024 | Single-instance restarts have an inherent downtime window | R deployment, RC pm2 |
| EXP-025 | "Change didn't take effect" may be the cache | R production-verification, R troubleshooting |
| EXP-026 | File transfers fail silently → verify checksums | R deployment |
| EXP-027 | Clean the workspace before building | R deployment, C pre-deploy |
| EXP-028 | Deleted routes leave stale type artifacts | RC nextjs-selfhost |
| EXP-029 | Post-deploy errors may be stale clients | R troubleshooting, RC nextjs-selfhost, P http-500-errors |
| EXP-030 | Reverse sync needs byte-level evidence | R deployment |
| EXP-031 | Security fixes die without a migration plan | R security, R change-management |
| EXP-032 | Confirm which copy is authoritative before syncing | S §6, R change-management |
| EXP-033 | Probes must look like real clients | RC cloud-vps-deploy |
| EXP-034 | Deploy scripts hard-code environments | R deployment, RC cloud-vps-deploy |
| EXP-035 | Deploy channels need a Plan B | RC cloud-vps-deploy |
| EXP-036 | Locate the failing layer before changing the system | S §4, R troubleshooting, P website-down |
| EXP-037 | "Stuck" ≠ "slow API" — measure end-to-end | R troubleshooting, R performance, P performance-incident |
| EXP-038 | Soft degradation is worse than an error | S §3.9, R production-verification, C post-deploy, P http-500-errors |
| EXP-039 | Comments lie — verify with real runs | R troubleshooting, R change-management |
| EXP-040 | Align the timeline before debugging | R troubleshooting, P http-500-errors |
| EXP-041 | Fix one instance, scan the class | S §3.10, R troubleshooting |
| EXP-042 | Same pitfall twice → make it a rule | S §9, R experience-loop §9 |
| EXP-043 | Data/code name mismatches fail silently | R troubleshooting, R content-operations |
| EXP-044 | Substring search on random strings is a lottery | R troubleshooting |
| EXP-045 | "No effect" may be a stale process/port | R troubleshooting, P website-down |
| EXP-046 | Noise errors mask real problems | R monitoring |
| EXP-047 | External dependencies need fallbacks and honest degradation | R troubleshooting, R monitoring |
| EXP-048 | Server identity comes from server sessions only | S §3, R security, R ai-agent-safety |
| EXP-049 | UGC endpoints are writes — authenticate them | R security |
| EXP-050 | Security and no-relogin cannot both win | R security |
| EXP-051 | Secret rotation invalidates tokens — plan for it | R security |
| EXP-052 | Client-IP extraction must be aligned across layers | R security, RC nginx |
| EXP-053 | Lockouts must be per-account/per-IP | R security |
| EXP-054 | Check callers before adding auth | R security |
| EXP-055 | Dual trust levels need explicit boundaries | R security |
| EXP-056 | Normalization must be symmetric | R security |
| EXP-057 | Verification codes need real randomness | R security |
| EXP-058 | File-backed sessions have no persistence promise | R security, R database-safety |
| EXP-059 | Unbounded lists starve connections | R performance, P performance-incident |
| EXP-060 | Measure the bottleneck before optimizing | R performance, RC cloud-vps-deploy |
| EXP-061 | Compression must cover real content types | R performance, RC nextjs-selfhost, RC nginx |
| EXP-062 | Disable image optimization before it blocks the business | RC nextjs-selfhost |
| EXP-063 | No synchronous blocking in request paths | R performance, RC node-json-store |
| EXP-064 | Internal APIs need field selection too | R performance |
| EXP-065 | Validate boundaries against real data | R performance |
| EXP-066 | High-frequency polling needs its own rate bucket | R security, RC nextjs-selfhost |
| EXP-067 | Public URLs are long-term contracts | S §3, R seo, C seo-change |
| EXP-068 | Fake sitemap metadata is worse than none | R seo, C seo-change |
| EXP-069 | Scheduled tasks must verify business semantics | R seo, R production-verification |
| EXP-070 | Never blacklist crawlers with generic patterns | R seo, C seo-change |
| EXP-071 | Middleware must not call its own HTTP endpoints | R seo, R performance |
| EXP-072 | Route params are not auto-decoded everywhere | RC nextjs-selfhost |
| EXP-073 | ID/URL rule changes need permanent redirects | R seo, RC nextjs-selfhost |
| EXP-074 | AI-facing assets must be generated from truth | R seo |
| EXP-075 | One encoding rule across the whole sitemap | R seo, C seo-change |
| EXP-076 | Access logs precede all monitoring | R monitoring, RC nginx |
| EXP-077 | 301 only for permanent moves | R seo, C seo-change |
| EXP-078 | Active sitemap submission is the cheapest SEO action | R seo |
| EXP-079 | Anti-scrape and SEO must be balanced | R seo, R security |
| EXP-080 | Restart counts are a stability signal | R monitoring, RC pm2 |
| EXP-081 | Lightweight three-layer monitoring for small sites | R monitoring |
| EXP-082 | Silently failing monitors are worse than none | R monitoring |
| EXP-083 | Retention policies need disk-headroom monitoring | R monitoring, R backup-recovery |
| EXP-084 | Two-level backups: change rollback + disaster snapshot | R backup-recovery |
| EXP-085 | Back up only what cannot be regenerated | R backup-recovery |
| EXP-086 | Verify exclusion patterns actually match | R backup-recovery |
| EXP-087 | Backups need three-way verification | R backup-recovery, C pre-deploy |
| EXP-088 | Backups must leave the server | R backup-recovery |
| EXP-089 | An unrestored backup is not a backup | R backup-recovery, C pre-deploy |
| EXP-090 | Smallest safe change | S §3.3, R change-management |
| EXP-091 | A closed operations loop: ideas → todos → changelog → review | R content-operations |
| EXP-092 | Change logs record why, not just what | R change-management, R content-operations |
| EXP-093 | Commit discipline: never `git add -A` | C pre-deploy, R change-management |
| EXP-094 | Informless auto-commits destroy the incident timeline | R change-management |
| EXP-095 | Incident comments prevent repeat mistakes | R change-management, R experience-loop |
| EXP-096 | Multi-source data imports need an authority declaration | R content-operations, C database-change |
| EXP-097 | Decommissioned features leave data and doc residue | R change-management |
| EXP-098 | Operational config must update without redeploys | R change-management, R content-operations |
| EXP-099 | Anti-scraping is graded, not absolute | R security, R seo |
| EXP-100 | Counters need dedup from day one | R content-operations |
| EXP-101 | UI-level copy protection is not a security boundary | R security |
| EXP-102 | Moderation word lists are a continuous operations item | R content-operations, R change-management |
| EXP-103 | Browser API fallbacks ship in v1 | RC windows-dev-environment |
| EXP-104 | Quota thresholds are tunable operations parameters | R security, R content-operations |
| EXP-105 | LLM features need input normalization | R content-operations |
| EXP-106 | LLM features need injection order + context budget | R content-operations |
| EXP-107 | Non-ASCII paths break shell arguments intermittently | RC windows-dev-environment |
| EXP-108 | Text vs binary checksums use different rules | R deployment, RC windows-dev-environment |
| EXP-109 | External imports need structural validation | R content-operations |
| EXP-110 | Local verification must not touch production data | R production-verification, C database-change |
| EXP-111 | Periodic full-site sweeps catch site-wide noise | R monitoring, A site-health-check.sh |

## Coverage summary

| Metric | Count |
|---|---|
| Lessons mined (deduplicated) | 111 |
| Mapped to at least one skill component | 111 (100%) |
| Universal (A) lessons driving core rules | 60 |
| Broadly-applicable (B) lessons in references | 38 |
| Stack-specific (C) lessons in recipes | 13 |
| Project-specific (D) lessons excluded from public core | 5 |
| Automated as read-only checks | 1 script covering EXP-111 + transport-level EXP-025/038/067/076 signals |

The full evidence-level audit (source commits, notes, and file traces per
lesson) is maintained privately by the project owner and is intentionally not
published — see `references/security.md` on why.
