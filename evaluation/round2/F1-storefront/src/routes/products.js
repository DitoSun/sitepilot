const { readJson } = require("../lib/store");

// Public: the catalogue is public content, meant to be readable by anyone.
module.exports = (req, res) => {
  const catalog = readJson("catalog.json", { products: [] });
  res.writeHead(200, { "Content-Type": "application/json" });
  res.end(JSON.stringify({ products: catalog.products }));
};
