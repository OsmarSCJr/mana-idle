import type {
  AuditResult,
  DeletionResult,
  LiveOpsAuditResult,
  LiveOpsBalanceConfig,
  LiveOpsCampaignEffects,
  LiveOpsSnapshot,
  Operations,
  Overview,
  PlayerDetail,
  PlayerSearchResult,
  SaveMutationResponse,
} from "./types";

interface ApiErrorEnvelope {
  error?: {
    code?: string;
    message?: string;
    requestId?: string;
  };
}

const ADMIN_BASE = "/api/v1/admin";

function liveOpsHeaders(etag: string): HeadersInit {
  return { "If-Match": etag };
}

export class AdminApiError extends Error {
  readonly status: number;
  readonly code: string;
  readonly requestId?: string;

  constructor(status: number, code: string, message: string, requestId?: string) {
    super(message);
    this.name = "AdminApiError";
    this.status = status;
    this.code = code;
    this.requestId = requestId;
  }
}

async function request<T>(path: string, init?: RequestInit): Promise<T> {
  const headers = new Headers(init?.headers);
  headers.set("Accept", "application/json");
  if (init?.body) headers.set("Content-Type", "application/json");

  const response = await fetch(`${ADMIN_BASE}${path}`, {
    ...init,
    headers,
    credentials: "same-origin",
    cache: "no-store",
  });

  if (!response.ok) {
    let envelope: ApiErrorEnvelope = {};
    try {
      envelope = (await response.json()) as ApiErrorEnvelope;
    } catch {
      // Erros de borda nem sempre têm corpo JSON.
    }
    throw new AdminApiError(
      response.status,
      envelope.error?.code ?? "REQUEST_FAILED",
      envelope.error?.message ?? "Não foi possível concluir a operação.",
      envelope.error?.requestId ?? response.headers.get("X-Request-Id") ?? undefined,
    );
  }

  if (response.status === 204) return undefined as T;
  const contentType = response.headers.get("Content-Type")?.toLowerCase() ?? "";
  if (response.redirected || !contentType.includes("application/json")) {
    throw new AdminApiError(
      401,
      "ACCESS_REQUIRED",
      "A sessão do Cloudflare Access expirou ou precisa ser renovada.",
      response.headers.get("X-Request-Id") ?? undefined,
    );
  }
  return (await response.json()) as T;
}

function queryString(params: Record<string, string | number | undefined | null>): string {
  const query = new URLSearchParams();
  for (const [key, value] of Object.entries(params)) {
    if (value !== undefined && value !== null && value !== "") query.set(key, String(value));
  }
  const encoded = query.toString();
  return encoded ? `?${encoded}` : "";
}

export const adminApi = {
  overview: () => request<Overview>("/overview"),
  players: (query: string, cursor?: string, limit = 25) =>
    request<PlayerSearchResult>(`/players${queryString({ query, cursor, limit })}`),
  player: (playerId: string) => request<PlayerDetail>(`/players/${encodeURIComponent(playerId)}`),
  revokeDevice: (playerId: string, deviceId: string, reason: string) =>
    request<{ revoked: true; deviceId: string }>(
      `/players/${encodeURIComponent(playerId)}/devices/${encodeURIComponent(deviceId)}/revoke`,
      { method: "POST", body: JSON.stringify({ reason }) },
    ),
  revokeAllSessions: (playerId: string, reason: string) =>
    request<{ revokedSessions: number }>(
      `/players/${encodeURIComponent(playerId)}/sessions/revoke-all`,
      { method: "POST", body: JSON.stringify({ reason }) },
    ),
  restorePreviousSave: (playerId: string, revision: number, reason: string) =>
    request<SaveMutationResponse>(
      `/players/${encodeURIComponent(playerId)}/save/restore-previous`,
      {
        method: "POST",
        headers: { "If-Match": `"save-${revision}"` },
        body: JSON.stringify({ reason }),
      },
    ),
  operations: () => request<Operations>("/operations"),
  updateOperations: (changes: Partial<Omit<Operations, "updatedAt">>, reason: string) =>
    request<Operations>("/operations", {
      method: "PUT",
      body: JSON.stringify({ ...changes, reason }),
    }),
  deletions: (status: "pending" | "completed", cursor?: string, limit = 50) =>
    request<DeletionResult>(`/deletions${queryString({ status, cursor, limit })}`),
  audit: (cursor?: string, limit = 50) =>
    request<AuditResult>(`/audit${queryString({ cursor, limit })}`),
  liveOps: () => request<LiveOpsSnapshot>("/liveops"),
  liveOpsAudit: (cursor?: string, limit = 30) =>
    request<LiveOpsAuditResult>(`/liveops/audit${queryString({ cursor, limit })}`),
  createBalanceDraft: (config: LiveOpsBalanceConfig, reason: string, etag: string) =>
    request<LiveOpsSnapshot>("/liveops/balance/drafts", {
      method: "POST",
      headers: liveOpsHeaders(etag),
      body: JSON.stringify({ config, reason }),
    }),
  publishBalance: (versionId: string, reason: string, etag: string) =>
    request<LiveOpsSnapshot>(
      `/liveops/balance/${encodeURIComponent(versionId)}/publish`,
      {
        method: "POST",
        headers: liveOpsHeaders(etag),
        body: JSON.stringify({ reason }),
      },
    ),
  rollbackBalance: (versionId: string, reason: string, etag: string) =>
    request<LiveOpsSnapshot>(
      `/liveops/balance/${encodeURIComponent(versionId)}/rollback`,
      {
        method: "POST",
        headers: liveOpsHeaders(etag),
        body: JSON.stringify({ reason }),
      },
    ),
  createCampaign: (campaign: {
    key: string;
    name: string;
    startsAt: number;
    endsAt: number;
    effects: LiveOpsCampaignEffects;
  }, reason: string, etag: string) =>
    request<LiveOpsSnapshot>("/liveops/campaigns", {
      method: "POST",
      headers: liveOpsHeaders(etag),
      body: JSON.stringify({ ...campaign, reason }),
    }),
  createCampaignDraft: (campaignId: string, campaign: {
    name: string;
    startsAt: number;
    endsAt: number;
    effects: LiveOpsCampaignEffects;
  }, reason: string, etag: string) =>
    request<LiveOpsSnapshot>(
      `/liveops/campaigns/${encodeURIComponent(campaignId)}/drafts`,
      {
        method: "POST",
        headers: liveOpsHeaders(etag),
        body: JSON.stringify({ ...campaign, reason }),
      },
    ),
  publishCampaign: (campaignId: string, versionId: string, reason: string, etag: string) =>
    request<LiveOpsSnapshot>(
      `/liveops/campaigns/${encodeURIComponent(campaignId)}/versions/${encodeURIComponent(versionId)}/publish`,
      {
        method: "POST",
        headers: liveOpsHeaders(etag),
        body: JSON.stringify({ reason }),
      },
    ),
  cancelCampaign: (campaignId: string, reason: string, etag: string) =>
    request<LiveOpsSnapshot>(
      `/liveops/campaigns/${encodeURIComponent(campaignId)}/cancel`,
      {
        method: "POST",
        headers: liveOpsHeaders(etag),
        body: JSON.stringify({ reason }),
      },
    ),
  rollbackCampaign: (campaignId: string, versionId: string, reason: string, etag: string) =>
    request<LiveOpsSnapshot>(
      `/liveops/campaigns/${encodeURIComponent(campaignId)}/versions/${encodeURIComponent(versionId)}/rollback`,
      {
        method: "POST",
        headers: liveOpsHeaders(etag),
        body: JSON.stringify({ reason }),
      },
    ),
};
