#!/usr/bin/env bash
# Publish dist/ to the web root.
set -e
WEBROOT="${WEBROOT:-/var/www/acme}"
mkdir -p "$WEBROOT"
cp -r dist/* "$WEBROOT"/
echo "published to $WEBROOT"
