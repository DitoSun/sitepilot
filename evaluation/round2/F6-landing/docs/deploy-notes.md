# Deploy notes

- Static site: `node scripts/build.js && node scripts/publish.js`
- Functions: deployed by CI on push to `main`
- `.env` holds local overrides only; production values come from the platform.
