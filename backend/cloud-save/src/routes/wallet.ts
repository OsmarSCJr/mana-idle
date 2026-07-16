import { Hono } from "hono";

import { ApiError, asServiceUnavailable } from "../errors";
import { noStoreHeaders, readBoundedJson, unixNow } from "../http";
import { requireGameSession, requirePlayerAuth } from "../middleware/auth";
import { enforceRateLimit } from "../middleware/rate-limit";
import { enforceOperationalState } from "../services/operations";
import type { AppContext, AppHonoEnv } from "../types";
import { claimDailySchema, migrateWalletSchema, spendWalletSchema } from "../validation/schemas";

interface WalletRow {
  free_balance: number;
  paid_balance: number;
  revision: number;
  updated_at: number;
}

interface WalletEntryRow {
  operation_id: string;
  grant_key: string | null;
  amount: number;
  reason: "migration" | "daily" | "entitlement";
  source_ref: string | null;
  balance_after: number;
  wallet_revision: number;
  created_at: number;
}

interface EntitlementSummaryRow {
  sku: string;
  quantity: number;
}

const SKU_CATALOG = {
  boost_fervor: { cost: 20, quantity: 1 },
  boost_passo_ligeiro: { cost: 12, quantity: 1 },
  study_slot: { cost: 100, quantity: 1 },
} as const;

const wallet = new Hono<AppHonoEnv>();
wallet.use("*", requirePlayerAuth);

function positiveConfigInteger(value: string, name: string): number {
  const parsed = Number(value);
  if (!Number.isSafeInteger(parsed) || parsed <= 0) {
    console.error(JSON.stringify({ event: "invalid_worker_config", name }));
    throw new ApiError(503, "SERVICE_MISCONFIGURED", "A carteira gratuita está temporariamente indisponível.");
  }
  return parsed;
}

async function getWallet(db: D1Database, playerId: string): Promise<WalletRow> {
  try {
    const row = await db.prepare(
      "SELECT free_balance, paid_balance, revision, updated_at FROM wallets WHERE player_id = ?",
    ).bind(playerId).first<WalletRow>();
    if (row === null) throw new ApiError(404, "WALLET_NOT_FOUND", "A carteira gratuita não foi encontrada.");
    return row;
  } catch (error) {
    if (error instanceof ApiError) throw error;
    asServiceUnavailable(error);
  }
}

async function findEntry(db: D1Database, playerId: string, operationId: string): Promise<WalletEntryRow | null> {
  try {
    return await db.prepare(
      `SELECT operation_id, grant_key, amount, reason, source_ref, balance_after, wallet_revision, created_at
       FROM wallet_entries WHERE player_id = ? AND operation_id = ?`,
    ).bind(playerId, operationId).first<WalletEntryRow>();
  } catch (error) {
    asServiceUnavailable(error);
  }
}

function entryResponse(entry: WalletEntryRow, serverNow: number, entitlement?: string): Record<string, unknown> {
  return {
    operationId: entry.operation_id,
    freeBalance: entry.balance_after,
    paidBalance: 0,
    revision: entry.wallet_revision,
    delta: entry.amount,
    grantKey: entry.grant_key,
    ...(entitlement === undefined ? {} : { entitlement }),
    serverNow,
  };
}

function ensureEntryMatches(
  entry: WalletEntryRow,
  amount: number,
  reason: WalletEntryRow["reason"],
  sourceRef: string,
): void {
  if (entry.amount !== amount || entry.reason !== reason || entry.source_ref !== sourceRef) {
    throw new ApiError(422, "OPERATION_REUSE_MISMATCH", "O operationId já foi usado com dados diferentes.");
  }
}

