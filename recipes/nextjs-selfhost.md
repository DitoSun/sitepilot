# Recipe: Next.js Self-Hosting (App Router)

## WHEN TO USE

`package.json` shows Next.js (App Router) on a self-managed server (VPS/bare metal), usually
behind an nginx reverse proxy and pm2. Build output `.next/` is built on the server or
locally then synced.

## ASSUMPTIONS

- App Router (not Pages Router), using the `app/` directory.
- Self-hosted (`next start` or a custom server), not a managed platform like Vercel.
- The site has endpoints reading runtime data (user data, config, logs).

## COMMON FAILURE MODES

1. **GET routes without request parameters get statically pre-rendered at build time**: run
   once at build, runtime data frozen into `.next`; the endpoint then always returns build-time
   data with a 200 — a classic silent failure. [REAL] Routes reading runtime data must set
   `export const dynamic = 'force-dynamic'`, with "**do not delete**" and the reason in a
   comment (deleting it throws no error; it silently freezes).
2. **TS2307 build errors after deleting routes**: `.next/types/` keeps type artifacts of
   deleted routes. Deleting an `app/` route directory requires cleaning the matching
   `.next/types/` artifacts in the same step; hit twice in one project — the cleanup checklist
   must include framework artifact directories. [REAL]
3. **Logs flooded with Server Action errors after redeploy**: usually old-tab clients calling
   dead action IDs — old-client noise, not a new-code bug. Rule: **log mtime vs restart time**
   — errors predate the restart. Changing code without aligning the timeline is chasing ghosts.
   [REAL]
4. **RSC prefetch payload compression often misconfigured**: App Router prefetching goes over
   `text/x-component` (RSC Payload); nginx gzipping only `text/html` sends prefetches
   uncompressed, and prefetch volume can differ by an order of magnitude — the invisible main
   cause of "clicking navigation takes seconds". Compression must cover actual content types.
   [REAL]
5. **params is not auto URL-decoded in page/layout, but route handlers decode**: same version,
   two entry points, inconsistent behavior. IDs with Chinese/special characters arrive encoded
   in page/layout; detail pages silently 404. Pages with Chinese IDs must be tested for real.
   [REAL]
6. **Single-machine Image Optimization easily breaks**: on a VPS the `/ _next/image` chain
   (sharp dependency, memory, timeouts) fails as broken avatar loads. When business is blocked,
   first set `images.unoptimized` to stay available, then fix the chain separately. [REAL]
7. **Deploy-time probes blocked by your own middleware**: background health probes carry no
   browser UA and get 403 from the site's own anti-scraping/security middleware, misdiagnosed
   as deploy failure. Probes must carry real client traits (UA), or you test against your own
   defenses. [REAL]

## SAFE WORKFLOW

1. Clear the field before building: stop dev server and old processes — dev and build both
   write `.next/`, producing phantom errors; a successful build means exit code 0. [REAL]
2. Confirm `force-dynamic` on every runtime-data route (first thing when adding routes).
3. Deleting a route = delete directory + delete `.next/types/` artifacts — both steps together.
4. Build into a new directory, verify, switch atomically; do not `mv .next && build` in place
   (site down during build).
5. After deploying, hard-refresh first to rule out client cache before judging "did the change
   take effect". [REAL]
6. nginx compression covers `text/html`, RSC payload types, `application/xml`, and other actual
   types.
7. Probes carry a browser UA; production semantic verification covers key page content, API
   data, auth state, detail pages with Chinese IDs.

## VERIFICATION

Semantic verification, not status codes:

- Key pages contain expected content (after hard refresh), not just 200.
- Dynamic endpoints return **current** runtime data (change one record, the endpoint reflects
  it), not a build-time snapshot.
- Prefetch volume reasonable (DevTools Network: RSC request transfer size).
- Pages with Chinese/special-character IDs open, no silent 404s.
- Images load normally (if the optimization chain is on).
- No large-scale new errors in logs — align mtime first to rule out old-tab noise before
  concluding.

## ROLLBACK

- Keep the old `.next/` before deploying (separate directory); switch back in seconds +
  restart on failure.
- Verify semantics after switching back — rollback is also a change.
- If data files are forward-compatible (fields only added), the rollback point is mainly the
  code.

## LESSONS LEARNED

- "200 but stale data" and "silent 404" are the two silent-failure shapes of self-hosted App
  Router; see core SKILL §8: verify semantics, not only transport success.
- Framework-version-specific behavior (params decoding, pre-rendering) **must be tested, never
  assumed**; entry points in the same version may differ.
- After a deploy, align error timelines first (mtime vs restart time); old-client noise is not
  a new bug — see `references/troubleshooting.md`.