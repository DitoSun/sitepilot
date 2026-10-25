const store = require("./store");
const { priceOf } = require("./plan");

// MRR by plan, from the primary store.
function mrr() {
  const rows = store.members();
  const by = {};
  for (const r of rows) {
    if (r.status !== "active") continue;
    by[r.plan] = (by[r.plan] || 0) + priceOf(r.plan);
  }
  return by;
}

module.exports = { mrr };
