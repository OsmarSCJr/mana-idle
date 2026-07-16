import { Hono } from "hono";

import { getOperationalSettings } from "../db/settings";
import { ApiError, asServiceUnavailable } from "../errors";
import { noStoreHeaders, parseIfMatch, readBoundedJson, saveEtag, unixNow } from "../http";
import { requireAdmin } from "../middleware/admin";
import { pseudonymize } from "../security/crypto";
import { reconcileTombstones } from "../services/deletion";
import type { AppContext, AppHonoEnv, OperationalSettings, SaveRow } from "../types";
import {
  adminReasonSchema,
  deviceIdParam,
  operationsSchema,
  playerIdParam,
} from "../validation/schemas";

interface CountRow { value: number }
interface OverviewSaveRow { total: number; with_payload: number; avg_bytes: number; max_bytes: number }
interface PlayerListRow {
  player_id: string;
  status: "active" | "deleting";
  created_at: number;
  device_count: number;
  active_session_count: number;
  save_revision: number;
  save_bytes: number | null;
  save_updated_at: number | null;
  free_balance: number;
}
interface PlayerRow {
  id: string;
  status: "active" | "deleting";
  created_at: number;
  recovery_rotated_at: number | null;
  deletion_requested_at: number | null;
}
interface AdminDeviceRow {
  id: string;
  installation_id: string;
  label: string | null;
  client_version: string | null;
  kind: "game" | "web_deletion";
  created_at: number;
  last_seen_at: number;
  revoked_at: number | null;
}
interface AdminSessionRow {
  id: string;
  device_id: string;
  purpose: "game" | "account_deletion";
  created_at: number;
  last_seen_at: number;
  idle_expires_at: number;
  absolute_expires_at: number;
  revoked_at: number | null;
}
interface AdminWalletRow { free_balance: number; paid_balance: number; revision: number; updated_at: number }
interface AdminActionRow {
  id: string;
  kind: "recovery_reset" | "account_delete";
  status: "pending" | "cancelled" | "completed";
  requested_by_device_id: string;
  execute_after: number;
  created_at: number;
  cancelled_at: number | null;
  completed_at: number | null;
}
interface TombstoneRow {
  player_hmac: string;
  status: "pending" | "completed";
  requested_at: number;
  completed_at: number | null;
  expires_at: number;
  last_error_code: string | null;
}
interface AuditRow {
  id: string;
  actor: string;
  action: string;
  target_type: string;
  target_id_hash: string | null;
  reason: string;
  created_at: number;
  request_id: string;
}

const admin = new Hono<AppHonoEnv>();
admin.use("*", requireAdmin);

function parsedPlayerId(value: string): string {
  const result = playerIdParam.safeParse(value);
  if (!result.success) throw new ApiError(400, "INVALID_PLAYER_ID", "O identificador da conta é inválido.");
  return result.data;
}

function parsedDeviceId(value: string): string {
  const result = deviceIdParam.safeParse(value);
  if (!result.success) throw new ApiError(400, "INVALID_DEVICE_ID", "O identificador do aparelho é inválido.");
  return result.data;
}

