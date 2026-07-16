import { env, exports as workerExports } from "cloudflare:workers";
import { applyD1Migrations } from "cloudflare:test";
import { beforeEach, describe, expect, it } from "vitest";
import { z } from "zod";

import type { BalanceConfig } from "../src/liveops/types";

const worker = workerExports.default;
const ADMIN_TOKEN = "test-admin-token-with-more-than-thirty-two-random-like-characters";

const balanceConfig: BalanceConfig = {
  economy: {
    growthRate: 1.12,
    saintBonus: 0.07,
    prestigeDivisor: 2_500_000_000_000,
    prophetUnlockQuantity: 30,
    prophetCostMultiplier: 18,
    offlineCapSeconds: 36_000,
    milestones: [
      { quantity: 50, multiplier: 2 },
      { quantity: 100, multiplier: 2.5 },
    ],
  },
  boosts: {
    fervorProductionMultiplier: 2.5,
    pentecostProductionMultiplier: 6,
    holyHandsManualMultiplier: 12,
    swiftStepTimeMultiplier: 0.45,
    harvestSeconds: 8_000,
  },
  rewards: {
    videoGems: 7,
    offlineTripleGemCost: 4,
  },
};

const balanceVersionSchema = z.object({
  id: z.string(),
  status: z.enum(["draft", "published", "superseded"]),
  config: z.object({ rewards: z.object({ videoGems: z.number() }) }).loose(),
  sha256: z.string().length(64),
  rollbackOfVersionId: z.string().nullable(),
});

const campaignVersionSchema = z.object({
  id: z.string(),
  version: z.number().int(),
  status: z.enum(["draft", "published", "superseded", "cancelled"]),
  rollbackOfVersionId: z.string().nullable(),
});

const campaignEffectsResponseSchema = z.object({
  globalProductionMultiplier: z.number(),
  offlineProductionMultiplier: z.number(),
  manualProductionMultiplier: z.number(),
  studyFaithMultiplier: z.number(),
  freeGemRewardMultiplier: z.number(),
  generatorProductionMultipliers: z.record(z.string(), z.number()),
}).strict();

const adminSnapshotSchema = z.object({
  schemaVersion: z.literal(1),
  revision: z.number().int(),
  etag: z.string(),
  activeBalance: balanceVersionSchema,
  balanceVersions: z.array(balanceVersionSchema),
  campaigns: z.array(z.object({
    id: z.string(),
    key: z.string(),
    activeVersionId: z.string().nullable(),
    versions: z.array(campaignVersionSchema),
  })),
});

const publicConfigSchema = z.object({
  schemaVersion: z.literal(1),
  revision: z.number().int(),
  versionId: z.string(),
  publishedAt: z.number().int(),
  serverNow: z.number().int(),
  config: z.object({
    economy: z.object({
      growthRate: z.number(),
      milestones: z.array(z.object({ quantity: z.number().int(), multiplier: z.number() })),
    }).loose(),
    boosts: z.object({ fervorProductionMultiplier: z.number() }).loose(),
    rewards: z.object({ videoGems: z.number() }).loose(),
  }),
  campaigns: z.array(z.object({
    id: z.string(),
    key: z.string(),
    versionId: z.string(),
    version: z.number().int(),
    startsAt: z.number().int(),
    endsAt: z.number().int(),
    effects: campaignEffectsResponseSchema,
  })),
});

function adminHeaders(revision?: number): Headers {
  const headers = new Headers({
    authorization: `Bearer ${ADMIN_TOKEN}`,
    origin: "http://localhost:5174",
  });
  if (revision !== undefined) {
    headers.set("content-type", "application/json");
    headers.set("if-match", `"liveops-${revision}"`);
  }
  return headers;
}

async function adminMutation(path: string, revision: number, body: unknown): Promise<Response> {
  return worker.fetch(`https://api.test/v1/admin/liveops${path}`, {
    method: "POST",
    headers: adminHeaders(revision),
    body: JSON.stringify(body),
  });
}

async function adminSnapshot(): Promise<z.infer<typeof adminSnapshotSchema>> {
  const response = await worker.fetch("https://api.test/v1/admin/liveops", { headers: adminHeaders() });
  expect(response.status).toBe(200);
  return adminSnapshotSchema.parse(await response.json());
}

async function publicConfig(): Promise<z.infer<typeof publicConfigSchema>> {
  const response = await worker.fetch("https://api.test/v1/config");
  expect(response.status).toBe(200);
  return publicConfigSchema.parse(await response.json());
}

