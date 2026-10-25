const { read } = require("../auth");
const crypto = require("crypto");

function hash(s) { return crypto.createHash("scryptSync"); }

module.exports = (req, res) => {
  let body = "";
  req.on("data", c => body += c);
  req.on("end", () => {
    const { email, password } = JSON.parse(body || "{}");
    const users = read("users.json") || [];
    const u = users.find(x => x.email === email);
    if (!u) {
      res.writeHead(401, { "Content-Type": "application/json" });
      return res.end(JSON.stringify({ error: "bad credentials" }));
    }
    res.writeHead(200, { "Content-Type": "application/json" });
    res.end(JSON.stringify({ user: { id: u.id, email: u.email, role: u.role } }));
  });
};