async function auditStatement(
  c: AppContext,
  action: string,
  targetType: string,
  targetId: string | null,
  reason: string,
): Promise<D1PreparedStatement> {
  const targetHash = targetId === null ? null : await pseudonymize(c.env, targetId);
  return c.env.DB.prepare(
    `INSERT INTO admin_audit
       (id, actor, action, target_type, target_id_hash, reason, request_id, created_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
  ).bind(
    crypto.randomUUID(), c.get("admin").actor, action, targetType, targetHash, reason,
    c.get("requestId"), unixNow(),
  );
}

admin.get("/overview", async (c) => {
  const now = unixNow();
  try {
    const [result, pendingTombstones] = await Promise.all([
      c.env.DB.batch([
        c.env.DB.prepare("SELECT COUNT(*) AS value FROM players WHERE status = 'active'"),
        c.env.DB.prepare("SELECT COUNT(*) AS value FROM players WHERE status = 'deleting'"),
        c.env.DB.prepare(
          `SELECT COUNT(*) AS total,
                  SUM(CASE WHEN payload_json IS NOT NULL THEN 1 ELSE 0 END) AS with_payload,
                  COALESCE(AVG(payload_bytes), 0) AS avg_bytes,
                  COALESCE(MAX(payload_bytes), 0) AS max_bytes
           FROM cloud_saves`,
        ),
        c.env.DB.prepare(
          `SELECT COUNT(*) AS value FROM sessions
           WHERE revoked_at IS NULL AND idle_expires_at > ? AND absolute_expires_at > ?`,
        ).bind(now, now),
        c.env.DB.prepare("SELECT COALESCE(SUM(free_balance), 0) AS value FROM wallets"),
      ]),
      c.env.DELETIONS_DB.prepare(
        "SELECT COUNT(*) AS value FROM deletion_tombstones WHERE status = 'pending'",
      ).first<CountRow>(),
    ]);
    const activePlayers = result[0]?.results[0] as CountRow | undefined;
    const deletingPlayers = result[1]?.results[0] as CountRow | undefined;
    const saveStats = result[2]?.results[0] as OverviewSaveRow | undefined;
    const activeSessions = result[3]?.results[0] as CountRow | undefined;
    const freeOutstanding = result[4]?.results[0] as CountRow | undefined;
    return c.json({
      players: { active: activePlayers?.value ?? 0, deleting: deletingPlayers?.value ?? 0 },
      saves: {
        total: saveStats?.total ?? 0,
        withPayload: saveStats?.with_payload ?? 0,
        avgBytes: Math.round(saveStats?.avg_bytes ?? 0),
        maxBytes: saveStats?.max_bytes ?? 0,
      },
      sessions: { active: activeSessions?.value ?? 0 },
      deletions: { pending: pendingTombstones?.value ?? 0 },
      wallet: { freeOutstanding: freeOutstanding?.value ?? 0 },
      serverNow: now,
    }, 200, noStoreHeaders());
  } catch (error) {
    asServiceUnavailable(error);
  }
});

admin.get("/players", async (c) => {
  const query = (c.req.query("query") ?? "").trim();
  if (query.length > 36 || (query !== "" && !/^[a-fA-F0-9-]+$/u.test(query))) {
    throw new ApiError(400, "INVALID_QUERY", "A busca de conta é inválida.");
  }
  const limit = Math.min(Math.max(Number(c.req.query("limit") ?? "25") || 25, 1), 100);
  const cursor = c.req.query("cursor");
  const match = cursor === undefined ? null : /^(\d+):([0-9a-f-]{36})$/u.exec(cursor);
  if (cursor !== undefined && match === null) throw new ApiError(400, "INVALID_CURSOR", "O cursor é inválido.");
  const cursorCreated = match?.[1] === undefined ? Number.MAX_SAFE_INTEGER : Number(match[1]);
  const cursorId = match?.[2] ?? "ffffffff-ffff-ffff-ffff-ffffffffffff";
  try {
    const result = await c.env.DB.prepare(
      `SELECT p.id AS player_id, p.status, p.created_at,
              (SELECT COUNT(*) FROM devices d WHERE d.player_id = p.id) AS device_count,
              (SELECT COUNT(*) FROM sessions s WHERE s.player_id = p.id AND s.revoked_at IS NULL
                AND s.idle_expires_at > unixepoch() AND s.absolute_expires_at > unixepoch()) AS active_session_count,
              cs.revision AS save_revision, cs.payload_bytes AS save_bytes, cs.updated_at AS save_updated_at,
              w.free_balance
       FROM players p
       JOIN cloud_saves cs ON cs.player_id = p.id
       JOIN wallets w ON w.player_id = p.id
       WHERE (? = '' OR p.id LIKE ?)
         AND (p.created_at < ? OR (p.created_at = ? AND p.id < ?))
       ORDER BY p.created_at DESC, p.id DESC
       LIMIT ?`,
    ).bind(query, `${query}%`, cursorCreated, cursorCreated, cursorId, limit + 1).all<PlayerListRow>();
    const hasMore = result.results.length > limit;
    const rows = result.results.slice(0, limit);
    const last = rows.at(-1);
    return c.json({
      items: rows.map((row) => ({
        playerId: row.player_id,
        status: row.status,
        createdAt: row.created_at,
        deviceCount: row.device_count,
        activeSessionCount: row.active_session_count,
        saveRevision: row.save_revision,
        saveBytes: row.save_bytes,
        saveUpdatedAt: row.save_updated_at,
        freeBalance: row.free_balance,
      })),
      nextCursor: hasMore && last !== undefined ? `${last.created_at}:${last.player_id}` : null,
    }, 200, noStoreHeaders());
  } catch (error) {
    asServiceUnavailable(error);
  }
});

admin.get("/players/:playerId", async (c) => {
  const playerId = parsedPlayerId(c.req.param("playerId"));
  try {
    const result = await c.env.DB.batch([
      c.env.DB.prepare(
        "SELECT id, status, created_at, recovery_rotated_at, deletion_requested_at FROM players WHERE id = ?",
      ).bind(playerId),
      c.env.DB.prepare(
        `SELECT player_id, revision, schema_version, payload_json, payload_sha256, payload_bytes,
                previous_revision, previous_schema_version, previous_payload_json,
                previous_payload_sha256, previous_payload_bytes, previous_updated_at, updated_at
         FROM cloud_saves WHERE player_id = ?`,
      ).bind(playerId),
      c.env.DB.prepare(
        `SELECT id, installation_id, label, client_version, kind, created_at, last_seen_at, revoked_at
         FROM devices WHERE player_id = ? ORDER BY last_seen_at DESC`,
      ).bind(playerId),
      c.env.DB.prepare(
        `SELECT id, device_id, purpose, created_at, last_seen_at, idle_expires_at, absolute_expires_at, revoked_at
         FROM sessions WHERE player_id = ? ORDER BY created_at DESC LIMIT 100`,
      ).bind(playerId),
      c.env.DB.prepare(
        "SELECT free_balance, paid_balance, revision, updated_at FROM wallets WHERE player_id = ?",
      ).bind(playerId),
      c.env.DB.prepare(
        `SELECT id, kind, status, requested_by_device_id, execute_after, created_at, cancelled_at, completed_at
         FROM security_actions WHERE player_id = ? ORDER BY created_at DESC LIMIT 20`,
      ).bind(playerId),
    ]);
    const player = result[0]?.results[0] as PlayerRow | undefined;
    if (player === undefined) throw new ApiError(404, "PLAYER_NOT_FOUND", "A conta não foi encontrada.");
    const save = result[1]?.results[0] as SaveRow | undefined;
    const devices = (result[2]?.results ?? []) as unknown as AdminDeviceRow[];
    const sessions = (result[3]?.results ?? []) as unknown as AdminSessionRow[];
    const wallet = result[4]?.results[0] as AdminWalletRow | undefined;
    const actions = (result[5]?.results ?? []) as unknown as AdminActionRow[];
    return c.json({
      player: {
        playerId: player.id,
        status: player.status,
        createdAt: player.created_at,
        recoveryRotatedAt: player.recovery_rotated_at,
        deletionRequestedAt: player.deletion_requested_at,
      },
      save: save === undefined ? null : {
        revision: save.revision,
        schemaVersion: save.schema_version,
        sha256: save.payload_sha256,
        bytes: save.payload_bytes,
        updatedAt: save.updated_at,
        previousRevision: save.previous_revision,
        previousUpdatedAt: save.previous_updated_at,
      },
      devices: devices.map((row) => ({
        deviceId: row.id, installationId: row.installation_id, deviceLabel: row.label,
        platform: null, clientVersion: row.client_version, kind: row.kind, createdAt: row.created_at,
        lastSeenAt: row.last_seen_at, revokedAt: row.revoked_at,
      })),
      sessions: sessions.map((row) => ({
        sessionId: row.id, deviceId: row.device_id, purpose: row.purpose, createdAt: row.created_at,
        lastSeenAt: row.last_seen_at, idleExpiresAt: row.idle_expires_at,
        absoluteExpiresAt: row.absolute_expires_at, revokedAt: row.revoked_at,
      })),
      wallet: wallet === undefined ? null : {
        freeBalance: wallet.free_balance, paidBalance: wallet.paid_balance,
        revision: wallet.revision, updatedAt: wallet.updated_at,
      },
      securityActions: actions.map((row) => ({
        id: row.id, kind: row.kind, status: row.status,
        requestedByDeviceId: row.requested_by_device_id, executeAfter: row.execute_after,
        createdAt: row.created_at, cancelledAt: row.cancelled_at, completedAt: row.completed_at,
      })),
    }, 200, noStoreHeaders());
  } catch (error) {
    if (error instanceof ApiError) throw error;
    asServiceUnavailable(error);
  }
});

admin.post("/players/:playerId/devices/:deviceId/revoke", async (c) => {
  const playerId = parsedPlayerId(c.req.param("playerId"));
  const deviceId = parsedDeviceId(c.req.param("deviceId"));
  const body = await readBoundedJson(c, adminReasonSchema);
  const now = unixNow();
  const audit = await auditStatement(c, "device.revoke", "device", deviceId, body.reason);
  try {
    const results = await c.env.DB.batch([
      c.env.DB.prepare(
        "UPDATE devices SET revoked_at = ? WHERE id = ? AND player_id = ? AND revoked_at IS NULL",
      ).bind(now, deviceId, playerId),
      c.env.DB.prepare(
        "UPDATE sessions SET revoked_at = ? WHERE device_id = ? AND player_id = ? AND revoked_at IS NULL",
      ).bind(now, deviceId, playerId),
      audit,
    ]);
    if ((results[0]?.meta.changes ?? 0) !== 1) throw new ApiError(404, "DEVICE_NOT_FOUND", "O aparelho não foi encontrado ou já foi revogado.");
    return c.json({ revoked: true, deviceId, revokedSessions: results[1]?.meta.changes ?? 0 }, 200, noStoreHeaders());
  } catch (error) {
    if (error instanceof ApiError) throw error;
    asServiceUnavailable(error);
  }
});

admin.post("/players/:playerId/sessions/revoke-all", async (c) => {
  const playerId = parsedPlayerId(c.req.param("playerId"));
  const body = await readBoundedJson(c, adminReasonSchema);
  const now = unixNow();
  const audit = await auditStatement(c, "sessions.revoke_all", "player", playerId, body.reason);
  try {
    const results = await c.env.DB.batch([
      c.env.DB.prepare("UPDATE sessions SET revoked_at = ? WHERE player_id = ? AND revoked_at IS NULL")
        .bind(now, playerId),
      audit,
    ]);
    return c.json({ revokedSessions: results[0]?.meta.changes ?? 0 }, 200, noStoreHeaders());
  } catch (error) {
    asServiceUnavailable(error);
  }
});

admin.post("/players/:playerId/save/restore-previous", async (c) => {
  const playerId = parsedPlayerId(c.req.param("playerId"));
  const baseRevision = parseIfMatch(c);
  const body = await readBoundedJson(c, adminReasonSchema);
  const now = unixNow();
  let save: SaveRow | null;
  try {
    save = await c.env.DB.prepare(
      `SELECT player_id, revision, schema_version, payload_json, payload_sha256, payload_bytes,
              previous_revision, previous_schema_version, previous_payload_json,
              previous_payload_sha256, previous_payload_bytes, previous_updated_at, updated_at
       FROM cloud_saves WHERE player_id = ?`,
    ).bind(playerId).first<SaveRow>();
  } catch (error) {
    asServiceUnavailable(error);
  }
  if (save === null) throw new ApiError(404, "PLAYER_NOT_FOUND", "A conta não foi encontrada.");
  if (save.revision !== baseRevision) throw new ApiError(412, "SAVE_CONFLICT", "A revisão do save mudou.", { currentRevision: save.revision });
  if (save.previous_payload_json === null || save.previous_payload_sha256 === null
    || save.previous_schema_version === null || save.previous_payload_bytes === null) {
    throw new ApiError(409, "NO_PREVIOUS_SAVE", "Não há uma cópia anterior disponível.");
  }
  const mutationId = crypto.randomUUID();
  const audit = await auditStatement(c, "save.restore_previous", "player", playerId, body.reason);
  try {
    const results = await c.env.DB.batch([
      c.env.DB.prepare(
        `INSERT INTO save_mutations
           (player_id, mutation_id, base_revision, resulting_revision, payload_sha256,
            device_id, server_updated_at, created_at)
         VALUES (?, ?, ?, ?, ?, 'admin', ?, ?)`,
      ).bind(playerId, mutationId, baseRevision, baseRevision + 1, save.previous_payload_sha256, now, now),
      c.env.DB.prepare(
        `INSERT INTO save_snapshots
           (player_id, revision, reason, schema_version, payload_json, payload_sha256, payload_bytes, created_at)
         SELECT player_id, revision, 'admin_restore', schema_version, payload_json, payload_sha256, payload_bytes, ?
         FROM cloud_saves WHERE player_id = ? AND revision = ? AND payload_json IS NOT NULL
         ON CONFLICT(player_id, revision, reason) DO NOTHING`,
      ).bind(now, playerId, baseRevision),
      c.env.DB.prepare(
        `UPDATE cloud_saves
         SET previous_revision = revision, previous_schema_version = schema_version,
             previous_payload_json = payload_json, previous_payload_sha256 = payload_sha256,
             previous_payload_bytes = payload_bytes, previous_updated_at = updated_at,
             revision = revision + 1, schema_version = ?, payload_json = ?, payload_sha256 = ?, payload_bytes = ?,
             last_mutation_id = ?, last_device_id = 'admin', client_saved_at = ?, updated_at = ?
         WHERE player_id = ? AND revision = ?`,
      ).bind(
        save.previous_schema_version, save.previous_payload_json, save.previous_payload_sha256,
        save.previous_payload_bytes, mutationId, now, now, playerId, baseRevision,
      ),
      audit,
    ]);
    if ((results[2]?.meta.changes ?? 0) !== 1) throw new ApiError(412, "SAVE_CONFLICT", "A revisão do save mudou.");
  } catch (error) {
    if (error instanceof ApiError) throw error;
    asServiceUnavailable(error);
  }
  return c.json({
    mutationId,
    revision: baseRevision + 1,
    etag: saveEtag(baseRevision + 1),
    sha256: save.previous_payload_sha256,
    serverUpdatedAt: now,
    serverNow: now,
  }, 200, noStoreHeaders(saveEtag(baseRevision + 1)));
});

admin.get("/operations", async (c) => {
  return c.json(await getOperationalSettings(c.env.DB), 200, noStoreHeaders());
});

admin.put("/operations", async (c) => {
  const body = await readBoundedJson(c, operationsSchema);
  const current = await getOperationalSettings(c.env.DB);
  const next: OperationalSettings = {
    maintenanceMode: body.maintenanceMode ?? current.maintenanceMode,
    readOnlyUploads: body.readOnlyUploads ?? current.readOnlyUploads,
    allowNewAccounts: body.allowNewAccounts ?? current.allowNewAccounts,
    minClientVersion: body.minClientVersion === undefined ? current.minClientVersion : body.minClientVersion,
    updatedAt: unixNow(),
  };
  const audit = await auditStatement(c, "operations.update", "system", null, body.reason);
  try {
    await c.env.DB.batch([
      c.env.DB.prepare(
        `UPDATE system_settings
         SET maintenance_mode = ?, read_only_uploads = ?, allow_new_accounts = ?,
             min_client_version = ?, updated_at = ? WHERE id = 1`,
      ).bind(
        next.maintenanceMode ? 1 : 0,
        next.readOnlyUploads ? 1 : 0,
        next.allowNewAccounts ? 1 : 0,
        next.minClientVersion,
        next.updatedAt,
      ),
      audit,
    ]);
  } catch (error) {
    asServiceUnavailable(error);
  }
  return c.json(next, 200, noStoreHeaders());
});

admin.get("/deletions", async (c) => {
  const status = c.req.query("status") ?? "pending";
  if (status !== "pending" && status !== "completed") throw new ApiError(400, "INVALID_STATUS", "O status é inválido.");
  const limit = Math.min(Math.max(Number(c.req.query("limit") ?? "25") || 25, 1), 100);
  const cursor = Number(c.req.query("cursor") ?? Number.MAX_SAFE_INTEGER);
  if (!Number.isSafeInteger(cursor) || cursor < 0) throw new ApiError(400, "INVALID_CURSOR", "O cursor é inválido.");
  try {
    const result = await c.env.DELETIONS_DB.prepare(
      `SELECT player_hmac, status, requested_at, completed_at, expires_at, last_error_code
       FROM deletion_tombstones WHERE status = ? AND requested_at < ?
       ORDER BY requested_at DESC LIMIT ?`,
    ).bind(status, cursor, limit + 1).all<TombstoneRow>();
    const rows = result.results.slice(0, limit);
    const hasMore = result.results.length > limit;
    return c.json({
      items: rows.map((row) => ({
        playerHmac: row.player_hmac,
        status: row.status,
        requestedAt: row.requested_at,
        completedAt: row.completed_at,
        expiresAt: row.expires_at,
        lastErrorCode: row.last_error_code,
      })),
      nextCursor: hasMore ? rows.at(-1)?.requested_at ?? null : null,
    }, 200, noStoreHeaders());
  } catch (error) {
    asServiceUnavailable(error);
  }
});

admin.post("/deletions/reconcile", async (c) => {
  const body = await readBoundedJson(c, adminReasonSchema);
  const result = await reconcileTombstones(c.env, 250);
  const audit = await auditStatement(c, "deletions.reconcile", "system", null, body.reason);
  try {
    await audit.run();
  } catch (error) {
    asServiceUnavailable(error);
  }
  return c.json({ ...result, serverNow: unixNow() }, 200, noStoreHeaders());
});

admin.get("/audit", async (c) => {
  const limit = Math.min(Math.max(Number(c.req.query("limit") ?? "25") || 25, 1), 100);
  const cursor = Number(c.req.query("cursor") ?? Number.MAX_SAFE_INTEGER);
  if (!Number.isSafeInteger(cursor) || cursor < 0) throw new ApiError(400, "INVALID_CURSOR", "O cursor é inválido.");
  try {
    const result = await c.env.DB.prepare(
      `SELECT id, actor, action, target_type, target_id_hash, reason, created_at, request_id
       FROM admin_audit WHERE created_at < ? ORDER BY created_at DESC, id DESC LIMIT ?`,
    ).bind(cursor, limit + 1).all<AuditRow>();
    const rows = result.results.slice(0, limit);
    const hasMore = result.results.length > limit;
    return c.json({
      items: rows.map((row) => ({
        id: row.id, actor: row.actor, action: row.action, targetType: row.target_type,
        targetIdHash: row.target_id_hash, reason: row.reason, createdAt: row.created_at,
        requestId: row.request_id,
      })),
      nextCursor: hasMore ? rows.at(-1)?.created_at ?? null : null,
    }, 200, noStoreHeaders());
  } catch (error) {
    asServiceUnavailable(error);
  }
});

export default admin;
