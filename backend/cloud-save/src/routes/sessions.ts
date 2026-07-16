import { Hono } from "hono";

import { asServiceUnavailable } from "../errors";
import { unixNow } from "../http";
import { requireGameSession, requirePlayerAuth } from "../middleware/auth";
import { enforceRateLimit } from "../middleware/rate-limit";
import type { AppHonoEnv } from "../types";

const sessions = new Hono<AppHonoEnv>();
sessions.use("*", requirePlayerAuth);

sessions.post("/sessions/logout", async (c) => {
  const auth = c.get("auth");
  const now = unixNow();
  try {
    await c.env.DB.batch([
      c.env.DB.prepare("UPDATE sessions SET revoked_at = ? WHERE id = ? AND revoked_at IS NULL")
        .bind(now, auth.sessionId),
      c.env.DB.prepare(
        `DELETE FROM devices
         WHERE id = ? AND kind = 'web_deletion'
           AND NOT EXISTS (
             SELECT 1 FROM sessions
             WHERE device_id = devices.id AND revoked_at IS NULL
               AND idle_expires_at > ? AND absolute_expires_at > ?
           )`,
      ).bind(auth.deviceId, now, now),
    ]);
  } catch (error) {
    asServiceUnavailable(error);
  }
  return c.body(null, 204);
});

sessions.post("/sessions/revoke-others", async (c) => {
  const auth = requireGameSession(c);
  await enforceRateLimit(c.env.SECURITY_LIMITER, `revoke-others:${auth.playerId}`);
  const now = unixNow();
  try {
    const result = await c.env.DB.prepare(
      `UPDATE sessions SET revoked_at = ?
       WHERE player_id = ? AND id <> ? AND revoked_at IS NULL`,
    ).bind(now, auth.playerId, auth.sessionId).run();
    return c.json({ revokedSessions: result.meta.changes, serverNow: now });
  } catch (error) {
    asServiceUnavailable(error);
  }
});

export default sessions;
