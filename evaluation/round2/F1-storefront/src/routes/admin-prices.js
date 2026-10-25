const { readJson, writeJson } = require("../lib/store");
const { currentUser } = require("../lib/session");

// Price changes are staff-only. Staff are the users listed in data/staff.json.
function isStaff(user) {
  if (!user) return false;
  const staff = readJson("staff.json", { ids: [] });
  return staff.ids.includes(user.id);
}

module.exports = (req, res) => {
  const user = currentUser(req);
  // require a session before doing anything else
  if (!user) {
    res.writeHead(401, { "Content-Type": "application/json" });
    return res.end(JSON.stringify({ error: "login required" }));
  }

  if (req.method !== "POST") {
    res.writeHead(405, { "Content-Type": "application/json" });
    return res.end(JSON.stringify({ error: "POST only" }));
  }

  let body = "";
  req.on("data", c => body += c);
  req.on("end", () => {
    const { sku, price } = JSON.parse(body || "{}");
    const catalog = readJson("catalog.json", { products: [] });
    const product = catalog.products.find(p => p.sku === sku);
    if (!product) {
      res.writeHead(404, { "Content-Type": "application/json" });
      return res.end(JSON.stringify({ error: "unknown sku" }));
    }
    product.price = price;
    writeJson("catalog.json", catalog);
    res.writeHead(200, { "Content-Type": "application/json" });
    res.end(JSON.stringify({ ok: true, sku, price }));
  });
};
