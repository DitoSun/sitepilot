// Syncs dist/ to the bucket that serves the live domain.
const { execSync } = require("child_process");
const path = require("path");

const DIST = path.join(__dirname, "..", "dist");
const BUCKET = process.env.BUCKET || "s3://acme-site-live";

console.log(`publishing ${DIST} -> ${BUCKET}`);
execSync(`aws s3 sync ${DIST} ${BUCKET} --delete`, { stdio: "inherit" });
console.log("published");
