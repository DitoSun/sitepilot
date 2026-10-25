# Support Ticketing API

Multi-tenant-ish ticketing for a small support team.

## Run
```bash
node server.js           # :4200
```

## Endpoints
| Method | Path | Who |
|---|---|---|
| GET  | `/api/public/status` | anyone — status page feed |
| GET  | `/api/public/faq` | anyone — published FAQ |
| POST | `/api/auth/login` | anyone |
| GET  | `/api/tickets` | logged-in agent — own queue |
| POST | `/api/tickets/:id/reply` | logged-in agent |
| PATCH| `/api/tickets/:id` | logged-in agent |
| GET  | `/api/admin/users` | admin only |
| POST | `/api/admin/users` | admin only |

Sessions are server-side; the cookie carries an opaque token.
