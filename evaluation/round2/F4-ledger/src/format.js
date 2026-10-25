const fmt = new Intl.NumberFormat("en-US");
module.exports = {
  count: (n) => fmt.format(n),
  date: (ts) => new Date(ts * 1000).toISOString().slice(0, 10),
};
