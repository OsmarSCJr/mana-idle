import { z } from "zod";

import { reason } from "../validation/schemas";

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

export const balanceConfigSchema = z
  .object({
    economy: z
      .object({
        growthRate: finiteNumber.min(1.001).max(2),
        saintBonus: finiteNumber.min(0).max(1),
        prestigeDivisor: finiteNumber.min(1_000_000).max(1e30),
        prophetUnlockQuantity: z.number().int().min(1).max(10_000),
        prophetCostMultiplier: finiteNumber.min(0.1).max(10_000),
        offlineCapSeconds: z.number().int().min(300).max(604_800),
        milestones: z
          .array(milestoneSchema)
          .min(1)
          .max(32)
          .superRefine((milestones, context) => {
            for (let index = 1; index < milestones.length; index += 1) {
              const previous = milestones[index - 1];
              const current = milestones[index];
              if (previous !== undefined && current !== undefined && current.quantity <= previous.quantity) {
                context.addIssue({
                  code: "custom",
                  message: "Milestones must use strictly increasing quantities.",
                  path: [index, "quantity"],
                });
              }
            }
          }),
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
      })
      .strict(),
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
