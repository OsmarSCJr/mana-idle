import type { z } from "zod";

import { ApiError } from "../errors";
import { liveOpsStateEtag } from "../http";
import { sha256Hex } from "../security/crypto";
import { balanceConfigSchema, campaignEffectsSchema } from "./schemas";
import type {
  AdminCampaign,
  BalanceConfig,
  BalanceVersion,
  BalanceVersionStatus,
  CampaignEffects,
  CampaignVersion,
  CampaignVersionStatus,
  LiveOpsAdminSnapshot,
  LiveOpsAuditEntry,
  PublicCampaign,
  PublicLiveOpsConfig,
} from "./types";

// O cliente pode dobrar o cap remoto de sete dias e somar 90 minutos com
// progressos locais. Quinze dias mantêm toda a janela efetiva com margem.
export const PUBLIC_CAMPAIGN_LOOKBACK_SECONDS = 15 * 24 * 60 * 60;
export const MAX_PUBLIC_CAMPAIGN_VERSIONS = 64;
const EMPTY_STATE_SHA256 = "74234e98afe7498fb5daf1f36ac2d78acc339464f950703b8c019892f982b90b";

interface BalanceVersionRow {
  id: string;
  status: BalanceVersionStatus;
  config_json: string;
  config_sha256: string;
  created_by: string;
  created_at: number;
  published_by: string | null;
  published_at: number | null;
  rollback_of_version_id: string | null;
}

interface StateWithBalanceRow extends BalanceVersionRow {
  state_revision: number;
  state_published_at: number;
}

interface CampaignRow {
  id: string;
  campaign_key: string;
  active_version_id: string | null;
  latest_version_number: number;
  created_at: number;
  active_hash: string | null;
}

interface CampaignVersionRow {
  id: string;
  campaign_id: string;
  version_number: number;
  status: CampaignVersionStatus;
  name: string;
  starts_at: number;
  ends_at: number;
  effects_json: string;
  payload_sha256: string;
  created_by: string;
  created_at: number;
  published_by: string | null;
  published_at: number | null;
  retired_at: number | null;
  rollback_of_version_id: string | null;
  cancelled_by: string | null;
  cancelled_at: number | null;
}

interface PublicCampaignRow extends CampaignVersionRow {
  campaign_key: string;
}

interface AuditRow {
  id: string;
  actor: string;
  action: string;
  target_type: string;
  target_id: string;
  before_hash: string | null;
  after_hash: string | null;
  reason: string;
  request_id: string;
  metadata_json: string;
  created_at: number;
}

export interface LiveOpsMutationContext {
  actor: string;
  requestId: string;
  now: number;
}

export interface CampaignDraftInput {
  name: string;
  startsAt: number;
  endsAt: number;
  effects: CampaignEffects;
}

function canonicalJson(value: unknown): string {
  if (Array.isArray(value)) return `[${value.map((item) => canonicalJson(item)).join(",")}]`;
  if (value !== null && typeof value === "object") {
    const record = value as Record<string, unknown>;
    return `{${Object.keys(record).sort().map((key) => `${JSON.stringify(key)}:${canonicalJson(record[key])}`).join(",")}}`;
  }
  if (value === undefined) throw new Error("LiveOps values must be JSON serializable.");
  return JSON.stringify(value);
}

function parseStored<T>(value: string, schema: z.ZodType<T>): T {
  const parsed: unknown = JSON.parse(value);
  const result = schema.safeParse(parsed);
  if (!result.success) throw new Error("Stored LiveOps data does not match schema version 1.");
  return result.data;
}

function parseMetadata(value: string): Record<string, unknown> {
  const parsed: unknown = JSON.parse(value);
  if (parsed === null || typeof parsed !== "object" || Array.isArray(parsed)) {
    throw new Error("Stored LiveOps audit metadata is invalid.");
  }
  return parsed as Record<string, unknown>;
}

function balanceVersion(row: BalanceVersionRow): BalanceVersion {
  return {
    id: row.id,
    status: row.status,
    config: parseStored(row.config_json, balanceConfigSchema),
    sha256: row.config_sha256,
    createdBy: row.created_by,
    createdAt: row.created_at,
    publishedBy: row.published_by,
    publishedAt: row.published_at,
    rollbackOfVersionId: row.rollback_of_version_id,
  };
}

