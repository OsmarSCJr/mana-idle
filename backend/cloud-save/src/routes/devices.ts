import { Hono } from "hono";

import { ApiError, asServiceUnavailable } from "../errors";
import { unixNow } from "../http";
import { requireGameSession, requirePlayerAuth } from "../middleware/auth";
import { enforceRateLimit } from "../middleware/rate-limit";
import type { AppHonoEnv } from "../types";
import { deviceIdParam } from "../validation/schemas";

interface DeviceRow {
  id: string;
  label: string | null;
  client_version: string | null;
  kind: "game" | "web_deletion";
  created_at: number;
  last_seen_at: number;
  revoked_at: number | null;
  active_sessions: number;
}

const devices = new Hono<AppHonoEnv>();
devices.use("*", requirePlayerAuth);

devices.get("/devices", async (c) => {
  const auth = requireGameSession(c);
  const now = unixNow();
  let rows: DeviceRow[];
  try {
    const result = await c.env.DB.prepare(
      `SELECT d.id, d.label, d.client_version, d.kind, d.created_at, d.last_seen_at, d.revoked_at,
              COUNT(s.id) AS active_sessions
       FROM devices d
       LEFT JOIN sessions s ON s.device_id = d.id AND s.revoked_at IS NULL
         AND s.idle_expires_at > ? AND s.absolute_expires_at > ?
       WHERE d.player_id = ?
       GROUP BY d.id
       ORDER BY d.last_seen_at DESC`,
    ).bind(now, now, auth.playerId).all<DeviceRow>();
    rows = result.results;
  } catch (error) {
    asServiceUnavailable(error);
  }
  return c.json({
    items: rows.map((row) => ({
      id: row.id,
      label: row.label,
      clientVersion: row.client_version,
      kind: row.kind,
      createdAt: row.created_at,
      lastSeenAt: row.last_seen_at,
      revokedAt: row.revoked_at,
      isCurrent: row.id === auth.deviceId,
      activeSessions: row.active_sessions,
    })),
    serverNow: now,
  });
});

devices.delete("/devices/:deviceId", async (c) => {
  const auth = requireGameSession(c);
  const parsed = deviceIdParam.safeParse(c.req.param("deviceId"));
  if (!parsed.success) throw new ApiError(400, "INVALID_DEVICE_ID", "O identificador do aparelho é inválido.");
  await enforceRateLimit(c.env.SECURITY_LIMITER, `revoke-device:${auth.playerId}`);
  const now = unixNow();
  try {
    const results = await c.env.DB.batch([
      c.env.DB.prepare(
        "UPDATE devices SET revoked_at = ? WHERE id = ? AND player_id = ? AND revoked_at IS NULL",
      ).bind(now, parsed.data, auth.playerId),
      c.env.DB.prepare(
        "UPDATE sessions SET revoked_at = ? WHERE device_id = ? AND player_id = ? AND revoked_at IS NULL",
      ).bind(now, parsed.data, auth.playerId),
    ]);
    if ((results[0]?.meta.changes ?? 0) !== 1) {
      throw new ApiError(404, "DEVICE_NOT_FOUND", "O aparelho não foi encontrado ou já está revogado.");
    }
    return c.json({
      revoked: true,
      deviceId: parsed.data,
      revokedSessions: results[1]?.meta.changes ?? 0,
      serverNow: now,
    });
  } catch (error) {
    if (error instanceof ApiError) throw error;
    asServiceUnavailable(error);
  }
});

export default devices;
