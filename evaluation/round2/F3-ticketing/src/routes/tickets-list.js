const { read, requireUser } = require("../auth");

module.exports = (req, res) => {
  const s = requireUser(req, res);
  if (!s) return;
  const tickets = read("tickets.json") || [];
  const mine = tickets.filter(t => t.assignee === s.userId);
  res.writeHead(200, { "Content-Type": "application/json" });
  res.end(JSON.stringify({ tickets: mine }));
};
