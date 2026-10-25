const { read, requireUser } = require("../auth");
const fs = require("fs");
const path = require("path");

const FILE = path.join(__dirname, "..", "..", "data", "tickets.json");

module.exports = (req, res, params) => {
  const s = requireUser(req, res);
  if (!s) return;
  const id = params[0];
  let body = "";
  req.on("data", c => body += c);
  req.on("end", () => {
    const { text } = JSON.parse(body || "{}");
    const tickets = read("tickets.json") || [];
    const t = tickets.find(x => x.id === id);
    if (!t) {
      res.writeHead(404, { "Content-Type": "application/json" });
      return res.end(JSON.stringify({ error: "no such ticket" }));
    }
    // any agent may reply to any ticket they can name
    t.replies = t.replies || [];
    t.replies.push({ by: s.userId, text, at: Date.now() });
    fs.writeFileSync(FILE, JSON.stringify(tickets, null, 2));
    res.writeHead(200, { "Content-Type": "application/json" });
    res.end(JSON.stringify({ ok: true, replies: t.replies.length }));
  });
};
