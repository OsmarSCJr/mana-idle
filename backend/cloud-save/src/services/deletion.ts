import { ApiError, asServiceUnavailable } from "../errors";
import { unixNow } from "../http";
import { hmacHex } from "../security/crypto";

const TOMBSTONE_RETENTION_SECONDS = 45 * 86_400;

export async function deletionHmac(env: Env, playerId: string): Promise<string> {
  return hmacHex(env.DELETION_PEPPER_V1, playerId);
}

export async function deletePlayerAccount(env: Env, playerId: string): Promise<void> {
  let row: { deletion_hmac: string } | null;
  try {
    row = await env.DB.prepare("SELECT deletion_hmac FROM players WHERE id = ?")
      .bind(playerId).first<{ deletion_hmac: string }>();
  } catch (error) {
    asServiceUnavailable(error);
  }
  if (row === null) throw new ApiError(404, "PLAYER_NOT_FOUND", "A conta não foi encontrada.");
  await deletePlayerByHmac(env, row.deletion_hmac);
}

export async function deletePlayerByHmac(env: Env, playerHmac: string): Promise<void> {
  const now = unixNow();
  try {
    await env.DELETIONS_DB.prepare(
      `INSERT INTO deletion_tombstones
         (player_hmac, status, requested_at, completed_at, expires_at, last_error_code, last_reconciled_at)
       VALUES (?, 'pending', ?, NULL, ?, NULL, ?)
       ON CONFLICT(player_hmac) DO UPDATE SET
         status = 'pending',
         requested_at = MIN(deletion_tombstones.requested_at, excluded.requested_at),
         completed_at = NULL,
         expires_at = MAX(deletion_tombstones.expires_at, excluded.expires_at),
         last_error_code = NULL,
         last_reconciled_at = excluded.last_reconciled_at`,
    ).bind(playerHmac, now, now + TOMBSTONE_RETENTION_SECONDS, now).run();
  } catch (error) {
    asServiceUnavailable(error);
  }

  try {
    const mark = await env.DB.prepare(
      `UPDATE players
       SET status = 'deleting', deletion_requested_at = COALESCE(deletion_requested_at, ?)
       WHERE deletion_hmac = ?`,
    ).bind(now, playerHmac).run();
    if (mark.meta.changes > 1) throw new ApiError(500, "DELETION_INVARIANT", "A exclusão não pôde ser concluída com segurança.");
    await env.DB.prepare("DELETE FROM players WHERE deletion_hmac = ?").bind(playerHmac).run();
    const remaining = await env.DB.prepare("SELECT 1 AS present FROM players WHERE deletion_hmac = ?")
      .bind(playerHmac).first<{ present: number }>();
    if (remaining !== null) throw new ApiError(503, "DELETION_PENDING", "A exclusão foi registrada e será tentada novamente.");
  } catch (error) {
    try {
      await env.DELETIONS_DB.prepare(
        "UPDATE deletion_tombstones SET last_error_code = 'PRIMARY_DELETE_FAILED' WHERE player_hmac = ?",
      ).bind(playerHmac).run();
    } catch {
      // O tombstone pendente já é a fonte de retry; nunca registrar identificadores aqui.
    }
    if (error instanceof ApiError) throw error;
    asServiceUnavailable(error);
  }

  try {
    await env.DELETIONS_DB.prepare(
      `UPDATE deletion_tombstones
       SET status = 'completed', completed_at = ?, last_error_code = NULL, last_reconciled_at = ?
       WHERE player_hmac = ?`,
    ).bind(now, now, playerHmac).run();
  } catch (error) {
    // A conta já não existe. O tombstone permanece pending e o cron concluirá idempotentemente.
    console.error(JSON.stringify({ event: "tombstone_completion_failed", errorType: error instanceof Error ? error.name : "unknown" }));
  }
}

export interface ReconciliationResult {
  inspected: number;
  accountsDeleted: number;
  tombstonesCompleted: number;
  failures: number;
}

export async function reconcileTombstones(env: Env, limit = 1_000): Promise<ReconciliationResult> {
  interface TombstoneRow { player_hmac: string; status: "pending" | "completed" }
  const now = unixNow();
  const output: ReconciliationResult = {
    inspected: 0,
    accountsDeleted: 0,
    tombstonesCompleted: 0,
    failures: 0,
  };
  let rows: TombstoneRow[];
  try {
    const result = await env.DELETIONS_DB.prepare(
      `SELECT player_hmac, status FROM deletion_tombstones
       WHERE expires_at > ?
       ORDER BY COALESCE(last_reconciled_at, 0), requested_at
       LIMIT ?`,
    ).bind(now, limit).all<TombstoneRow>();
    rows = result.results;
  } catch (error) {
    asServiceUnavailable(error);
  }

  for (const row of rows) {
    output.inspected += 1;
    try {
      const account = await env.DB.prepare("SELECT 1 AS present FROM players WHERE deletion_hmac = ?")
        .bind(row.player_hmac).first<{ present: number }>();
      if (account !== null) {
        await deletePlayerByHmac(env, row.player_hmac);
        output.accountsDeleted += 1;
      } else {
        const result = await env.DELETIONS_DB.prepare(
          `UPDATE deletion_tombstones
           SET status = 'completed', completed_at = COALESCE(completed_at, ?),
               last_error_code = NULL, last_reconciled_at = ?
           WHERE player_hmac = ?`,
        ).bind(now, now, row.player_hmac).run();
        if (row.status === "pending" && result.meta.changes === 1) output.tombstonesCompleted += 1;
      }
    } catch (error) {
      output.failures += 1;
      console.error(JSON.stringify({
        event: "tombstone_reconcile_item_failed",
        errorType: error instanceof Error ? error.name : "unknown",
      }));
    }
  }

  try {
    const deleting = await env.DB.prepare(
      "SELECT deletion_hmac FROM players WHERE status = 'deleting' LIMIT 100",
    ).all<{ deletion_hmac: string }>();
    for (const row of deleting.results) {
      try {
        await deletePlayerByHmac(env, row.deletion_hmac);
        output.accountsDeleted += 1;
      } catch (error) {
        output.failures += 1;
        console.error(JSON.stringify({
          event: "deleting_account_retry_failed",
          errorType: error instanceof Error ? error.name : "unknown",
        }));
      }
    }
  } catch (error) {
    output.failures += 1;
    console.error(JSON.stringify({ event: "deleting_accounts_scan_failed", errorType: error instanceof Error ? error.name : "unknown" }));
  }
  return output;
}
