import { Hono } from "hono";

import { ApiError, asServiceUnavailable } from "../errors";
import { readBoundedJson, unixNow } from "../http";
import { requireGameSession, requirePlayerAuth } from "../middleware/auth";
import { enforceRateLimit } from "../middleware/rate-limit";
import {
  generateRecoveryCode,
  getCredentialKeyVersion,
  hmacHex,
  normalizeRecoveryCode,
  secureStringEqual,
} from "../security/crypto";
import { recoveryPepper } from "../security/peppers";
import { deletePlayerAccount } from "../services/deletion";
import { enforceOperationalState } from "../services/operations";
import type { AppHonoEnv } from "../types";
import {
  actionIdParam,
  deleteAccountSchema,
  rotateRecoverySchema,
} from "../validation/schemas";

interface RecoveryRow {
  recovery_hash: string;
  recovery_key_version: number;
}

interface SecurityActionRow {
  id: string;
  kind: "recovery_reset" | "account_delete";
  status: "pending" | "cancelled" | "completed";
  requested_by_device_id: string;
  execute_after: number;
  created_at: number;
  cancelled_at: number | null;
  completed_at: number | null;
}

const security = new Hono<AppHonoEnv>();
security.use("*", requirePlayerAuth);

security.post("/recovery-code/rotate", async (c) => {
  const auth = requireGameSession(c);
  await enforceOperationalState(c.env, "security", c.req.header("x-client-version"));
  await enforceRateLimit(c.env.SECURITY_LIMITER, `rotate-recovery:${auth.playerId}`);
  const body = await readBoundedJson(c, rotateRecoverySchema);
  const normalized = normalizeRecoveryCode(body.recoveryCode);
  const oldVersion = normalized === null ? null : getCredentialKeyVersion(normalized, "R");
  if (normalized === null || oldVersion === null) {
    throw new ApiError(401, "INVALID_RECOVERY", "O código de recuperação é inválido.");
  }
  const oldHash = await hmacHex(recoveryPepper(c.env, oldVersion), normalized);
  const newVersion = Number(c.env.CURRENT_RECOVERY_KEY_VERSION);
  const newCode = generateRecoveryCode(newVersion);
  const normalizedNew = normalizeRecoveryCode(newCode);
  if (normalizedNew === null) throw new ApiError(500, "CREDENTIAL_GENERATION_FAILED", "A credencial não pôde ser criada.");
  const newHash = await hmacHex(recoveryPepper(c.env, newVersion), normalizedNew);
  const now = unixNow();
  try {
    const results = await c.env.DB.batch([
      c.env.DB.prepare(
        `UPDATE players
         SET recovery_hash = ?, recovery_key_version = ?, recovery_rotated_at = ?
         WHERE id = ? AND recovery_hash = ? AND recovery_key_version = ? AND status = 'active'`,
      ).bind(newHash, newVersion, now, auth.playerId, oldHash, oldVersion),
      c.env.DB.prepare(
        `UPDATE security_actions SET status = 'cancelled', cancelled_at = ?
         WHERE player_id = ? AND status = 'pending'
           AND EXISTS (
             SELECT 1 FROM players
             WHERE id = security_actions.player_id AND recovery_hash = ? AND recovery_rotated_at = ?
           )`,
      ).bind(now, auth.playerId, newHash, now),
      c.env.DB.prepare(
        `UPDATE sessions SET revoked_at = ?
         WHERE player_id = ? AND id <> ? AND revoked_at IS NULL
           AND EXISTS (
             SELECT 1 FROM players
             WHERE id = sessions.player_id AND recovery_hash = ? AND recovery_rotated_at = ?
           )`,
      ).bind(now, auth.playerId, auth.sessionId, newHash, now),
    ]);
    if ((results[0]?.meta.changes ?? 0) !== 1) {
      throw new ApiError(401, "INVALID_RECOVERY", "O código de recuperação é inválido.");
    }
    return c.json({
      recoveryCode: newCode,
      recoveryRotatedAt: now,
      pendingActionsCancelled: results[1]?.meta.changes ?? 0,
      otherSessionsRevoked: results[2]?.meta.changes ?? 0,
      serverNow: now,
    });
  } catch (error) {
    if (error instanceof ApiError) throw error;
    asServiceUnavailable(error);
  }
});

