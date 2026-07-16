import { Hono } from "hono";

import { ApiError, asServiceUnavailable } from "../errors";
import {
  MAX_ENVELOPE_BYTES,
  noStoreHeaders,
  parseIfMatch,
  readBoundedJson,
  saveEtag,
  saveRepresentation,
  unixNow,
} from "../http";
import { requireGameSession, requirePlayerAuth } from "../middleware/auth";
import { enforceRateLimit } from "../middleware/rate-limit";
import { pseudonymize, secureStringEqual, sha256Hex } from "../security/crypto";
import { enforceOperationalState } from "../services/operations";
import type { AppHonoEnv, MutationRow, SaveRow } from "../types";
import { restorePreviousSchema, saveWriteSchema } from "../validation/schemas";
import { validateSavePayload } from "../validation/save";

const saves = new Hono<AppHonoEnv>();
saves.use("*", requirePlayerAuth);

async function getSave(db: D1Database, playerId: string): Promise<SaveRow> {
  try {
    const row = await db.prepare(
      `SELECT player_id, revision, schema_version, payload_json, payload_sha256, payload_bytes,
              previous_revision, previous_schema_version, previous_payload_json,
              previous_payload_sha256, previous_payload_bytes, previous_updated_at, updated_at
       FROM cloud_saves WHERE player_id = ?`,
    ).bind(playerId).first<SaveRow>();
    if (row === null) throw new ApiError(404, "SAVE_NOT_FOUND", "O save online não foi encontrado.");
    return row;
  } catch (error) {
    if (error instanceof ApiError) throw error;
    asServiceUnavailable(error);
  }
}

async function findMutation(db: D1Database, playerId: string, mutationId: string): Promise<MutationRow | null> {
  try {
    return await db.prepare(
      `SELECT mutation_id, base_revision, resulting_revision, payload_sha256, device_id, server_updated_at
       FROM save_mutations WHERE player_id = ? AND mutation_id = ?`,
    ).bind(playerId, mutationId).first<MutationRow>();
  } catch (error) {
    asServiceUnavailable(error);
  }
}

function mutationResponse(row: MutationRow, serverNow: number): Record<string, unknown> {
  return {
    mutationId: row.mutation_id,
    revision: row.resulting_revision,
    etag: saveEtag(row.resulting_revision),
    sha256: row.payload_sha256,
    serverUpdatedAt: row.server_updated_at,
    serverNow,
  };
}

function ensureMutationMatches(row: MutationRow, baseRevision: number, sha256: string, deviceId: string): void {
  if (row.base_revision !== baseRevision || row.payload_sha256 !== sha256 || row.device_id !== deviceId) {
    throw new ApiError(422, "MUTATION_REUSE_MISMATCH", "O mutationId já foi usado com dados diferentes.");
  }
}

saves.get("/save", async (c) => {
  const auth = requireGameSession(c);
  await enforceOperationalState(c.env, "read", c.req.header("x-client-version"));
  await enforceRateLimit(c.env.SAVE_READ_LIMITER, auth.playerId);
  const now = unixNow();
  const row = await getSave(c.env.DB, auth.playerId);
  const etag = saveEtag(row.revision);
  if (c.req.header("if-none-match")?.trim() === etag) {
    return c.body(null, 304, noStoreHeaders(etag));
  }
  return c.json(saveRepresentation(row, now), 200, noStoreHeaders(etag));
});