function campaignVersion(row: CampaignVersionRow): CampaignVersion {
  return {
    id: row.id,
    version: row.version_number,
    status: row.status,
    name: row.name,
    startsAt: row.starts_at,
    endsAt: row.ends_at,
    effects: parseStored(row.effects_json, campaignEffectsSchema),
    sha256: row.payload_sha256,
    createdBy: row.created_by,
    createdAt: row.created_at,
    publishedBy: row.published_by,
    publishedAt: row.published_at,
    retiredAt: row.retired_at,
    rollbackOfVersionId: row.rollback_of_version_id,
    cancelledBy: row.cancelled_by,
    cancelledAt: row.cancelled_at,
  };
}

function stateWithActiveBalanceStatement(db: D1Database): D1PreparedStatement {
  return db.prepare(
    `SELECT s.revision AS state_revision, s.published_at AS state_published_at,
            b.id, b.status, b.config_json, b.config_sha256, b.created_by, b.created_at,
            b.published_by, b.published_at, b.rollback_of_version_id
     FROM liveops_state s
     JOIN balance_versions b ON b.id = s.active_balance_version_id
     WHERE s.id = 1`,
  );
}

async function stateWithActiveBalance(db: D1Database): Promise<StateWithBalanceRow> {
  const row = await stateWithActiveBalanceStatement(db).first<StateWithBalanceRow>();
  if (row === null) throw new Error("LiveOps state has no active balance version.");
  return row;
}

function assertRevision(actual: number, expected: number): void {
  if (actual !== expected) {
    throw new ApiError(412, "LIVEOPS_REVISION_CONFLICT", "O LiveOps mudou desde a última leitura.", {
      currentRevision: actual,
      etag: liveOpsStateEtag(actual),
    });
  }
}

function assertBatchRevision(result: D1Result | undefined, expected: number): void {
  if ((result?.meta.changes ?? 0) !== 1) {
    throw new ApiError(412, "LIVEOPS_REVISION_CONFLICT", "O LiveOps mudou durante a alteração.", {
      expectedRevision: expected,
    });
  }
}

function auditStatement(
  db: D1Database,
  context: LiveOpsMutationContext,
  revisionAfter: number,
  action: string,
  targetType: string,
  targetId: string,
  beforeHash: string,
  afterHash: string,
  reason: string,
  metadata: Record<string, unknown>,
): D1PreparedStatement {
  return db.prepare(
    `INSERT INTO liveops_audit
       (id, actor, action, target_type, target_id, before_hash, after_hash,
        reason, request_id, metadata_json, created_at)
     SELECT ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?
     FROM liveops_state WHERE id = 1 AND revision = ?`,
  ).bind(
    crypto.randomUUID(), context.actor, action, targetType, targetId, beforeHash, afterHash,
    reason, context.requestId, canonicalJson(metadata), context.now, revisionAfter,
  );
}

async function campaignById(db: D1Database, campaignId: string): Promise<CampaignRow> {
  const row = await db.prepare(
    `SELECT c.id, c.campaign_key, c.active_version_id, c.latest_version_number, c.created_at,
            active.payload_sha256 AS active_hash
     FROM campaigns c
     LEFT JOIN campaign_versions active ON active.id = c.active_version_id
     WHERE c.id = ?`,
  ).bind(campaignId).first<CampaignRow>();
  if (row === null) throw new ApiError(404, "CAMPAIGN_NOT_FOUND", "A campanha não foi encontrada.");
  return row;
}

async function campaignVersionById(
  db: D1Database,
  campaignId: string,
  versionId: string,
): Promise<CampaignVersionRow> {
  const row = await db.prepare(
    `SELECT id, campaign_id, version_number, status, name, starts_at, ends_at,
            effects_json, payload_sha256, created_by, created_at, published_by, published_at, retired_at,
            rollback_of_version_id, cancelled_by, cancelled_at
     FROM campaign_versions WHERE campaign_id = ? AND id = ?`,
  ).bind(campaignId, versionId).first<CampaignVersionRow>();
  if (row === null) throw new ApiError(404, "CAMPAIGN_VERSION_NOT_FOUND", "A versão da campanha não foi encontrada.");
  return row;
}

async function balanceVersionById(db: D1Database, versionId: string): Promise<BalanceVersionRow> {
  const row = await db.prepare(
    `SELECT id, status, config_json, config_sha256, created_by, created_at,
            published_by, published_at, rollback_of_version_id
     FROM balance_versions WHERE id = ?`,
  ).bind(versionId).first<BalanceVersionRow>();
  if (row === null) throw new ApiError(404, "BALANCE_VERSION_NOT_FOUND", "A versão de balanceamento não foi encontrada.");
  return row;
}

