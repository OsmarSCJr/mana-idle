import { z } from "zod";

const uuid = z.uuid();
const label = z.string().trim().min(1).max(64);
const clientVersion = z.string().trim().min(1).max(32).regex(/^[0-9A-Za-z._+-]+$/u);
export const operationId = z.uuid();
export const recoveryCode = z.string().trim().min(20).max(80);
export const reason = z.string().trim().min(3).max(300);

export const createPlayerSchema = z
  .object({
    installationId: uuid,
    deviceLabel: label.optional(),
    clientVersion: clientVersion.optional(),
  })
  .strict();

export const recoverSessionSchema = z
  .object({
    recoveryCode,
    installationId: uuid,
    deviceLabel: label.optional(),
    clientVersion: clientVersion.optional(),
    purpose: z.enum(["game", "account_deletion"]).default("game"),
  })
  .strict();

export const rotateRecoverySchema = z.object({ recoveryCode }).strict();

export const deleteAccountSchema = z
  .object({
    confirmation: z.literal("EXCLUIR"),
    recoveryCode: recoveryCode.optional(),
  })
  .strict();

export const saveWriteSchema = z
  .object({
    mutationId: operationId,
    schemaVersion: z.number().int().positive(),
    clientSavedAt: z.number().int().nonnegative(),
    resolution: z.enum(["normal", "keep_device"]),
    payloadSha256: z.string().regex(/^[a-f0-9]{64}$/u),
    payloadJson: z.string().min(1),
  })
  .strict();

export const restorePreviousSchema = z
  .object({
    mutationId: operationId,
    reason: z.string().trim().min(3).max(40).default("user_restore"),
  })
  .strict();

export const migrateWalletSchema = z
  .object({
    operationId,
    localFreeBalance: z.number().int().positive().max(1_000_000),
  })
  .strict();

export const claimDailySchema = z.object({ operationId }).strict();

export const spendWalletSchema = z
  .object({
    operationId,
    sku: z.enum(["boost_fervor", "boost_passo_ligeiro", "study_slot"]),
  })
  .strict();

export const adminReasonSchema = z.object({ reason }).strict();

export const operationsSchema = z
  .object({
    maintenanceMode: z.boolean().optional(),
    readOnlyUploads: z.boolean().optional(),
    allowNewAccounts: z.boolean().optional(),
    minClientVersion: clientVersion.nullable().optional(),
    reason,
  })
  .strict();

export const playerIdParam = z.uuid();
export const deviceIdParam = z.uuid();
export const actionIdParam = z.uuid();
