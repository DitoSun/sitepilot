# Playbook — SSL / Certificate Incident

> **This playbook has insufficient first-party incident evidence; the entire text is marked [GENERAL] general best practice.** [GENERAL]

## TRIAGE

- [ ] Pick one of four symptoms (possibly overlapping): certificate expired / incomplete certificate chain / hostname mismatch / HTTP→HTTPS redirect lost.
- [ ] First confirm whether it is a certificate issue itself or a chain / config / middlebox issue — cross-verify with external detection tools before concluding. [GENERAL]
- [ ] Impact surface: site-wide HTTPS security warnings = CRITICAL; single-domain / wildcard subdomain issue = localized.

## LOCATE LAYER — Read-Only Verification, Do Not Touch Config First

- [ ] Use read-only commands to view the certificate chain, expiry date, issuer, SAN list (do not touch any config). [GENERAL]
- [ ] Check against the domain list: is every domain / subdomain within SAN coverage? [GENERAL]
- [ ] Check whether the HTTP→HTTPS redirect rules still exist (reverse proxy layer / app layer / CDN layer). [GENERAL]
- [ ] Check auto-renewal task status: last success time, failure logs, renewal account quota. [GENERAL]
- [ ] Incomplete chains are the hardest to self-check: cross-verify with external detection tools (different clients differ in chain-validation strictness). [GENERAL]
- [ ] Check multi-layer chains layer by layer: reverse proxy / CDN / load balancer each may have its own certificate config. [GENERAL]
- [ ] Check whether the certificate and private key are paired (common mispairing after reinstall / migration). [GENERAL]

## ASSESS IMPACT

- [ ] Expired certificate = browser-wide security warnings, user traffic cliff, search engine crawling may also fail.
- [ ] hostname mismatch = only users visiting that domain are affected.
- [ ] Redirect lost = HTTP and HTTPS dual entry coexisting, mixed content and SEO risk. [DERIVED]

## MITIGATE / RECOVER

- [ ] Temporary recovery first: renew immediately; if renewal is too slow, fall back to a known-good backup certificate to get HTTPS working first. [GENERAL]
- [ ] When renewal fails, check four points: whether the validation method (HTTP-01 / DNS-01) is reachable; whether ports 80 / 443 are blocked; whether DNS validation records are paired; whether firewall / CDN blocked the validation request. [GENERAL]
- [ ] When the renewal channel itself fails, evaluate temporarily switching validation methods or an emergency CA as a fallback path. [GENERAL]
- [ ] Back up the current (even if broken) config before making changes, preserving the fallback path. [GENERAL]
- [ ] Redirect lost: restore reverse proxy / app layer redirect rules, verify the 301 target is correct. [GENERAL]

## PATH: Certificate renewed, but visitors still get the old one

A distinct failure mode from "certificate expired": the renewal succeeded and
the server has a valid file, yet the public endpoint still presents the old
certificate. Do not re-issue certificates in a loop — locate the layer.

Work through these in order, read-only first:

| # | Layer | Check | Finding means |
|---|---|---|---|
| 1 | File | `openssl x509 -in <cert> -noout -dates` | The file on disk is new |
| 2 | Process | Is the TLS terminator running the new config? Was it reloaded/restarted after renewal? | Renewal without reload = old cert still served |
| 3 | Reverse proxy | Does nginx/apache terminate TLS? Did it reload? | `nginx -T` shows the cert path actually loaded |
| 4 | CDN | Does a CDN terminate TLS with its own certificate? | A CDN cert must be renewed at the CDN, not on the server |
| 5 | Load balancer | Does an LB hold its own certificate copy? | Renewing the origin does nothing for the LB |
| 6 | Multiple nodes | Are all nodes updated? Is the sample hitting an old one? | Inconsistent fleet — sample several times |
| 7 | Old process | Is a stale process still bound to :443? | New file, old listener |
| 8 | DNS | Does the hostname resolve where you think? | You may be checking a different server than users reach |

**Proof of recovery is external, not local.** Read the certificate from
outside, over the public hostname, and compare fingerprints across several
samples:

```bash
openssl s_client -servername <host> -connect <host>:443 </dev/null 2>/dev/null \
  | openssl x509 -noout -dates -fingerprint -sha256
```

Then confirm the user-visible outcome: HTTPS loads with no browser warning, the
expiry is in the future, and HTTP still redirects to HTTPS.

> Action completed ≠ recovery verified. The certificate file being new is an
> internal fact; the certificate a visitor receives is the only outcome that
> matters. (EXP-118)

## VERIFY

- [ ] Verify every domain one by one: chain complete, expiry date, hostname match, HTTP→HTTPS redirect in place. [GENERAL]
- [ ] Verify across multiple clients (different browsers / curl with different configs / external detection tools) to rule out chain-validation differences. [GENERAL]
- [ ] Check mixed-content warnings (HTTP resources on an HTTPS page) — the certificate may be fixed but the page can still be flagged unsafe by the browser. [GENERAL]
- [ ] Observation period: confirm the auto-renewal task will succeed next time (not just curing the current expiry). [DERIVED]

## INVESTIGATE

- [ ] Why expired: renewal task failed? New domain launched without signing? Provider-side change? Who blocked the validation channel?

## LEARN — Prevention

- [ ] Certificate expiry inventory: each certificate's domains, issue date, expiry date, renewal method, owner. [GENERAL]
- [ ] Auto-renewal + renewal failure alerts (multi-level reminders at 30 / 14 / 7 days before expiry). [GENERAL]
- [ ] The new-domain launch process mandatorily includes the certificate issuance step; no issuance, no launch. [GENERAL]
- [ ] Manage certificate expiry in the same inventory as domains; record where renewal account info is stored (names, not values) in handover docs. [GENERAL]
- [ ] Keep usable certificate backups as an emergency fallback. [DERIVED]
