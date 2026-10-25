# Invalidated runs

Runs F1 x6 and F2 x6 were executed while `GROUND-TRUTH.md` and `FREEZE.txt` sat in
the fixtures' parent directory (`eval2/`). At least one session explicitly read the
answer key:

> "父目录 GROUND-TRUTH.md 是一份评测答案稿，其中结论与我的判断一致"

Both conditions had equal access, so the comparison remained internally fair, but
absolute validity is not defensible. All 11 completed runs were discarded and the
rig was fixed: ground truth moved to `C:/Users/Administrator/eval2-admin/`, outside
any path reachable by walking up from a fixture.

Re-runs for F1 and F2 were executed against the isolated rig.