async function assertPublicCampaignCapacity(
  db: D1Database,
  campaign: CampaignRow,
  target: CampaignVersionRow,
  now: number,
): Promise<void> {
  const targetEffectiveStart = Math.max(target.starts_at, now);
  if (target.ends_at <= targetEffectiveStart) return;

  const [countRow, active] = await Promise.all([
    db.prepare(
      `SELECT COUNT(*) AS value
       FROM campaign_versions
       WHERE published_at IS NOT NULL
         AND MIN(ends_at, COALESCE(retired_at, ends_at)) > ?
         AND MIN(ends_at, COALESCE(retired_at, ends_at)) > MAX(starts_at, published_at)`,
    ).bind(now - PUBLIC_CAMPAIGN_LOOKBACK_SECONDS).first<{ value: number }>(),
    campaign.active_version_id === null
      ? Promise.resolve(null)
      : campaignVersionById(db, campaign.id, campaign.active_version_id),
  ]);

  let projected = countRow?.value ?? 0;
  if (active !== null && active.published_at !== null) {
    const currentStart = Math.max(active.starts_at, active.published_at);
    const retiredEnd = Math.min(active.ends_at, now);
    if (retiredEnd <= currentStart) projected -= 1;
  }
  projected += 1;
  if (projected > MAX_PUBLIC_CAMPAIGN_VERSIONS) {
    throw new ApiError(
      409,
      "LIVEOPS_CAMPAIGN_CAPACITY_REACHED",
      "HÃ¡ campanhas demais na janela offline. Aguarde o histÃ³rico mais antigo expirar.",
      { maximum: MAX_PUBLIC_CAMPAIGN_VERSIONS },
    );
  }
}

export async function hashLiveOpsValue(value: unknown): Promise<{ json: string; sha256: string }> {
  const json = canonicalJson(value);
  return { json, sha256: await sha256Hex(json) };
}

export async function getPublicLiveOps(
  db: D1Database,
  now: number,
): Promise<{ body: PublicLiveOpsConfig; etag: string }> {
  const readBatch = await db.batch([
    stateWithActiveBalanceStatement(db),
    db.prepare(
      `SELECT c.id AS campaign_id, c.campaign_key,
              v.id, v.campaign_id, v.version_number, v.status, v.name, v.starts_at, v.ends_at,
              v.effects_json, v.payload_sha256, v.created_by, v.created_at,
              v.published_by, v.published_at, v.retired_at, v.rollback_of_version_id,
              v.cancelled_by, v.cancelled_at
       FROM campaigns c
       JOIN campaign_versions v ON v.campaign_id = c.id
       WHERE v.published_at IS NOT NULL
         AND MIN(v.ends_at, COALESCE(v.retired_at, v.ends_at)) > ?
         AND MIN(v.ends_at, COALESCE(v.retired_at, v.ends_at))
             > MAX(v.starts_at, v.published_at)
       ORDER BY MAX(v.starts_at, v.published_at) ASC,
                c.campaign_key ASC, v.version_number ASC
       LIMIT ?`,
    ).bind(now - PUBLIC_CAMPAIGN_LOOKBACK_SECONDS, MAX_PUBLIC_CAMPAIGN_VERSIONS + 1),
  ]);
  const state = readBatch[0]?.results[0] as StateWithBalanceRow | undefined;
  if (state === undefined) throw new Error("LiveOps state has no active balance version.");
  const campaignRows = (readBatch[1]?.results ?? []) as unknown as PublicCampaignRow[];
  if (campaignRows.length > MAX_PUBLIC_CAMPAIGN_VERSIONS) {
    throw new Error("LiveOps public campaign capacity was exceeded.");
  }

  const campaigns: PublicCampaign[] = campaignRows.map((row) => {
    if (row.published_at === null) throw new Error("Published campaign is missing published_at.");
    const effectiveStartsAt = Math.max(row.starts_at, row.published_at);
    const effectiveEndsAt = Math.min(row.ends_at, row.retired_at ?? row.ends_at);
    return {
      id: row.campaign_id,
      key: row.campaign_key,
      versionId: row.id,
      version: row.version_number,
      name: row.name,
      startsAt: effectiveStartsAt,
      endsAt: effectiveEndsAt,
      publishedAt: row.published_at,
      effects: parseStored(row.effects_json, campaignEffectsSchema),
    };
  });
  const publicHash = await hashLiveOpsValue({
    revision: state.state_revision,
    balance: state.config_sha256,
    campaigns: campaignRows.map((row) => ({ id: row.id, sha256: row.payload_sha256 })),
  });
  return {
    body: {
      schemaVersion: 1,
      revision: state.state_revision,
      versionId: state.id,
      publishedAt: state.state_published_at,
      serverNow: now,
      config: parseStored(state.config_json, balanceConfigSchema),
      campaigns,
    },
    // serverNow muda a cada resposta; o ETag fraco representa apenas o
    // conteúdo semântico e X-Server-Now recalibra o cliente também no 304.
    etag: `W/"liveops-${state.state_revision}-${publicHash.sha256.slice(0, 12)}"`,
  };
}

