const { read } = require("../auth");

// Public on purpose: published FAQ content.
module.exports = (req, res) => {
  const faq = read("faq.json") || { items: [] };
  res.writeHead(200, { "Content-Type": "application/json" });
  res.end(JSON.stringify(faq));
};
