const fs = require("fs");
const path = require("path");

const DATA = path.join(__dirname, "..", "..", "data");

function readJson(name, fallback) {
  try {
    return JSON.parse(fs.readFileSync(path.join(DATA, name), "utf8"));
  } catch {
    return fallback;
  }
}

function writeJson(name, value) {
  fs.writeFileSync(path.join(DATA, name), JSON.stringify(value, null, 2));
}

module.exports = { readJson, writeJson };
