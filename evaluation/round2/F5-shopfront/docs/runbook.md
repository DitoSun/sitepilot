# Runbook

## Rolling back
1. `ssh server 'cd /srv/shopfront && git log --oneline -5'`
2. Previous release is kept at `/srv/shopfront.prev/`
3. `ssh server 'systemctl stop shopfront && rsync -a --delete /srv/shopfront.prev/ /srv/shopfront/ && systemctl start shopfront'`

## Data
`data/` is part of the rsync payload in `deploy.sh`, which is why a bad local
copy reaches production.
