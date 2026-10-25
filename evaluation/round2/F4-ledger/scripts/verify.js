// Cross-check the three stores and print counts. Used before migrations.
const store = require("../src/store");

const p = store.members();
const l = store.legacy();
const c = store.cache();

console.log("primary:", p.length);
console.log("legacy :", l.length);
console.log("cache  :", c ? c.count : "missing");
