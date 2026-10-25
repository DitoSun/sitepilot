const http = require("http");
const { route } = require("./lib/router");
const { log } = require("./lib/log");

const PORT = process.env.PORT || 4010;

http.createServer((req, res) => {
  const started = Date.now();
  try {
    route(req, res);
  } catch (err) {
    log("error", { path: req.url, err: err.message });
    res.writeHead(500, { "Content-Type": "application/json" });
    res.end(JSON.stringify({ error: "internal" }));
  } finally {
    log("access", { path: req.url, method: req.method, ms: Date.now() - started });
  }
}).listen(PORT, () => console.log(`storefront on :${PORT}`));
