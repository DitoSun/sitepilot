# Membership Ledger

Tracks member records. Two stores exist because of a migration that never finished.

## Layout
```
data/
  members.json            primary store (app writes here)
  members.legacy.json     old store, exported 2025-03, read-only now
  cache/
    members.index.json    generated lookup cache, rebuilt on boot
backup/
  members-2026-09-01.json snapshot taken before a schema change
src/
  store.js                read/write helpers
  index.js                small HTTP surface
  rebuild-cache.js        regenerates cache/members.index.json
```

## Notes
- `members.json` is authoritative. The legacy file was imported once and kept
  "just in case".
- The cache is derived. If it disagrees with the store, rebuild it.