saves.put("/save", async (c) => {
  const auth = requireGameSession(c);
  await enforceOperationalState(c.env, "upload", c.req.header("x-client-version"));
  await enforceRateLimit(c.env.SAVE_WRITE_LIMITER, auth.playerId);
  const baseRevision = parseIfMatch(c);
  const body = await readBoundedJson(c, saveWriteSchema, MAX_ENVELOPE_BYTES);
  const now = unixNow();
  if (body.clientSavedAt > now + 300) {
    throw new ApiError(422, "CLIENT_TIME_INVALID", "O horário do save está muito adiantado.", { serverNow: now });
  }
  const computedSha = await sha256Hex(body.payloadJson);
  if (!await secureStringEqual(computedSha, body.payloadSha256)) {
    throw new ApiError(422, "SAVE_CHECKSUM_MISMATCH", "O checksum do save não corresponde ao conteúdo.");
  }
  const supportedSchema = Number(c.env.SUPPORTED_SAVE_SCHEMA);
  const validated = validateSavePayload(body.payloadJson, body.schemaVersion, supportedSchema);
  if (validated.lastSeen > now + 300) {
    throw new ApiError(422, "SAVE_TIME_INVALID", "O relógio registrado no save está muito adiantado.", { serverNow: now });
  }

  const existing = await findMutation(c.env.DB, auth.playerId, body.mutationId);
  if (existing !== null) {
    ensureMutationMatches(existing, baseRevision, computedSha, auth.deviceId);
    return c.json(mutationResponse(existing, now), 200, noStoreHeaders(saveEtag(existing.resulting_revision)));
  }

  const statements: D1PreparedStatement[] = [
    c.env.DB.prepare(
      `INSERT INTO save_mutations
         (player_id, mutation_id, base_revision, resulting_revision,
          payload_sha256, device_id, server_updated_at, created_at)
       SELECT player_id, ?, ?, revision + 1, ?, ?, ?, ?
       FROM cloud_saves
       WHERE player_id = ? AND revision = ?
         AND (schema_version IS NULL OR schema_version <= ?)`,
    ).bind(
      body.mutationId,
      baseRevision,
      computedSha,
      auth.deviceId,
      now,
      now,
      auth.playerId,
      baseRevision,
      body.schemaVersion,
    ),
    c.env.DB.prepare(
      `UPDATE cloud_saves
       SET previous_revision = CASE WHEN payload_json IS NULL THEN NULL ELSE revision END,
           previous_schema_version = schema_version,
           previous_payload_json = payload_json,
           previous_payload_sha256 = payload_sha256,
           previous_payload_bytes = payload_bytes,
           previous_updated_at = updated_at,
           revision = revision + 1,
           schema_version = ?, payload_json = ?, payload_sha256 = ?, payload_bytes = ?,
           last_mutation_id = ?, last_device_id = ?, client_saved_at = ?, updated_at = ?
       WHERE player_id = ? AND revision = ?
         AND (schema_version IS NULL OR schema_version <= ?)`,
    ).bind(
      body.schemaVersion,
      body.payloadJson,
      computedSha,
      validated.bytes,
      body.mutationId,
      auth.deviceId,
      body.clientSavedAt,
      now,
      auth.playerId,
      baseRevision,
      body.schemaVersion,
    ),
  ];
  if (body.resolution === "keep_device") {
    statements.push(
      c.env.DB.prepare(
        `INSERT INTO save_snapshots
           (player_id, revision, reason, schema_version, payload_json, payload_sha256, payload_bytes, created_at)
         SELECT player_id, previous_revision, 'keep_device', previous_schema_version,
                previous_payload_json, previous_payload_sha256, previous_payload_bytes, ?
         FROM cloud_saves
         WHERE player_id = ? AND last_mutation_id = ? AND previous_payload_json IS NOT NULL
         ON CONFLICT(player_id, revision, reason) DO NOTHING`,
      ).bind(now, auth.playerId, body.mutationId),
    );
  }

  try {
    const results = await c.env.DB.batch(statements);
    if ((results[0]?.meta.changes ?? 0) === 1 && (results[1]?.meta.changes ?? 0) === 1) {
      const accepted = await findMutation(c.env.DB, auth.playerId, body.mutationId);
      if (accepted === null) throw new ApiError(503, "SAVE_CONFIRMATION_FAILED", "A confirmação do save falhou temporariamente.");
      console.log(JSON.stringify({
        event: "save_written",
        requestId: c.get("requestId"),
        player: await pseudonymize(c.env, auth.playerId),
        fromRevision: baseRevision,
        toRevision: accepted.resulting_revision,
        payloadBytes: validated.bytes,
        resolution: body.resolution,
      }));
      return c.json(mutationResponse(accepted, now), 200, noStoreHeaders(saveEtag(accepted.resulting_revision)));
    }
  } catch (error) {
    const retry = await findMutation(c.env.DB, auth.playerId, body.mutationId);
    if (retry !== null) {
      ensureMutationMatches(retry, baseRevision, computedSha, auth.deviceId);
      return c.json(mutationResponse(retry, now), 200, noStoreHeaders(saveEtag(retry.resulting_revision)));
    }
    if (error instanceof ApiError) throw error;
    asServiceUnavailable(error);
  }

  const retry = await findMutation(c.env.DB, auth.playerId, body.mutationId);
  if (retry !== null) {
    ensureMutationMatches(retry, baseRevision, computedSha, auth.deviceId);
    return c.json(mutationResponse(retry, now), 200, noStoreHeaders(saveEtag(retry.resulting_revision)));
  }
  const current = await getSave(c.env.DB, auth.playerId);
  if (current.schema_version !== null && current.schema_version > body.schemaVersion) {
    throw new ApiError(422, "SAVE_SCHEMA_TOO_OLD", "A nuvem já usa uma versão de save mais recente.", {
      currentSchemaVersion: current.schema_version,
    });
  }
  throw new ApiError(412, "SAVE_CONFLICT", "O save da nuvem mudou em outro aparelho.", {
    conflict: saveRepresentation(current, now),
  });
});

