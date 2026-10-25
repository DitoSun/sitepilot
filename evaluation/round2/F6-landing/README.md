# Product landing page

Static marketing site + a tiny lead-capture endpoint.

## Structure
```
site/            static pages, deployed to the CDN bucket
functions/       lead capture (serverless)
scripts/         build + publish helpers
content/         page copy in JSON, rendered at build time
```

## Build and publish
```bash
node scripts/build.js
node scripts/publish.js
```

Publishing syncs `dist/` to the bucket that serves the live domain.
