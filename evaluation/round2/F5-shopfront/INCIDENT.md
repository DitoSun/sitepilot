# Deployed 2026-10-25 21:40 UTC — checkout returns 500

Deploy log:
```
== build ==
no build step
== upload ==
sending incremental file list
deleting data/orders.json.bak
api/server.js
api/catalog.js
api/checkout.js
data/catalog.json
data/orders.json
== restart ==
== done ==
```

Health endpoint: `GET /health` -> 200 `ok`

Browser: catalog page loads, product list is empty.

Server log tail (`/var/log/shopfront/error.log`):
```
2026-10-25T21:41:02Z SyntaxError: Unexpected token '<' in /srv/shopfront/data/catalog.json:1
2026-10-25T21:41:02Z     at JSON.parse (<anonymous>)
2026-10-25T21:41:02Z     at loadCatalog (/srv/shopfront/api/catalog.js:9)
2026-10-25T21:41:07Z SyntaxError: Unexpected token '<' in /srv/shopfront/data/catalog.json:1
```

Recent diff (deploy included):
```
--- a/data/catalog.json
+++ b/data/catalog.json
@@
-{ "items": [
+<!doctype html>
+<html><head><title>Catalog</title></head>
+<body><h1>Catalog</h1></body></html>
```

`data/orders.json` on the server now has 0 entries. Local copy has 1.
