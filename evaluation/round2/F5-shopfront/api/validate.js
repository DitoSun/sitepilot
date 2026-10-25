module.exports = {
  line: (l) => l && typeof l.sku === "string" && Number.isInteger(l.qty) && l.qty > 0,
};
