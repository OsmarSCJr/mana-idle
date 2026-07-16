import type { MiddlewareHandler } from "hono";

import { ApiError, asServiceUnavailable } from "../errors";
import { unixNow } from "../http";
import { getCredentialKeyVersion, hmacHex } from "../security/crypto";
import { tokenPepper } from "../security/peppers";
import type { AppHonoEnv, AuthContext } from "../types";

interface SessionAuthRow {
  session_id: string;
  player_id: string;
  device_id: string;
  purpose: "game" | "account_deletion";
  last_seen_at: number;
  absolute_expires_at: number;
}

export const requirePlayerAuth: MiddlewareHandler<AppHonoEnv> = async (c, next) => {
  const authorization = c.req.header("authorization");
  const token = authorization?.startsWith("Bearer ") === true ? authorization.slice(7).trim() : "";
  const keyVersion = getCredentialKeyVersion(token, "S");
  if (token === "" || keyVersion === null) {
    throw new ApiError(401, "INVALID_SESSION", "A sessão é inválida ou expirou.");
  }

  const now = unixNow();
  const tokenHash = await hmacHex(tokenPepper(c.env, keyVersion), token);
  let row: SessionAuthRow | null;
  try {
    row = await c.env.DB.prepare(
      `SELECT s.id AS session_id, s.player_id, s.device_id, s.purpose,
              s.last_seen_at, s.absolute_expires_at
       FROM sessions s
       JOIN devices d ON d.id = s.device_id AND d.player_id = s.player_id
       JOIN players p ON p.id = s.player_id
       WHERE s.token_hash = ?
         AND s.token_key_version = ?
         AND s.revoked_at IS NULL
         AND s.idle_expires_at > ?
         AND s.absolute_expires_at > ?
         AND d.revoked_at IS NULL
         AND p.status = 'active'`,
    ).bind(tokenHash, keyVersion, now, now).first<SessionAuthRow>();
  } catch (error) {
    asServiceUnavailable(error);
  }
  if (row === null) throw new ApiError(401, "INVALID_SESSION", "A sessão é inválida ou expirou.");

  const path = new URL(c.req.url).pathname;
  if (row.purpose === "account_deletion" && path !== "/v1/account" && path !== "/v1/sessions/logout") {
    throw new ApiError(403, "SESSION_PURPOSE_RESTRICTED", "Esta sessão só pode excluir a conta.");
  }

  const auth: AuthContext = {
    sessionId: row.session_id,
    playerId: row.player_id,
    deviceId: row.device_id,
    purpose: row.purpose,
    absoluteExpiresAt: row.absolute_expires_at,
  };
  c.set("auth", auth);

  if (now - row.last_seen_at >= 86_400) {
    const idleExpiry = Math.min(now + 180 * 86_400, row.absolute_expires_at);
    try {
      await c.env.DB.batch([
        c.env.DB.prepare(
          `UPDATE sessions SET last_seen_at = ?, idle_expires_at = ?
           WHERE id = ? AND revoked_at IS NULL`,
        ).bind(now, idleExpiry, row.session_id),
        c.env.DB.prepare("UPDATE devices SET last_seen_at = ? WHERE id = ? AND revoked_at IS NULL")
          .bind(now, row.device_id),
      ]);
    } catch (error) {
      asServiceUnavailable(error);
    }
  }
  await next();
};

export function requireGameSession(c: { get(name: "auth"): AuthContext }): AuthContext {
  const auth = c.get("auth");
  if (auth.purpose !== "game") {
    throw new ApiError(403, "SESSION_PURPOSE_RESTRICTED", "Esta operação exige uma sessão do jogo.");
  }
  return auth;
}
