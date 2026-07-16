import { Hono } from "hono";

import { ApiError, asServiceUnavailable } from "../errors";
import { noStoreHeaders, readBoundedJson, saveEtag, unixNow } from "../http";
import { enforceRateLimit } from "../middleware/rate-limit";
import {
  generateRecoveryCode,
  generateSessionToken,
  getCredentialKeyVersion,
  hmacHex,
  normalizeRecoveryCode,
} from "../security/crypto";
import { recoveryPepper, tokenPepper } from "../security/peppers";
import { deletionHmac } from "../services/deletion";
import { enforceOperationalState } from "../services/operations";
import type { AppHonoEnv } from "../types";
import { createPlayerSchema, recoverSessionSchema } from "../validation/schemas";

interface RecoverPlayerRow {
  id: string;
}

interface DeviceIdRow {
  id: string;
}

interface SaveMetaRow {
  revision: number;
  payload_json: string | null;
}

const identity = new Hono<AppHonoEnv>();

identity.post("/players", async (c) => {
  const body = await readBoundedJson(c, createPlayerSchema);
  await enforceOperationalState(c.env, "new_account", body.clientVersion);
  const installationKey = await hmacHex(c.env.DELETION_PEPPER_V1, `install:${body.installationId}`);
  const ipKey = await hmacHex(c.env.DELETION_PEPPER_V1, `ip:${c.req.header("cf-connecting-ip") ?? "unknown"}`);
  await Promise.all([
    enforceRateLimit(c.env.ACCOUNT_CREATE_LIMITER, installationKey),
    enforceRateLimit(c.env.ACCOUNT_CREATE_IP_LIMITER, ipKey),
  ]);

  const now = unixNow();
  const playerId = crypto.randomUUID();
  const deviceId = crypto.randomUUID();
  const sessionId = crypto.randomUUID();
  const recoveryVersion = Number(c.env.CURRENT_RECOVERY_KEY_VERSION);
  const tokenVersion = Number(c.env.CURRENT_TOKEN_KEY_VERSION);
  const recoveryCode = generateRecoveryCode(recoveryVersion);
  const normalizedRecovery = normalizeRecoveryCode(recoveryCode);
  if (normalizedRecovery === null) throw new ApiError(500, "CREDENTIAL_GENERATION_FAILED", "A credencial não pôde ser criada.");
  const sessionToken = generateSessionToken(tokenVersion);
  const [recoveryHash, tokenHash, playerDeletionHmac] = await Promise.all([
    hmacHex(recoveryPepper(c.env, recoveryVersion), normalizedRecovery),
    hmacHex(tokenPepper(c.env, tokenVersion), sessionToken),
    deletionHmac(c.env, playerId),
  ]);
  const idleExpiresAt = now + 180 * 86_400;
  const absoluteExpiresAt = now + 365 * 86_400;

  try {
    await c.env.DB.batch([
      c.env.DB.prepare(
        `INSERT INTO players
           (id, recovery_hash, recovery_key_version, deletion_hmac, deletion_key_version, status, created_at)
         VALUES (?, ?, ?, ?, 1, 'active', ?)`,
      ).bind(playerId, recoveryHash, recoveryVersion, playerDeletionHmac, now),
      c.env.DB.prepare(
        `INSERT INTO devices
           (id, player_id, installation_id, label, client_version, kind, created_at, last_seen_at)
         VALUES (?, ?, ?, ?, ?, 'game', ?, ?)`,
      ).bind(deviceId, playerId, body.installationId, body.deviceLabel ?? null, body.clientVersion ?? null, now, now),
      c.env.DB.prepare(
        `INSERT INTO sessions
           (id, player_id, device_id, token_hash, token_key_version, purpose,
            created_at, last_seen_at, idle_expires_at, absolute_expires_at)
         VALUES (?, ?, ?, ?, ?, 'game', ?, ?, ?, ?)`,
      ).bind(sessionId, playerId, deviceId, tokenHash, tokenVersion, now, now, idleExpiresAt, absoluteExpiresAt),
      c.env.DB.prepare("INSERT INTO cloud_saves (player_id, revision, created_at) VALUES (?, 0, ?)")
        .bind(playerId, now),
      c.env.DB.prepare(
        `INSERT INTO wallets
           (player_id, free_balance, paid_balance, revision, created_at, updated_at)
         VALUES (?, 0, 0, 0, ?, ?)`,
      ).bind(playerId, now, now),
    ]);
  } catch (error) {
    asServiceUnavailable(error);
  }

  return c.json({
    playerId,
    deviceId,
    sessionToken,
    sessionExpiresAt: absoluteExpiresAt,
    recoveryCode,
    save: { hasPayload: false, revision: 0, etag: saveEtag(0) },
    wallet: { freeBalance: 0, paidBalance: 0, revision: 0 },
    serverNow: now,
  }, 201, noStoreHeaders());
});

