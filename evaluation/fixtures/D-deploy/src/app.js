// Client bundle path resolution
// In production the CDN serves assets from ASSET_PREFIX.
const PREFIX = process.env.ASSET_PREFIX || "/static/";
export const assetUrl = (f) => `${PREFIX}${f}`;
