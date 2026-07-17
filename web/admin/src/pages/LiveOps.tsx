import {
  ArchiveRestore,
  CalendarClock,
  CheckCircle2,
  ChevronRight,
  CircleDotDashed,
  Clock3,
  Coins,
  Gem,
  History,
  LoaderCircle,
  Megaphone,
  Plus,
  RefreshCw,
  Rocket,
  Save,
  Search,
  SlidersHorizontal,
  Sparkles,
  Trash2,
  TriangleAlert,
  Zap,
} from "lucide-react";
import { useCallback, useEffect, useMemo, useState, type ReactNode } from "react";
import { adminApi, AdminApiError } from "../api";
import { formatDate, shortId } from "../format";
import type {
  LiveOpsAdminCampaign,
  LiveOpsAuditRecord,
  LiveOpsBalanceConfig,
  LiveOpsBalanceVersion,
  LiveOpsCampaignVersion,
  LiveOpsSnapshot,
} from "../types";
import {
  ConfirmDialog,
  CopyButton,
  EmptyState,
  ErrorPanel,
  LoadingBlock,
  PageHeader,
  StatusBadge,
  type ConfirmationRequest,
} from "../components/Ui";

type LiveOpsTab = "balance" | "campaigns" | "history";
type CampaignDisplayStatus = "draft" | "scheduled" | "active" | "ended" | "cancelled";

interface CampaignForm {
  campaignId: string | null;
  sourceVersionId: string | null;
  key: string;
  name: string;
  startsAt: string;
  endsAt: string;
  effects: CampaignEditorEffects;
}

interface CampaignEditorEffects {
  globalProductionMultiplier: number;
  offlineProductionMultiplier: number;
  manualProductionMultiplier: number;
  studyFaithMultiplier: number;
  freeGemRewardMultiplier: number;
  generatorProductionMultipliers: Record<string, number>;
}

const DEFAULT_MILESTONES = [
  [25, 1.5], [50, 3], [75, 3], [100, 7], [200, 1.5], [300, 3], [400, 1.5], [500, 7],
  [600, 1.5], [700, 3], [800, 1.5], [900, 3], [1000, 7], [1250, 1.5], [1500, 3],
  [1750, 1.5], [2000, 7], [2250, 1.5], [2500, 3], [2750, 1.5], [3000, 7], [3250, 1.5],
  [3500, 3], [3750, 1.5], [4000, 7], [4250, 1.5], [4500, 3], [4750, 1.5], [5000, 7],
  [5250, 1.5], [5500, 3], [5750, 1.5], [6000, 7], [6250, 1.5], [6500, 3], [6750, 1.5],
  [7000, 7], [7250, 1.5], [7500, 3], [7750, 1.5], [8000, 7], [8250, 1.5], [8500, 3],
  [8750, 1.5], [9000, 7], [9250, 1.5], [9500, 3],
] as const;

const DEFAULT_BALANCE: LiveOpsBalanceConfig = {
  economy: {
    growthSegments: [
      { maxQuantity: 300, rate: 1.11 }, { maxQuantity: 1500, rate: 1.05 },
      { maxQuantity: 4000, rate: 1.012 }, { maxQuantity: 0, rate: 1.008 },
    ],
    saintBonus: 0.2,
    prestigeDivisor: 200_000_000_000,
    prophetUnlockQuantity: 25,
    prophetCostMultiplier: 10,
    prophetSpeedMultiplier: 0.8,
    offlineCapSeconds: 28_800,
    dadivaLadderBaseCost: 10,
    dadivaLadderCostGrowth: 1.8,
    dadivaLadderMultiplier: 1.3,
    milestones: DEFAULT_MILESTONES.map(([quantity, multiplier]) => ({ quantity, multiplier })),
    generalMilestones: [
      { quantity: 25, type: "speed", multiplier: 1.5, gems: 0, relics: 0 },
      { quantity: 50, type: "speed", multiplier: 1.5, gems: 0, relics: 0 },
      { quantity: 100, type: "speed", multiplier: 2, gems: 10, relics: 0 },
      { quantity: 250, type: "prod", multiplier: 3, gems: 0, relics: 0 },
      { quantity: 500, type: "prod", multiplier: 5, gems: 20, relics: 0 },
      { quantity: 1000, type: "prod", multiplier: 7, gems: 0, relics: 25 },
      { quantity: 2500, type: "prod", multiplier: 10, gems: 30, relics: 0 },
      { quantity: 5000, type: "prod", multiplier: 15, gems: 0, relics: 50 },
      { quantity: 10_000, type: "prod", multiplier: 20, gems: 100, relics: 100 },
    ],
  },
  boosts: {
    fervorProductionMultiplier: 2,
    pentecostProductionMultiplier: 5,
    holyHandsManualMultiplier: 10,
    swiftStepTimeMultiplier: 0.5,
    harvestSeconds: 7_200,
  },
  rewards: {
    videoGems: 5,
    offlineTripleGemCost: 3,
    novaStarMinSeconds: 300,
    novaStarMaxSeconds: 900,
    novaStarProductionSeconds: 120,
    novaStarDailyGems: 2,
  },
};

const DEFAULT_EFFECTS: CampaignEditorEffects = {
  globalProductionMultiplier: 1,
  offlineProductionMultiplier: 1,
  manualProductionMultiplier: 1,
  studyFaithMultiplier: 1,
  freeGemRewardMultiplier: 1,
  generatorProductionMultipliers: {},
};

const GENERATORS = [
  "Haja Luz",
  "Jardim do Éden",
  "Arca de Noé",
  "Torre de Babel",
  "Maná do Céu",
  "Mar Vermelho",
  "Muralhas de Jericó",
  "Sansão",
  "Davi vs Golias",
  "Templo de Salomão",
  "Jonas e a Baleia",
  "Fornalha Ardente",
  "Nascimento em Belém",
  "Fuga para o Egito",
  "Batismo no Jordão",
  "Bodas de Caná",
  "Sermão do Monte",
  "Multiplicação dos Pães",
  "Caminhar sobre as Águas",
  "Transfiguração",
  "Ressurreição de Lázaro",
  "Entrada em Jerusalém",
  "Última Ceia",
  "Ressurreição",
  "Pentecostes",
  "Conversão de Saulo",
  "Viagens Missionárias",
  "Cartas às Igrejas",
  "Mártires da Fé",
  "Édito de Milão",
  "Reforma Protestante",
  "Grande Comissão",
  "Evangelismo Mundial",
  "Sete Igrejas da Ásia",
  "Apocalipse",
  "Nova Jerusalém",
].map((name, index) => ({ id: String(index + 1), name }));

function clone<T>(value: T): T {
  return structuredClone(value);
}

function latestBalanceDraft(snapshot: LiveOpsSnapshot): LiveOpsBalanceVersion | null {
  return [...snapshot.balanceVersions]
    .filter((version) => version.status === "draft")
    .sort((left, right) => right.createdAt - left.createdAt)[0] ?? null;
}

function latestCampaignVersion(campaign: LiveOpsAdminCampaign): LiveOpsCampaignVersion | null {
  return [...campaign.versions].sort((left, right) => right.version - left.version)[0] ?? null;
}

function activeCampaignVersion(campaign: LiveOpsAdminCampaign): LiveOpsCampaignVersion | null {
  if (!campaign.activeVersionId) return null;
  return campaign.versions.find((version) => version.id === campaign.activeVersionId) ?? null;
}

function preferredCampaignVersion(campaign: LiveOpsAdminCampaign): LiveOpsCampaignVersion | null {
  const draft = [...campaign.versions]
    .filter((version) => version.status === "draft")
    .sort((left, right) => right.version - left.version)[0];
  return draft ?? activeCampaignVersion(campaign) ?? latestCampaignVersion(campaign);
}

function campaignStatus(campaign: LiveOpsAdminCampaign, serverNow: number): CampaignDisplayStatus {
  const active = activeCampaignVersion(campaign);
  if (!active) {
    const latest = latestCampaignVersion(campaign);
    return latest?.status === "cancelled" ? "cancelled" : "draft";
  }
  if (active.status === "cancelled") return "cancelled";
  if (active.startsAt > serverNow) return "scheduled";
  if (active.endsAt <= serverNow) return "ended";
  return "active";
}

function pad(value: number): string {
  return String(value).padStart(2, "0");
}

function toLocalDateTime(timestamp: number): string {
  const date = new Date(timestamp * 1000);
  if (Number.isNaN(date.getTime())) return "";
  return [
    date.getFullYear(),
    "-",
    pad(date.getMonth() + 1),
    "-",
    pad(date.getDate()),
    "T",
    pad(date.getHours()),
    ":",
    pad(date.getMinutes()),
  ].join("");
}

function fromLocalDateTime(value: string): number {
  const milliseconds = new Date(value).getTime();
  return Number.isFinite(milliseconds) ? Math.floor(milliseconds / 1000) : 0;
}

function newCampaignForm(serverNow: number): CampaignForm {
  const start = new Date((serverNow + 3_600) * 1000);
  start.setMinutes(0, 0, 0);
  const end = new Date(start.getTime() + 3 * 86_400_000);
  return {
    campaignId: null,
    sourceVersionId: null,
    key: "",
    name: "",
    startsAt: toLocalDateTime(Math.floor(start.getTime() / 1000)),
    endsAt: toLocalDateTime(Math.floor(end.getTime() / 1000)),
    effects: clone(DEFAULT_EFFECTS),
  };
}

