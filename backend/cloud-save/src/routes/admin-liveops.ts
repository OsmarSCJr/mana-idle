import { Hono } from "hono";

import { ApiError, asServiceUnavailable } from "../errors";
import { noStoreHeaders, parseLiveOpsIfMatch, readBoundedJson, unixNow } from "../http";
import {
  cancelCampaign,
  createBalanceDraft,
  createCampaign,
  createCampaignDraft,
  getLiveOpsAdminSnapshot,
  getLiveOpsAudit,
  publishBalanceVersion,
  publishCampaignVersion,
  rollbackBalanceVersion,
  rollbackCampaignVersion,
  type LiveOpsMutationContext,
} from "../liveops/service";
import {
  createBalanceDraftSchema,
  createCampaignDraftSchema,
  createCampaignSchema,
  liveOpsReasonSchema,
  liveOpsResourceIdSchema,
} from "../liveops/schemas";
import { requireAdmin } from "../middleware/admin";
import type { AppContext, AppHonoEnv } from "../types";

const adminLiveOps = new Hono<AppHonoEnv>();
adminLiveOps.use("*", requireAdmin);

async function databaseCall<T>(callback: () => Promise<T>): Promise<T> {
  try {
    return await callback();
  } catch (error) {
    if (error instanceof ApiError) throw error;
    asServiceUnavailable(error);
  }
}

function parsedResourceId(value: string, code: string, message: string): string {
  const result = liveOpsResourceIdSchema.safeParse(value);
  if (!result.success) throw new ApiError(400, code, message);
  return result.data;
}

function mutationContext(c: AppContext): LiveOpsMutationContext {
  return {
    actor: c.get("admin").actor,
    requestId: c.get("requestId"),
    now: unixNow(),
  };
}

async function snapshotResponse(c: AppContext, status: 200 | 201 = 200): Promise<Response> {
  const snapshot = await databaseCall(() => getLiveOpsAdminSnapshot(c.env.LIVEOPS_DB, unixNow()));
  return c.json(snapshot, status, noStoreHeaders(snapshot.etag));
}

adminLiveOps.get("/", async (c) => snapshotResponse(c));

adminLiveOps.post("/balance/drafts", async (c) => {
  const expectedRevision = parseLiveOpsIfMatch(c);
  const body = await readBoundedJson(c, createBalanceDraftSchema);
  await databaseCall(() => createBalanceDraft(
    c.env.LIVEOPS_DB,
    expectedRevision,
    body.config,
    body.reason,
    mutationContext(c),
  ));
  return snapshotResponse(c, 201);
});

adminLiveOps.post("/balance/:versionId/publish", async (c) => {
  const expectedRevision = parseLiveOpsIfMatch(c);
  const versionId = parsedResourceId(
    c.req.param("versionId"),
    "INVALID_BALANCE_VERSION_ID",
    "O identificador da versão de balanceamento é inválido.",
  );
  const body = await readBoundedJson(c, liveOpsReasonSchema);
  await databaseCall(() => publishBalanceVersion(
    c.env.LIVEOPS_DB,
    expectedRevision,
    versionId,
    body.reason,
    mutationContext(c),
  ));
  return snapshotResponse(c);
});

adminLiveOps.post("/balance/:versionId/rollback", async (c) => {
  const expectedRevision = parseLiveOpsIfMatch(c);
  const versionId = parsedResourceId(
    c.req.param("versionId"),
    "INVALID_BALANCE_VERSION_ID",
    "O identificador da versão de balanceamento é inválido.",
  );
  const body = await readBoundedJson(c, liveOpsReasonSchema);
  await databaseCall(() => rollbackBalanceVersion(
    c.env.LIVEOPS_DB,
    expectedRevision,
    versionId,
    body.reason,
    mutationContext(c),
  ));
  return snapshotResponse(c);
});

adminLiveOps.post("/campaigns", async (c) => {
  const expectedRevision = parseLiveOpsIfMatch(c);
  const body = await readBoundedJson(c, createCampaignSchema);
  await databaseCall(() => createCampaign(
    c.env.LIVEOPS_DB,
    expectedRevision,
    body.key,
    { name: body.name, startsAt: body.startsAt, endsAt: body.endsAt, effects: body.effects },
    body.reason,
    mutationContext(c),
  ));
  return snapshotResponse(c, 201);
});

