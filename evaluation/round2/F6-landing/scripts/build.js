// Renders content/*.json into dist/ from templates in site/.
const fs = require("fs");
const path = require("path");

const ROOT = path.join(__dirname, "..");
const SITE = path.join(ROOT, "site");
const CONTENT = path.join(ROOT, "content");
const OUT = path.join(ROOT, "dist");

fs.rmSync(OUT, { recursive: true, force: true });
fs.mkdirSync(OUT, { recursive: true });

const copy = (dir) => {
  for (const f of fs.readdirSync(dir, { withFileTypes: true })) {
    const src = path.join(dir, f.name);
    const dst = path.join(OUT, path.relative(SITE, src));
    if (f.isDirectory()) { fs.mkdirSync(dst, { recursive: true }); copy(src); }
    else { fs.mkdirSync(path.dirname(dst), { recursive: true }); fs.copyFileSync(src, dst); }
  }
};
copy(SITE);

for (const f of fs.readdirSync(CONTENT)) {
  const data = JSON.parse(fs.readFileSync(path.join(CONTENT, f), "utf8"));
  const target = path.join(OUT, data.page);
  if (fs.existsSync(target)) {
    let html = fs.readFileSync(target, "utf8");
    for (const [k, v] of Object.entries(data.slots || {})) {
      html = html.split(`{{${k}}}`).join(v);
    }
    fs.writeFileSync(target, html);
  }
}
console.log("build ok -> dist/");
