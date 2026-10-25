const fs = require("fs"), path = require("path");
const src = path.join(__dirname, "src");
const out = path.join(__dirname, "dist");
fs.rmSync(out, { recursive: true, force: true });
fs.mkdirSync(out, { recursive: true });
for (const f of fs.readdirSync(src)) {
  fs.copyFileSync(path.join(src, f), path.join(out, f));
}
console.log("build ok -> dist/ (" + fs.readdirSync(out).length + " files)");
