# Checklist — DNS / Domain Change

> **This checklist has insufficient first-party incident evidence; the entire text is marked [GENERAL] general best practice** — do not disguise it as real experience.
> DNS change impact surface = whole-site reachability; rated HIGH at minimum; any step that cannot be confirmed → **STOP → REPORT**.

## A. Before Change (do not act until complete)

- [ ] Confirm the DNS provider and management entry — from evidence, never guess. [GENERAL]
- [ ] Export and save the current **all** records (A / AAAA / CNAME / MX / TXT / NS / CAA…), archived to a safe location outside version control. [GENERAL]
- [ ] Confirm the current TTL of every record to be changed — TTL determines how long old records live in cache and how long propagation takes. [GENERAL]
- [ ] Assess the propagation time window: full global resolution switching takes time; old and new records coexist during the window, and the business must be able to accept that. [GENERAL]
- [ ] Write down rollback records: old records archived as-is + rollback operation steps + rollback verification method — all three on paper. [GENERAL]
- [ ] Confirm the registrar account security state (2FA enabled, contact email valid) — domain hijacks mostly start with account compromise. [GENERAL]
- [ ] Confirm domain and certificate expiry dates; do not change records inside an expiry window. [GENERAL]
- [ ] Assess downstream impact: certificate issuance method (e.g., DNS validation), mail send/receive, CDN origin, third-party allowlists that depend on old records. [GENERAL]

## B. During Change

- [ ] Change only one record type at a time; verify each type before the next; no mixed batch submissions. [GENERAL]
- [ ] Save a before/after comparison table (record type / old value / new value / change time) for post-review and rollback. [GENERAL]
- [ ] Immediately after each record type is changed, verify with read-only queries — do not save all verification for the end. [GENERAL]
- [ ] Execute during off-peak hours; prepare a rollback on-call owner; do not leave immediately after the change. [DERIVED]

## C. Post-Change Verification

- [ ] Verify global resolution consistency from multiple locations / public DNS servers, not just the local resolver. [GENERAL]
- [ ] Verify HTTPS: certificate covers the relevant domains, HTTP→HTTPS redirect in place. [GENERAL]
- [ ] Verify mail records (if applicable): MX / SPF / DKIM / DMARC aligned with the new egress IP; send/receive tested live. [GENERAL]
- [ ] Verify whether CDN / WAF origin config needs to change in tandem. [GENERAL]
- [ ] Check whether domains referenced in monitoring / alerting / third-party integrations need synchronized updates. [DERIVED]
- [ ] Observation window covers at least 2× the old TTL: error rates, traffic volume, mail, certificate alerts. [DERIVED]

## D. Stop Conditions

- [ ] Unknown current records / unknown TTL / no saved old records → stop, fill the gaps before changing. [GENERAL]
- [ ] Local and remote resolution disagree and you cannot confirm which is authoritative → stop, confirm before changing. [REAL] (the authoritative-copy principle is general)
- [ ] NS delegation changes / registrar transfer → CRITICAL, must obtain explicit user confirmation. [GENERAL]
- [ ] When batch-changing multiple records, write rollback steps for each, to avoid omissions during rollback making the incident worse. [GENERAL]

## Appendix: Change Record Template (one per record)

```
Record type: (A / AAAA / CNAME / MX / TXT / ...)
Old value: (original value exported before change, as-is)
New value: (value to be written)
TTL: (current value)
Change time: (actual execution time)
Verification method: (multiple DNS queries + HTTPS + business smoke + mail live test)
Rollback steps: (specific operation to restore the old value as-is)
```
