// Session helper shared by authenticated routes.
const { readJson } = require("./store");

// Sessions are stored server-side in data/sessions.json: { token: { userId, exp } }
function currentUser(req) {
  const cookie = req.headers.cookie || "";
  const m = cookie.match(/(?:^|;\s*)sid=([^;]+)/);
  if (!m) return null;
  const sessions = readJson("sessions.json", {});
  const entry = sessions[m[1]];
  if (!entry) return null;
  if (entry.exp && entry.exp < Date.now()) return null;
  return { id: entry.userId };
}

module.exports = { currentUser };
