#!/usr/bin/env bash
set -euo pipefail
: "${TARGET:?set TARGET=user@host:/srv/dashboard}"
rsync -az --delete dist/ "$TARGET"
echo "synced to $TARGET"