async function grantFreeBalance(
  c: AppContext,
  operationId: string,
  amount: number,
  reason: "migration" | "daily",
  grantKey: string,
): Promise<Response> {
  const auth = requireGameSession(c);
  const now = unixNow();
  const existing = await findEntry(c.env.DB, auth.playerId, operationId);
  if (existing !== null) {
    ensureEntryMatches(existing, amount, reason, grantKey);
    return c.json(entryResponse(existing, now), 200, noStoreHeaders());
  }
  const current = await getWallet(c.env.DB, auth.playerId);
  try {
    const results = await c.env.DB.batch([
      c.env.DB.prepare(
        `INSERT INTO wallet_entries
           (id, player_id, operation_id, grant_key, bucket, amount, reason, source_ref,
            balance_after, wallet_revision, created_at)
         SELECT ?, player_id, ?, ?, 'free', ?, ?, ?, free_balance + ?, revision + 1, ?
         FROM wallets WHERE player_id = ? AND revision = ?`,
      ).bind(
        crypto.randomUUID(), operationId, grantKey, amount, reason, grantKey, amount, now,
        auth.playerId, current.revision,
      ),
      c.env.DB.prepare(
        `UPDATE wallets SET free_balance = free_balance + ?, revision = revision + 1, updated_at = ?
         WHERE player_id = ? AND revision = ?`,
      ).bind(amount, now, auth.playerId, current.revision),
    ]);
    if ((results[0]?.meta.changes ?? 0) !== 1 || (results[1]?.meta.changes ?? 0) !== 1) {
      throw new ApiError(409, "WALLET_CONFLICT", "A carteira mudou em outro aparelho. Tente novamente.");
    }
  } catch (error) {
    const retry = await findEntry(c.env.DB, auth.playerId, operationId);
    if (retry !== null) {
      ensureEntryMatches(retry, amount, reason, grantKey);
      return c.json(entryResponse(retry, now), 200, noStoreHeaders());
    }
    let claimed: WalletEntryRow | null;
    try {
      claimed = await c.env.DB.prepare(
        `SELECT operation_id, grant_key, amount, reason, source_ref, balance_after, wallet_revision, created_at
         FROM wallet_entries WHERE player_id = ? AND grant_key = ?`,
      ).bind(auth.playerId, grantKey).first<WalletEntryRow>();
    } catch (lookupError) {
      asServiceUnavailable(lookupError);
    }
    if (claimed !== null) {
      throw new ApiError(409, "REWARD_ALREADY_CLAIMED", "Esta recompensa gratuita já foi recebida.");
    }
    if (error instanceof ApiError) throw error;
    asServiceUnavailable(error);
  }
  const accepted = await findEntry(c.env.DB, auth.playerId, operationId);
  if (accepted === null) throw new ApiError(503, "WALLET_CONFIRMATION_FAILED", "A carteira não pôde ser confirmada.");
  return c.json(entryResponse(accepted, now), 200, noStoreHeaders());
}

wallet.get("/wallet", async (c) => {
  const auth = requireGameSession(c);
  await enforceOperationalState(c.env, "read", c.req.header("x-client-version"));
  await enforceRateLimit(c.env.WALLET_LIMITER, `wallet-read:${auth.playerId}`);
  let row: WalletRow;
  let entitlementResult: D1Result<EntitlementSummaryRow>;
  try {
    [row, entitlementResult] = await Promise.all([
      getWallet(c.env.DB, auth.playerId),
      c.env.DB.prepare(
        "SELECT sku, SUM(quantity) AS quantity FROM entitlements WHERE player_id = ? GROUP BY sku",
      ).bind(auth.playerId).all<EntitlementSummaryRow>(),
    ]);
  } catch (error) {
    if (error instanceof ApiError) throw error;
    asServiceUnavailable(error);
  }
  return c.json({
    freeBalance: row.free_balance,
    paidBalance: row.paid_balance,
    revision: row.revision,
    updatedAt: row.updated_at,
    entitlements: entitlementResult.results.map((item) => ({ sku: item.sku, quantity: item.quantity })),
    serverNow: unixNow(),
  }, 200, noStoreHeaders());
});

wallet.post("/wallet/migrate", async (c) => {
  const auth = requireGameSession(c);
  await enforceOperationalState(c.env, "wallet", c.req.header("x-client-version"));
  await enforceRateLimit(c.env.WALLET_LIMITER, `wallet-write:${auth.playerId}`);
  const body = await readBoundedJson(c, migrateWalletSchema);
  const amount = Math.min(
    body.localFreeBalance,
    positiveConfigInteger(c.env.WALLET_MIGRATION_CAP, "WALLET_MIGRATION_CAP"),
  );
  return grantFreeBalance(c, body.operationId, amount, "migration", "migration:free-v1");
});

