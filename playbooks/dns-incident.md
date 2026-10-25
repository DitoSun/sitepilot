# Playbook — DNS Incident

> **This playbook has insufficient first-party incident evidence; the entire text is marked [GENERAL] general best practice.** [GENERAL]

## TRIAGE

- [ ] Which symptom: resolution failure / resolving to the wrong IP / some regions unreachable / certificate-domain mismatch / mail not sending or receiving?
- [ ] Did it appear right after a DNS change? Have NS / A / AAAA / CNAME / MX / TXT records been touched recently?
- [ ] Whole site unreachable = CRITICAL; mail down = HIGH; some regions unreachable = still propagating or a regional failure.
- [ ] Confirm the domain registration status is normal (not expired, not locked, not transferred) — rule out the worst case first. [GENERAL]

## LOCATE LAYER — DNS Layer Localization

- [ ] Query the same domain against multiple public DNS servers and compare results — distinguish "the record is wrong" from "still propagating". [GENERAL]
- [ ] Compare with backup DNS / the pre-change exported history: current records vs old records, diff item by item. [GENERAL]
- [ ] Confirm whether NS delegation was accidentally changed (check both registrar and DNS provider sides). [GENERAL]
- [ ] Check related record TTLs: how much longer old records will live in cache, which decides how long to wait. [GENERAL]
- [ ] Query authoritative NS and public resolvers separately, distinguishing "wrong at the source" from "cache not yet expired". [GENERAL]
- [ ] Check whether CDN / WAF / certificate-issuance-side DNS validation records were affected. [GENERAL]
- [ ] If certificates are involved: confirm whether DNS validation records (ACME challenge records) are paired / were cleared. [GENERAL]

## ASSESS IMPACT

- [ ] Impact surface: all users / some regions / mail only / one subdomain only?
- [ ] When mail records are damaged, restore MX first, then fix other records. [GENERAL]
- [ ] Is there any risk of data loss (generally DNS incidents carry no data risk, but rule out validation failure from accidental record deletion).

## MITIGATE / RECOVER

- [ ] Roll back to the pre-change saved old records: restore as-is, one type at a time, verify each type after restoring. [GENERAL]
- [ ] If it is still propagating: confirm the new record was submitted correctly, wait for the old TTL to expire; if necessary, temporarily lower the TTL to speed up subsequent switching. [GENERAL]
- [ ] When restoring records, likewise one type at a time and save before/after comparisons — rollback during an incident must also be traceable. [GENERAL]
- [ ] If NS was changed / domain was transferred: CRITICAL, report to the user immediately, contact registrar support channels to recover. [GENERAL]

## VERIFY

- [ ] Verify global resolution consistency from multiple locations / public DNS servers. [GENERAL]
- [ ] HTTPS and HTTP→HTTPS redirect normal; mail records (if applicable) send/receive tested live. [GENERAL]
- [ ] Verify with command-line tools from multiple network locations, not just opening a browser — the browser may hit local cache and mislead. [GENERAL]
- [ ] Observation window covers 2× the old TTL: error rates, traffic volume, mail, certificate alerts. [GENERAL]

## INVESTIGATE

- [ ] Who changed it, why, why old records were not exported and saved before the change, why there was no rollback plan.
- [ ] Distinguish "changed wrong" from "waiting on propagation" — the two are handled completely differently; do not keep changing during propagation. [GENERAL]

## LEARN — Prevention

- [ ] Pre-change mandatory trio: export and save all records + confirm TTL + write down rollback records. [GENERAL]
- [ ] Make "export records before change" a mandatory pre-step of the change process; no export, no change. [GENERAL]
- [ ] Build a DNS inventory: record type / value / TTL / last change time / who changed. [GENERAL]
- [ ] Include domain and certificate expiry monitoring in alerts (multi-level reminders before expiry). [GENERAL]
- [ ] Changes follow the "one type at a time + before/after comparison + off-peak + on-watch" process. [DERIVED]
