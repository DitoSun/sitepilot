# Site Context — <project name>

> Authoritative facts about THIS website. The agent loads this before acting.
> If a fact here conflicts with an assumption, this file wins.
> Never store secrets, tokens, user data, env values, private IPs, or internal URLs.

## Identity
- Site / purpose:
- Tech stack (detected from: package.json / requirements.txt / Dockerfile / …):
- Environments: production = ?, staging = ?, local = ?

## Infrastructure (evidence-based, never guessed)
- Hosting / server:
- Reverse proxy / CDN / WAF:
- Process manager / runtime versions:
- Deploy mechanism (the REAL one — script, CI, manual):
- DNS provider:
- TLS certificate: issuer, renewal method, expiry:

## Data
- Authoritative data store(s) and which copy is authoritative:
- Local/dev copies are stale snapshots of:
- Data files or tables that must NOT be modified without confirmation:

## Special knowledge (the expensive-to-learn facts)
- e.g. "deleting route X also requires deleting .next/types/app/X"
- e.g. "endpoint Y is a user-facing write endpoint, not admin"
- e.g. "historical SEO reason: URL Z must 301 to W forever"

## Known issues / watch list
- (link to lessons/ and incidents/ files)

## Verification basics
- Critical pages / endpoints that must be semantically verified after any change:
- How to hard-refresh past cache when verifying:
