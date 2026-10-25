import { renderSummary } from "./ui/summary.js";
import { loadConfig } from "./config.js";
import { fetchMetrics } from "./api/metrics.js";

const cfg = loadConfig();
renderSummary(document.getElementById("root"), cfg);
fetchMetrics(cfg.apiBase).then(rows => {
  document.getElementById("root").dataset.rows = String(rows.length);
});
