const http = require("http");
const { handle } = require("./src/router");

const PORT = process.env.PORT || 4200;
http.createServer((req, res) => handle(req, res))
  .listen(PORT, () => console.log(`ticketing on :${PORT}`));
