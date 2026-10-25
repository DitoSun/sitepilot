# Recipe: Windows Development Environment

## WHEN TO USE

Local development or ops work on Windows: running scripts, comparing files, starting
services, calling endpoints, preparing deployment packages. Involves Chinese paths, file
transfer verification, local service debugging.

## ASSUMPTIONS

- The dev machine is Windows, shell a mix of Git Bash / PowerShell.
- File transfers exist between local and server (scp/rsync/archives).
- Project paths may contain non-ASCII characters like Chinese.

## COMMON FAILURE MODES

1. **Chinese paths as shell arguments intermittently garble**: the same command works sometimes
   and not others — this "intermittency" most easily causes misdiagnosis ("it worked a moment
   ago"). Correct handling: **put the logic in script files, run with ASCII paths**; do not
   rename paths (it breaks dual links/shortcuts). Git Bash's `/tmp` and the temp locations
   visible to Python and other programs are not the same place; mixing them makes "files
   mysteriously disappear". [REAL]
2. **CRLF normalization holds for text only**: comparing after `tr -d '\r'` works for text
   files; in binaries `\r` is an ordinary byte, and deleting it changes content — "deleted" and
   "replaced with `\n`" are two different files. **Comparison rules split by type: text gets
   CRLF normalization, binary always raw md5**. [REAL]
3. **Ports held by leftover processes, services running old code**: old node/python processes
   not fully dead, new service `EADDRINUSE` or never starts, curl hits old code — looks like
   "edited for ages, no effect". For "changed but no effect", first `netstat` to find the PID
   and the actual listener, then check the code. [REAL]
4. **Clipboard API unavailable under HTTP**: `navigator.clipboard` is directly unavailable in a
   non-secure context (HTTP); copy silently fails. The fallback (e.g. `execCommand`) must be
   written in the first version and tested against the real deployment environment — localhost
   and production protocols differ, behavior may differ. [REAL]
5. **Parsing external data loses columns**: dirty preambles in xlsx/csv (unclosed quotes, etc.)
   make parsers swallow rows; whole columns of data silently vanish. Parsing external data must
   verify row/column completeness. [REAL]

## SAFE WORKFLOW

1. Put multi-step logic into script files (.sh/.py), avoiding long commands typed directly;
   scripts and their data use ASCII paths.
2. File comparison/verification: classify first (text vs binary), text compared after CRLF
   normalization, binary raw md5; two-way verification (compute once each on source and
   target).
3. Before starting a local service, `netstat` to confirm no leftover process holds the port;
   after starting, confirm the listening PID is this startup's process.
4. Do not dirty data when locally verifying endpoints: intercept write requests, return fake
   responses, keeping verification isolated from real data. [REAL]
5. Production-touching operations (deploy package builds, data sync prep) follow the core
   SKILL's full change workflow; the local environment does not lower the bar.

## VERIFICATION

- Comparison rules split by type: text (consistent after CRLF normalization), binary (raw md5
  consistent) — take "byte-identical" evidence, not "should be fine". [REAL]
- Service verification: process PID, listening port, actual response content (confirm it is
  the new code).
- Cross-environment behavior (e.g. clipboard) tested under the target protocol environment,
  not only on localhost.

## ROLLBACK

- This recipe's traps are all local/environment-layer and **do not involve production
  rollback**; but local misdiagnosis (old code treated as new code, a corrupted file uploaded)
  directly becomes a production incident, so the discipline stands: verify locally first, then
  touch production.
- Local experiments touch local copies only; back up before touching authoritative data (core
  SKILL §6).

## LESSONS LEARNED

- The three illusions of Windows: intermittent garbling (works then doesn't), rule mismatch
  (text rules applied to binary), process residue (old code passing as new) — none of them
  throw errors, they just quietly err.
- "Check process/port/actual listener first, then the code" is the first reflex of local
  troubleshooting, of the same origin as the core SKILL's "locate the layer before changing
  the system".