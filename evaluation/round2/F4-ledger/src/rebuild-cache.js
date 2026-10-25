// Rebuilds data/cache/members.index.json from the primary store.
const fs = require("fs");
const path = require("path");
const store = require("./store");

const rows = store.members();
const index = {
  count: rows.length,
  builtAt: Date.now(),
  byEmail: Object.fromEntries(rows.map(r => [r.email, r.id])),
};

fs.mkdirSync(path.join(__dirname, "..", "data", "cache"), { recursive: true });
fs.writeFileSync(
  path.join(__dirname, "..", "data", "cache", "members.index.json"),
  JSON.stringify(index, null, 2)
);
console.log(`index rebuilt: ${rows.length} members`);
