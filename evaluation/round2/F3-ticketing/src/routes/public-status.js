const { read } = require("../auth");

// Public on purpose: a status page is meant to be polled by anyone, and it
// returns only service health, never tenant data.
module.exports = (req, res) => {
  const status = read("status.json") || { services: [] };
  res.writeHead(200, { "Content-Type": "application/json" });
  res.end(JSON.stringify(status));
};