function normalizedCampaignEffects(
  effects: LiveOpsCampaignVersion["effects"],
): CampaignEditorEffects {
  return {
    globalProductionMultiplier: effects.globalProductionMultiplier ?? 1,
    offlineProductionMultiplier: effects.offlineProductionMultiplier ?? 1,
    manualProductionMultiplier: effects.manualProductionMultiplier ?? 1,
    studyFaithMultiplier: effects.studyFaithMultiplier ?? 1,
    freeGemRewardMultiplier: effects.freeGemRewardMultiplier ?? 1,
    generatorProductionMultipliers: clone(effects.generatorProductionMultipliers ?? {}),
  };
}

function campaignForm(
  campaign: LiveOpsAdminCampaign,
  version: LiveOpsCampaignVersion,
): CampaignForm {
  return {
    campaignId: campaign.id,
    sourceVersionId: version.id,
    key: campaign.key,
    name: version.name,
    startsAt: toLocalDateTime(version.startsAt),
    endsAt: toLocalDateTime(version.endsAt),
    effects: normalizedCampaignEffects(version.effects),
  };
}

function etagFor(snapshot: LiveOpsSnapshot): string {
  return snapshot.etag.trim() || "\"liveops-" + snapshot.revision + "\"";
}

function balanceErrors(config: LiveOpsBalanceConfig): string[] {
  const errors: string[] = [];
  const inRange = (value: number, minimum: number, maximum: number) =>
    Number.isFinite(value) && value >= minimum && value <= maximum;
  const segments = config.economy.growthSegments;
  if (segments.length === 0 || segments.length > 8) errors.push("Use entre 1 e 8 faixas de custo.");
  if (segments.some((segment) => !inRange(segment.rate, 1.000001, 2))) {
    errors.push("O growth de cada faixa deve ficar entre 1,000001 e 2.");
  }
  if (segments.some((segment, index) => {
    const last = index === segments.length - 1;
    return !Number.isInteger(segment.maxQuantity)
      || (last ? segment.maxQuantity !== 0 : segment.maxQuantity <= (segments[index - 1]?.maxQuantity ?? 0));
  })) errors.push("As faixas devem ter limites crescentes e terminar em 0 (sem teto).");
  if (!inRange(config.economy.saintBonus, 0, 10)) {
    errors.push("O bônus por Santo deve ficar entre 0 e 10.");
  }
  if (!inRange(config.economy.prestigeDivisor, 1, 1e100)) {
    errors.push("O divisor de prestígio deve ficar entre 1 e 1e100.");
  }
  if (!Number.isInteger(config.economy.prophetUnlockQuantity)
    || !inRange(config.economy.prophetUnlockQuantity, 1, 10_000)) {
    errors.push("O desbloqueio de Profeta deve ser um inteiro entre 1 e 10.000.");
  }
  if (!inRange(config.economy.prophetCostMultiplier, 0.001, 1_000_000)) {
    errors.push("O custo do Profeta deve ficar entre 0,001 e 1.000.000.");
  }
  if (!inRange(config.economy.prophetSpeedMultiplier, 0.05, 2)) {
    errors.push("A velocidade do Profeta deve ficar entre 0,05 e 2.");
  }
  if (!inRange(config.economy.dadivaLadderBaseCost, 1, 1_000_000_000)
    || !inRange(config.economy.dadivaLadderCostGrowth, 1.01, 100)
    || !inRange(config.economy.dadivaLadderMultiplier, 1, 100)) {
    errors.push("Revise os parâmetros da escada de Dádivas.");
  }
  if (!Number.isInteger(config.economy.offlineCapSeconds)
    || !inRange(config.economy.offlineCapSeconds, 60, 31_536_000)) {
    errors.push("O limite offline deve ser um inteiro entre 1 minuto e 1 ano.");
  }
  if (![config.boosts.fervorProductionMultiplier, config.boosts.pentecostProductionMultiplier,
    config.boosts.holyHandsManualMultiplier].every((value) => inRange(value, 1, 100))) {
    errors.push("Multiplicadores de Fervor, Pentecoste e Mãos Santas devem ficar entre 1 e 100.");
  }
  if (!inRange(config.boosts.swiftStepTimeMultiplier, 0.05, 1)) {
    errors.push("O fator do Passo Ligeiro deve ficar entre 0,05 e 1.");
  }
  if (!Number.isInteger(config.boosts.harvestSeconds)
    || !inRange(config.boosts.harvestSeconds, 60, 604_800)) {
    errors.push("A Colheita deve representar entre 60 segundos e 7 dias.");
  }
  if (!Number.isInteger(config.rewards.videoGems)
    || !inRange(config.rewards.videoGems, 0, 10_000)
    || !Number.isInteger(config.rewards.offlineTripleGemCost)
    || !inRange(config.rewards.offlineTripleGemCost, 0, 10_000)) {
    errors.push("Recompensas em gemas devem ser inteiros entre 0 e 10.000.");
  }
  if (![config.rewards.novaStarMinSeconds, config.rewards.novaStarMaxSeconds,
    config.rewards.novaStarProductionSeconds, config.rewards.novaStarDailyGems]
    .every((value) => Number.isInteger(value) && inRange(value, 0, 1_000_000))
    || config.rewards.novaStarMaxSeconds < config.rewards.novaStarMinSeconds) {
    errors.push("Revise frequência, produção e gemas da Estrela Nova.");
  }
  const quantities = config.economy.milestones.map((milestone) => milestone.quantity);
  if (quantities.length === 0) errors.push("Adicione ao menos um marco de estágio.");
  if (quantities.length > 64) errors.push("Use no máximo 64 marcos.");
  if (quantities.some((quantity) => !Number.isInteger(quantity) || !inRange(quantity, 1, 1_000_000))) {
    errors.push("Quantidades dos marcos devem ser inteiros entre 1 e 1.000.000.");
  }
  if (quantities.some((quantity, index) => index > 0 && quantity <= (quantities[index - 1] ?? 0))) {
    errors.push("Ordene os marcos em quantidades estritamente crescentes.");
  }
  if (config.economy.milestones.some((milestone) => !inRange(milestone.multiplier, 1, 1_000))) {
    errors.push("Multiplicadores dos marcos devem ficar entre 1 e 1.000.");
  }
  const general = config.economy.generalMilestones;
  if (general.length === 0 || general.length > 32) errors.push("Use entre 1 e 32 marcos gerais.");
  if (general.some((milestone, index) => !Number.isInteger(milestone.quantity)
    || milestone.quantity <= (general[index - 1]?.quantity ?? 0)
    || !["speed", "prod"].includes(milestone.type)
    || !inRange(milestone.multiplier, 1, 1_000)
    || !Number.isInteger(milestone.gems) || !inRange(milestone.gems, 0, 1_000_000)
    || !Number.isInteger(milestone.relics) || !inRange(milestone.relics, 0, 1_000_000))) {
    errors.push("Revise a ordem, o tipo e as recompensas dos marcos gerais.");
  }
  return errors;
}

function campaignErrors(form: CampaignForm): string[] {
  const errors: string[] = [];
  if (!/^[a-z0-9][a-z0-9_-]{0,63}$/u.test(form.key)) {
    errors.push("A chave aceita até 64 letras minúsculas, números, hífen e sublinhado.");
  }
  if (form.name.trim().length < 1 || form.name.trim().length > 80) {
    errors.push("O nome deve ter entre 1 e 80 caracteres.");
  }
  const startsAt = fromLocalDateTime(form.startsAt);
  const endsAt = fromLocalDateTime(form.endsAt);
  if (!startsAt || !endsAt) errors.push("Informe início e término válidos.");
  else if (endsAt <= startsAt) errors.push("O término precisa ser posterior ao início.");
  else if (endsAt - startsAt > 366 * 86_400) errors.push("A campanha pode durar no máximo 366 dias.");
  const multipliers = [
    form.effects.globalProductionMultiplier,
    form.effects.offlineProductionMultiplier,
    form.effects.manualProductionMultiplier,
    form.effects.studyFaithMultiplier,
  ];
  if (multipliers.some((value) => !Number.isFinite(value) || value < 0.01 || value > 100)) {
    errors.push("Multiplicadores globais da campanha devem ficar entre 0,01 e 100.");
  }
  if (!Number.isFinite(form.effects.freeGemRewardMultiplier)
    || form.effects.freeGemRewardMultiplier < 0 || form.effects.freeGemRewardMultiplier > 100) {
    errors.push("O multiplicador de gemas gratuitas deve ficar entre 0 e 100.");
  }
  if (Object.values(form.effects.generatorProductionMultipliers)
    .some((value) => !Number.isFinite(value) || value < 0.01 || value > 1_000)) {
    errors.push("Multiplicadores por gerador devem ficar entre 0,01 e 1.000.");
  }
  return errors;
}

function NumberField({
  id,
  label,
  hint,
  value,
  onChange,
  step = "any",
  min,
  max,
  suffix,
}: {
  id: string;
  label: string;
  hint: string;
  value: number;
  onChange: (value: number) => void;
  step?: number | "any";
  min?: number;
  max?: number;
  suffix?: string;
}) {
  return (
    <label className="liveops-number-field" htmlFor={id}>
      <span><strong>{label}</strong><small>{hint}</small></span>
      <span className="liveops-number-field__control">
        <input
          id={id}
          type="number"
          value={value}
          min={min}
          max={max}
          step={step}
          inputMode="decimal"
          onChange={(event) => {
            const next = event.currentTarget.valueAsNumber;
            if (Number.isFinite(next)) onChange(next);
          }}
        />
        {suffix && <em>{suffix}</em>}
      </span>
    </label>
  );
}

