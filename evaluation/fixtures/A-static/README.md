# Northwind Docs (static site)

A small documentation site built with plain HTML, deployed to a static host.

## Run locally
```bash
cd public && python -m http.server 8080
```

## Deploy
Static host serves `public/` as web root. Rewrites are configured in `netlify/redirects`.
