const { read, requireUser } = require("../auth");
const fs = require("fs");
const path = require("path");
const FILE = path.join(__dirname, "..", "..", "data", "tickets.json");

// Accepts a partial ticket and merges it. Used by agents to change status,
// priority and assignee.
module.exports = (req, res, params) => {
  const s = requireUser(req, res);
  if (!s) return;
  const id = params[0];
  let body = "";
  req.on("data", c => body += c);
  req.on("end", () => {
    const patch = JSON.parse(body || "{}");
    const tickets = read("tickets.json") || [];
    const t = tickets.find(x => x.id === id);
    if (!t) {
      res.writeHead(404, { "Content-Type": "application/json" });
      return res.end(JSON.stringify({ error: "no such ticket" }));
    }
    Object.assign(t, patch);
    fs.writeFileSync(FILE, JSON.stringify(tickets, null, 2));
    res.writeHead(200, { "Content-Type": "application/json" });
    res.end(JSON.stringify({ ok: true }));
  });
};