function EditorSection({
  icon,
  title,
  description,
  children,
}: {
  icon: ReactNode;
  title: string;
  description: string;
  children: ReactNode;
}) {
  return (
    <fieldset className="liveops-editor-section">
      <legend className="sr-only">{title}</legend>
      <header>
        <span aria-hidden="true">{icon}</span>
        <div><h3>{title}</h3><p>{description}</p></div>
      </header>
      {children}
    </fieldset>
  );
}

function VersionMeta({ version }: { version: LiveOpsBalanceVersion }) {
  return (
    <div className="liveops-version-meta">
      <StatusBadge value={version.status} />
      <span><strong>{shortId(version.id, 12)}</strong><small>{formatDate(version.createdAt)}</small></span>
    </div>
  );
}

export function LiveOpsPage({
  onUnauthorized,
  onToast,
}: {
  onUnauthorized: () => void;
  onToast: (message: string) => void;
}) {
  const [tab, setTab] = useState<LiveOpsTab>("balance");
  const [snapshot, setSnapshot] = useState<LiveOpsSnapshot | null>(null);
  const [balanceDraft, setBalanceDraft] = useState<LiveOpsBalanceConfig | null>(null);
  const [balanceReason, setBalanceReason] = useState("");
  const [balanceRollbackId, setBalanceRollbackId] = useState("");
  const [selectedCampaignId, setSelectedCampaignId] = useState<string | null>(null);
  const [campaignEditor, setCampaignEditor] = useState<CampaignForm | null>(null);
  const [campaignReason, setCampaignReason] = useState("");
  const [campaignRollbackId, setCampaignRollbackId] = useState("");
  const [campaignQuery, setCampaignQuery] = useState("");
  const [campaignFilter, setCampaignFilter] = useState<CampaignDisplayStatus | "all">("all");
  const [generatorQuery, setGeneratorQuery] = useState("");
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<unknown>(null);
  const [conflict, setConflict] = useState(false);
  const [confirmation, setConfirmation] = useState<ConfirmationRequest | null>(null);
  const [auditItems, setAuditItems] = useState<LiveOpsAuditRecord[]>([]);
  const [auditCursor, setAuditCursor] = useState<string | null>(null);
  const [auditLoaded, setAuditLoaded] = useState(false);
  const [auditLoading, setAuditLoading] = useState(false);
  const [auditError, setAuditError] = useState<unknown>(null);

  const installBalanceSnapshot = useCallback((next: LiveOpsSnapshot) => {
    const draft = latestBalanceDraft(next);
    setSnapshot(next);
    setBalanceDraft(clone(draft?.config ?? next.activeBalance?.config ?? DEFAULT_BALANCE));
    setBalanceReason("");
    setBalanceRollbackId("");
    setError(null);
    setConflict(false);
    setAuditLoaded(false);
    setAuditItems([]);
  }, []);

  const installCampaignSnapshot = useCallback((next: LiveOpsSnapshot, campaignId: string | null) => {
    setSnapshot(next);
    const campaign = next.campaigns.find((item) => item.id === campaignId)
      ?? next.campaigns[0]
      ?? null;
    setSelectedCampaignId(campaign?.id ?? null);
    const version = campaign ? preferredCampaignVersion(campaign) : null;
    setCampaignEditor(
      campaign && version ? campaignForm(campaign, version) : newCampaignForm(next.serverNow),
    );
    setCampaignReason("");
    setCampaignRollbackId("");
    setError(null);
    setConflict(false);
    setAuditLoaded(false);
    setAuditItems([]);
  }, []);

  const handleError = useCallback((caught: unknown) => {
    if (caught instanceof AdminApiError && (caught.status === 401 || caught.status === 403)) {
      onUnauthorized();
      return;
    }
    if (caught instanceof AdminApiError && caught.status === 412) {
      setConflict(true);
      setConfirmation(null);
    }
    setError(caught);
  }, [onUnauthorized]);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const next = await adminApi.liveOps();
      const draft = latestBalanceDraft(next);
      setSnapshot(next);
      setBalanceDraft(clone(draft?.config ?? next.activeBalance?.config ?? DEFAULT_BALANCE));
      const firstCampaign = next.campaigns[0] ?? null;
      const version = firstCampaign ? preferredCampaignVersion(firstCampaign) : null;
      setSelectedCampaignId(firstCampaign?.id ?? null);
      setCampaignEditor(
        firstCampaign && version
          ? campaignForm(firstCampaign, version)
          : newCampaignForm(next.serverNow),
      );
      setBalanceReason("");
      setCampaignReason("");
      setBalanceRollbackId("");
      setCampaignRollbackId("");
      setConflict(false);
      setAuditLoaded(false);
      setAuditItems([]);
    } catch (caught) {
      handleError(caught);
    } finally {
      setLoading(false);
    }
  }, [handleError]);

  useEffect(() => {
    void load();
  }, [load]);

  const loadAudit = useCallback(async (cursor?: string, append = false) => {
    setAuditLoading(true);
    setAuditError(null);
    try {
      const result = await adminApi.liveOpsAudit(cursor, 30);
      setAuditItems((current) => append ? [...current, ...result.items] : result.items);
      setAuditCursor(result.nextCursor);
      setAuditLoaded(true);
    } catch (caught) {
      if (caught instanceof AdminApiError && (caught.status === 401 || caught.status === 403)) {
        onUnauthorized();
      } else {
        setAuditError(caught);
      }
    } finally {
      setAuditLoading(false);
    }
  }, [onUnauthorized]);

  useEffect(() => {
    if (tab === "history" && !auditLoaded && !auditLoading) void loadAudit();
  }, [auditLoaded, auditLoading, loadAudit, tab]);

  const savedBalanceBase = useMemo(() => {
    if (!snapshot) return null;
    return latestBalanceDraft(snapshot)?.config ?? snapshot.activeBalance?.config ?? DEFAULT_BALANCE;
  }, [snapshot]);
  const balanceChanged = Boolean(
    balanceDraft && savedBalanceBase
    && JSON.stringify(balanceDraft) !== JSON.stringify(savedBalanceBase),
  );
  const currentBalanceErrors = balanceDraft ? balanceErrors(balanceDraft) : [];
  const currentCampaignErrors = campaignEditor ? campaignErrors(campaignEditor) : [];

  const selectedCampaign = useMemo(
    () => snapshot?.campaigns.find((campaign) => campaign.id === selectedCampaignId) ?? null,
    [selectedCampaignId, snapshot],
  );
  const selectedCampaignSource = useMemo(
    () => selectedCampaign?.versions.find((version) => version.id === campaignEditor?.sourceVersionId) ?? null,
    [campaignEditor?.sourceVersionId, selectedCampaign],
  );
  const campaignChanged = useMemo(() => {
    if (!campaignEditor) return false;
    if (!selectedCampaignSource) return true;
    return JSON.stringify({
      name: campaignEditor.name.trim(),
      startsAt: fromLocalDateTime(campaignEditor.startsAt),
      endsAt: fromLocalDateTime(campaignEditor.endsAt),
      effects: campaignEditor.effects,
    }) !== JSON.stringify({
      name: selectedCampaignSource.name,
      startsAt: selectedCampaignSource.startsAt,
      endsAt: selectedCampaignSource.endsAt,
      effects: normalizedCampaignEffects(selectedCampaignSource.effects),
    });
  }, [campaignEditor, selectedCampaignSource]);

  const visibleCampaigns = useMemo(() => {
    if (!snapshot) return [];
    const normalized = campaignQuery.trim().toLocaleLowerCase("pt-BR");
    return snapshot.campaigns
      .filter((campaign) => campaignFilter === "all"
        || campaignStatus(campaign, snapshot.serverNow) === campaignFilter)
      .filter((campaign) => {
        const version = preferredCampaignVersion(campaign);
        return normalized === ""
          || campaign.key.toLocaleLowerCase("pt-BR").includes(normalized)
          || version?.name.toLocaleLowerCase("pt-BR").includes(normalized);
      })
      .sort((left, right) => {
        const leftVersion = preferredCampaignVersion(left);
        const rightVersion = preferredCampaignVersion(right);
        return (rightVersion?.startsAt ?? right.createdAt) - (leftVersion?.startsAt ?? left.createdAt);
      });
  }, [campaignFilter, campaignQuery, snapshot]);

  const filteredGenerators = useMemo(() => {
    const normalized = generatorQuery.trim().toLocaleLowerCase("pt-BR");
    if (!normalized) return GENERATORS;
    return GENERATORS.filter((generator) =>
      generator.name.toLocaleLowerCase("pt-BR").includes(normalized)
      || generator.id.includes(normalized));
  }, [generatorQuery]);

  const balanceRollbackVersions = useMemo(
    () => snapshot?.balanceVersions
      .filter((version) => version.status !== "draft" && version.id !== snapshot.activeBalance?.id)
      .sort((left, right) => right.createdAt - left.createdAt) ?? [],
    [snapshot],
  );
  const campaignRollbackVersions = useMemo(
    () => selectedCampaign?.versions
      .filter((version) =>
        (version.status === "published" || version.status === "superseded"
          || (version.status === "cancelled" && version.publishedAt !== null))
        && version.id !== selectedCampaign.activeVersionId)
      .sort((left, right) => right.version - left.version) ?? [],
    [selectedCampaign],
  );

  function selectCampaign(campaign: LiveOpsAdminCampaign) {
    const version = preferredCampaignVersion(campaign);
    setSelectedCampaignId(campaign.id);
    if (version) setCampaignEditor(campaignForm(campaign, version));
    setCampaignReason("");
    setCampaignRollbackId("");
    setGeneratorQuery("");
  }

  function startCampaign() {
    if (!snapshot) return;
    setSelectedCampaignId(null);
    setCampaignEditor(newCampaignForm(snapshot.serverNow));
    setCampaignReason("");
    setCampaignRollbackId("");
    setGeneratorQuery("");
  }

  function selectCampaignVersion(versionId: string) {
    if (!selectedCampaign) return;
    const version = selectedCampaign.versions.find((item) => item.id === versionId);
    if (!version) return;
    setCampaignEditor(campaignForm(selectedCampaign, version));
    setCampaignReason("");
    setGeneratorQuery("");
  }

  async function saveBalanceDraft() {
    if (!snapshot || !balanceDraft || currentBalanceErrors.length > 0
      || balanceReason.trim().length < 3 || !balanceChanged || saving || conflict) return;
    setSaving(true);
    setError(null);
    try {
      const next = await adminApi.createBalanceDraft(
        balanceDraft,
        balanceReason.trim(),
        etagFor(snapshot),
      );
      installBalanceSnapshot(next);
      onToast("Nova versão de balanceamento salva como rascunho.");
    } catch (caught) {
      handleError(caught);
    } finally {
      setSaving(false);
    }
  }

  function requestBalancePublish(version: LiveOpsBalanceVersion) {
    if (!snapshot || conflict) return;
    setConfirmation({
      title: "Publicar este balanceamento?",
      description: "A versão " + shortId(version.id, 12)
        + " passará a ser entregue aos jogadores. A revisão atual é "
        + snapshot.revision + ".",
      confirmLabel: "Publicar versão",
      reasonLabel: "Motivo da publicação",
      tone: "warning",
      onConfirm: async (reason) => {
        try {
          const next = await adminApi.publishBalance(version.id, reason, etagFor(snapshot));
          installBalanceSnapshot(next);
          onToast("Balanceamento publicado com controle de revisão.");
        } catch (caught) {
          handleError(caught);
          throw caught;
        }
      },
    });
  }

  function requestBalanceRollback() {
    if (!snapshot || !balanceRollbackId || conflict) return;
    const version = snapshot.balanceVersions.find((item) => item.id === balanceRollbackId);
    if (!version) return;
    setConfirmation({
      title: "Reverter o balanceamento ativo?",
      description: "Uma nova versão será publicada a partir de "
        + shortId(version.id, 12)
        + ". A versão atual continuará preservada no histórico.",
      confirmLabel: "Confirmar rollback",
      reasonLabel: "Motivo do rollback",
      tone: "danger",
      onConfirm: async (reason) => {
        try {
          const next = await adminApi.rollbackBalance(version.id, reason, etagFor(snapshot));
          installBalanceSnapshot(next);
          onToast("Rollback de balanceamento publicado e auditado.");
        } catch (caught) {
          handleError(caught);
          throw caught;
        }
      },
    });
  }

  async function saveCampaignDraft() {
    if (!snapshot || !campaignEditor || currentCampaignErrors.length > 0
      || campaignReason.trim().length < 3 || !campaignChanged || saving || conflict) return;
    setSaving(true);
    setError(null);
    const data = {
      name: campaignEditor.name.trim(),
      startsAt: fromLocalDateTime(campaignEditor.startsAt),
      endsAt: fromLocalDateTime(campaignEditor.endsAt),
      effects: campaignEditor.effects,
    };
    try {
      const next = campaignEditor.campaignId
        ? await adminApi.createCampaignDraft(
            campaignEditor.campaignId,
            data,
            campaignReason.trim(),
            etagFor(snapshot),
          )
        : await adminApi.createCampaign(
            { key: campaignEditor.key.trim(), ...data },
            campaignReason.trim(),
            etagFor(snapshot),
          );
      const nextCampaignId = campaignEditor.campaignId
        ?? next.campaigns.find((campaign) => campaign.key === campaignEditor.key.trim())?.id
        ?? null;
      installCampaignSnapshot(next, nextCampaignId);
      onToast(campaignEditor.campaignId
        ? "Nova versão da campanha salva como rascunho."
        : "Campanha criada como rascunho.");
    } catch (caught) {
      handleError(caught);
    } finally {
      setSaving(false);
    }
  }

  function requestCampaignPublish(version: LiveOpsCampaignVersion) {
    if (!snapshot || !selectedCampaign || conflict) return;
    setConfirmation({
      title: "Publicar esta campanha?",
      description: version.startsAt > snapshot.serverNow
        ? "A versão " + version.version + " ficará agendada para " + formatDate(version.startsAt) + "."
        : "A versão " + version.version + " ficará ativa imediatamente, conforme o relógio do servidor.",
      confirmLabel: "Publicar campanha",
      reasonLabel: "Motivo da publicação",
      tone: "warning",
      onConfirm: async (reason) => {
        try {
          const next = await adminApi.publishCampaign(
            selectedCampaign.id,
            version.id,
            reason,
            etagFor(snapshot),
          );
          installCampaignSnapshot(next, selectedCampaign.id);
          onToast("Campanha publicada com janela controlada pelo servidor.");
        } catch (caught) {
          handleError(caught);
          throw caught;
        }
      },
    });
  }

  function requestCampaignCancel() {
    if (!snapshot || !selectedCampaign || conflict) return;
    const active = activeCampaignVersion(selectedCampaign);
    if (!active) return;
    setConfirmation({
      title: "Cancelar a campanha publicada?",
      description: "Os efeitos de “" + active.name
        + "” deixarão de ser entregues. Esta ação cria um registro auditável e não apaga o histórico.",
      confirmLabel: "Cancelar campanha",
      reasonLabel: "Motivo do cancelamento",
      tone: "danger",
      onConfirm: async (reason) => {
        try {
          const next = await adminApi.cancelCampaign(
            selectedCampaign.id,
            reason,
            etagFor(snapshot),
          );
          installCampaignSnapshot(next, selectedCampaign.id);
          onToast("Campanha cancelada.");
        } catch (caught) {
          handleError(caught);
          throw caught;
        }
      },
    });
  }

  function requestCampaignRollback() {
    if (!snapshot || !selectedCampaign || !campaignRollbackId || conflict) return;
    const version = selectedCampaign.versions.find((item) => item.id === campaignRollbackId);
    if (!version) return;
    setConfirmation({
      title: "Reverter para a versão " + version.version + "?",
      description: "Uma nova versão publicada será criada com o conteúdo selecionado. Datas e efeitos voltarão juntos.",
      confirmLabel: "Confirmar rollback",
      reasonLabel: "Motivo do rollback",
      tone: "danger",
      onConfirm: async (reason) => {
        try {
          const next = await adminApi.rollbackCampaign(
            selectedCampaign.id,
            version.id,
            reason,
            etagFor(snapshot),
          );
          installCampaignSnapshot(next, selectedCampaign.id);
          onToast("Rollback da campanha publicado.");
        } catch (caught) {
          handleError(caught);
          throw caught;
        }
      },
    });
  }

  function updateGeneratorMultiplier(generatorId: string, value: number) {
    setCampaignEditor((current) => {
      if (!current) return current;
      const multipliers = { ...current.effects.generatorProductionMultipliers };
      if (value === 1) delete multipliers[generatorId];
      else multipliers[generatorId] = value;
      return {
        ...current,
        effects: { ...current.effects, generatorProductionMultipliers: multipliers },
      };
    });
  }

  const activeCampaignCount = snapshot?.campaigns.filter((campaign) =>
    campaignStatus(campaign, snapshot.serverNow) === "active").length ?? 0;
  const scheduledCampaignCount = snapshot?.campaigns.filter((campaign) =>
    campaignStatus(campaign, snapshot.serverNow) === "scheduled").length ?? 0;

  return (
    <>
      <PageHeader
        eyebrow="Configuração remota"
        title="LiveOps"
        description="Balanceamento e campanhas versionados, publicados sem recompilar o aplicativo."
        action={
          <button className="button button--quiet" type="button" onClick={() => void load()} disabled={loading}>
            <RefreshCw size={16} /> Recarregar estado
          </button>
        }
      />

      {conflict && (
        <div className="liveops-conflict" role="alert">
          <TriangleAlert size={21} />
          <div>
            <strong>Outra pessoa publicou uma revisão enquanto você editava.</strong>
            <span>As edições locais continuam visíveis, mas novas gravações estão bloqueadas até recarregar.</span>
          </div>
          <button className="button button--warning" type="button" onClick={() => void load()}>
            <RefreshCw size={15} /> Carregar revisão atual
          </button>
        </div>
      )}
      {error && !conflict && <ErrorPanel error={error} onRetry={() => void load()} />}

      {loading && !snapshot ? <LoadingBlock rows={8} label="Carregando LiveOps" /> : snapshot ? (
        <>
          <section className="liveops-statebar" aria-label="Estado da configuração remota">
            <div><CircleDotDashed size={17} /><span><small>Revisão</small><strong>{snapshot.revision}</strong></span></div>
            <div><CheckCircle2 size={17} /><span><small>Balance ativo</small><strong>{snapshot.activeBalance ? shortId(snapshot.activeBalance.id, 10) : "Não publicado"}</strong></span></div>
            <div><Rocket size={17} /><span><small>Campanhas</small><strong>{activeCampaignCount} ativas · {scheduledCampaignCount} agendadas</strong></span></div>
            <div><Clock3 size={17} /><span><small>Relógio do servidor</small><strong>{formatDate(snapshot.serverNow)}</strong></span></div>
          </section>

          <div className="liveops-tabs" role="tablist" aria-label="Áreas de LiveOps">
            <button
              id="liveops-balance-tab"
              type="button"
              role="tab"
              aria-selected={tab === "balance"}
              aria-controls="liveops-balance-panel"
              className={tab === "balance" ? "is-active" : ""}
              onClick={() => setTab("balance")}
            >
              <SlidersHorizontal size={17} /><span>Balanceamento<small>Economia, impulsos e recompensas</small></span>
            </button>
            <button
              id="liveops-campaigns-tab"
              type="button"
              role="tab"
              aria-selected={tab === "campaigns"}
              aria-controls="liveops-campaigns-panel"
              className={tab === "campaigns" ? "is-active" : ""}
              onClick={() => setTab("campaigns")}
            >
              <Megaphone size={17} /><span>Campanhas<small>Agenda e multiplicadores temporários</small></span>
            </button>
            <button
              id="liveops-history-tab"
              type="button"
              role="tab"
              aria-selected={tab === "history"}
              aria-controls="liveops-history-panel"
              className={tab === "history" ? "is-active" : ""}
              onClick={() => setTab("history")}
            >
              <History size={17} /><span>Histórico<small>Motivos, autores e revisões</small></span>
            </button>
          </div>

          {tab === "balance" && balanceDraft && (
            <section
              id="liveops-balance-panel"
              role="tabpanel"
              aria-labelledby="liveops-balance-tab"
              className="liveops-workbench"
            >
              <div className="panel liveops-editor">
                <header className="panel__header">
                  <div><span>Próxima versão</span><h2>Editor de balanceamento</h2></div>
                  <SlidersHorizontal size={22} />
                </header>

                <EditorSection
                  icon={<Coins size={18} />}
                  title="Economia"
                  description="Curva de custo, prestígio, Profetas e limite da produção offline."
                >
                  <div className="liveops-field-grid">
                    <NumberField id="balance-saint" label="Bônus por Santo" hint="Acréscimo por prestígio" value={balanceDraft.economy.saintBonus} min={0} max={10} step={0.01} suffix="×" onChange={(value) => setBalanceDraft({ ...balanceDraft, economy: { ...balanceDraft.economy, saintBonus: value } })} />
                    <NumberField id="balance-prestige" label="Divisor de prestígio" hint="Fé necessária na fórmula" value={balanceDraft.economy.prestigeDivisor} min={1} max={1e100} step={1} suffix="Fé" onChange={(value) => setBalanceDraft({ ...balanceDraft, economy: { ...balanceDraft.economy, prestigeDivisor: value } })} />
                    <NumberField id="balance-prophet-unlock" label="Desbloqueio de Profeta" hint="Unidades do gerador" value={balanceDraft.economy.prophetUnlockQuantity} min={1} max={10_000} step={1} suffix="un." onChange={(value) => setBalanceDraft({ ...balanceDraft, economy: { ...balanceDraft.economy, prophetUnlockQuantity: value } })} />
                    <NumberField id="balance-prophet-cost" label="Custo do Profeta" hint="Sobre o custo de liberação" value={balanceDraft.economy.prophetCostMultiplier} min={0.001} max={1_000_000} step={0.1} suffix="×" onChange={(value) => setBalanceDraft({ ...balanceDraft, economy: { ...balanceDraft.economy, prophetCostMultiplier: value } })} />
                    <NumberField id="balance-prophet-speed" label="Velocidade do Profeta" hint="Fator do tempo de ciclo" value={balanceDraft.economy.prophetSpeedMultiplier} min={0.05} max={2} step={0.05} suffix="×" onChange={(value) => setBalanceDraft({ ...balanceDraft, economy: { ...balanceDraft.economy, prophetSpeedMultiplier: value } })} />
                    <NumberField id="balance-offline-cap" label="Limite offline" hint="Tempo máximo acumulado" value={balanceDraft.economy.offlineCapSeconds} min={60} max={31_536_000} step={60} suffix="s" onChange={(value) => setBalanceDraft({ ...balanceDraft, economy: { ...balanceDraft.economy, offlineCapSeconds: value } })} />
                    <NumberField id="balance-ladder-base" label="Dádiva: custo base" hint="Primeiro nível de Frutos" value={balanceDraft.economy.dadivaLadderBaseCost} min={1} max={1_000_000_000} step={1} suffix="Santos" onChange={(value) => setBalanceDraft({ ...balanceDraft, economy: { ...balanceDraft.economy, dadivaLadderBaseCost: value } })} />
                    <NumberField id="balance-ladder-growth" label="Dádiva: crescimento" hint="Custo entre níveis" value={balanceDraft.economy.dadivaLadderCostGrowth} min={1.01} max={100} step={0.01} suffix="×" onChange={(value) => setBalanceDraft({ ...balanceDraft, economy: { ...balanceDraft.economy, dadivaLadderCostGrowth: value } })} />
                    <NumberField id="balance-ladder-mult" label="Dádiva: produção" hint="Multiplicador por nível" value={balanceDraft.economy.dadivaLadderMultiplier} min={1} max={100} step={0.01} suffix="×" onChange={(value) => setBalanceDraft({ ...balanceDraft, economy: { ...balanceDraft.economy, dadivaLadderMultiplier: value } })} />
                  </div>
                  <div className="milestone-editor">
                    <div className="milestone-editor__head" aria-hidden="true"><span>Limite da faixa</span><span>Growth</span><span>Ação</span></div>
                    {balanceDraft.economy.growthSegments.map((segment, index) => (
                      <div className="milestone-editor__row" key={index}>
                        <input type="number" min={0} step={1} value={segment.maxQuantity} aria-label={`Limite da faixa ${index + 1}`} onChange={(event) => {
                          const value = event.currentTarget.valueAsNumber;
                          if (!Number.isFinite(value)) return;
                          const growthSegments = balanceDraft.economy.growthSegments.map((item, itemIndex) => itemIndex === index ? { ...item, maxQuantity: value } : item);
                          setBalanceDraft({ ...balanceDraft, economy: { ...balanceDraft.economy, growthSegments } });
                        }} />
                        <span className="milestone-editor__multiplier"><input type="number" min={1.000001} max={2} step={0.001} value={segment.rate} aria-label={`Growth da faixa ${index + 1}`} onChange={(event) => {
                          const value = event.currentTarget.valueAsNumber;
                          if (!Number.isFinite(value)) return;
                          const growthSegments = balanceDraft.economy.growthSegments.map((item, itemIndex) => itemIndex === index ? { ...item, rate: value } : item);
                          setBalanceDraft({ ...balanceDraft, economy: { ...balanceDraft.economy, growthSegments } });
                        }} /><em>×</em></span>
                        <button className="icon-button icon-button--danger" type="button" aria-label={`Remover faixa ${index + 1}`} onClick={() => {
                          const growthSegments = balanceDraft.economy.growthSegments.filter((_, itemIndex) => itemIndex !== index);
                          setBalanceDraft({ ...balanceDraft, economy: { ...balanceDraft.economy, growthSegments } });
                        }}><Trash2 size={15} /></button>
                      </div>
                    ))}
                    <button className="liveops-add-row" type="button" onClick={() => {
                      const growthSegments = balanceDraft.economy.growthSegments.map((item, index, values) => index === values.length - 1 && item.maxQuantity === 0 ? { ...item, maxQuantity: (values[index - 1]?.maxQuantity ?? 0) + 1000 } : item);
                      growthSegments.push({ maxQuantity: 0, rate: growthSegments.at(-1)?.rate ?? 1.01 });
                      setBalanceDraft({ ...balanceDraft, economy: { ...balanceDraft.economy, growthSegments } });
                    }}><Plus size={15} /> Adicionar faixa</button>
                  </div>
                </EditorSection>

                <EditorSection
                  icon={<Zap size={18} />}
                  title="Impulsos"
                  description="Potência e duração base dos impulsos existentes no aplicativo."
                >
                  <div className="liveops-field-grid">
                    <NumberField id="boost-fervor" label="Fervor" hint="Produção global" value={balanceDraft.boosts.fervorProductionMultiplier} min={1} max={100} step={0.1} suffix="×" onChange={(value) => setBalanceDraft({ ...balanceDraft, boosts: { ...balanceDraft.boosts, fervorProductionMultiplier: value } })} />
                    <NumberField id="boost-pentecost" label="Pentecoste" hint="Produção global" value={balanceDraft.boosts.pentecostProductionMultiplier} min={1} max={100} step={0.1} suffix="×" onChange={(value) => setBalanceDraft({ ...balanceDraft, boosts: { ...balanceDraft.boosts, pentecostProductionMultiplier: value } })} />
                    <NumberField id="boost-hands" label="Mãos Santas" hint="Produção manual" value={balanceDraft.boosts.holyHandsManualMultiplier} min={1} max={100} step={0.1} suffix="×" onChange={(value) => setBalanceDraft({ ...balanceDraft, boosts: { ...balanceDraft.boosts, holyHandsManualMultiplier: value } })} />
                    <NumberField id="boost-step" label="Passo Ligeiro" hint="Fator do tempo de ciclo" value={balanceDraft.boosts.swiftStepTimeMultiplier} min={0.05} max={1} step={0.05} suffix="×" onChange={(value) => setBalanceDraft({ ...balanceDraft, boosts: { ...balanceDraft.boosts, swiftStepTimeMultiplier: value } })} />
                    <NumberField id="boost-harvest" label="Colheita" hint="Produção instantânea equivalente" value={balanceDraft.boosts.harvestSeconds} min={60} max={604_800} step={60} suffix="s" onChange={(value) => setBalanceDraft({ ...balanceDraft, boosts: { ...balanceDraft.boosts, harvestSeconds: value } })} />
                  </div>
                </EditorSection>

                <EditorSection
                  icon={<Gem size={18} />}
                  title="Recompensas"
                  description="Concessões gratuitas e custo da escolha offline tripla."
                >
                  <div className="liveops-field-grid">
                    <NumberField id="reward-video" label="Gemas por vídeo" hint="Recompensa gratuita" value={balanceDraft.rewards.videoGems} min={0} max={10_000} step={1} suffix="gemas" onChange={(value) => setBalanceDraft({ ...balanceDraft, rewards: { ...balanceDraft.rewards, videoGems: value } })} />
                    <NumberField id="reward-offline" label="Offline triplo" hint="Custo da coleta ×3" value={balanceDraft.rewards.offlineTripleGemCost} min={0} max={10_000} step={1} suffix="gemas" onChange={(value) => setBalanceDraft({ ...balanceDraft, rewards: { ...balanceDraft.rewards, offlineTripleGemCost: value } })} />
                    <NumberField id="reward-star-min" label="Estrela: intervalo mínimo" hint="Tempo até reaparecer" value={balanceDraft.rewards.novaStarMinSeconds} min={0} max={1_000_000} step={1} suffix="s" onChange={(value) => setBalanceDraft({ ...balanceDraft, rewards: { ...balanceDraft.rewards, novaStarMinSeconds: value } })} />
                    <NumberField id="reward-star-max" label="Estrela: intervalo máximo" hint="Tempo até reaparecer" value={balanceDraft.rewards.novaStarMaxSeconds} min={0} max={1_000_000} step={1} suffix="s" onChange={(value) => setBalanceDraft({ ...balanceDraft, rewards: { ...balanceDraft.rewards, novaStarMaxSeconds: value } })} />
                    <NumberField id="reward-star-production" label="Estrela: produção" hint="Equivalência da recompensa" value={balanceDraft.rewards.novaStarProductionSeconds} min={0} max={1_000_000} step={1} suffix="s" onChange={(value) => setBalanceDraft({ ...balanceDraft, rewards: { ...balanceDraft.rewards, novaStarProductionSeconds: value } })} />
                    <NumberField id="reward-star-gems" label="Estrela: gemas diárias" hint="Primeiro clique do dia" value={balanceDraft.rewards.novaStarDailyGems} min={0} max={1_000_000} step={1} suffix="gemas" onChange={(value) => setBalanceDraft({ ...balanceDraft, rewards: { ...balanceDraft.rewards, novaStarDailyGems: value } })} />
                  </div>
                </EditorSection>

                <EditorSection
                  icon={<Sparkles size={18} />}
                  title="Marcos de estágio"
                  description="Os multiplicadores são acumulados ao atingir cada quantidade."
                >
                  <div className="milestone-editor">
                    <div className="milestone-editor__head" aria-hidden="true"><span>Quantidade</span><span>Multiplicador</span><span>Ação</span></div>
                    {balanceDraft.economy.milestones.map((milestone, index) => (
                      <div className="milestone-editor__row" key={index}>
                        <label>
                          <span className="sr-only">Quantidade do marco {index + 1}</span>
                          <input type="number" min={1} step={1} value={milestone.quantity} onChange={(event) => {
                            const value = event.currentTarget.valueAsNumber;
                            if (!Number.isFinite(value)) return;
                            const milestones = balanceDraft.economy.milestones.map((item, itemIndex) => itemIndex === index ? { ...item, quantity: value } : item);
                            setBalanceDraft({ ...balanceDraft, economy: { ...balanceDraft.economy, milestones } });
                          }} />
                        </label>
                        <label>
                          <span className="sr-only">Multiplicador do marco {index + 1}</span>
                          <span className="milestone-editor__multiplier">
                            <input type="number" min={1} step={0.1} value={milestone.multiplier} onChange={(event) => {
                              const value = event.currentTarget.valueAsNumber;
                              if (!Number.isFinite(value)) return;
                              const milestones = balanceDraft.economy.milestones.map((item, itemIndex) => itemIndex === index ? { ...item, multiplier: value } : item);
                              setBalanceDraft({ ...balanceDraft, economy: { ...balanceDraft.economy, milestones } });
                            }} />
                            <em>×</em>
                          </span>
                        </label>
                        <button className="icon-button icon-button--danger" type="button" aria-label={"Remover marco " + milestone.quantity} onClick={() => {
                          const milestones = balanceDraft.economy.milestones.filter((_, itemIndex) => itemIndex !== index);
                          setBalanceDraft({ ...balanceDraft, economy: { ...balanceDraft.economy, milestones } });
                        }}><Trash2 size={15} /></button>
                      </div>
                    ))}
                    <button className="liveops-add-row" type="button" onClick={() => {
                      const last = balanceDraft.economy.milestones.at(-1);
                      const milestones = [...balanceDraft.economy.milestones, { quantity: (last?.quantity ?? 0) + 100, multiplier: 2 }];
                      setBalanceDraft({ ...balanceDraft, economy: { ...balanceDraft.economy, milestones } });
                    }}><Plus size={15} /> Adicionar marco</button>
                  </div>
                </EditorSection>

                <EditorSection
                  icon={<Sparkles size={18} />}
                  title="Marcos gerais"
                  description="Recompensas recorrentes e únicas quando todos os geradores alcançam a quantidade."
                >
                  <div className="milestone-editor">
                    <div className="milestone-editor__head" style={{ gridTemplateColumns: "1fr 1fr 1fr 1fr 1fr auto" }} aria-hidden="true">
                      <span>Quantidade</span><span>Tipo</span><span>Multiplicador</span><span>Gemas</span><span>Relíquias</span><span>Ação</span>
                    </div>
                    {balanceDraft.economy.generalMilestones.map((milestone, index) => (
                      <div className="milestone-editor__row" style={{ gridTemplateColumns: "1fr 1fr 1fr 1fr 1fr auto" }} key={index}>
                        <input type="number" min={1} step={1} value={milestone.quantity} aria-label={`Quantidade do marco geral ${index + 1}`} onChange={(event) => {
                          const value = event.currentTarget.valueAsNumber;
                          if (!Number.isFinite(value)) return;
                          const generalMilestones = balanceDraft.economy.generalMilestones.map((item, itemIndex) => itemIndex === index ? { ...item, quantity: value } : item);
                          setBalanceDraft({ ...balanceDraft, economy: { ...balanceDraft.economy, generalMilestones } });
                        }} />
                        <select value={milestone.type} aria-label={`Tipo do marco geral ${index + 1}`} onChange={(event) => {
                          const type = event.currentTarget.value as "speed" | "prod";
                          const generalMilestones = balanceDraft.economy.generalMilestones.map((item, itemIndex) => itemIndex === index ? { ...item, type } : item);
                          setBalanceDraft({ ...balanceDraft, economy: { ...balanceDraft.economy, generalMilestones } });
                        }}><option value="speed">Velocidade</option><option value="prod">Produção</option></select>
                        <input type="number" min={1} max={1000} step={0.1} value={milestone.multiplier} aria-label={`Multiplicador do marco geral ${index + 1}`} onChange={(event) => {
                          const value = event.currentTarget.valueAsNumber;
                          if (!Number.isFinite(value)) return;
                          const generalMilestones = balanceDraft.economy.generalMilestones.map((item, itemIndex) => itemIndex === index ? { ...item, multiplier: value } : item);
                          setBalanceDraft({ ...balanceDraft, economy: { ...balanceDraft.economy, generalMilestones } });
                        }} />
                        <input type="number" min={0} step={1} value={milestone.gems} aria-label={`Gemas do marco geral ${index + 1}`} onChange={(event) => {
                          const value = event.currentTarget.valueAsNumber;
                          if (!Number.isFinite(value)) return;
                          const generalMilestones = balanceDraft.economy.generalMilestones.map((item, itemIndex) => itemIndex === index ? { ...item, gems: value } : item);
                          setBalanceDraft({ ...balanceDraft, economy: { ...balanceDraft.economy, generalMilestones } });
                        }} />
                        <input type="number" min={0} step={1} value={milestone.relics} aria-label={`Relíquias do marco geral ${index + 1}`} onChange={(event) => {
                          const value = event.currentTarget.valueAsNumber;
                          if (!Number.isFinite(value)) return;
                          const generalMilestones = balanceDraft.economy.generalMilestones.map((item, itemIndex) => itemIndex === index ? { ...item, relics: value } : item);
                          setBalanceDraft({ ...balanceDraft, economy: { ...balanceDraft.economy, generalMilestones } });
                        }} />
                        <button className="icon-button icon-button--danger" type="button" aria-label={`Remover marco geral ${milestone.quantity}`} onClick={() => {
                          const generalMilestones = balanceDraft.economy.generalMilestones.filter((_, itemIndex) => itemIndex !== index);
                          setBalanceDraft({ ...balanceDraft, economy: { ...balanceDraft.economy, generalMilestones } });
                        }}><Trash2 size={15} /></button>
                      </div>
                    ))}
                    <button className="liveops-add-row" type="button" onClick={() => {
                      const last = balanceDraft.economy.generalMilestones.at(-1);
                      const generalMilestones = [...balanceDraft.economy.generalMilestones, {
                        quantity: (last?.quantity ?? 0) + 100,
                        type: "prod" as const,
                        multiplier: 2,
                        gems: 0,
                        relics: 0,
                      }];
                      setBalanceDraft({ ...balanceDraft, economy: { ...balanceDraft.economy, generalMilestones } });
                    }}><Plus size={15} /> Adicionar marco geral</button>
                  </div>
                </EditorSection>
              </div>

              <aside className="liveops-rail">
                <section className="panel liveops-published">
                  <span>Em produção</span>
                  {snapshot.activeBalance ? (
                    <>
                      <strong>{shortId(snapshot.activeBalance.id, 14)}</strong>
                      <dl>
                        <div><dt>Publicada</dt><dd>{formatDate(snapshot.activeBalance.publishedAt)}</dd></div>
                        <div><dt>Autor</dt><dd>{snapshot.activeBalance.publishedBy ?? "—"}</dd></div>
                        <div><dt>SHA</dt><dd><code>{shortId(snapshot.activeBalance.sha256, 12)}</code></dd></div>
                      </dl>
                    </>
                  ) : <p>Nenhuma versão publicada.</p>}
                </section>

                <section className="panel liveops-savebox">
                  <label htmlFor="balance-reason">Motivo do rascunho</label>
                  <textarea id="balance-reason" value={balanceReason} maxLength={300} onChange={(event) => setBalanceReason(event.target.value)} placeholder="Hipótese, ticket ou decisão de balanceamento…" disabled={saving || conflict} />
                  {currentBalanceErrors.length > 0 && (
                    <ul className="liveops-validation" role="alert">
                      {currentBalanceErrors.map((item) => <li key={item}>{item}</li>)}
                    </ul>
                  )}
                  <button className="button button--primary" type="button" disabled={!balanceChanged || balanceReason.trim().length < 3 || currentBalanceErrors.length > 0 || saving || conflict} onClick={() => void saveBalanceDraft()}>
                    {saving ? <LoaderCircle className="spin" size={16} /> : <Save size={16} />}
                    {saving ? "Salvando…" : "Salvar nova versão"}
                  </button>
                  <small>{balanceChanged ? "Alterações locais ainda não versionadas." : "Editor sincronizado com o rascunho mais recente."}</small>
                </section>

                <section className="panel liveops-version-list">
                  <header><span>Rascunhos</span><strong>Prontos para publicar</strong></header>
                  {snapshot.balanceVersions.filter((version) => version.status === "draft").length === 0 ? (
                    <p>Nenhum rascunho pendente.</p>
                  ) : snapshot.balanceVersions
                    .filter((version) => version.status === "draft")
                    .sort((left, right) => right.createdAt - left.createdAt)
                    .map((version) => (
                      <div key={version.id}>
                        <VersionMeta version={version} />
                        <button className="button button--warning" type="button" disabled={conflict} onClick={() => requestBalancePublish(version)}><Rocket size={14} /> Publicar</button>
                      </div>
                    ))}
                </section>

                <section className="panel liveops-rollback">
                  <header><ArchiveRestore size={18} /><div><span>Rollback</span><strong>Restaurar versão anterior</strong></div></header>
                  <label htmlFor="balance-rollback">Versão de origem</label>
                  <select id="balance-rollback" value={balanceRollbackId} onChange={(event) => setBalanceRollbackId(event.target.value)}>
                    <option value="">Selecione uma versão</option>
                    {balanceRollbackVersions.map((version) => <option key={version.id} value={version.id}>{formatDate(version.publishedAt ?? version.createdAt)} · {shortId(version.id, 10)}</option>)}
                  </select>
                  <button className="button button--danger-outline" type="button" disabled={!balanceRollbackId || conflict} onClick={requestBalanceRollback}><ArchiveRestore size={15} /> Preparar rollback</button>
                </section>
              </aside>
            </section>
          )}

          {tab === "campaigns" && campaignEditor && (
            <section
              id="liveops-campaigns-panel"
              role="tabpanel"
              aria-labelledby="liveops-campaigns-tab"
              className="campaigns-workbench"
            >
              <aside className="panel campaign-browser">
                <header className="panel__header">
                  <div><span>Calendário operacional</span><h2>Campanhas</h2></div>
                  <button className="icon-button" type="button" onClick={startCampaign} aria-label="Criar campanha"><Plus size={17} /></button>
                </header>
                <div className="campaign-browser__tools">
                  <label><span className="sr-only">Buscar campanha</span><Search size={15} /><input type="search" value={campaignQuery} onChange={(event) => setCampaignQuery(event.target.value)} placeholder="Buscar nome ou chave" /></label>
                  <label><span className="sr-only">Filtrar status</span><select value={campaignFilter} onChange={(event) => setCampaignFilter(event.target.value as CampaignDisplayStatus | "all")}><option value="all">Todos os estados</option><option value="draft">Rascunho</option><option value="scheduled">Agendada</option><option value="active">Ativa</option><option value="ended">Encerrada</option><option value="cancelled">Cancelada</option></select></label>
                </div>
                <button className={selectedCampaignId === null ? "campaign-create is-active" : "campaign-create"} type="button" onClick={startCampaign}><Plus size={16} /><span><strong>Nova campanha</strong><small>Criar chave e primeira versão</small></span></button>
                <div className="campaign-list" aria-label="Lista de campanhas">
                  {visibleCampaigns.length === 0 ? (
                    <EmptyState title="Nenhuma campanha aqui" text="Ajuste os filtros ou crie uma nova campanha." icon={<CalendarClock size={26} />} />
                  ) : visibleCampaigns.map((campaign) => {
                    const version = preferredCampaignVersion(campaign);
                    const status = campaignStatus(campaign, snapshot.serverNow);
                    const hasDraft = campaign.versions.some((item) => item.status === "draft");
                    return (
                      <button key={campaign.id} type="button" className={selectedCampaignId === campaign.id ? "campaign-list__item is-active" : "campaign-list__item"} onClick={() => selectCampaign(campaign)} aria-current={selectedCampaignId === campaign.id ? "true" : undefined}>
                        <span className="campaign-list__status"><StatusBadge value={status} />{hasDraft && status !== "draft" && <small>+ rascunho</small>}</span>
                        <strong>{version?.name ?? campaign.key}</strong>
                        <code>{campaign.key}</code>
                        <span className="campaign-list__date">{version ? formatDate(version.startsAt) : formatDate(campaign.createdAt)}</span>
                        <ChevronRight size={16} />
                      </button>
                    );
                  })}
                </div>
              </aside>

              <div className="campaign-editor-column">
                <section className="panel campaign-editor">
                  <header className="panel__header">
                    <div><span>{campaignEditor.campaignId ? "Nova versão" : "Primeira versão"}</span><h2>{campaignEditor.campaignId ? "Editar campanha" : "Criar campanha"}</h2></div>
                    <Megaphone size={22} />
                  </header>

                  {selectedCampaign && (
                    <div className="campaign-version-picker">
                      <label htmlFor="campaign-version">Conteúdo de origem</label>
                      <select id="campaign-version" value={campaignEditor.sourceVersionId ?? ""} onChange={(event) => selectCampaignVersion(event.target.value)}>
                        {selectedCampaign.versions.slice().sort((left, right) => right.version - left.version).map((version) => <option key={version.id} value={version.id}>Versão {version.version} · {version.status} · {formatDate(version.createdAt)}</option>)}
                      </select>
                      <span><History size={14} /> Editar uma versão publicada sempre cria um novo rascunho.</span>
                    </div>
                  )}

                  <div className="campaign-identity">
                    <label htmlFor="campaign-key"><span>Chave estável</span><small>Imutável depois da criação</small><input id="campaign-key" value={campaignEditor.key} readOnly={campaignEditor.campaignId !== null} maxLength={64} placeholder="natal_2026" onChange={(event) => setCampaignEditor({ ...campaignEditor, key: event.target.value.toLowerCase().replace(/[^a-z0-9_-]/gu, "") })} /></label>
                    <label htmlFor="campaign-name"><span>Nome administrativo</span><small>Visível apenas neste painel</small><input id="campaign-name" value={campaignEditor.name} maxLength={80} placeholder="Natal 2026" onChange={(event) => setCampaignEditor({ ...campaignEditor, name: event.target.value })} /></label>
                  </div>

                  <fieldset className="campaign-schedule">
                    <legend><CalendarClock size={17} /> Janela da campanha</legend>
                    <div>
                      <label htmlFor="campaign-start"><span>Início local</span><input id="campaign-start" type="datetime-local" value={campaignEditor.startsAt} onChange={(event) => setCampaignEditor({ ...campaignEditor, startsAt: event.target.value })} /></label>
                      <span aria-hidden="true">→</span>
                      <label htmlFor="campaign-end"><span>Término local</span><input id="campaign-end" type="datetime-local" value={campaignEditor.endsAt} onChange={(event) => setCampaignEditor({ ...campaignEditor, endsAt: event.target.value })} /></label>
                    </div>
                    <p><Clock3 size={13} /> Horários digitados em {Intl.DateTimeFormat().resolvedOptions().timeZone}; enviados como epoch UTC e ativados pelo relógio do servidor.</p>
                  </fieldset>

                  <EditorSection icon={<Rocket size={18} />} title="Efeitos globais" description="Os fatores ativos são combinados com o balanceamento publicado.">
                    <div className="liveops-field-grid">
                      <NumberField id="campaign-global" label="Produção global" hint="Todos os geradores" value={campaignEditor.effects.globalProductionMultiplier} min={0.01} max={100} step={0.1} suffix="×" onChange={(value) => setCampaignEditor({ ...campaignEditor, effects: { ...campaignEditor.effects, globalProductionMultiplier: value } })} />
                      <NumberField id="campaign-offline" label="Produção offline" hint="Período dentro da campanha" value={campaignEditor.effects.offlineProductionMultiplier} min={0.01} max={100} step={0.1} suffix="×" onChange={(value) => setCampaignEditor({ ...campaignEditor, effects: { ...campaignEditor.effects, offlineProductionMultiplier: value } })} />
                      <NumberField id="campaign-manual" label="Produção manual" hint="Ciclos iniciados pelo jogador" value={campaignEditor.effects.manualProductionMultiplier} min={0.01} max={100} step={0.1} suffix="×" onChange={(value) => setCampaignEditor({ ...campaignEditor, effects: { ...campaignEditor.effects, manualProductionMultiplier: value } })} />
                      <NumberField id="campaign-study" label="Fé de estudos" hint="Leituras e questões" value={campaignEditor.effects.studyFaithMultiplier} min={0.01} max={100} step={0.1} suffix="×" onChange={(value) => setCampaignEditor({ ...campaignEditor, effects: { ...campaignEditor.effects, studyFaithMultiplier: value } })} />
                      <NumberField id="campaign-gems" label="Gemas gratuitas" hint="Recompensas gratuitas existentes" value={campaignEditor.effects.freeGemRewardMultiplier} min={0} max={100} step={0.1} suffix="×" onChange={(value) => setCampaignEditor({ ...campaignEditor, effects: { ...campaignEditor.effects, freeGemRewardMultiplier: value } })} />
                    </div>
                  </EditorSection>

                  <details className="generator-effects">
                    <summary><span><Zap size={17} /><span><strong>Multiplicadores por gerador</strong><small>{Object.keys(campaignEditor.effects.generatorProductionMultipliers).length} substituições configuradas</small></span></span><ChevronRight size={17} /></summary>
                    <div className="generator-effects__body">
                      <label className="generator-search"><span className="sr-only">Buscar gerador</span><Search size={15} /><input type="search" value={generatorQuery} onChange={(event) => setGeneratorQuery(event.target.value)} placeholder="Buscar por nome ou ID" /></label>
                      <p>O valor ×1 usa o comportamento global e não é enviado como substituição.</p>
                      <div className="generator-grid">
                        {filteredGenerators.map((generator) => (
                          <label key={generator.id}>
                            <span><strong>{generator.id.padStart(2, "0")}</strong><small>{generator.name}</small></span>
                            <span><input type="number" min={0.01} max={1_000} step={0.1} value={campaignEditor.effects.generatorProductionMultipliers[generator.id] ?? 1} onChange={(event) => {
                              const value = event.currentTarget.valueAsNumber;
                              if (Number.isFinite(value)) updateGeneratorMultiplier(generator.id, value);
                            }} /><em>×</em></span>
                          </label>
                        ))}
                      </div>
                    </div>
                  </details>

                  <div className="campaign-save">
                    <div>
                      <label htmlFor="campaign-reason">Motivo da versão</label>
                      <textarea id="campaign-reason" value={campaignReason} maxLength={300} onChange={(event) => setCampaignReason(event.target.value)} placeholder="Objetivo, público e decisão operacional…" disabled={saving || conflict} />
                    </div>
                    <div>
                      {currentCampaignErrors.length > 0 && <ul className="liveops-validation" role="alert">{currentCampaignErrors.map((item) => <li key={item}>{item}</li>)}</ul>}
                      <button className="button button--primary" type="button" disabled={!campaignChanged || campaignReason.trim().length < 3 || currentCampaignErrors.length > 0 || saving || conflict} onClick={() => void saveCampaignDraft()}>
                        {saving ? <LoaderCircle className="spin" size={16} /> : <Save size={16} />}
                        {saving ? "Salvando…" : campaignEditor.campaignId ? "Salvar novo rascunho" : "Criar rascunho"}
                      </button>
                    </div>
                  </div>
                </section>

                {selectedCampaign && (
                  <section className="campaign-actions">
                    <div className="panel campaign-publish">
                      <header><Rocket size={18} /><div><span>Publicação</span><strong>Rascunhos disponíveis</strong></div></header>
                      {selectedCampaign.versions.filter((version) => version.status === "draft").length === 0 ? <p>Nenhum rascunho pendente.</p> : selectedCampaign.versions.filter((version) => version.status === "draft").sort((left, right) => right.version - left.version).map((version) => (
                        <div className="campaign-action-row" key={version.id}><span><StatusBadge value="draft" /><strong>Versão {version.version}</strong><small>{formatDate(version.createdAt)}</small></span><button className="button button--warning" type="button" disabled={conflict} onClick={() => requestCampaignPublish(version)}><Rocket size={14} /> Publicar</button></div>
                      ))}
                    </div>

                    <div className="panel liveops-rollback campaign-rollback">
                      <header><ArchiveRestore size={18} /><div><span>Histórico</span><strong>Rollback de campanha</strong></div></header>
                      <label htmlFor="campaign-rollback">Versão de origem</label>
                      <select id="campaign-rollback" value={campaignRollbackId} onChange={(event) => setCampaignRollbackId(event.target.value)}><option value="">Selecione uma versão</option>{campaignRollbackVersions.map((version) => <option key={version.id} value={version.id}>Versão {version.version} · {formatDate(version.publishedAt ?? version.createdAt)}</option>)}</select>
                      <button className="button button--danger-outline" type="button" disabled={!campaignRollbackId || conflict} onClick={requestCampaignRollback}><ArchiveRestore size={15} /> Preparar rollback</button>
                    </div>

                    {activeCampaignVersion(selectedCampaign) && campaignStatus(selectedCampaign, snapshot.serverNow) !== "cancelled" && (
                      <div className="panel campaign-cancel">
                        <header><TriangleAlert size={18} /><div><span>Interrupção</span><strong>Cancelar publicação</strong></div></header>
                        <p>Interrompe a entrega dos efeitos sem apagar versões ou auditoria.</p>
                        <button className="button button--danger-outline" type="button" disabled={conflict} onClick={requestCampaignCancel}><Trash2 size={15} /> Cancelar campanha</button>
                      </div>
                    )}
                  </section>
                )}
              </div>
            </section>
          )}

          {tab === "history" && (
            <section
              id="liveops-history-panel"
              role="tabpanel"
              aria-labelledby="liveops-history-tab"
              className="panel liveops-history"
            >
              <header className="panel__header">
                <div><span>Trilha de mudanças</span><h2>Histórico de LiveOps</h2></div>
                <button className="icon-button" type="button" aria-label="Atualizar histórico" disabled={auditLoading} onClick={() => void loadAudit()}><RefreshCw size={17} /></button>
              </header>
              {auditError !== null && <div className="liveops-history__error"><ErrorPanel error={auditError} onRetry={() => void loadAudit()} /></div>}
              {auditLoading && !auditLoaded ? <LoadingBlock rows={7} label="Carregando histórico de LiveOps" /> : auditItems.length === 0 ? (
                <EmptyState title="Nenhuma mudança registrada" text="Criação, publicação, cancelamento e rollback aparecerão aqui." icon={<History size={27} />} />
              ) : (
                <ol className="liveops-history-list">
                  {auditItems.map((item) => (
                    <li key={item.id}>
                      <span className="liveops-history-list__mark" aria-hidden="true" />
                      <article>
                        <header><span><StatusBadge value={item.action.includes("publish") ? "published" : item.action.includes("cancel") ? "cancelled" : "draft"} /><strong>{item.action.replaceAll("_", " ").replaceAll(".", " ")}</strong></span><time dateTime={new Date(item.createdAt * 1000).toISOString()}>{formatDate(item.createdAt)}</time></header>
                        <p>{item.reason}</p>
                        <dl>
                          <div><dt>Ator</dt><dd>{item.actor}</dd></div>
                          <div><dt>Alvo</dt><dd>{item.targetType} · {shortId(item.targetId, 14)}</dd></div>
                          <div><dt>Antes</dt><dd><code>{shortId(item.beforeHash, 12)}</code></dd></div>
                          <div><dt>Depois</dt><dd><code>{shortId(item.afterHash, 12)}</code></dd></div>
                          <div><dt>Request</dt><dd><code>{shortId(item.requestId, 14)}</code><CopyButton value={item.requestId} /></dd></div>
                        </dl>
                        {item.metadata && Object.keys(item.metadata).length > 0 && <details><summary>Metadados técnicos</summary><pre>{JSON.stringify(item.metadata, null, 2)}</pre></details>}
                      </article>
                    </li>
                  ))}
                </ol>
              )}
              {auditCursor && auditLoaded && <button className="load-more" type="button" disabled={auditLoading} onClick={() => void loadAudit(auditCursor, true)}>{auditLoading && <LoaderCircle className="spin" size={16} />} Carregar eventos anteriores</button>}
            </section>
          )}
        </>
      ) : null}

      {confirmation && <ConfirmDialog request={confirmation} onClose={() => setConfirmation(null)} />}
    </>
  );
}
