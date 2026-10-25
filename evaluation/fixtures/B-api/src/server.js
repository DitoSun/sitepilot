const http = require("http");
const fs = require("fs");
const path = require("path");

const PAGE_SIZE = parseInt(process.env.PAGE_SIZE || "20", 10);
const DATA = JSON.parse(fs.readFileSync(path.join(__dirname, "data.json"), "utf8"));

const server = http.createServer((req, res) => {
  if (req.url.startsWith("/api/orders")) {
    // Returns a page of orders. Callers are expected to use ?page= to walk.
    const slice = DATA.orders.slice(0, PAGE_SIZE);
    res.writeHead(200, { "Content-Type": "application/json" });
    res.end(JSON.stringify({
      orders: slice,
      page: 1,
      pageSize: PAGE_SIZE,
      total: DATA.orders.length
    }));
    return;
  }
  if (req.url === "/health") {
    res.writeHead(200, { "Content-Type": "text/plain" });
    res.end("ok");
    return;
  }
  res.writeHead(404); res.end("not found");
});

const PORT = process.env.PORT || 3001;
server.listen(PORT, () => console.log(`orders api on :${PORT}`));