security.post("/security/recovery-reset", async (c) => {
  const auth = requireGameSession(c);
  await enforceOperationalState(c.env, "security", c.req.header("x-client-version"));
  await enforceRateLimit(c.env.SECURITY_LIMITER, `reset-recovery:${auth.playerId}`);
  const now = unixNow();
  const action = {
    id: crypto.randomUUID(),
    kind: "recovery_reset" as const,
    status: "pending" as const,
    executeAfter: now + 86_400,
    createdAt: now,
  };
  try {
    await c.env.DB.prepare(
      `INSERT INTO security_actions
         (id, player_id, kind, status, requested_by_device_id, execute_after, created_at)
       VALUES (?, ?, 'recovery_reset', 'pending', ?, ?, ?)`,
    ).bind(action.id, auth.playerId, auth.deviceId, action.executeAfter, now).run();
  } catch (error) {
    if (error instanceof Error && error.name === "Error") {
      const existing = await c.env.DB.prepare(
        `SELECT id, execute_after, created_at FROM security_actions
         WHERE player_id = ? AND kind = 'recovery_reset' AND status = 'pending'`,
      ).bind(auth.playerId).first<{ id: string; execute_after: number; created_at: number }>();
      if (existing !== null) {
        throw new ApiError(409, "SECURITY_ACTION_PENDING", "Já existe uma redefinição pendente.", {
          action: {
            id: existing.id,
            kind: "recovery_reset",
            status: "pending",
            executeAfter: existing.execute_after,
            createdAt: existing.created_at,
          },
        });
      }
    }
    asServiceUnavailable(error);
  }
  return c.json({ action, serverNow: now }, 202);
});

security.get("/security/actions", async (c) => {
  const auth = requireGameSession(c);
  const now = unixNow();
  let rows: SecurityActionRow[];
  try {
    const result = await c.env.DB.prepare(
      `SELECT id, kind, status, requested_by_device_id, execute_after, created_at, cancelled_at, completed_at
       FROM security_actions WHERE player_id = ?
       ORDER BY created_at DESC LIMIT 20`,
    ).bind(auth.playerId).all<SecurityActionRow>();
    rows = result.results;
  } catch (error) {
    asServiceUnavailable(error);
  }
  return c.json({
    items: rows.map((row) => ({
      id: row.id,
      kind: row.kind,
      status: row.status,
      requestedByThisDevice: row.requested_by_device_id === auth.deviceId,
      executeAfter: row.execute_after,
      createdAt: row.created_at,
      cancelledAt: row.cancelled_at,
      completedAt: row.completed_at,
    })),
    serverNow: now,
  });
});

security.delete("/security/actions/:actionId", async (c) => {
  const auth = requireGameSession(c);
  const parsed = actionIdParam.safeParse(c.req.param("actionId"));
  if (!parsed.success) throw new ApiError(400, "INVALID_ACTION_ID", "A ação de segurança é inválida.");
  await enforceRateLimit(c.env.SECURITY_LIMITER, `cancel-security:${auth.playerId}`);
  const now = unixNow();
  try {
    const result = await c.env.DB.prepare(
      `UPDATE security_actions SET status = 'cancelled', cancelled_at = ?
       WHERE id = ? AND player_id = ? AND status = 'pending'`,
    ).bind(now, parsed.data, auth.playerId).run();
    if (result.meta.changes !== 1) throw new ApiError(404, "ACTION_NOT_FOUND", "A ação pendente não foi encontrada.");
  } catch (error) {
    if (error instanceof ApiError) throw error;
    asServiceUnavailable(error);
  }
  return c.body(null, 204);
});

