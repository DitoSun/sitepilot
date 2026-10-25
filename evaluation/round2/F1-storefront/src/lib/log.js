const fs = require("fs");
const path = require("path");

const LOG_DIR = process.env.LOG_DIR || path.join(__dirname, "..", "..", "logs");

function log(kind, fields) {
  const line = JSON.stringify({ t: new Date().toISOString(), kind, ...fields });
  try {
    fs.mkdirSync(LOG_DIR, { recursive: true });
    fs.appendFileSync(path.join(LOG_DIR, `${kind}.log`), line + "\n");
  } catch {
    // logging must never take the app down
  }
}

module.exports = { log };