export async function getLiveOpsAdminSnapshot(db: D1Database, now: number): Promise<LiveOpsAdminSnapshot> {
  const readBatch = await db.batch([
    stateWithActiveBalanceStatement(db),
    db.prepare(
      `SELECT id, status, config_json, config_sha256, created_by, created_at,
              published_by, published_at, rollback_of_version_id
       FROM balance_versions ORDER BY created_at DESC, id DESC`,
    ),
    db.prepare(
      `SELECT c.id, c.campaign_key, c.active_version_id, c.latest_version_number, c.created_at,
              active.payload_sha256 AS active_hash
       FROM campaigns c
       LEFT JOIN campaign_versions active ON active.id = c.active_version_id
       ORDER BY c.created_at DESC, c.id DESC`,
    ),
    db.prepare(
      `SELECT id, campaign_id, version_number, status, name, starts_at, ends_at,
              effects_json, payload_sha256, created_by, created_at, published_by, published_at, retired_at,
              rollback_of_version_id, cancelled_by, cancelled_at
       FROM campaign_versions ORDER BY campaign_id ASC, version_number DESC`,
    ),
  ]);
  const state = readBatch[0]?.results[0] as StateWithBalanceRow | undefined;
  if (state === undefined) throw new Error("LiveOps state has no active balance version.");
  const balanceRows = (readBatch[1]?.results ?? []) as unknown as BalanceVersionRow[];
  const campaignRows = (readBatch[2]?.results ?? []) as unknown as CampaignRow[];
  const campaignVersionRows = (readBatch[3]?.results ?? []) as unknown as CampaignVersionRow[];

  const versionsByCampaign = new Map<string, CampaignVersion[]>();
  for (const row of campaignVersionRows) {
    const versions = versionsByCampaign.get(row.campaign_id) ?? [];
    versions.push(campaignVersion(row));
    versionsByCampaign.set(row.campaign_id, versions);
  }
  const campaigns: AdminCampaign[] = campaignRows.map((row) => ({
    id: row.id,
    key: row.campaign_key,
    activeVersionId: row.active_version_id,
    createdAt: row.created_at,
    versions: versionsByCampaign.get(row.id) ?? [],
  }));

  return {
    schemaVersion: 1,
    revision: state.state_revision,
    etag: liveOpsStateEtag(state.state_revision),
    activeBalance: balanceVersion(state),
    balanceVersions: balanceRows.map((row) => balanceVersion(row)),
    campaigns,
    serverNow: now,
  };
}

export async function createBalanceDraft(
  db: D1Database,
  expectedRevision: number,
  config: BalanceConfig,
  reason: string,
  context: LiveOpsMutationContext,
): Promise<void> {
  const state = await stateWithActiveBalance(db);
  assertRevision(state.state_revision, expectedRevision);
  const versionId = crypto.randomUUID();
  const payload = await hashLiveOpsValue(config);
  const nextRevision = expectedRevision + 1;
  const result = await db.batch([
    db.prepare(
      `INSERT INTO balance_versions
         (id, schema_version, status, config_json, config_sha256, created_by, created_at)
       SELECT ?, 1, 'draft', ?, ?, ?, ?
       FROM liveops_state WHERE id = 1 AND revision = ?`,
    ).bind(versionId, payload.json, payload.sha256, context.actor, context.now, expectedRevision),
    db.prepare(
      `UPDATE liveops_state SET revision = revision + 1, updated_at = ?
       WHERE id = 1 AND revision = ?
         AND EXISTS (SELECT 1 FROM balance_versions WHERE id = ? AND status = 'draft')`,
    ).bind(context.now, expectedRevision, versionId),
    auditStatement(
      db, context, nextRevision, "balance.draft.create", "balance_version", versionId,
      state.config_sha256, payload.sha256, reason, { baseRevision: expectedRevision, revision: nextRevision },
    ),
  ]);
  assertBatchRevision(result[1], expectedRevision);
}

