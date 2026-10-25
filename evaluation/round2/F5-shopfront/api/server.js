const http = require("http");
const { loadCatalog } = require("./catalog");
const { createCheckout } = require("./checkout");

http.createServer(async (req, res) => {
  if (req.url.startsWith("/api/catalog")) {
    const items = await loadCatalog();
    res.writeHead(200, { "Content-Type": "application/json" });
    return res.end(JSON.stringify({ items }));
  }
  if (req.url === "/api/checkout" && req.method === "POST") {
    let b = "";
    req.on("data", c => b += c);
    req.on("end", async () => {
      const out = await createCheckout(JSON.parse(b || "{}"));
      res.writeHead(out.ok ? 200 : 500, { "Content-Type": "application/json" });
      res.end(JSON.stringify(out));
    });
    return;
  }
  if (req.url === "/health") { res.writeHead(200); return res.end("ok"); }
  res.writeHead(404); res.end();
}).listen(process.env.PORT || 4400);
