import type { D1Migration } from "cloudflare:test";

declare global {
  namespace Cloudflare {
    interface Env {
      MAIN_MIGRATIONS: D1Migration[];
      DELETION_MIGRATIONS: D1Migration[];
      LIVEOPS_MIGRATIONS: D1Migration[];
    }
  }
}

declare module "cloudflare:test" {
  interface ProvidedEnv {
    MAIN_MIGRATIONS: D1Migration[];
    DELETION_MIGRATIONS: D1Migration[];
    LIVEOPS_MIGRATIONS: D1Migration[];
  }
}

export {};
