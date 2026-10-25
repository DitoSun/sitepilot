# Orders API

Minimal read API over a JSON dataset.

## Run
```bash
node src/server.js
```
Then: `curl http://localhost:3001/api/orders`

## Config
`PAGE_SIZE` (default 20) controls how many orders the list endpoint returns.
