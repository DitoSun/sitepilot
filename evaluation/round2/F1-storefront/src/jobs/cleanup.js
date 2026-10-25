// Nightly: drop carts older than 30 days and prune the access log.
const fs = require("fs");
const path = require("path");

const DATA = path.join(__dirname, "..", "..", "data");
const LOGS = path.join(__dirname, "..", "..", "logs");

function pruneCarts() {
  const file = path.join(DATA, "carts.json");
  if (!fs.existsSync(file)) return;
  const carts = JSON.parse(fs.readFileSync(file, "utf8"));
  const cutoff = Date.now() - 30 * 24 * 3600 * 1000;
  const kept = carts.filter(c => c.updatedAt > cutoff);
  fs.writeFileSync(file, JSON.stringify(kept, null, 2));
  console.log(`carts: ${carts.length} -> ${kept.length}`);
}

function pruneLogs() {
  if (!fs.existsSync(LOGS)) return;
  for (const f of fs.readdirSync(LOGS)) {
    const full = path.join(LOGS, f);
    const st = fs.statSync(full);
    if (Date.now() - st.mtimeMs > 90 * 24 * 3600 * 1000) {
      fs.unlinkSync(full);
      console.log(`pruned log ${f}`);
    }
  }
}

pruneCarts();
pruneLogs();
