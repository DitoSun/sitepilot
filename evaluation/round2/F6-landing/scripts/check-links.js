// Rough internal link check over dist/.
const fs = require("fs");
const path = require("path");
const DIST = path.join(__dirname, "..", "dist");

function walk(d, out = []) {
  for (const f of fs.readdirSync(d, { withFileTypes: true })) {
    const p = path.join(d, f.name);
    f.isDirectory() ? walk(p, out) : out.push(p);
  }
  return out;
}

if (fs.existsSync(DIST)) {
  for (const f of walk(DIST).filter(f => f.endsWith(".html"))) {
    const html = fs.readFileSync(f, "utf8");
    const links = [...html.matchAll(/href="(\/[^"]*)"/g)].map(m => m[1]);
    for (const l of links) {
      const target = path.join(DIST, l.replace(/^\//, ""));
      if (!fs.existsSync(target) && !fs.existsSync(target + ".html")) {
        console.log("broken:", path.relative(DIST, f), "->", l);
      }
    }
  }
}
