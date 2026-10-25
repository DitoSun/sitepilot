// Serverless lead capture. Writes into the CRM webhook.
const https = require("https");

exports.handler = async (event) => {
  const body = JSON.parse(event.body || "{}");
  if (!body.email) return { statusCode: 400, body: "email required" };

  const payload = JSON.stringify({
    email: body.email,
    source: "landing",
    at: new Date().toISOString(),
  });

  await new Promise((resolve, reject) => {
    const req = https.request(
      {
        hostname: "hooks.internal",
        path: "/crm/lead",
        method: "POST",
        headers: { "Content-Type": "application/json", "Content-Length": Buffer.byteLength(payload) },
      },
      res => { res.resume(); resolve(); }
    );
    req.on("error", reject);
    req.write(payload);
    req.end();
  });

  return { statusCode: 200, body: "thanks" };
};