export async function publishBalanceVersion(
  db: D1Database,
  expectedRevision: number,
  versionId: string,
  reason: string,
  context: LiveOpsMutationContext,
): Promise<void> {
  const [state, target] = await Promise.all([
    stateWithActiveBalance(db),
    balanceVersionById(db, versionId),
  ]);
  assertRevision(state.state_revision, expectedRevision);
  if (target.status !== "draft") {
    throw new ApiError(409, "BALANCE_VERSION_NOT_DRAFT", "Somente uma versão em rascunho pode ser publicada.");
  }
  const nextRevision = expectedRevision + 1;
  const result = await db.batch([
    db.prepare(
      `UPDATE balance_versions
       SET status = 'published', published_by = ?, published_at = ?
       WHERE id = ? AND status = 'draft'
         AND EXISTS (SELECT 1 FROM liveops_state WHERE id = 1 AND revision = ?)`,
    ).bind(context.actor, context.now, versionId, expectedRevision),
    db.prepare(
      `UPDATE balance_versions SET status = 'superseded'
       WHERE id = (SELECT active_balance_version_id FROM liveops_state WHERE id = 1 AND revision = ?)
         AND id <> ? AND status = 'published'
         AND EXISTS (SELECT 1 FROM balance_versions WHERE id = ? AND status = 'published')`,
    ).bind(expectedRevision, versionId, versionId),
    db.prepare(
      `UPDATE liveops_state
       SET active_balance_version_id = ?, revision = revision + 1, published_at = ?, updated_at = ?
       WHERE id = 1 AND revision = ?
         AND EXISTS (SELECT 1 FROM balance_versions WHERE id = ? AND status = 'published')`,
    ).bind(versionId, context.now, context.now, expectedRevision, versionId),
    auditStatement(
      db, context, nextRevision, "balance.publish", "balance_version", versionId,
      state.config_sha256, target.config_sha256, reason, { baseRevision: expectedRevision, revision: nextRevision },
    ),
  ]);
  assertBatchRevision(result[2], expectedRevision);
}

export async function rollbackBalanceVersion(
  db: D1Database,
  expectedRevision: number,
  sourceVersionId: string,
  reason: string,
  context: LiveOpsMutationContext,
): Promise<void> {
  const [state, source] = await Promise.all([
    stateWithActiveBalance(db),
    balanceVersionById(db, sourceVersionId),
  ]);
  assertRevision(state.state_revision, expectedRevision);
  if (source.published_at === null) {
    throw new ApiError(409, "BALANCE_VERSION_NEVER_PUBLISHED", "O rollback exige uma versão publicada anteriormente.");
  }
  const versionId = crypto.randomUUID();
  const nextRevision = expectedRevision + 1;
  const result = await db.batch([
    db.prepare(
      `INSERT INTO balance_versions
         (id, schema_version, status, config_json, config_sha256, created_by, created_at,
          published_by, published_at, rollback_of_version_id)
       SELECT ?, 1, 'published', config_json, config_sha256, ?, ?, ?, ?, id
       FROM balance_versions
       WHERE id = ? AND published_at IS NOT NULL
         AND EXISTS (SELECT 1 FROM liveops_state WHERE id = 1 AND revision = ?)`,
    ).bind(
      versionId, context.actor, context.now, context.actor, context.now,
      sourceVersionId, expectedRevision,
    ),
    db.prepare(
      `UPDATE balance_versions SET status = 'superseded'
       WHERE id = (SELECT active_balance_version_id FROM liveops_state WHERE id = 1 AND revision = ?)
         AND status = 'published'
         AND EXISTS (SELECT 1 FROM balance_versions WHERE id = ? AND status = 'published')`,
    ).bind(expectedRevision, versionId),
    db.prepare(
      `UPDATE liveops_state
       SET active_balance_version_id = ?, revision = revision + 1, published_at = ?, updated_at = ?
       WHERE id = 1 AND revision = ?
         AND EXISTS (SELECT 1 FROM balance_versions WHERE id = ? AND status = 'published')`,
    ).bind(versionId, context.now, context.now, expectedRevision, versionId),
    auditStatement(
      db, context, nextRevision, "balance.rollback", "balance_version", versionId,
      state.config_sha256, source.config_sha256, reason,
      { baseRevision: expectedRevision, revision: nextRevision, sourceVersionId },
    ),
  ]);
  assertBatchRevision(result[2], expectedRevision);
}

