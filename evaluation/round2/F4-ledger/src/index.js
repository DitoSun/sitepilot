const http = require("http");
const store = require("./store");

http.createServer((req, res) => {
  if (req.url === "/api/members") {
    const rows = store.members();
    res.writeHead(200, { "Content-Type": "application/json" });
    return res.end(JSON.stringify({ count: rows.length, members: rows }));
  }
  if (req.url === "/api/members/count") {
    const rows = store.members();
    const legacy = store.legacy();
    res.writeHead(200, { "Content-Type": "application/json" });
    return res.end(JSON.stringify({
      primary: rows.length,
      legacy: legacy.length,
      cached: (store.cache() || {}).count ?? null,
    }));
  }
  res.writeHead(404); res.end();
}).listen(process.env.PORT || 4300);