wallet.post("/wallet/claim-daily", async (c) => {
  const auth = requireGameSession(c);
  await enforceOperationalState(c.env, "wallet", c.req.header("x-client-version"));
  await enforceRateLimit(c.env.WALLET_LIMITER, `wallet-write:${auth.playerId}`);
  const body = await readBoundedJson(c, claimDailySchema);
  const day = new Date().toISOString().slice(0, 10);
  return grantFreeBalance(
    c,
    body.operationId,
    positiveConfigInteger(c.env.DAILY_FREE_GEMS, "DAILY_FREE_GEMS"),
    "daily",
    `daily:${day}`,
  );
});

wallet.post("/wallet/spend", async (c) => {
  const auth = requireGameSession(c);
  await enforceOperationalState(c.env, "wallet", c.req.header("x-client-version"));
  await enforceRateLimit(c.env.WALLET_LIMITER, `wallet-write:${auth.playerId}`);
  const body = await readBoundedJson(c, spendWalletSchema);
  const catalogItem = SKU_CATALOG[body.sku];
  const cost = catalogItem.cost;
  const now = unixNow();
  const existing = await findEntry(c.env.DB, auth.playerId, body.operationId);
  if (existing !== null) {
    ensureEntryMatches(existing, -cost, "entitlement", body.sku);
    return c.json(entryResponse(existing, now, body.sku), 200, noStoreHeaders());
  }
  const current = await getWallet(c.env.DB, auth.playerId);
  if (current.free_balance < cost) {
    throw new ApiError(409, "INSUFFICIENT_FREE_BALANCE", "O saldo de gemas gratuitas é insuficiente.", {
      freeBalance: current.free_balance,
      required: cost,
    });
  }
  try {
    const results = await c.env.DB.batch([
      c.env.DB.prepare(
        `INSERT INTO wallet_entries
           (id, player_id, operation_id, grant_key, bucket, amount, reason, source_ref,
            balance_after, wallet_revision, created_at)
         SELECT ?, player_id, ?, NULL, 'free', ?, 'entitlement', ?,
                free_balance - ?, revision + 1, ?
         FROM wallets
         WHERE player_id = ? AND revision = ? AND free_balance >= ?`,
      ).bind(
        crypto.randomUUID(), body.operationId, -cost, body.sku, cost, now,
        auth.playerId, current.revision, cost,
      ),
      c.env.DB.prepare(
        `UPDATE wallets SET free_balance = free_balance - ?, revision = revision + 1, updated_at = ?
         WHERE player_id = ? AND revision = ? AND free_balance >= ?`,
      ).bind(cost, now, auth.playerId, current.revision, cost),
      c.env.DB.prepare(
        `INSERT INTO entitlements (id, player_id, sku, operation_id, quantity, granted_at)
         SELECT ?, player_id, ?, operation_id, ?, ?
         FROM wallet_entries WHERE player_id = ? AND operation_id = ?`,
      ).bind(crypto.randomUUID(), body.sku, catalogItem.quantity, now, auth.playerId, body.operationId),
    ]);
    if (results.some((result) => result.meta.changes !== 1)) {
      throw new ApiError(409, "WALLET_CONFLICT", "A carteira mudou em outro aparelho. Tente novamente.");
    }
  } catch (error) {
    const retry = await findEntry(c.env.DB, auth.playerId, body.operationId);
    if (retry !== null) {
      ensureEntryMatches(retry, -cost, "entitlement", body.sku);
      return c.json(entryResponse(retry, now, body.sku), 200, noStoreHeaders());
    }
    if (error instanceof ApiError) throw error;
    asServiceUnavailable(error);
  }
  const accepted = await findEntry(c.env.DB, auth.playerId, body.operationId);
  if (accepted === null) throw new ApiError(503, "WALLET_CONFIRMATION_FAILED", "A carteira não pôde ser confirmada.");
  return c.json(entryResponse(accepted, now, body.sku), 200, noStoreHeaders());
});

export default wallet;