export async function createCampaign(
  db: D1Database,
  expectedRevision: number,
  key: string,
  draft: CampaignDraftInput,
  reason: string,
  context: LiveOpsMutationContext,
): Promise<void> {
  const [state, existing] = await Promise.all([
    stateWithActiveBalance(db),
    db.prepare("SELECT id FROM campaigns WHERE campaign_key = ?").bind(key).first<{ id: string }>(),
  ]);
  assertRevision(state.state_revision, expectedRevision);
  if (existing !== null) throw new ApiError(409, "CAMPAIGN_KEY_EXISTS", "Já existe uma campanha com essa chave.");
  const campaignId = crypto.randomUUID();
  const versionId = crypto.randomUUID();
  const effects = await hashLiveOpsValue(draft.effects);
  const payload = await hashLiveOpsValue(draft);
  const nextRevision = expectedRevision + 1;
  const result = await db.batch([
    db.prepare(
      `INSERT INTO campaigns
         (id, campaign_key, active_version_id, latest_version_number, created_by, created_at)
       SELECT ?, ?, NULL, 1, ?, ?
       FROM liveops_state WHERE id = 1 AND revision = ?`,
    ).bind(campaignId, key, context.actor, context.now, expectedRevision),
    db.prepare(
      `INSERT INTO campaign_versions
         (id, campaign_id, version_number, status, name, starts_at, ends_at,
          effects_json, payload_sha256, created_by, created_at)
       SELECT ?, id, 1, 'draft', ?, ?, ?, ?, ?, ?, ?
       FROM campaigns WHERE id = ?`,
    ).bind(
      versionId, draft.name, draft.startsAt, draft.endsAt, effects.json, payload.sha256,
      context.actor, context.now, campaignId,
    ),
    db.prepare(
      `UPDATE liveops_state SET revision = revision + 1, updated_at = ?
       WHERE id = 1 AND revision = ?
         AND EXISTS (SELECT 1 FROM campaign_versions WHERE id = ? AND status = 'draft')`,
    ).bind(context.now, expectedRevision, versionId),
    auditStatement(
      db, context, nextRevision, "campaign.create", "campaign", campaignId,
      EMPTY_STATE_SHA256, payload.sha256, reason,
      { baseRevision: expectedRevision, revision: nextRevision, key, versionId, version: 1 },
    ),
  ]);
  assertBatchRevision(result[2], expectedRevision);
}

export async function createCampaignDraft(
  db: D1Database,
  expectedRevision: number,
  campaignId: string,
  draft: CampaignDraftInput,
  reason: string,
  context: LiveOpsMutationContext,
): Promise<void> {
  const [state, campaign] = await Promise.all([
    stateWithActiveBalance(db),
    campaignById(db, campaignId),
  ]);
  assertRevision(state.state_revision, expectedRevision);
  const versionId = crypto.randomUUID();
  const version = campaign.latest_version_number + 1;
  const effects = await hashLiveOpsValue(draft.effects);
  const payload = await hashLiveOpsValue(draft);
  const nextRevision = expectedRevision + 1;
  const result = await db.batch([
    db.prepare(
      `INSERT INTO campaign_versions
         (id, campaign_id, version_number, status, name, starts_at, ends_at,
          effects_json, payload_sha256, created_by, created_at)
       SELECT ?, c.id, ?, 'draft', ?, ?, ?, ?, ?, ?, ?
       FROM campaigns c, liveops_state s
       WHERE c.id = ? AND c.latest_version_number = ? AND s.id = 1 AND s.revision = ?`,
    ).bind(
      versionId, version, draft.name, draft.startsAt, draft.endsAt, effects.json, payload.sha256,
      context.actor, context.now, campaignId, campaign.latest_version_number, expectedRevision,
    ),
    db.prepare(
      `UPDATE campaigns SET latest_version_number = ?
       WHERE id = ? AND latest_version_number = ?
         AND EXISTS (SELECT 1 FROM campaign_versions WHERE id = ? AND status = 'draft')`,
    ).bind(version, campaignId, campaign.latest_version_number, versionId),
    db.prepare(
      `UPDATE liveops_state SET revision = revision + 1, updated_at = ?
       WHERE id = 1 AND revision = ?
         AND EXISTS (SELECT 1 FROM campaign_versions WHERE id = ? AND status = 'draft')`,
    ).bind(context.now, expectedRevision, versionId),
    auditStatement(
      db, context, nextRevision, "campaign.draft.create", "campaign", campaignId,
      campaign.active_hash ?? EMPTY_STATE_SHA256, payload.sha256, reason,
      { baseRevision: expectedRevision, revision: nextRevision, versionId, version },
    ),
  ]);
  assertBatchRevision(result[2], expectedRevision);
}

