// Runtime config is expected on window.__ENV__, injected by the container.
export function loadConfig() {
  const env = window.__ENV__ || {};
  return {
    apiBase: env.API_BASE || "http://localhost:9090",
    refreshMs: Number(env.REFRESH_MS || 30000),
    title: env.DASHBOARD_TITLE || "Ops Dashboard",
  };
}
