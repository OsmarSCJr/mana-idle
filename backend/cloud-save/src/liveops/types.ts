export interface MilestoneConfig {
  quantity: number;
  multiplier: number;
}

export interface BalanceConfig {
  economy: {
    growthRate: number;
    saintBonus: number;
    prestigeDivisor: number;
    prophetUnlockQuantity: number;
    prophetCostMultiplier: number;
    offlineCapSeconds: number;
    milestones: MilestoneConfig[];
  };
  boosts: {
    fervorProductionMultiplier: number;
    pentecostProductionMultiplier: number;
    holyHandsManualMultiplier: number;
    swiftStepTimeMultiplier: number;
    harvestSeconds: number;
  };
  rewards: {
    videoGems: number;
    offlineTripleGemCost: number;
  };
}

export interface CampaignEffects {
  globalProductionMultiplier: number;
  offlineProductionMultiplier: number;
  manualProductionMultiplier: number;
  studyFaithMultiplier: number;
  freeGemRewardMultiplier: number;
  generatorProductionMultipliers: Record<string, number>;
}

export type BalanceVersionStatus = "draft" | "published" | "superseded";
export type CampaignVersionStatus = "draft" | "published" | "superseded" | "cancelled";

export interface BalanceVersion {
  id: string;
  status: BalanceVersionStatus;
  config: BalanceConfig;
  sha256: string;
  createdBy: string;
  createdAt: number;
  publishedBy: string | null;
  publishedAt: number | null;
  rollbackOfVersionId: string | null;
}

export interface CampaignVersion {
  id: string;
  version: number;
  status: CampaignVersionStatus;
  name: string;
  startsAt: number;
  endsAt: number;
  effects: CampaignEffects;
  sha256: string;
  createdBy: string;
  createdAt: number;
  publishedBy: string | null;
  publishedAt: number | null;
  retiredAt: number | null;
  rollbackOfVersionId: string | null;
  cancelledBy: string | null;
  cancelledAt: number | null;
}

export interface AdminCampaign {
  id: string;
  key: string;
  activeVersionId: string | null;
  createdAt: number;
  versions: CampaignVersion[];
}

export interface LiveOpsAdminSnapshot {
  schemaVersion: 1;
  revision: number;
  etag: string;
  activeBalance: BalanceVersion;
  balanceVersions: BalanceVersion[];
  campaigns: AdminCampaign[];
  serverNow: number;
}

export interface PublicCampaign {
  id: string;
  key: string;
  versionId: string;
  version: number;
  name: string;
  startsAt: number;
  endsAt: number;
  publishedAt: number;
  effects: CampaignEffects;
}

export interface PublicLiveOpsConfig {
  schemaVersion: 1;
  revision: number;
  versionId: string;
  publishedAt: number;
  serverNow: number;
  config: BalanceConfig;
  campaigns: PublicCampaign[];
}

export interface LiveOpsAuditEntry {
  id: string;
  actor: string;
  action: string;
  targetType: string;
  targetId: string;
  beforeHash: string | null;
  afterHash: string | null;
  reason: string;
  requestId: string;
  metadata: Record<string, unknown>;
  createdAt: number;
}