export async function publishCampaignVersion(
  db: D1Database,
  expectedRevision: number,
  campaignId: string,
  versionId: string,
  reason: string,
  context: LiveOpsMutationContext,
): Promise<void> {
  const [state, campaign, target] = await Promise.all([
    stateWithActiveBalance(db),
    campaignById(db, campaignId),
    campaignVersionById(db, campaignId, versionId),
  ]);
  assertRevision(state.state_revision, expectedRevision);
  if (target.status !== "draft") {
    throw new ApiError(409, "CAMPAIGN_VERSION_NOT_DRAFT", "Somente uma versão em rascunho pode ser publicada.");
  }
  await assertPublicCampaignCapacity(db, campaign, target, context.now);
  const nextRevision = expectedRevision + 1;
  const result = await db.batch([
    db.prepare(
      `UPDATE campaign_versions
       SET status = 'published', published_by = ?, published_at = ?, retired_at = NULL,
           cancelled_by = NULL, cancelled_at = NULL
       WHERE id = ? AND campaign_id = ? AND status = 'draft'
         AND EXISTS (SELECT 1 FROM liveops_state WHERE id = 1 AND revision = ?)`,
    ).bind(context.actor, context.now, versionId, campaignId, expectedRevision),
    db.prepare(
      `UPDATE campaign_versions SET status = 'superseded', retired_at = ?
       WHERE id = (SELECT active_version_id FROM campaigns WHERE id = ?)
         AND id <> ? AND status = 'published'
         AND EXISTS (SELECT 1 FROM liveops_state WHERE id = 1 AND revision = ?)
         AND EXISTS (SELECT 1 FROM campaign_versions WHERE id = ? AND status = 'published')`,
    ).bind(context.now, campaignId, versionId, expectedRevision, versionId),
    db.prepare(
      `UPDATE campaigns SET active_version_id = ?
       WHERE id = ?
         AND EXISTS (SELECT 1 FROM liveops_state WHERE id = 1 AND revision = ?)
         AND EXISTS (SELECT 1 FROM campaign_versions WHERE id = ? AND status = 'published')`,
    ).bind(versionId, campaignId, expectedRevision, versionId),
    db.prepare(
      `UPDATE liveops_state SET revision = revision + 1, updated_at = ?
       WHERE id = 1 AND revision = ?
         AND EXISTS (SELECT 1 FROM campaigns WHERE id = ? AND active_version_id = ?)`,
    ).bind(context.now, expectedRevision, campaignId, versionId),
    auditStatement(
      db, context, nextRevision, "campaign.publish", "campaign", campaignId,
      campaign.active_hash ?? EMPTY_STATE_SHA256, target.payload_sha256, reason,
      { baseRevision: expectedRevision, revision: nextRevision, versionId, version: target.version_number },
    ),
  ]);
  assertBatchRevision(result[3], expectedRevision);
}

export async function cancelCampaign(
  db: D1Database,
  expectedRevision: number,
  campaignId: string,
  reason: string,
  context: LiveOpsMutationContext,
): Promise<void> {
  const [state, campaign] = await Promise.all([
    stateWithActiveBalance(db),
    campaignById(db, campaignId),
  ]);
  assertRevision(state.state_revision, expectedRevision);
  if (campaign.active_version_id === null || campaign.active_hash === null) {
    throw new ApiError(409, "CAMPAIGN_NOT_PUBLISHED", "A campanha não possui uma versão publicada para cancelar.");
  }
  const activeVersionId = campaign.active_version_id;
  const nextRevision = expectedRevision + 1;
  const result = await db.batch([
    db.prepare(
      `UPDATE campaign_versions
       SET status = 'cancelled', retired_at = ?, cancelled_by = ?, cancelled_at = ?
       WHERE id = ? AND campaign_id = ? AND status = 'published'
         AND EXISTS (SELECT 1 FROM liveops_state WHERE id = 1 AND revision = ?)`,
    ).bind(context.now, context.actor, context.now, activeVersionId, campaignId, expectedRevision),
    db.prepare(
      `UPDATE campaigns SET active_version_id = NULL
       WHERE id = ? AND active_version_id = ?
         AND EXISTS (SELECT 1 FROM liveops_state WHERE id = 1 AND revision = ?)
         AND EXISTS (SELECT 1 FROM campaign_versions WHERE id = ? AND status = 'cancelled')`,
    ).bind(campaignId, activeVersionId, expectedRevision, activeVersionId),
    db.prepare(
      `UPDATE liveops_state SET revision = revision + 1, updated_at = ?
       WHERE id = 1 AND revision = ?
         AND EXISTS (SELECT 1 FROM campaigns WHERE id = ? AND active_version_id IS NULL)`,
    ).bind(context.now, expectedRevision, campaignId),
    auditStatement(
      db, context, nextRevision, "campaign.cancel", "campaign", campaignId,
      campaign.active_hash, EMPTY_STATE_SHA256, reason,
      { baseRevision: expectedRevision, revision: nextRevision, versionId: activeVersionId },
    ),
  ]);
  assertBatchRevision(result[2], expectedRevision);
}

