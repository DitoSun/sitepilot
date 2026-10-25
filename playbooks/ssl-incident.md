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
