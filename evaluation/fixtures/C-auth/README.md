# Notes App

A tiny notes service with a JSON API and a browser client.

## Run
```bash
node src/server.js
```

Users log in via `/api/login`. The browser stores the returned profile and sends
`userId` with subsequent requests so the server knows who is asking.

## Endpoints
- `POST /api/login` { username, password } → { user }
- `GET  /api/notes?userId=...` → notes for that user
- `DELETE /api/notes?id=...` with body { userId } → delete a note
