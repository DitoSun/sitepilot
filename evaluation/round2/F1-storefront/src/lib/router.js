const routes = {
  "/api/products": require("../routes/products"),
  "/api/orders": require("../routes/orders"),
  "/api/cart": require("../routes/cart"),
  "/api/admin/prices": require("../routes/admin-prices"),
  "/api/health": require("../routes/health"),
};

function route(req, res) {
  const path = req.url.split("?")[0];
  const handler = routes[path];
  if (!handler) {
    res.writeHead(404, { "Content-Type": "application/json" });
    return res.end(JSON.stringify({ error: "not found" }));
  }
  handler(req, res);
}

module.exports = { route, routes };
