export async function fetchMetrics(base) {
  const res = await fetch(`${base}/metrics`);
  if (!res.ok) throw new Error(`metrics ${res.status}`);
  return res.json();
}
