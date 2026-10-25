#!/usr/bin/env bash
# Deploy the app.
set -e
cd /srv/cornerstore/app
git pull origin main
npm ci --omit=dev
systemctl restart cornerstore
echo "released"
