import { defineConfig, loadEnv } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), "");
  const target = env.VITE_ADMIN_API_URL?.replace(/\/+$/, "");
  const devToken = env.ADMIN_DEV_TOKEN?.trim();

  return {
    plugins: [react()],
    build: {
      target: "es2022",
      cssCodeSplit: true,
      sourcemap: false,
    },
    server: target
      ? {
          proxy: {
            "/api": {
              target,
              changeOrigin: true,
              rewrite: (path) => path.replace(/^\/api/, ""),
              headers: devToken ? { Authorization: `Bearer ${devToken}` } : undefined,
            },
          },
        }
      : undefined,
  };
});
