const fs = require("fs");
const path = require("path");

const DATA = path.join(__dirname, "..", "data");

function load(name) {
  return JSON.parse(fs.readFileSync(path.join(DATA, name), "utf8"));
}

function save(name, value) {
  fs.writeFileSync(path.join(DATA, name), JSON.stringify(value, null, 2));
}

function members() { return load("members.json"); }
function legacy() { return load("members.legacy.json"); }
function cache() {
  try { return load("cache/members.index.json"); } catch { return null; }
}

module.exports = { members, legacy, cache, save, load };
