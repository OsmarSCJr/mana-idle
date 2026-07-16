import { cloudflareTest, readD1Migrations } from "@cloudflare/vitest-pool-workers";
import { defineConfig } from "vitest/config";

export default defineConfig({
  plugins: [
    cloudflareTest(async () => ({
      wrangler: { configPath: "./wrangler.jsonc" },
      miniflare: {
        bindings: {
          MAIN_MIGRATIONS: await readD1Migrations("./migrations/main"),
          DELETION_MIGRATIONS: await readD1Migrations("./migrations/deletions"),
          LIVEOPS_MIGRATIONS: await readD1Migrations("./migrations/liveops"),
          TOKEN_PEPPER_V1: "test-token-pepper-v1-32-bytes-minimum-value",
          RECOVERY_PEPPER_V1: "test-recovery-pepper-v1-32-bytes-minimum",
          DELETION_PEPPER_V1: "test-deletion-pepper-v1-32-bytes-minimum",
          TOKEN_PEPPER_V2: "test-token-pepper-v2-32-bytes-minimum-value",
          RECOVERY_PEPPER_V2: "test-recovery-pepper-v2-32-bytes-minimum",
          DEV_ADMIN_TOKEN: "test-admin-token-with-more-than-thirty-two-random-like-characters",
        },
      },
    })),
  ],
  test: {
    include: ["test/**/*.test.ts"],
    testTimeout: 20_000,
    hookTimeout: 20_000,
  },
});
