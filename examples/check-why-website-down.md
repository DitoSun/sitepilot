# Example: "Help me check why the website won't open"

> Demonstrates: layered localization. Core SKILL §10 troubleshooting model +
> `playbooks/website-down.md` + `references/troubleshooting.md`.

---

**User**: Help me check why the website won't open.

## How SitePilot Thinks

"Won't open" is user language, not a fault description. It could be DNS, TLS, the server,
processes, the application — any layer. **Locate the layer first, then act.** Never touch code
first thing. Run read-only diagnostics only; stop-and-report before any write operation.

## What to Load

- Core SKILL §10 (layered troubleshooting model) — already in the built-in layer
- `playbooks/website-down.md` (website unreachable playbook)
- If a concrete stack is detected: the matching recipe (e.g. nginx-reverse-proxy /
  pm2-process-manager)

## Reasoning Process

```
Layer               Check method (read-only)                     Typical misdiagnosis
USER/CLIENT         curl local against production domain;        "my internet is broken"
                    reproduce on another network/device
DNS                 dig/nslookup: does resolution return the     resolves to old IP
                    expected address
TLS                 cert chain/validity; HTTP→HTTPS redirect     cert expired
CDN/WAF             origin judgment; blocked by WAF (403 vs      "server is down" is actually a block
                    timeout)
REVERSE PROXY       nginx -t; access_log last write time         0-byte logs = no monitoring foundation
SERVER              processes/ports/disk/memory; restart counts  port held by leftover process
RUNTIME             Node/PHP version; process manager status     process running but serving old code
APPLICATION         app logs; error reporting; build artifact    new build missing files
                    completeness
API                 curl the endpoint directly for latency;      "endpoint slow" is actually client-layer
                    distinguish 403 from business 403
CACHE               static pages/browser cache; hard-refresh     "changed but no effect" = cache
                    retest
DATA                data file counts/freshness                   data corrupted/cleared
EXTERNAL            upstream deps/SMTP/third-party APIs          upstream down, this site pays along
```

## Key Decision Points

1. **Read-only probes per layer, eliminate layer by layer**. Probes must carry real client
   characteristics (UA) — otherwise the site's own anti-scraping middleware may 403 them and a
   fault is misdiagnosed.
2. **"Stuck ≠ slow endpoint"**: curl the endpoint directly to measure server latency first, then
   check the client connection/render layer. Server measures fast → the problem is client-side.
3. After finding the layer, **restore service first, then analyze the root cause** (MITIGATE →
   STABILIZE → RECOVER → INVESTIGATE). No large refactors during an incident.
4. If recovery needs a write operation (restart/rollback/config change) → stop-report-confirm
   (even when the user says "use your judgment", state the blast radius and rollback point
   first).

## How to Verify

- After the fix: all multi-network/device reproduction paths pass; key pages contain expected
  content after hard refresh; logs resume writing; restart counts stop climbing abnormally.
- Report back: **which layer, root cause, what was done, how verified, residual risk**.

## Lesson Review

This involved a real fault + a possible misdiagnosis. If "I guessed the wrong layer" or "some
signal misled me" (old process holding the port, cache faking "no effect") appears → write it
into `.sitepilot/lessons/` as a Lesson Candidate, and check whether the trap deserves a
checklist item or monitoring metric (recurrence = escalate).