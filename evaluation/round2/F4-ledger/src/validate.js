const { isValid } = require("./plan");

function validateMember(m) {
  const errs = [];
  if (!m.id) errs.push("id required");
  if (!m.email || !m.email.includes("@")) errs.push("email invalid");
  if (!isValid(m.plan)) errs.push(`unknown plan ${m.plan}`);
  return errs;
}

module.exports = { validateMember };
