# Corner Store — storefront

Legacy storefront, in production since 2021. Node 18, no framework.

## Layout
```
src/
  server.js        HTTP entry
  routes/          one file per area
  lib/             helpers, shared state
  jobs/            scheduled work
public/            static assets
deploy/            ops scripts
```

## Running
```bash
node src/server.js          # http://localhost:4010
node src/jobs/cleanup.js    # nightly job
```

## Notes
- Product catalogue is read from `data/catalog.json` (edited by ops, deployed with the app).
- Orders live in `data/orders.json` (runtime-written, never deployed).
- `deploy/README.md` describes the release process.
