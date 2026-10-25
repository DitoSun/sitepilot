# Evaluation Fixtures

Five throwaway projects used for the A/B evaluation in
[`../../docs/agent-evaluation.md`](../../docs/agent-evaluation.md).

Each contains deliberately seeded defects. **They are test material, not
examples.** Do not copy patterns from here.

| Fixture | Shape | Primary defect |
|---|---|---|
| `A-static` | static HTML + host config | host never reads the config; redirects file never applies |
| `B-api` | Node HTTP over JSON | `?page=` accepted but never implemented — 200 with 25 of 45 rows lost |
| `C-auth` | login + notes CRUD | identity is whatever the caller claims |
| `D-deploy` | build + publish scripts | build and publish both exit 0, every asset 404s in production |
| `E-gitdata` | Node + JSON store | `.gitignore` has the rule; the files are tracked anyway |

## Reproducing

`FREEZE.txt` records the content hash of each fixture at the time of the
evaluation. Verify nothing drifted:

```bash
cd evaluation/fixtures
while read -r name hash; do
  case "$name" in \#*|"") continue ;; esac
  cur=$(find "$name" -type f -not -path '*/.git/*' -not -path '*/dist/*' \
        | sort | xargs cat | md5sum | cut -d' ' -f1)
  [ "$cur" = "$hash" ] && echo "OK   $name" || echo "DRIFT $name"
done < FREEZE.txt
```

`E-gitdata` needs one extra step, because a `.git` directory cannot be shipped
inside another repository. To reproduce its defect:

```bash
cd E-gitdata
git init && git add .gitignore README.md app/server.js package.json
git commit -m initial
git add -f data/            # force-added AFTER the ignore rule existed
git commit -m "add seed data"
git ls-files data/          # the files are tracked
git check-ignore --no-index data/users.json   # the rule still matches
```

Note: `E-gitdata` contains placeholder credentials and fake emails. They are
synthetic and were never valid anywhere.
