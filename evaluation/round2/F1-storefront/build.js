// Copies public/ to dist/ and rewrites /assets/ paths for the CDN prefix.
const fs = require("fs");
const path = require("path");

const SRC = path.join(__dirname, "public");
const OUT = path.join(__dirname, "dist");
const PREFIX = process.env.CDN_PREFIX || "/assets/";

fs.rmSync(OUT, { recursive: true, force: true });
fs.mkdirSync(OUT, { recursive: true });

for (const f of fs.readdirSync(SRC)) {
  let html = fs.readFileSync(path.join(SRC, f), "utf8");
  html = html.replace(/__ASSET__/g, PREFIX);
  fs.writeFileSync(path.join(OUT, f), html);
}
console.log("built dist/");
