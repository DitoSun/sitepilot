const { readJson, writeJson } = require("../lib/store");

// Cart lives in a cookie for anonymous shoppers: { sku: qty }
function readCart(req) {
  const cookie = req.headers.cookie || "";
  const m = cookie.match(/(?:^|;\s*)cart=([^;]+)/);
  if (!m) return {};
  try { return JSON.parse(decodeURIComponent(m[1])); } catch { return {}; }
}

module.exports = (req, res) => {
  const catalog = readJson("catalog.json", { products: [] });
  const cart = readCart(req);

  if (req.method === "POST") {
    let body = "";
    req.on("data", c => body += c);
    req.on("end", () => {
      const { sku, qty } = JSON.parse(body || "{}");
      const product = catalog.products.find(p => p.sku === sku);
      if (!product) {
        res.writeHead(400, { "Content-Type": "application/json" });
        return res.end(JSON.stringify({ error: "unknown sku" }));
      }
      cart[sku] = qty;
      res.writeHead(200, {
        "Content-Type": "application/json",
        "Set-Cookie": `cart=${encodeURIComponent(JSON.stringify(cart))}; Path=/`,
      });
      res.end(JSON.stringify({ cart }));
    });
    return;
  }

  const items = Object.entries(cart).map(([sku, qty]) => {
    const p = catalog.products.find(x => x.sku === sku);
    return { sku, qty, name: p ? p.name : "unknown", price: p ? p.price : 0 };
  });
  const total = items.reduce((s, i) => s + i.price * i.qty, 0);
  res.writeHead(200, { "Content-Type": "application/json" });
  res.end(JSON.stringify({ items, total }));
};
