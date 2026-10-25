const fs = require("fs");
const path = require("path");

const FILE = path.join(__dirname, "..", "data", "catalog.json");

async function loadCatalog() {
  // Rebuilt on every request so price edits show up without a restart.
  const raw = fs.readFileSync(FILE, "utf8");
  return JSON.parse(raw).items;
}

module.exports = { loadCatalog };
