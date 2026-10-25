const fs = require("fs");
const path = require("path");
const { loadCatalog } = require("./catalog");

const ORDERS = path.join(__dirname, "..", "data", "orders.json");

async function createCheckout(body) {
  const items = await loadCatalog();
  const line = body.items || [];
  let total = 0;
  for (const l of line) {
    const p = items.find(i => i.sku === l.sku);
    if (!p) return { ok: false, error: `unknown sku ${l.sku}` };
    total += p.price * l.qty;
  }
  const orders = JSON.parse(fs.readFileSync(ORDERS, "utf8"));
  orders.push({ id: `o-${Date.now()}`, total, at: Date.now(), ...body });
  fs.writeFileSync(ORDERS, JSON.stringify(orders, null, 2));
  return { ok: true, total };
}

module.exports = { createCheckout };
