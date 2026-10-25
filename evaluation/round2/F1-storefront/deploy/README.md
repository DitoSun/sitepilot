# Release process

1. `node build.js` — copies `public/` to `dist/` and rewrites asset paths.
2. `rsync -a dist/ /srv/cornerstore/public/`
3. `systemctl reload cornerstore`

The app itself is deployed separately by `deploy/release.sh`, which pulls the
repo and restarts the service.
