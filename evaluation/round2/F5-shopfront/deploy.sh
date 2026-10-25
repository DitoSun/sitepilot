#!/usr/bin/env bash
set -e
echo "== build =="
node -e "console.log('no build step')"
echo "== upload =="
rsync -az --delete api/ data/ server:/srv/shopfront/
echo "== restart =="
ssh server 'systemctl restart shopfront'
echo "== done =="
