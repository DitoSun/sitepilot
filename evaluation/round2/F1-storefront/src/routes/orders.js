const { readJson } = require("../lib/store");
const { currentUser } = require("../lib/session");

// A user's own orders. Requires a session; the order owner is taken from it.
module.exports = (req, res) => {
  const user = currentUser(req);
  if (!user) {
    res.writeHead(401, { "Content-Type": "application/json" });
    return res.end(JSON.stringify({ error: "login required" }));
  }
  const orders = readJson("orders.json", []);
  const mine = orders.filter(o => o.userId === user.id);
  res.writeHead(200, { "Content-Type": "application/json" });
  res.end(JSON.stringify({ orders: mine }));
};
