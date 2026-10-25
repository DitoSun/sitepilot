const fs = require("fs");
const path = require("path");
const crypto = require("crypto");

const DB = path.join(__dirname, "..", "data");

function read(name) {
  try { return JSON.parse(fs.readFileSync(path.join(DB, name), "utf8")); }
  catch { return null; }
}

function session(req) {
  const raw = req.headers.cookie || "";
  const m = raw.match(/(?:^|;\s*)sid=([^;]+)/);
  if (!m) return null;
  const sessions = read("sessions.json") || {};
  const s = sessions[m[1]];
  if (!s) return null;
  if (s.exp && s.exp < Date.now()) return null;
  return s; // { userId, role, exp }
}

function requireUser(req, res) {
  const s = session(req);
  if (!s) {
    res.writeHead(401, { "Content-Type": "application/json" });
    res.end(JSON.stringify({ error: "login required" }));
    return null;
  }
  return s;
}

function requireAdmin(req, res) {
  const s = requireUser(req, res);
  if (!s) return null;
  if (s.role !== "admin") {
    res.writeHead(403, { "Content-Type": "application/json" });
    res.end(JSON.stringify({ error: "forbidden" }));
    return null;
  }
  return s;
}

module.exports = { read, session, requireUser, requireAdmin, crypto };
