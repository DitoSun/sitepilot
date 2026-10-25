# Ops Dashboard

Internal dashboard. Vite build, served as static files behind nginx.

## Build & deploy
```bash
npm ci
npm run build      # -> dist/
./deploy/sync.sh   # rsync dist/ to the server
```

## Config
Runtime config is injected at container start from `deploy/runtime.env`.
The build reads `VITE_API_BASE` at **build** time.
