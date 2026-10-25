# Performance — SitePilot Reference

> **Solves:** diagnosing "the site is slow" by layer, measuring the real
> bottleneck before optimizing, and avoiding the classic traps (unpaginated
> lists, uncompressed payloads, blocking request paths). Load with
> `playbooks/performance-incident.md`.

## 1. Locate the layer before optimizing [DERIVED]

"Slow" is a symptom, not a diagnosis. Never assume it is the frontend.
Real lesson: an admin panel that "hung" was reported as "the API is slow" —
the API answered in milliseconds; the page rendered thousands of images at
once and starved its own connections (EXP-037, L6). Measure end-to-end before
guessing.

| Layer | Typical question | Evidence |
|---|---|---|
| CLIENT | Rendering, request count, cache, old tabs | DevTools; hard-refresh first |
| NETWORK | Bandwidth, latency, connection limits | Host egress stats; curl timing breakdown |
| CDN | Cache hit ratio, edge compression | CDN dashboard / response headers |
| SERVER | CPU, memory, disk, process/port state | Host metrics; process inspection |
| APPLICATION | Code path, blocking calls, payload size | App logs; profiling |
| DATABASE / DATA | Query cost, file size, consistency | Query timing; data-file stats |
| EXTERNAL | Upstream APIs, mail, third parties | Timeout logs; dependency checks |

## 2. Measure the bottleneck first [REAL]

A constrained host with Mbps-class egress bandwidth and near-idle CPU: the
bandwidth was the hard ceiling — shrinking bytes mattered, a CPU upgrade would
not have (EXP-060).

| Rule | Detail |
|---|---|
| Bottleneck decides the fix | Bandwidth-bound → shrink bytes. CPU-bound → cheaper code. Connection-bound → fewer requests. |
| Watch the small machine | On constrained hosts, build artifacts and logs accumulate — disk and memory are part of performance |

## 3. Large lists: pagination + lazy loading [REAL]

An admin page rendered thousands of users (thousands of `<img>` requests) in
one shot: HTTP/1.1's six-connections-per-domain limit starved the page; the
underlying API answered in milliseconds and was innocent (EXP-037/059).

| Rule | Detail |
|---|---|
| Paginate big lists | Page in the low hundreds of rows + "load more"; never render the full table |
| Lazy-load media | `loading="lazy"` on below-the-fold images |
| Count the requests | When a page "hangs", count concurrent requests before blaming the API |
| curl the API directly | Server timing first, client second — one layer at a time |

## 4. Compression must cover the content types you actually serve [REAL]

gzip configured for HTML only; the framework's RSC prefetch payload and the
XML sitemap streamed uncompressed — one route's payload was ~14× larger than
its compressed size, and navigation prefetches were multiples oversized. That
was the real cause of "clicking navigation takes seconds" (EXP-061).

| Rule | Detail |
|---|---|
| Audit real content types | List what the server actually returns (HTML, RSC payloads, JSON, XML…) and verify each is compressed |
| Verify with real transfers | Compare transferred sizes before/after; a config that misses the dominant type is not compression |
| Framework-specific | App-Router-style sites: verify RSC prefetch payloads explicitly |

## 5. No synchronous blocking on the request path [REAL]

A write endpoint ran a synchronous external command inline (multi-second
timeout): "editing a profile card took forever" (EXP-063).

| Rule | Detail |
|---|---|
| No synchronous external commands | No execSync-style git / shell / slow-IO inside request handling |
| Async or queue | Move slow work off the request path entirely |

## 6. Internal APIs: trim to the fields you need [REAL]

An admin screen pulled a ~280KB full-dataset endpoint just to build an
id→name map (EXP-064).

| Rule | Detail |
|---|---|
| Internal ≠ excused | Internal endpoints get the same field-selection discipline; evaluate payload size before "just fetch it all" |

## 7. Boundary values must be validated against the real data distribution [REAL]

A filter cap was set to a round number chosen from memory; the most expensive
real item exceeded it and silently vanished from the list (EXP-065).

| Rule | Detail |
|---|---|
| Caps from data, not memory | Derive filter bounds from the actual distribution (min / max / percentiles) |
| Test the extremes | Test with the real maximum and minimum, not the typical case |

## 8. High-frequency polling gets its own rate-limit bucket [REAL]

A realtime room polled every couple of seconds and crowded out the shared API
quota (EXP-066).

| Rule | Detail |
|---|---|
| Isolate hot pollers | A separate bucket / quota for high-frequency endpoints so they cannot starve normal traffic |

## 9. When the optimization path blocks the business, fall back [REAL]

An image-optimization pipeline misbehaved on a small VPS (broken avatars); the
site first disabled optimization to stay available, then fixed it separately
(EXP-062).

| Rule | Detail |
|---|---|
| Availability first | If a performance feature breaks the product, turn it off, ship availability, fix it in isolation |

---

## Agent Quick Check

1. Layer identified with evidence (curl timings, host metrics, request counts) before any optimization?
2. Bottleneck measured — bandwidth vs. CPU vs. connections — and the fix targets that layer?
3. Big lists paginated + lazy-loaded; concurrent request count counted, not guessed?
4. Compression verified against actually-served content types (incl. RSC / XML) with real transferred sizes?
5. Request path free of synchronous blocking; polling endpoints on isolated quotas; filter bounds derived from real data?
