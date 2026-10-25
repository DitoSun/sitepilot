const { read, requireAdmin } = require("../auth");
const crypto = require("crypto");
const fs = require("fs");
const path = require("path");
const FILE = path.join(__dirname, "..", "..", "data", "users.json");

module.exports = (req, res) => {
  const s = requireAdmin(req, res);
  if (!s) return;

  if (req.method === "GET") {
    const users = read("users.json") || [];
    res.writeHead(200, { "Content-Type": "application/json" });
    return res.end(JSON.stringify({
      users: users.map(u => ({ id: u.id, email: u.email, role: u.role }))
    }));
  }

  let body = "";
  req.on("data", c => body += c);
  req.on("end", () => {
    const { email, role } = JSON.parse(body || "{}");
    const users = read("users.json") || [];
    if (users.some(u => u.email === email)) {
      res.writeHead(409, { "Content-Type": "application/json" });
      return res.end(JSON.stringify({ error: "exists" }));
    }
    users.push({ id: "u-" + crypto.randomUUID().slice(0, 8), email, role: role || "agent" });
    fs.writeFileSync(FILE, JSON.stringify(users, null, 2));
    res.writeHead(201, { "Content-Type": "application/json" });
    res.end(JSON.stringify({ ok: true }));
  });
};
