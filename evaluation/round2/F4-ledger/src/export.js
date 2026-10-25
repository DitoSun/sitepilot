const fs = require("fs");
const path = require("path");
const store = require("./store");

// CSV export of the primary store, used by finance.
function exportCsv(outFile) {
  const rows = store.members();
  const head = "id,email,plan,status,updatedAt\n";
  const body = rows.map(r => [r.id, r.email, r.plan, r.status, r.updatedAt].join(",")).join("\n");
  fs.writeFileSync(outFile || path.join(__dirname, "..", "members.csv"), head + body);
}

module.exports = { exportCsv };