saves.post("/save/restore-previous", async (c) => {
  const auth = requireGameSession(c);
  await enforceOperationalState(c.env, "upload", c.req.header("x-client-version"));
  await enforceRateLimit(c.env.SAVE_WRITE_LIMITER, auth.playerId);
  const baseRevision = parseIfMatch(c);
  const body = await readBoundedJson(c, restorePreviousSchema);
  const now = unixNow();
  const idempotentRetry = await findMutation(c.env.DB, auth.playerId, body.mutationId);
  if (idempotentRetry !== null) {
    if (idempotentRetry.base_revision !== baseRevision || idempotentRetry.device_id !== auth.deviceId) {
      throw new ApiError(422, "MUTATION_REUSE_MISMATCH", "O mutationId já foi usado com dados diferentes.");
    }
    return c.json(
      mutationResponse(idempotentRetry, now),
      200,
      noStoreHeaders(saveEtag(idempotentRetry.resulting_revision)),
    );
  }
  const current = await getSave(c.env.DB, auth.playerId);
  if (current.revision !== baseRevision) {
    throw new ApiError(412, "SAVE_CONFLICT", "O save da nuvem mudou em outro aparelho.", {
      conflict: saveRepresentation(current, now),
    });
  }
  if (current.previous_payload_json === null || current.previous_payload_sha256 === null
    || current.previous_schema_version === null || current.previous_payload_bytes === null) {
    throw new ApiError(409, "NO_PREVIOUS_SAVE", "Não há uma cópia anterior disponível.");
  }
  try {
    const results = await c.env.DB.batch([
      c.env.DB.prepare(
        `INSERT INTO save_mutations
           (player_id, mutation_id, base_revision, resulting_revision,
            payload_sha256, device_id, server_updated_at, created_at)
         SELECT player_id, ?, ?, revision + 1, previous_payload_sha256, ?, ?, ?
         FROM cloud_saves
         WHERE player_id = ? AND revision = ? AND previous_payload_json IS NOT NULL`,
      ).bind(body.mutationId, baseRevision, auth.deviceId, now, now, auth.playerId, baseRevision),
      c.env.DB.prepare(
        `INSERT INTO save_snapshots
           (player_id, revision, reason, schema_version, payload_json, payload_sha256, payload_bytes, created_at)
         SELECT player_id, revision, ?, schema_version, payload_json, payload_sha256, payload_bytes, ?
         FROM cloud_saves
         WHERE player_id = ? AND revision = ? AND payload_json IS NOT NULL
         ON CONFLICT(player_id, revision, reason) DO NOTHING`,
      ).bind(body.reason, now, auth.playerId, baseRevision),
      c.env.DB.prepare(
        `UPDATE cloud_saves
         SET previous_revision = revision,
             previous_schema_version = schema_version,
             previous_payload_json = payload_json,
             previous_payload_sha256 = payload_sha256,
             previous_payload_bytes = payload_bytes,
             previous_updated_at = updated_at,
             revision = revision + 1,
             schema_version = ?, payload_json = ?, payload_sha256 = ?, payload_bytes = ?,
             last_mutation_id = ?, last_device_id = ?, client_saved_at = ?, updated_at = ?
         WHERE player_id = ? AND revision = ?`,
      ).bind(
        current.previous_schema_version,
        current.previous_payload_json,
        current.previous_payload_sha256,
        current.previous_payload_bytes,
        body.mutationId,
        auth.deviceId,
        now,
        now,
        auth.playerId,
        baseRevision,
      ),
    ]);
    if ((results[0]?.meta.changes ?? 0) !== 1 || (results[2]?.meta.changes ?? 0) !== 1) {
      const latest = await getSave(c.env.DB, auth.playerId);
      throw new ApiError(412, "SAVE_CONFLICT", "O save da nuvem mudou em outro aparelho.", {
        conflict: saveRepresentation(latest, now),
      });
    }
  } catch (error) {
    if (error instanceof ApiError) throw error;
    const retry = await findMutation(c.env.DB, auth.playerId, body.mutationId);
    if (retry === null) asServiceUnavailable(error);
  }
  const accepted = await findMutation(c.env.DB, auth.playerId, body.mutationId);
  if (accepted === null) throw new ApiError(503, "SAVE_CONFIRMATION_FAILED", "A confirmação do save falhou temporariamente.");
  ensureMutationMatches(accepted, baseRevision, current.previous_payload_sha256, auth.deviceId);
  return c.json(mutationResponse(accepted, now), 200, noStoreHeaders(saveEtag(accepted.resulting_revision)));
});

export default saves;