adminLiveOps.post("/campaigns/:campaignId/drafts", async (c) => {
  const expectedRevision = parseLiveOpsIfMatch(c);
  const campaignId = parsedResourceId(
    c.req.param("campaignId"),
    "INVALID_CAMPAIGN_ID",
    "O identificador da campanha é inválido.",
  );
  const body = await readBoundedJson(c, createCampaignDraftSchema);
  await databaseCall(() => createCampaignDraft(
    c.env.LIVEOPS_DB,
    expectedRevision,
    campaignId,
    { name: body.name, startsAt: body.startsAt, endsAt: body.endsAt, effects: body.effects },
    body.reason,
    mutationContext(c),
  ));
  return snapshotResponse(c, 201);
});

adminLiveOps.post("/campaigns/:campaignId/versions/:versionId/publish", async (c) => {
  const expectedRevision = parseLiveOpsIfMatch(c);
  const campaignId = parsedResourceId(
    c.req.param("campaignId"),
    "INVALID_CAMPAIGN_ID",
    "O identificador da campanha é inválido.",
  );
  const versionId = parsedResourceId(
    c.req.param("versionId"),
    "INVALID_CAMPAIGN_VERSION_ID",
    "O identificador da versão da campanha é inválido.",
  );
  const body = await readBoundedJson(c, liveOpsReasonSchema);
  await databaseCall(() => publishCampaignVersion(
    c.env.LIVEOPS_DB,
    expectedRevision,
    campaignId,
    versionId,
    body.reason,
    mutationContext(c),
  ));
  return snapshotResponse(c);
});

adminLiveOps.post("/campaigns/:campaignId/cancel", async (c) => {
  const expectedRevision = parseLiveOpsIfMatch(c);
  const campaignId = parsedResourceId(
    c.req.param("campaignId"),
    "INVALID_CAMPAIGN_ID",
    "O identificador da campanha é inválido.",
  );
  const body = await readBoundedJson(c, liveOpsReasonSchema);
  await databaseCall(() => cancelCampaign(
    c.env.LIVEOPS_DB,
    expectedRevision,
    campaignId,
    body.reason,
    mutationContext(c),
  ));
  return snapshotResponse(c);
});

adminLiveOps.post("/campaigns/:campaignId/versions/:versionId/rollback", async (c) => {
  const expectedRevision = parseLiveOpsIfMatch(c);
  const campaignId = parsedResourceId(
    c.req.param("campaignId"),
    "INVALID_CAMPAIGN_ID",
    "O identificador da campanha é inválido.",
  );
  const versionId = parsedResourceId(
    c.req.param("versionId"),
    "INVALID_CAMPAIGN_VERSION_ID",
    "O identificador da versão da campanha é inválido.",
  );
  const body = await readBoundedJson(c, liveOpsReasonSchema);
  await databaseCall(() => rollbackCampaignVersion(
    c.env.LIVEOPS_DB,
    expectedRevision,
    campaignId,
    versionId,
    body.reason,
    mutationContext(c),
  ));
  return snapshotResponse(c);
});

adminLiveOps.get("/audit", async (c) => {
  const limit = Number(c.req.query("limit") ?? "50");
  if (!Number.isSafeInteger(limit) || limit < 1 || limit > 100) {
    throw new ApiError(400, "INVALID_LIMIT", "O limite da auditoria deve ser um inteiro entre 1 e 100.");
  }
  const rawCursor = c.req.query("cursor");
  let cursor = { createdAt: Number.MAX_SAFE_INTEGER, id: "\uffff" };
  if (rawCursor !== undefined) {
    const match = /^(0|[1-9]\d*):([A-Za-z0-9-]{1,64})$/u.exec(rawCursor);
    const createdAt = Number(match?.[1]);
    if (match?.[2] === undefined || !Number.isSafeInteger(createdAt)) {
      throw new ApiError(400, "INVALID_CURSOR", "O cursor de auditoria é inválido.");
    }
    cursor = { createdAt, id: match[2] };
  }
  const result = await databaseCall(() => getLiveOpsAudit(c.env.LIVEOPS_DB, cursor, limit));
  return c.json(result, 200, noStoreHeaders());
});

export default adminLiveOps;
