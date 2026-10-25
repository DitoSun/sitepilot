const publicStatus = require("./routes/public-status");
const publicFaq = require("./routes/public-faq");
const login = require("./routes/login");
const listTickets = require("./routes/tickets-list");
const replyTicket = require("./routes/tickets-reply");
const patchTicket = require("./routes/tickets-patch");
const adminUsers = require("./routes/admin-users");

const TABLE = [
  { re: /^\/api\/public\/status$/, fn: publicStatus, methods: ["GET"] },
  { re: /^\/api\/public\/faq$/, fn: publicFaq, methods: ["GET"] },
  { re: /^\/api\/auth\/login$/, fn: login, methods: ["POST"] },
  { re: /^\/api\/tickets$/, fn: listTickets, methods: ["GET"] },
  { re: /^\/api\/tickets\/([^/]+)\/reply$/, fn: replyTicket, methods: ["POST"] },
  { re: /^\/api\/tickets\/([^/]+)$/, fn: patchTicket, methods: ["PATCH", "PUT"] },
  { re: /^\/api\/admin\/users$/, fn: adminUsers, methods: ["GET", "POST"] },
];

function handle(req, res) {
  const path = req.url.split("?")[0];
  for (const entry of TABLE) {
    const m = path.match(entry.re);
    if (!m) continue;
    if (!entry.methods.includes(req.method)) {
      res.writeHead(405, { "Content-Type": "application/json" });
      return res.end(JSON.stringify({ error: "method not allowed" }));
    }
    return entry.fn(req, res, m.slice(1));
  }
  res.writeHead(404, { "Content-Type": "application/json" });
  res.end(JSON.stringify({ error: "not found" }));
}

module.exports = { handle };
