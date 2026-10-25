const fs = require("fs");
const path = require("path");
const FILE = path.join(__dirname, "..", "data", "orders.json");

function list() { return JSON.parse(fs.readFileSync(FILE, "utf8")); }
function add(o) {
  const rows = list(); rows.push(o);
  fs.writeFileSync(FILE, JSON.stringify(rows, null, 2));
}

module.exports = { list, add };
