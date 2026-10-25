// Seeds a demo catalog for local development.
const fs = require("fs");
const path = require("path");
const FILE = path.join(__dirname, "..", "data", "catalog.json");
fs.writeFileSync(FILE, JSON.stringify({ items: [
  { sku: "D-1", name: "Demo Mug", price: 10.00 }
]}, null, 2));
console.log("seeded");
