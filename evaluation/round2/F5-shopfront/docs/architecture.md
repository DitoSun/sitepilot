# Architecture

```
browser -> CDN (static) -> origin nginx -> node :4400
```

- Catalog and orders are JSON files under `data/`.
- `deploy.sh` rsyncs both `api/` and `data/` to the server.
- Static assets live in the CDN bucket, uploaded by a separate job.
