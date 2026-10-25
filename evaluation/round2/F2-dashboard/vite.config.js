import { defineConfig } from "vite";

export default defineConfig({
  build: { outDir: "dist", assetsDir: "assets" },
  base: process.env.PUBLIC_BASE || "/",
});
