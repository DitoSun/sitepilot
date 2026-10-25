# Recipe: nginx Reverse Proxy

## WHEN TO USE

nginx reverse-proxies to an application port (Node/Python/PHP, etc.); it terminates TLS,
compresses, forwards, and logs in front of the app. The most common entry layer for self-hosted
sites.

## ASSUMPTIONS

- nginx faces clients directly (no CDN/WAF in front, or its impact is considered).
- The app needs the real client IP (rate limiting, anti-abuse, audit, login risk control).
- The site has SEO/crawler needs (logs and compression affect them).

## COMMON FAILURE MODES

1. **Real IP misaligned across layers**: code takes the first XFF segment while nginx leaves the
   forged client value leftmost → clients fill their own IPs; rate limiting is worthless. Correct
   rule: **two-layer alignment** — nginx overwrites `x-real-ip` with `remote_addr` (unforgeable);
   the app falls back to the last XFF segment (closest, trusted-proxy written). First segment =
   clients fill their own IPs. Put the rule in comments; unify globally. [REAL]
2. **access_log not enabled**: the vhost's 443 block misses access_log; the file sits at 0 bytes
   for months — crawler behavior, failure timelines, rate-limit effectiveness all un-auditable.
   **First thing on serving: confirm logs are being written** — server logs precede all
   monitoring. [REAL]
3. **Compression configured for text/html only**: actual content types (RSC payloads, xml, js/css,
   json) go uncovered; prefetches and API responses travel uncompressed; load speed differs by an
   order of magnitude. Check actual content types, not impressions. [REAL]
4. **Certificate and redirect omissions**: missing HTTP→HTTPS redirect or a redirect loop;
   incomplete certificate chain; no expiry ledger. Certificates and redirects need a ledger and
   expiry monitoring. [DERIVED]

## SAFE WORKFLOW

1. Validate with `nginx -t` before changing config — a syntax error reloaded directly takes the
   site to 502.
2. Back up old config for seconds-level restore (e.g. a timestamped copy).
3. Minimize changes: one at a time, reload immediately + semantic verification after each.
4. Real IP chain: `remote_addr` → `x-real-ip` (overwrite, never trust the client's value); the app
   takes `x-real-ip`, falling back to the last XFF segment. Write the two-layer rule into
   comments.
5. Logs: confirm the access_log path exists and is being written; configure logrotate against a
   full disk.
6. Compression: configure against actual response content types (check `content-type` with curl):
   html / RSC payload types / xml / js / css / json.
7. Probes carry real client characteristics (UA), or the app's own middleware may block them.

## VERIFICATION

Check item by item with curl (mandatory after changes):

- Headers: compression active (`content-encoding`), cache headers, security headers as expected.
- Redirects: HTTP→HTTPS correct; no loops; retired pages 301 to the parent instead of 404.
- Compression: confirm on actual content types (not only homepage html).
- Real IP passthrough: the IP the app sees matches the test client, **not** the forged value when
  a forged XFF header is sent.
- access_log is growing, counts matching request volume.

## ROLLBACK

- Restore the old config → `nginx -t` → `reload` (not `restart`, which drops all connections).
- Re-run the curl verification after rollback — rollback is also a change.
- If the old config is also uncertain, prepare a "minimal working config" (reverse proxy + basic
  logs).

## LESSONS LEARNED

- nginx is "the single point of the entry layer": config errors hit security (IP forgery),
  performance (compression), and observability (logging) at once, none throwing errors.
- "Two-layer alignment" is a universal pattern: identity/address info on any proxy chain must
  state per layer "whom to trust, whom to overwrite" — never assume the upstream handles it.
- See the reverse-proxy layer of core SKILL §10, plus `references/security.md` (IP rules) and
  `references/monitoring.md` (logs precede monitoring).