beforeEach(async () => {
  await applyD1Migrations(env.DB, env.MAIN_MIGRATIONS);
  await applyD1Migrations(env.DELETIONS_DB, env.DELETION_MIGRATIONS);
  await applyD1Migrations(env.LIVEOPS_DB, env.LIVEOPS_MIGRATIONS);
  await env.LIVEOPS_DB.batch([
    env.LIVEOPS_DB.prepare("DELETE FROM liveops_audit"),
    env.LIVEOPS_DB.prepare("DELETE FROM campaign_versions"),
    env.LIVEOPS_DB.prepare("DELETE FROM campaigns"),
    env.LIVEOPS_DB.prepare(
      `UPDATE liveops_state
       SET revision = 1, active_balance_version_id = 'balance-baseline-v1',
           published_at = unixepoch(), updated_at = unixepoch()
       WHERE id = 1`,
    ),
    env.LIVEOPS_DB.prepare("DELETE FROM balance_versions WHERE id <> 'balance-baseline-v1'"),
    env.LIVEOPS_DB.prepare(
      `UPDATE balance_versions
       SET status = 'published', published_by = 'system-migration'
       WHERE id = 'balance-baseline-v1'`,
    ),
  ]);
});

describe("LiveOps API", () => {
  it("serve o baseline público, CORS restrito, cache revalidável e ETag com 304", async () => {
    const response = await worker.fetch("https://api.test/v1/config", {
      headers: { origin: "http://localhost:5173" },
    });
    expect(response.status).toBe(200);
    expect(response.headers.get("access-control-allow-origin")).toBe("http://localhost:5173");
    expect(response.headers.get("cache-control")).toBe("public, max-age=0, must-revalidate");
    expect(Number(response.headers.get("x-server-now"))).toBeGreaterThan(0);
    expect(response.headers.get("x-content-type-options")).toBe("nosniff");
    const etag = response.headers.get("etag");
    expect(etag).toMatch(/^W\/"liveops-1-[a-f0-9]{12}"$/u);
    const body = publicConfigSchema.parse(await response.json());
    expect(body.versionId).toBe("balance-baseline-v1");
    expect(body.config.economy.growthRate).toBe(1.11);
    expect(body.config.economy.milestones[0]).toEqual({ quantity: 25, multiplier: 1 });
    expect(body.config.rewards.videoGems).toBe(5);

    const notModified = await worker.fetch("https://api.test/v1/config", {
      headers: {
        origin: "http://localhost:5173",
        "if-none-match": etag ?? "missing",
      },
    });
    expect(notModified.status).toBe(304);
    expect(notModified.headers.get("etag")).toBe(etag);
    expect(notModified.headers.get("cache-control")).toBe("public, max-age=0, must-revalidate");
    expect(Number(notModified.headers.get("x-server-now"))).toBeGreaterThan(0);
    expect(await notModified.text()).toBe("");

    const hostileOrigin = await worker.fetch("https://api.test/v1/config", {
      headers: { origin: "https://evil.example" },
    });
    expect(hostileOrigin.status).toBe(403);
    expect(hostileOrigin.headers.get("cache-control")).toBe("no-store");

    const nativeRouteFromLanding = await worker.fetch("https://api.test/v1/save", {
      headers: { origin: "http://localhost:5173" },
    });
    expect(nativeRouteFromLanding.status).toBe(403);
  });

  it("rejeita configurações fora dos ranges, aliases e campos extras sem alterar revision", async () => {
    const invalidBalance = structuredClone(balanceConfig);
    invalidBalance.economy.growthRate = 1;
    const rejectedBalance = await adminMutation("/balance/drafts", 1, {
      config: invalidBalance,
      reason: "range inseguro",
    });
    expect(rejectedBalance.status).toBe(422);

    const excessiveGrowth = structuredClone(balanceConfig);
    excessiveGrowth.economy.growthRate = 2.001;
    expect((await adminMutation("/balance/drafts", 1, {
      config: excessiveGrowth,
      reason: "growth acima do cliente",
    })).status).toBe(422);

    const emptyMilestones = structuredClone(balanceConfig);
    emptyMilestones.economy.milestones = [];
    expect((await adminMutation("/balance/drafts", 1, {
      config: emptyMilestones,
      reason: "milestones obrigatórios",
    })).status).toBe(422);

    const now = Math.floor(Date.now() / 1000);
    const rejectedAlias = await adminMutation("/campaigns", 1, {
      key: "alias-invalido",
      name: "Alias inválido",
      startsAt: now + 60,
      endsAt: now + 3_600,
      effects: { freeGemsRewardMultiplier: 2 },
      reason: "validar contrato",
    });
    expect(rejectedAlias.status).toBe(422);

    const rejectedGenerator = await adminMutation("/campaigns", 1, {
      key: "gerador-invalido",
      name: "Gerador inválido",
      startsAt: now + 60,
      endsAt: now + 3_600,
      effects: { generatorProductionMultipliers: { "37": 2 } },
      reason: "limitar geradores",
    });
    expect(rejectedGenerator.status).toBe(422);

    const snapshot = await adminSnapshot();
    expect(snapshot.revision).toBe(1);
    expect(snapshot.balanceVersions).toHaveLength(1);
    expect(snapshot.campaigns).toHaveLength(0);
    const fractionalLimit = await worker.fetch(
      "https://api.test/v1/admin/liveops/audit?limit=1.5",
      { headers: adminHeaders() },
    );
    expect(fractionalLimit.status).toBe(400);
    const auditCount = await env.LIVEOPS_DB.prepare("SELECT COUNT(*) AS value FROM liveops_audit")
      .first<{ value: number }>();
    expect(auditCount?.value).toBe(0);
  });

  it("publica balance com CAS, preserva versões imutáveis e faz rollback auditável", async () => {
    const draftResponse = await adminMutation("/balance/drafts", 1, {
      config: balanceConfig,
      reason: "ajuste de alpha",
    });
    expect(draftResponse.status).toBe(201);
    const draftSnapshot = adminSnapshotSchema.parse(await draftResponse.json());
    expect(draftSnapshot.revision).toBe(2);
    const draft = draftSnapshot.balanceVersions.find((version) => version.status === "draft");
    expect(draft).toBeDefined();
    if (draft === undefined) throw new Error("missing balance draft");

    const stalePublish = await adminMutation(`/balance/${draft.id}/publish`, 1, {
      reason: "publicação concorrente",
    });
    expect(stalePublish.status).toBe(412);

    const publishedResponse = await adminMutation(`/balance/${draft.id}/publish`, 2, {
      reason: "publicar alpha",
    });
    expect(publishedResponse.status).toBe(200);
    const published = adminSnapshotSchema.parse(await publishedResponse.json());
    expect(published.revision).toBe(3);
    expect(published.activeBalance.id).toBe(draft.id);
    expect(published.activeBalance.config.rewards.videoGems).toBe(7);
    expect((await publicConfig()).versionId).toBe(draft.id);

    const rollbackResponse = await adminMutation("/balance/balance-baseline-v1/rollback", 3, {
      reason: "reverter balance",
    });
    expect(rollbackResponse.status).toBe(200);
    const rolledBack = adminSnapshotSchema.parse(await rollbackResponse.json());
    expect(rolledBack.revision).toBe(4);
    expect(rolledBack.activeBalance.id).not.toBe("balance-baseline-v1");
    expect(rolledBack.activeBalance.rollbackOfVersionId).toBe("balance-baseline-v1");
    expect(rolledBack.activeBalance.config.rewards.videoGems).toBe(5);

    const originalDraft = await env.LIVEOPS_DB.prepare(
      "SELECT config_json, config_sha256 FROM balance_versions WHERE id = ?",
    ).bind(draft.id).first<{ config_json: string; config_sha256: string }>();
    expect(originalDraft?.config_json).toContain('"videoGems":7');
    expect(originalDraft?.config_sha256).toBe(draft.sha256);
    await expect(env.LIVEOPS_DB.prepare(
      "UPDATE balance_versions SET config_json = '{}' WHERE id = ?",
    ).bind(draft.id).run()).rejects.toThrow(/immutable/u);

    const audits = await env.LIVEOPS_DB.prepare(
      "SELECT action, before_hash, after_hash FROM liveops_audit ORDER BY created_at, id",
    ).all<{ action: string; before_hash: string | null; after_hash: string | null }>();
    expect(audits.results.map((entry) => entry.action).sort()).toEqual([
      "balance.draft.create",
      "balance.publish",
      "balance.rollback",
    ].sort());
    expect(audits.results.every((entry) => entry.before_hash?.length === 64 && entry.after_hash?.length === 64)).toBe(true);
  });

  it("preserva a janela efetiva ao cancelar e substituir uma campanha", async () => {
    const now = Math.floor(Date.now() / 1000);
    const created = await adminMutation("/campaigns", 1, {
      key: "historico-efetivo",
      name: "Histórico efetivo",
      startsAt: now - 3_600,
      endsAt: now + 3_600,
      effects: { globalProductionMultiplier: 2 },
      reason: "criar campanha histórica",
    });
    const createdSnapshot = adminSnapshotSchema.parse(await created.json());
    const campaign = createdSnapshot.campaigns[0];
    const draft = campaign?.versions[0];
    if (campaign === undefined || draft === undefined) throw new Error("missing historical campaign");

    expect((await adminMutation(
      `/campaigns/${campaign.id}/versions/${draft.id}/publish`,
      2,
      { reason: "publicar campanha histórica" },
    )).status).toBe(200);
    // Simula uma versão que foi publicada no início da janela sem esperar uma hora no teste.
    await env.LIVEOPS_DB.prepare(
      "UPDATE campaign_versions SET published_at = ? WHERE id = ?",
    ).bind(now - 3_600, draft.id).run();

    expect((await adminMutation(`/campaigns/${campaign.id}/cancel`, 3, {
      reason: "encerrar campanha histórica",
    })).status).toBe(200);
    const afterCancel = (await publicConfig()).campaigns
      .filter((item) => item.key === "historico-efetivo");
    expect(afterCancel).toHaveLength(1);
    expect(afterCancel[0]?.startsAt).toBe(now - 3_600);
    expect(afterCancel[0]?.endsAt).toBeGreaterThanOrEqual(now);

    expect((await adminMutation(
      `/campaigns/${campaign.id}/versions/${draft.id}/rollback`,
      4,
      { reason: "reativar campanha histórica" },
    )).status).toBe(200);
    const afterRollback = (await publicConfig()).campaigns
      .filter((item) => item.key === "historico-efetivo")
      .sort((left, right) => left.startsAt - right.startsAt);
    expect(afterRollback).toHaveLength(2);
    expect(new Set(afterRollback.map((item) => item.versionId)).size).toBe(2);
    expect(afterRollback[0]?.endsAt).toBeLessThanOrEqual(afterRollback[1]?.startsAt ?? 0);
  });

  it("agenda campanhas futuras, mantém janela offline de 15 dias e suporta cancel/rollback/audit paginado", async () => {
    const now = Math.floor(Date.now() / 1000);
    const createdFuture = await adminMutation("/campaigns", 1, {
      key: "semana-pentecostes",
      name: "Semana de Pentecostes",
      startsAt: now + 86_400,
      endsAt: now + 172_800,
      effects: {
        globalProductionMultiplier: 2,
        freeGemRewardMultiplier: 1.5,
        generatorProductionMultipliers: { "25": 3 },
      },
      reason: "criar campanha futura",
    });
    expect(createdFuture.status).toBe(201);
    const futureDraftSnapshot = adminSnapshotSchema.parse(await createdFuture.json());
    const futureCampaign = futureDraftSnapshot.campaigns[0];
    const futureDraft = futureCampaign?.versions[0];
    if (futureCampaign === undefined || futureDraft === undefined) throw new Error("missing campaign draft");

    const publishFuture = await adminMutation(
      `/campaigns/${futureCampaign.id}/versions/${futureDraft.id}/publish`,
      2,
      { reason: "agendar campanha futura" },
    );
    expect(publishFuture.status).toBe(200);
    const publicFuture = await publicConfig();
    expect(publicFuture.campaigns.map((campaign) => campaign.key)).toContain("semana-pentecostes");

    const cancelled = await adminMutation(`/campaigns/${futureCampaign.id}/cancel`, 3, {
      reason: "cancelar agenda",
    });
    expect(cancelled.status).toBe(200);
    expect((await publicConfig()).campaigns).toHaveLength(0);

    const rollback = await adminMutation(
      `/campaigns/${futureCampaign.id}/versions/${futureDraft.id}/rollback`,
      4,
      { reason: "restaurar agenda" },
    );
    expect(rollback.status).toBe(200);
    const rollbackSnapshot = adminSnapshotSchema.parse(await rollback.json());
    const restoredCampaign = rollbackSnapshot.campaigns.find((campaign) => campaign.id === futureCampaign.id);
    const restored = restoredCampaign?.versions.find((version) => version.status === "published");
    expect(restored?.rollbackOfVersionId).toBe(futureDraft.id);
    await expect(env.LIVEOPS_DB.prepare(
      "UPDATE campaign_versions SET name = 'mutado' WHERE id = ?",
    ).bind(futureDraft.id).run()).rejects.toThrow(/immutable/u);

    const recentExpired = await adminMutation("/campaigns", 5, {
      key: "offline-recente",
      name: "Evento encerrado recentemente",
      startsAt: now - 7_200,
      endsAt: now - 3_600,
      effects: { offlineProductionMultiplier: 2, freeGemRewardMultiplier: 0 },
      reason: "cobrir cálculo offline",
    });
    const recentSnapshot = adminSnapshotSchema.parse(await recentExpired.json());
    const recentCampaign = recentSnapshot.campaigns.find((campaign) => campaign.key === "offline-recente");
    const recentDraft = recentCampaign?.versions[0];
    if (recentCampaign === undefined || recentDraft === undefined) throw new Error("missing recent campaign");
    expect((await adminMutation(
      `/campaigns/${recentCampaign.id}/versions/${recentDraft.id}/publish`,
      6,
      { reason: "publicar janela offline" },
    )).status).toBe(200);
    await env.LIVEOPS_DB.prepare(
      "UPDATE campaign_versions SET published_at = starts_at - 60 WHERE id = ?",
    ).bind(recentDraft.id).run();

    const tooOld = await adminMutation("/campaigns", 7, {
      key: "offline-antigo",
      name: "Evento fora da janela",
      startsAt: now - 17 * 86_400,
      endsAt: now - 16 * 86_400,
      effects: { manualProductionMultiplier: 2 },
      reason: "validar corte offline",
    });
    const tooOldSnapshot = adminSnapshotSchema.parse(await tooOld.json());
    const oldCampaign = tooOldSnapshot.campaigns.find((campaign) => campaign.key === "offline-antigo");
    const oldDraft = oldCampaign?.versions[0];
    if (oldCampaign === undefined || oldDraft === undefined) throw new Error("missing old campaign");
    expect((await adminMutation(
      `/campaigns/${oldCampaign.id}/versions/${oldDraft.id}/publish`,
      8,
      { reason: "publicar campanha antiga" },
    )).status).toBe(200);
    await env.LIVEOPS_DB.prepare(
      "UPDATE campaign_versions SET published_at = starts_at - 60 WHERE id = ?",
    ).bind(oldDraft.id).run();

    const publicCampaignKeys = (await publicConfig()).campaigns.map((campaign) => campaign.key);
    expect(publicCampaignKeys).toContain("semana-pentecostes");
    expect(publicCampaignKeys).toContain("offline-recente");
    expect(publicCampaignKeys).not.toContain("offline-antigo");
    const publicRecent = (await publicConfig()).campaigns.find((campaign) => campaign.key === "offline-recente");
    expect(publicRecent?.effects).toEqual({
      globalProductionMultiplier: 1,
      offlineProductionMultiplier: 2,
      manualProductionMultiplier: 1,
      studyFaithMultiplier: 1,
      freeGemRewardMultiplier: 0,
      generatorProductionMultipliers: {},
    });

    const firstAuditPageResponse = await worker.fetch(
      "https://api.test/v1/admin/liveops/audit?limit=2",
      { headers: adminHeaders() },
    );
    expect(firstAuditPageResponse.status).toBe(200);
    const auditPageSchema = z.object({
      items: z.array(z.object({
        action: z.string(),
        beforeHash: z.string().nullable(),
        afterHash: z.string().nullable(),
        reason: z.string(),
        metadata: z.record(z.string(), z.unknown()),
      })),
      nextCursor: z.string().nullable(),
    });
    const firstAuditPage = auditPageSchema.parse(await firstAuditPageResponse.json());
    expect(firstAuditPage.items).toHaveLength(2);
    expect(firstAuditPage.nextCursor).toMatch(/^\d+:[A-Za-z0-9-]+$/u);
    const secondAuditPageResponse = await worker.fetch(
      `https://api.test/v1/admin/liveops/audit?limit=100&cursor=${encodeURIComponent(firstAuditPage.nextCursor ?? "")}`,
      { headers: adminHeaders() },
    );
    const secondAuditPage = auditPageSchema.parse(await secondAuditPageResponse.json());
    const allActions = [...firstAuditPage.items, ...secondAuditPage.items].map((entry) => entry.action);
    expect(allActions).toContain("campaign.publish");
    expect(allActions).toContain("campaign.cancel");
    expect(allActions).toContain("campaign.rollback");
    const completeAuditResponse = await worker.fetch(
      "https://api.test/v1/admin/liveops/audit?limit=100",
      { headers: adminHeaders() },
    );
    const completeAudit = auditPageSchema.parse(await completeAuditResponse.json());
    const rollbackAudit = completeAudit.items
      .find((entry) => entry.action === "campaign.rollback");
    expect(rollbackAudit?.beforeHash).toHaveLength(64);
    expect(rollbackAudit?.afterHash).toHaveLength(64);
  });
});
