import { Hono } from "hono";

import { getOperationalSettings } from "./db/settings";
import { errorHandler } from "./errors";
import { noStoreHeaders, unixNow } from "./http";
import { requestMiddleware } from "./middleware/request";
import adminLiveOps from "./routes/admin-liveops";
import admin from "./routes/admin";
import devices from "./routes/devices";
import identity from "./routes/identity";
import liveOps from "./routes/liveops";
import saves from "./routes/saves";
import security from "./routes/security";
import sessions from "./routes/sessions";
import wallet from "./routes/wallet";
import { runScheduledMaintenance } from "./scheduled";
import type { AppHonoEnv } from "./types";

const app = new Hono<AppHonoEnv>();
app.use("*", requestMiddleware);

app.get("/health", (c) => c.json({ status: "ok", serverNow: unixNow() }));

app.get("/v1/status", async (c) => {
  const settings = await getOperationalSettings(c.env.DB);
  return c.json({
    maintenanceMode: settings.maintenanceMode,
    readOnlyUploads: settings.readOnlyUploads,
    allowNewAccounts: settings.allowNewAccounts,
    minClientVersion: settings.minClientVersion,
    serverNow: unixNow(),
  }, 200, noStoreHeaders());
});

// Register the administrative namespace before the player routers. Several
// player routers use wildcard auth middleware when mounted at /v1, so they
// must not get a chance to treat /v1/admin/* as a game-session request.
app.route("/v1/admin/liveops", adminLiveOps);
app.route("/v1/admin", admin);
app.route("/v1", liveOps);
app.route("/v1", identity);
app.route("/v1", sessions);
app.route("/v1", devices);
app.route("/v1", saves);
app.route("/v1", security);
app.route("/v1", wallet);

app.notFound((c) => c.json({
  error: {
    code: "NOT_FOUND",
    message: "A rota solicitada não existe.",
    requestId: c.get("requestId"),
  },
}, 404));
app.onError(errorHandler);

export { app };

export default {
  fetch: app.fetch,
  scheduled(_event: ScheduledController, env: Env, ctx: ExecutionContext): void {
    ctx.waitUntil(runScheduledMaintenance(env));
  },
} satisfies ExportedHandler<Env>;
