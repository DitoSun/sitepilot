#!/bin/sh
# Substitute __ENV__ placeholders in index.html at container start.
set -e
envsubst '${API_BASE} ${REFRESH_MS} ${DASHBOARD_TITLE}'   < /usr/share/nginx/html/index.html   > /usr/share/nginx/html/index.html.tmp
mv /usr/share/nginx/html/index.html.tmp /usr/share/nginx/html/index.html
exec nginx -g 'daemon off;'
