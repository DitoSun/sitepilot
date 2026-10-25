const http = require("http");
const crypto = require("crypto");

// In-memory store for the demo.
const users = [
  { id: "u1", username: "alice", pass: hash("alice-pw") },
  { id: "u2", username: "bob",   pass: hash("bob-pw") }
];
const notes = [
  { id: "n1", userId: "u1", body: "alice private note" },
  { id: "n2", userId: "u2", body: "bob private note" }
];

function hash(s) { return crypto.createHash("sha256").update(s).digest("hex"); }

function json(res, code, obj) {
  res.writeHead(code, { "Content-Type": "application/json" });
  res.end(JSON.stringify(obj));
}

const server = http.createServer((req, res) => {
  const url = new URL(req.url, "http://localhost");

  if (req.method === "POST" && url.pathname === "/api/login") {
    let body = "";
    req.on("data", c => body += c);
    req.on("end", () => {
      const { username, password } = JSON.parse(body || "{}");
      const u = users.find(x => x.username === username && x.pass === hash(password || ""));
      if (!u) return json(res, 401, { error: "bad credentials" });
      json(res, 200, { user: { id: u.id, username: u.username } });
    });
    return;
  }

  if (req.method === "GET" && url.pathname === "/api/notes") {
    const userId = url.searchParams.get("userId");
    if (!userId) return json(res, 400, { error: "userId required" });
    json(res, 200, { notes: notes.filter(n => n.userId === userId) });
    return;
  }

  if (req.method === "DELETE" && url.pathname === "/api/notes") {
    let body = "";
    req.on("data", c => body += c);
    req.on("end", () => {
      const id = url.searchParams.get("id");
      const { userId } = JSON.parse(body || "{}");
      const idx = notes.findIndex(n => n.id === id && n.userId === userId);
      if (idx === -1) return json(res, 404, { error: "not found" });
      notes.splice(idx, 1);
      json(res, 200, { ok: true });
    });
    return;
  }

  res.writeHead(404); res.end("not found");
});

server.listen(process.env.PORT || 3002, () => console.log("notes app up"));
