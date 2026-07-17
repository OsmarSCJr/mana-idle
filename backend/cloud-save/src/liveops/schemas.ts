import { z } from "zod";

import { reason } from "../validation/schemas";
import type { BalanceConfig } from "./types";

const defaultMilestones = [
  [25, 1.5], [50, 3], [75, 3], [100, 7], [200, 1.5], [300, 3], [400, 1.5], [500, 7],
  [600, 1.5], [700, 3], [800, 1.5], [900, 3], [1000, 7], [1250, 1.5], [1500, 3],
  [1750, 1.5], [2000, 7], [2250, 1.5], [2500, 3], [2750, 1.5], [3000, 7], [3250, 1.5],
  [3500, 3], [3750, 1.5], [4000, 7], [4250, 1.5], [4500, 3], [4750, 1.5], [5000, 7],
  [5250, 1.5], [5500, 3], [5750, 1.5], [6000, 7], [6250, 1.5], [6500, 3], [6750, 1.5],
  [7000, 7], [7250, 1.5], [7500, 3], [7750, 1.5], [8000, 7], [8250, 1.5], [8500, 3],
  [8750, 1.5], [9000, 7], [9250, 1.5], [9500, 3],
] as const;

export const DEFAULT_BALANCE_CONFIG: BalanceConfig = {
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
    milestones: defaultMilestones.map(([quantity, multiplier]) => ({ quantity, multiplier })),
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
    harvestSeconds: 7200,
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

const finiteNumber = z.number();
const positiveMultiplier = finiteNumber.min(0.01).max(100);
const campaignKey = z.string().trim().min(1).max(64).regex(/^[a-z0-9][a-z0-9_-]*$/u);
const campaignName = z.string().trim().min(1).max(80);
const unixTimestamp = z.number().int().nonnegative().max(253_402_300_799);
const resourceId = z.string().min(1).max(64).regex(/^[A-Za-z0-9-]+$/u);

const milestoneSchema = z
  .object({
    quantity: z.number().int().min(1).max(1_000_000),
    multiplier: finiteNumber.min(1).max(1_000),
  })
  .strict();

const growthSegmentSchema = z
  .object({
    maxQuantity: z.number().int().min(0).max(10_000_000),
    rate: finiteNumber.min(1.000001).max(2),
  })
  .strict();

const generalMilestoneSchema = z
  .object({
    quantity: z.number().int().min(1).max(10_000_000),
    type: z.enum(["speed", "prod"]),
    multiplier: finiteNumber.min(1).max(1_000),
    gems: z.number().int().min(0).max(1_000_000),
    relics: z.number().int().min(0).max(1_000_000),
  })
  .strict();

function strictlyIncreasingQuantities(
  values: { quantity: number }[],
  context: z.RefinementCtx,
): void {
  for (let index = 1; index < values.length; index += 1) {
    if ((values[index]?.quantity ?? 0) <= (values[index - 1]?.quantity ?? 0)) {
      context.addIssue({
        code: "custom",
        message: "Milestones must use strictly increasing quantities.",
        path: [index, "quantity"],
      });
    }
  }
}

export const balanceConfigSchema = z
  .object({
    economy: z
      .object({
        growthSegments: z.array(growthSegmentSchema).min(1).max(8)
          .superRefine((segments, context) => {
            let previousLimit = 0;
            for (const [index, segment] of segments.entries()) {
              const last = index === segments.length - 1;
              if ((last && segment.maxQuantity !== 0) || (!last && segment.maxQuantity <= previousLimit)) {
                context.addIssue({ code: "custom", message: "Growth segments must end in 0 and use increasing limits.", path: [index, "maxQuantity"] });
              }
              previousLimit = segment.maxQuantity;
            }
          }),
        saintBonus: finiteNumber.min(0).max(10),
        prestigeDivisor: finiteNumber.min(1).max(1e100),
        prophetUnlockQuantity: z.number().int().min(1).max(10_000),
        prophetCostMultiplier: finiteNumber.min(0.001).max(1_000_000),
        prophetSpeedMultiplier: finiteNumber.min(0.05).max(2),
        offlineCapSeconds: z.number().int().min(60).max(31_536_000),
        dadivaLadderBaseCost: finiteNumber.min(1).max(1_000_000_000),
        dadivaLadderCostGrowth: finiteNumber.min(1.01).max(100),
        dadivaLadderMultiplier: finiteNumber.min(1).max(100),
        milestones: z
          .array(milestoneSchema)
          .min(1)
          .max(64)
          .superRefine(strictlyIncreasingQuantities),
        generalMilestones: z.array(generalMilestoneSchema).min(1).max(32)
          .superRefine(strictlyIncreasingQuantities),
      })
      .strict(),
    boosts: z
      .object({
        fervorProductionMultiplier: finiteNumber.min(1).max(100),
        pentecostProductionMultiplier: finiteNumber.min(1).max(100),
        holyHandsManualMultiplier: finiteNumber.min(1).max(100),
        swiftStepTimeMultiplier: finiteNumber.min(0.05).max(1),
        harvestSeconds: z.number().int().min(60).max(604_800),
      })
      .strict(),
    rewards: z
      .object({
        videoGems: z.number().int().min(0).max(10_000),
        offlineTripleGemCost: z.number().int().min(0).max(10_000),
        novaStarMinSeconds: z.number().int().min(0).max(1_000_000),
        novaStarMaxSeconds: z.number().int().min(0).max(1_000_000),
        novaStarProductionSeconds: z.number().int().min(0).max(1_000_000),
        novaStarDailyGems: z.number().int().min(0).max(1_000_000),
      })
      .strict()
      .refine((value) => value.novaStarMaxSeconds >= value.novaStarMinSeconds, {
        message: "Nova Star maximum interval must be greater than or equal to the minimum.",
        path: ["novaStarMaxSeconds"],
      }),
  })
  .strict();

const generatorMultipliers = z
  .record(
    z.string().regex(/^(?:[1-9]|[12]\d|3[0-6])$/u),
    finiteNumber.min(0.01).max(1_000),
  )
  .superRefine((value, context) => {
    if (Object.keys(value).length > 36) {
      context.addIssue({ code: "custom", message: "Too many generator multipliers." });
    }
  });

export const campaignEffectsSchema = z
  .object({
    globalProductionMultiplier: positiveMultiplier.optional(),
    offlineProductionMultiplier: positiveMultiplier.optional(),
    manualProductionMultiplier: positiveMultiplier.optional(),
    studyFaithMultiplier: positiveMultiplier.optional(),
    freeGemRewardMultiplier: finiteNumber.min(0).max(100).optional(),
    generatorProductionMultipliers: generatorMultipliers.optional(),
  })
  .strict()
  .superRefine((value, context) => {
    const hasScalar = value.globalProductionMultiplier !== undefined
      || value.offlineProductionMultiplier !== undefined
      || value.manualProductionMultiplier !== undefined
      || value.studyFaithMultiplier !== undefined
      || value.freeGemRewardMultiplier !== undefined;
    const hasGenerator = value.generatorProductionMultipliers !== undefined
      && Object.keys(value.generatorProductionMultipliers).length > 0;
    if (!hasScalar && !hasGenerator) {
      context.addIssue({ code: "custom", message: "At least one campaign effect is required." });
    }
  })
  .transform((value) => ({
    globalProductionMultiplier: value.globalProductionMultiplier ?? 1,
    offlineProductionMultiplier: value.offlineProductionMultiplier ?? 1,
    manualProductionMultiplier: value.manualProductionMultiplier ?? 1,
    studyFaithMultiplier: value.studyFaithMultiplier ?? 1,
    freeGemRewardMultiplier: value.freeGemRewardMultiplier ?? 1,
    generatorProductionMultipliers: value.generatorProductionMultipliers ?? {},
  }));

const campaignScheduleShape = {
  name: campaignName,
  startsAt: unixTimestamp,
  endsAt: unixTimestamp,
  effects: campaignEffectsSchema,
} as const;

function validCampaignWindow(value: { startsAt: number; endsAt: number }, context: z.RefinementCtx): void {
  if (value.endsAt <= value.startsAt) {
    context.addIssue({ code: "custom", message: "endsAt must be later than startsAt.", path: ["endsAt"] });
  }
  if (value.endsAt - value.startsAt > 366 * 24 * 60 * 60) {
    context.addIssue({ code: "custom", message: "Campaigns may last at most 366 days.", path: ["endsAt"] });
  }
}

export const createBalanceDraftSchema = z.object({ config: balanceConfigSchema, reason }).strict();
export const liveOpsReasonSchema = z.object({ reason }).strict();

export const createCampaignSchema = z
  .object({ key: campaignKey, ...campaignScheduleShape, reason })
  .strict()
  .superRefine(validCampaignWindow);

export const createCampaignDraftSchema = z
  .object({ ...campaignScheduleShape, reason })
  .strict()
  .superRefine(validCampaignWindow);

export const liveOpsResourceIdSchema = resourceId;

export type BalanceConfigInput = z.infer<typeof balanceConfigSchema>;
export type CampaignEffectsInput = z.infer<typeof campaignEffectsSchema>;
