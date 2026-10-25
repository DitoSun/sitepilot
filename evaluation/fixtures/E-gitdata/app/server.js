const http = require("http");
const fs = require("fs");
const path = require("path");
const DATA = path.join(__dirname, "..", "data", "feedback.json");

function read() {
  try { return JSON.parse(fs.readFileSync(DATA, "utf8")); } catch { return []; }
}
function write(rows) {
  fs.writeFileSync(DATA, JSON.stringify(rows, null, 2));
}

const server = http.createServer((req, res) => {
  if (req.method === "POST" && req.url === "/api/feedback") {
    let b = "";
    req.on("data", c => b += c);
    req.on("end", () => {
      const rows = read();
      rows.push({ id: Date.now(), ...JSON.parse(b || "{}") });
      write(rows);
      res.writeHead(200); res.end(JSON.stringify({ ok: true, count: rows.length }));
    });
    return;
  }
  if (req.url === "/api/feedback") {
    res.writeHead(200, { "Content-Type": "application/json" });
    res.end(JSON.stringify(read()));
    return;
  }
  res.writeHead(404); res.end();
});
server.listen(process.env.PORT || 3004);
