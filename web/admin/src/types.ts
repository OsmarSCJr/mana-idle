export interface Overview {
  players: { active: number; deleting: number };
  saves: { total: number; withPayload: number; avgBytes: number; maxBytes: number };
  sessions: { active: number };
  deletions: { pending: number };
  wallet: { freeOutstanding: number };
  serverNow: number;
}

export interface PlayerListItem {
  playerId: string;
  status: "active" | "deleting" | string;
  createdAt: number;
  deviceCount: number;
  activeSessionCount: number;
  saveRevision: number;
  saveBytes: number | null;
  saveUpdatedAt: number | null;
  freeBalance: number;
}

export interface PlayerSearchResult {
  items: PlayerListItem[];
  nextCursor?: string | null;
}

export interface PlayerRecord {
  playerId: string;
  status: string;
  createdAt: number;
  recoveryRotatedAt?: number | null;
  deletionRequestedAt?: number | null;
}

export interface SaveMetadata {
  revision: number;
  schemaVersion: number | null;
  sha256: string | null;
  bytes: number | null;
  updatedAt: number | null;
  previousRevision: number | null;
  previousUpdatedAt: number | null;
}

export interface DeviceMetadata {
  deviceId: string;
  installationId: string;
  deviceLabel?: string | null;
  platform?: string | null;
  clientVersion?: string | null;
  kind: "game" | "web_deletion" | string;
  createdAt: number;
  lastSeenAt?: number | null;
  revokedAt?: number | null;
}

export interface SessionMetadata {
  sessionId: string;
  deviceId: string;
  purpose?: string | null;
  createdAt: number;
  lastSeenAt?: number | null;
  idleExpiresAt?: number | null;
  absoluteExpiresAt?: number | null;
  revokedAt?: number | null;
}

export interface WalletMetadata {
  freeBalance: number;
  paidBalance?: number;
  revision: number;
  updatedAt?: number | null;
}

export interface SecurityAction {
  id: string;
  kind: string;
  status: string;
  requestedByDeviceId?: string | null;
  createdAt: number;
  executeAfter?: number | null;
  cancelledAt?: number | null;
  completedAt?: number | null;
}

export interface PlayerDetail {
  player: PlayerRecord;
  save: SaveMetadata | null;
  devices: DeviceMetadata[];
  sessions: SessionMetadata[];
  wallet: WalletMetadata | null;
  securityActions: SecurityAction[];
}

export interface SaveMutationResponse {
  revision: number;
  etag: string;
  sha256: string;
  serverUpdatedAt: number;
  serverNow: number;
}

export interface Operations {
  maintenanceMode: boolean;
  readOnlyUploads: boolean;
  allowNewAccounts: boolean;
  minClientVersion: string | null;
  updatedAt: number;
}

export interface DeletionRecord {
  playerHmac: string;
  status: "pending" | "completed" | string;
  requestedAt: number;
  completedAt: number | null;
  expiresAt: number;
  lastErrorCode: string | null;
}

export interface DeletionResult {
  items: DeletionRecord[];
  nextCursor?: string | null;
}

export interface AuditRecord {
  id: string;
  actor: string;
  action: string;
  targetType: string;
  targetIdHash: string | null;
  reason: string;
  createdAt: number;
  requestId: string;
}

export interface AuditResult {
  items: AuditRecord[];
  nextCursor?: string | null;
}

export interface LiveOpsMilestone {
  quantity: number;
  multiplier: number;
}

export interface LiveOpsGrowthSegment {
  maxQuantity: number;
  rate: number;
}

export interface LiveOpsGeneralMilestone extends LiveOpsMilestone {
  type: "speed" | "prod";
  gems: number;
  relics: number;
}

export interface LiveOpsBalanceConfig {
  economy: {
    growthSegments: LiveOpsGrowthSegment[];
    saintBonus: number;
    prestigeDivisor: number;
    prophetUnlockQuantity: number;
    prophetCostMultiplier: number;
    prophetSpeedMultiplier: number;
    offlineCapSeconds: number;
    dadivaLadderBaseCost: number;
    dadivaLadderCostGrowth: number;
    dadivaLadderMultiplier: number;
    milestones: LiveOpsMilestone[];
    generalMilestones: LiveOpsGeneralMilestone[];
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
    novaStarMinSeconds: number;
    novaStarMaxSeconds: number;
    novaStarProductionSeconds: number;
    novaStarDailyGems: number;
  };
}

export interface LiveOpsBalanceVersion {
  id: string;
  status: "draft" | "published" | "superseded";
  config: LiveOpsBalanceConfig;
  sha256: string;
  createdBy: string;
  createdAt: number;
  publishedBy: string | null;
  publishedAt: number | null;
  rollbackOfVersionId: string | null;
}

export interface LiveOpsCampaignEffects {
  globalProductionMultiplier?: number;
  offlineProductionMultiplier?: number;
  manualProductionMultiplier?: number;
  studyFaithMultiplier?: number;
  freeGemRewardMultiplier?: number;
  generatorProductionMultipliers?: Record<string, number>;
}

export interface LiveOpsCampaignVersion {
  id: string;
  version: number;
  status: "draft" | "published" | "superseded" | "cancelled";
  name: string;
  startsAt: number;
  endsAt: number;
  effects: LiveOpsCampaignEffects;
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

export interface LiveOpsAdminCampaign {
  id: string;
  key: string;
  activeVersionId: string | null;
  createdAt: number;
  versions: LiveOpsCampaignVersion[];
}

export interface LiveOpsSnapshot {
  schemaVersion: number;
  revision: number;
  etag: string;
  activeBalance: LiveOpsBalanceVersion | null;
  balanceVersions: LiveOpsBalanceVersion[];
  campaigns: LiveOpsAdminCampaign[];
  serverNow: number;
}

export interface LiveOpsAuditRecord {
  id: string;
  actor: string;
  action: string;
  targetType: string;
  targetId: string | null;
  beforeHash: string | null;
  afterHash: string | null;
  reason: string;
  requestId: string;
  metadata: Record<string, unknown> | null;
  createdAt: number;
}

export interface LiveOpsAuditResult {
  items: LiveOpsAuditRecord[];
  nextCursor: string | null;
}