identity.post("/sessions/recover", async (c) => {
  const body = await readBoundedJson(c, recoverSessionSchema);
  await enforceOperationalState(
    c.env,
    body.purpose === "account_deletion" ? "deletion" : "security",
    body.clientVersion,
  );
  const ipKey = await hmacHex(c.env.DELETION_PEPPER_V1, `ip:${c.req.header("cf-connecting-ip") ?? "unknown"}`);
  const normalized = normalizeRecoveryCode(body.recoveryCode);
  const recoveryAttemptKey = await hmacHex(c.env.DELETION_PEPPER_V1, `recovery:${normalized ?? body.recoveryCode.trim().toUpperCase()}`);
  await Promise.all([
    enforceRateLimit(c.env.ACCOUNT_RECOVERY_LIMITER, recoveryAttemptKey),
    enforceRateLimit(c.env.ACCOUNT_RECOVERY_IP_LIMITER, ipKey),
  ]);
  if (normalized === null) throw new ApiError(401, "INVALID_RECOVERY", "O código de recuperação é inválido.");
  const recoveryVersion = getCredentialKeyVersion(normalized, "R");
  if (recoveryVersion === null) throw new ApiError(401, "INVALID_RECOVERY", "O código de recuperação é inválido.");
  const recoveryHash = await hmacHex(recoveryPepper(c.env, recoveryVersion), normalized);

  let player: RecoverPlayerRow | null;
  try {
    player = await c.env.DB.prepare(
      `SELECT id FROM players
       WHERE recovery_hash = ? AND recovery_key_version = ? AND status = 'active'`,
    ).bind(recoveryHash, recoveryVersion).first<RecoverPlayerRow>();
  } catch (error) {
    asServiceUnavailable(error);
  }
  if (player === null) throw new ApiError(401, "INVALID_RECOVERY", "O código de recuperação é inválido.");

  const now = unixNow();
  const proposedDeviceId = crypto.randomUUID();
  const sessionId = crypto.randomUUID();
  const tokenVersion = Number(c.env.CURRENT_TOKEN_KEY_VERSION);
  const sessionToken = generateSessionToken(tokenVersion);
  const tokenHash = await hmacHex(tokenPepper(c.env, tokenVersion), sessionToken);
  const isDeletionSession = body.purpose === "account_deletion";
  const absoluteExpiresAt = now + (isDeletionSession ? 15 * 60 : 365 * 86_400);
  const idleExpiresAt = now + (isDeletionSession ? 15 * 60 : 180 * 86_400);
  const deviceKind = isDeletionSession ? "web_deletion" : "game";
  const deviceLabel = body.deviceLabel ?? (isDeletionSession ? "Página de exclusão" : null);

  try {
    const results = await c.env.DB.batch([
      c.env.DB.prepare(
        `INSERT INTO devices
           (id, player_id, installation_id, label, client_version, kind, created_at, last_seen_at, revoked_at)
         SELECT ?, id, ?, ?, ?, ?, ?, ?, NULL
         FROM players
         WHERE id = ? AND recovery_hash = ? AND recovery_key_version = ? AND status = 'active'
         ON CONFLICT(player_id, installation_id) DO UPDATE SET
           label = excluded.label,
           client_version = excluded.client_version,
           kind = excluded.kind,
           last_seen_at = excluded.last_seen_at,
           revoked_at = NULL`,
      ).bind(
        proposedDeviceId,
        body.installationId,
        deviceLabel,
        body.clientVersion ?? null,
        deviceKind,
        now,
        now,
        player.id,
        recoveryHash,
        recoveryVersion,
      ),
      c.env.DB.prepare(
        `INSERT INTO sessions
           (id, player_id, device_id, token_hash, token_key_version, purpose,
            created_at, last_seen_at, idle_expires_at, absolute_expires_at)
         SELECT ?, ?, d.id, ?, ?, ?, ?, ?, ?, ?
         FROM devices d
         JOIN players p ON p.id = d.player_id
         WHERE d.player_id = ? AND d.installation_id = ?
           AND p.recovery_hash = ? AND p.recovery_key_version = ? AND p.status = 'active'`,
      ).bind(
        sessionId,
        player.id,
        tokenHash,
        tokenVersion,
        body.purpose,
        now,
        now,
        idleExpiresAt,
        absoluteExpiresAt,
        player.id,
        body.installationId,
        recoveryHash,
        recoveryVersion,
      ),
    ]);
    if ((results[1]?.meta.changes ?? 0) !== 1) {
      throw new ApiError(401, "INVALID_RECOVERY", "O código de recuperação é inválido.");
    }
  } catch (error) {
    if (error instanceof ApiError) throw error;
    asServiceUnavailable(error);
  }

  let device: DeviceIdRow | null;
  let save: SaveMetaRow | null;
  try {
    [device, save] = await Promise.all([
      c.env.DB.prepare("SELECT id FROM devices WHERE player_id = ? AND installation_id = ?")
        .bind(player.id, body.installationId).first<DeviceIdRow>(),
      c.env.DB.prepare("SELECT revision, payload_json FROM cloud_saves WHERE player_id = ?")
        .bind(player.id).first<SaveMetaRow>(),
    ]);
  } catch (error) {
    asServiceUnavailable(error);
  }
  if (device === null || save === null) throw new ApiError(503, "SERVICE_UNAVAILABLE", "A sessão não pôde ser criada.");

  return c.json({
    playerId: player.id,
    deviceId: device.id,
    sessionToken,
    sessionExpiresAt: absoluteExpiresAt,
    purpose: body.purpose,
    save: {
      hasPayload: save.payload_json !== null,
      revision: save.revision,
      etag: saveEtag(save.revision),
    },
    serverNow: now,
  }, 200, noStoreHeaders());
});

export default identity;
