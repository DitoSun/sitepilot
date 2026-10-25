# Recipe: Node + JSON File Store

## WHEN TO USE

`package.json` is a Node project with no database, using files like `data/*.json` as
persistent storage (common in small sites, personal projects, MVPs).

## ASSUMPTIONS

- Single machine or a few machines; no real store with merge semantics (SQLite/Redis, etc.)
  introduced.
- Data files may be touched concurrently by the application runtime and scripts on multiple
  machines.
- Data files are within version control or carried by the deployment pipeline.

## COMMON FAILURE MODES

1. **Multi-writer divergence**: local, server, and backup copies of JSON each evolve separately
   — every machine becomes a data source; git-style sync inevitably conflicts, ending in manual
   merges that are easy to get wrong. Root cause: no declared "which copy is authoritative".
   [REAL]
2. **Non-atomic write race causing intermittent failures**: overwriting directly with
   `writeFileSync`, reading a half-written file → parse failure → intermittent 404/500.
   Intermittent failures are most easily misdiagnosed as "network problems". [REAL]
3. **Read-modify-write lost updates**: two concurrent requests read, each modifies, each
   writes; the later overwrites the earlier, one update vanishes. [REAL]
4. **Synchronous blocking in the request path**: running git/external commands with `execSync`
   in write endpoints, users "editing a profile card takes forever". Synchronous blocking is
   forbidden in the request path. [REAL]
5. **No guardrails on bulk writes**: scripts corrupt data, over-broad conditions delete by
   mistake — counts plummet, data quality degrades, recovered afterwards via git (the recovery
   itself is an incident signal). [REAL]

## SAFE WORKFLOW

1. **Single-writer principle**: only the server (production runtime) writes data files; local
   is read-only; backups pull but never write. Multi-writer JSON + sync = guaranteed
   divergence. [REAL]
2. **Atomic writes**: write `.tmp` first, then `rename` to the target file — rename is atomic
   on the same filesystem, readers always see a complete file. [REAL]
3. **Mutex queue to serialize writes**: a single process queues writes, solving
   read-modify-write lost updates. **Queues must not nest (deadlock)** — write the "why" and
   this ban into the file header comment. Reads may be slightly stale. [REAL]
4. **Pre-write snapshots**: archive the old version before every write (e.g. keep N copies per
   file), with a restore tool. New write points easily miss the snapshot — grep every write
   point to confirm. [REAL]
5. **Sanity check**: validate before destructive/bulk writes — e.g. refuse the write and alert
   when counts drop past a threshold. Better a false refusal than silent corruption. [REAL]
6. **Declare the authoritative copy** in docs: "only the server's data/ is authoritative, local
   copies are stale snapshots, experiments touch local only". [REAL]
7. **Separate data from code in deployment**: the package must not mix in data files (abort if
   data/ is found), plus a data sync health-check tool (per-file comparison, verdict by exit
   code). [REAL]
8. **Bulk data changes get their own commit**, stating the data source; keep serialization
   format and sort keys stable, avoiding one reformat producing a thousands-line giant diff.
   [REAL]
9. **Version control is the last line of defense**: data files in git is fine, but runtime code
   never auto-commits+pushes (core SKILL iron law: runtime data must never flow through Git).
   [REAL]

## VERIFICATION

- **Re-verify a while after** writes (against race overwrites — right-after-write
  correct-then-overwritten cases do exist). [REAL]
- Compare counts, key fields, modification times; not just "no errors".
- Check the snapshot directory actually gained pre-write archives.
- Compare local and server per file (sync health-check tool), confirm no divergence.

## ROLLBACK

- Restore the pre-write state from pre-write snapshots (seconds, lossless semantics).
- When snapshots are missing/stale, git history is the last line of defense — but "recovering
  data via git" is itself an incident signal: the snapshot guardrail has a missed write point;
  fix the guardrail, not just the data. [REAL]
- After recovery, run the sync health check to confirm all copies agree again.

## LESSONS LEARNED

- Three fatal weaknesses of JSON file storage: multi-writer, non-atomic writes, unguarded bulk
  writes — countered by single-writer, tmp+rename, and sanity check respectively.
- "Which copy is authoritative" must be declared explicitly and written into docs;
  local/server/backup copies evolving separately is the most expensive tuition on this road.
- Restore drills matter equally — a restore tool that has never run is no restore tool. See
  `references/backup-recovery.md`.