security.post("/security/actions/:actionId/complete", async (c) => {
  const auth = requireGameSession(c);
  const parsed = actionIdParam.safeParse(c.req.param("actionId"));
  if (!parsed.success) throw new ApiError(400, "INVALID_ACTION_ID", "A ação de segurança é inválida.");
  await enforceRateLimit(c.env.SECURITY_LIMITER, `complete-security:${auth.playerId}`);
  const now = unixNow();
  let action: SecurityActionRow | null;
  let currentRecovery: RecoveryRow | null;
  try {
    [action, currentRecovery] = await Promise.all([
      c.env.DB.prepare(
        `SELECT id, kind, status, requested_by_device_id, execute_after, created_at, cancelled_at, completed_at
         FROM security_actions WHERE id = ? AND player_id = ?`,
      ).bind(parsed.data, auth.playerId).first<SecurityActionRow>(),
      c.env.DB.prepare("SELECT recovery_hash, recovery_key_version FROM players WHERE id = ? AND status = 'active'")
        .bind(auth.playerId).first<RecoveryRow>(),
    ]);
  } catch (error) {
    asServiceUnavailable(error);
  }
  if (action === null || currentRecovery === null || action.status !== "pending") {
    throw new ApiError(404, "ACTION_NOT_FOUND", "A ação pendente não foi encontrada.");
  }
  if (action.kind !== "recovery_reset") {
    throw new ApiError(422, "ACTION_COMPLETES_AUTOMATICALLY", "A exclusão é concluída automaticamente após o prazo.");
  }
  if (action.requested_by_device_id !== auth.deviceId) {
    throw new ApiError(403, "INITIATING_DEVICE_REQUIRED", "Somente o aparelho que iniciou pode concluir a redefinição.");
  }
  if (action.execute_after > now) {
    throw new ApiError(409, "SECURITY_DELAY_ACTIVE", "O prazo de segurança ainda não terminou.", {
      executeAfter: action.execute_after,
    });
  }

  const version = Number(c.env.CURRENT_RECOVERY_KEY_VERSION);
  const recoveryCode = generateRecoveryCode(version);
  const normalized = normalizeRecoveryCode(recoveryCode);
  if (normalized === null) throw new ApiError(500, "CREDENTIAL_GENERATION_FAILED", "A credencial não pôde ser criada.");
  const hash = await hmacHex(recoveryPepper(c.env, version), normalized);
  try {
    const results = await c.env.DB.batch([
      c.env.DB.prepare(
        `UPDATE players
         SET recovery_hash = ?, recovery_key_version = ?, recovery_rotated_at = ?
         WHERE id = ? AND recovery_hash = ? AND recovery_key_version = ?
           AND EXISTS (
             SELECT 1 FROM security_actions
             WHERE id = ? AND player_id = players.id AND kind = 'recovery_reset'
               AND status = 'pending' AND requested_by_device_id = ? AND execute_after <= ?
           )`,
      ).bind(
        hash, version, now, auth.playerId, currentRecovery.recovery_hash,
        currentRecovery.recovery_key_version, action.id, auth.deviceId, now,
      ),
      c.env.DB.prepare(
        `UPDATE security_actions SET status = 'completed', completed_at = ?
         WHERE id = ? AND player_id = ? AND status = 'pending'
           AND requested_by_device_id = ? AND execute_after <= ?`,
      ).bind(now, action.id, auth.playerId, auth.deviceId, now),
      c.env.DB.prepare(
        `UPDATE sessions SET revoked_at = ?
         WHERE player_id = ? AND id <> ? AND revoked_at IS NULL`,
      ).bind(now, auth.playerId, auth.sessionId),
    ]);
    if ((results[0]?.meta.changes ?? 0) !== 1 || (results[1]?.meta.changes ?? 0) !== 1) {
      throw new ApiError(409, "SECURITY_ACTION_CHANGED", "A ação já foi alterada em outro aparelho.");
    }
    return c.json({
      recoveryCode,
      recoveryRotatedAt: now,
      otherSessionsRevoked: results[2]?.meta.changes ?? 0,
      serverNow: now,
    });
  } catch (error) {
    if (error instanceof ApiError) throw error;
    asServiceUnavailable(error);
  }
});

security.delete("/account", async (c) => {
  const auth = c.get("auth");
  await enforceOperationalState(c.env, "deletion");
  await enforceRateLimit(c.env.SECURITY_LIMITER, `delete-account:${auth.playerId}`);
  const body = await readBoundedJson(c, deleteAccountSchema);
  const now = unixNow();

  if (body.recoveryCode === undefined) {
    if (auth.purpose !== "game") {
      throw new ApiError(422, "RECOVERY_REQUIRED", "O código de recuperação é obrigatório nesta página.");
    }
    const action = {
      id: crypto.randomUUID(),
      kind: "account_delete" as const,
      status: "pending" as const,
      executeAfter: now + 7 * 86_400,
      createdAt: now,
    };
    try {
      await c.env.DB.prepare(
        `INSERT INTO security_actions
           (id, player_id, kind, status, requested_by_device_id, execute_after, created_at)
         VALUES (?, ?, 'account_delete', 'pending', ?, ?, ?)`,
      ).bind(action.id, auth.playerId, auth.deviceId, action.executeAfter, now).run();
    } catch (error) {
      const existing = await c.env.DB.prepare(
        `SELECT id, execute_after, created_at FROM security_actions
         WHERE player_id = ? AND kind = 'account_delete' AND status = 'pending'`,
      ).bind(auth.playerId).first<{ id: string; execute_after: number; created_at: number }>();
      if (existing !== null) {
        throw new ApiError(409, "SECURITY_ACTION_PENDING", "Já existe uma exclusão pendente.", {
          action: {
            id: existing.id,
            kind: "account_delete",
            status: "pending",
            executeAfter: existing.execute_after,
            createdAt: existing.created_at,
          },
        });
      }
      asServiceUnavailable(error);
    }
    return c.json({ action, serverNow: now }, 202);
  }

  const normalized = normalizeRecoveryCode(body.recoveryCode);
  const version = normalized === null ? null : getCredentialKeyVersion(normalized, "R");
  if (normalized === null || version === null) throw new ApiError(401, "INVALID_RECOVERY", "O código de recuperação é inválido.");
  const providedHash = await hmacHex(recoveryPepper(c.env, version), normalized);
  let expected: RecoveryRow | null;
  try {
    expected = await c.env.DB.prepare(
      "SELECT recovery_hash, recovery_key_version FROM players WHERE id = ? AND status = 'active'",
    ).bind(auth.playerId).first<RecoveryRow>();
  } catch (error) {
    asServiceUnavailable(error);
  }
  if (expected?.recovery_key_version !== version
    || !await secureStringEqual(providedHash, expected.recovery_hash)) {
    throw new ApiError(401, "INVALID_RECOVERY", "O código de recuperação é inválido.");
  }
  await deletePlayerAccount(c.env, auth.playerId);
  return c.body(null, 204);
});

export default security;