export async function rollbackCampaignVersion(
  db: D1Database,
  expectedRevision: number,
  campaignId: string,
  sourceVersionId: string,
  reason: string,
  context: LiveOpsMutationContext,
): Promise<void> {
  const [state, campaign, source] = await Promise.all([
    stateWithActiveBalance(db),
    campaignById(db, campaignId),
    campaignVersionById(db, campaignId, sourceVersionId),
  ]);
  assertRevision(state.state_revision, expectedRevision);
  if (source.published_at === null) {
    throw new ApiError(409, "CAMPAIGN_VERSION_NEVER_PUBLISHED", "O rollback exige uma versão publicada anteriormente.");
  }
  await assertPublicCampaignCapacity(db, campaign, source, context.now);
  const versionId = crypto.randomUUID();
  const version = campaign.latest_version_number + 1;
  const nextRevision = expectedRevision + 1;
  const result = await db.batch([
    db.prepare(
      `INSERT INTO campaign_versions
         (id, campaign_id, version_number, status, name, starts_at, ends_at,
          effects_json, payload_sha256, created_by, created_at, published_by, published_at,
          rollback_of_version_id)
       SELECT ?, campaign_id, ?, 'published', name, starts_at, ends_at,
              effects_json, payload_sha256, ?, ?, ?, ?, id
       FROM campaign_versions
       WHERE id = ? AND campaign_id = ? AND published_at IS NOT NULL
         AND EXISTS (SELECT 1 FROM liveops_state WHERE id = 1 AND revision = ?)`,
    ).bind(
      versionId, version, context.actor, context.now, context.actor, context.now,
      sourceVersionId, campaignId, expectedRevision,
    ),
    db.prepare(
      `UPDATE campaign_versions SET status = 'superseded', retired_at = ?
       WHERE id = (SELECT active_version_id FROM campaigns WHERE id = ?)
         AND status = 'published'
         AND EXISTS (SELECT 1 FROM campaign_versions WHERE id = ? AND status = 'published')
         AND EXISTS (SELECT 1 FROM liveops_state WHERE id = 1 AND revision = ?)`,
    ).bind(context.now, campaignId, versionId, expectedRevision),
    db.prepare(
      `UPDATE campaigns SET active_version_id = ?, latest_version_number = ?
       WHERE id = ? AND latest_version_number = ?
         AND EXISTS (SELECT 1 FROM campaign_versions WHERE id = ? AND status = 'published')
         AND EXISTS (SELECT 1 FROM liveops_state WHERE id = 1 AND revision = ?)`,
    ).bind(
      versionId, version, campaignId, campaign.latest_version_number,
      versionId, expectedRevision,
    ),
    db.prepare(
      `UPDATE liveops_state SET revision = revision + 1, updated_at = ?
       WHERE id = 1 AND revision = ?
         AND EXISTS (SELECT 1 FROM campaigns WHERE id = ? AND active_version_id = ?)`,
    ).bind(context.now, expectedRevision, campaignId, versionId),
    auditStatement(
      db, context, nextRevision, "campaign.rollback", "campaign", campaignId,
      campaign.active_hash ?? EMPTY_STATE_SHA256, source.payload_sha256, reason,
      {
        baseRevision: expectedRevision,
        revision: nextRevision,
        sourceVersionId,
        versionId,
        version,
      },
    ),
  ]);
  assertBatchRevision(result[3], expectedRevision);
}

export async function getLiveOpsAudit(
  db: D1Database,
  cursor: { createdAt: number; id: string },
  limit: number,
): Promise<{ items: LiveOpsAuditEntry[]; nextCursor: string | null }> {
  const result = await db.prepare(
    `SELECT id, actor, action, target_type, target_id, before_hash, after_hash,
            reason, request_id, metadata_json, created_at
     FROM liveops_audit
     WHERE created_at < ? OR (created_at = ? AND id < ?)
     ORDER BY created_at DESC, id DESC
     LIMIT ?`,
  ).bind(cursor.createdAt, cursor.createdAt, cursor.id, limit + 1).all<AuditRow>();
  const rows = result.results.slice(0, limit);
  return {
    items: rows.map((row) => ({
      id: row.id,
      actor: row.actor,
      action: row.action,
      targetType: row.target_type,
      targetId: row.target_id,
      beforeHash: row.before_hash,
      afterHash: row.after_hash,
      reason: row.reason,
      requestId: row.request_id,
      metadata: parseMetadata(row.metadata_json),
      createdAt: row.created_at,
    })),
    nextCursor: result.results.length > limit
      ? (() => {
          const last = rows.at(-1);
          return last === undefined ? null : `${last.created_at}:${last.id}`;
        })()
      : null,
  };
}
