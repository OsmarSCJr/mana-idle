import { unixNow } from "./http";
import { deletePlayerAccount, reconcileTombstones } from "./services/deletion";

interface DueDeletionRow { player_id: string }
interface AbandonedPlayerRow { id: string }

export async function runScheduledMaintenance(env: Env): Promise<void> {
  const startedAt = Date.now();
  const now = unixNow();
  let dueDeleted = 0;
  let abandonedDeleted = 0;
  let failures = 0;

  try {
    const due = await env.DB.prepare(
      `SELECT player_id FROM security_actions
       WHERE kind = 'account_delete' AND status = 'pending' AND execute_after <= ?
       ORDER BY execute_after LIMIT 50`,
    ).bind(now).all<DueDeletionRow>();
    for (const action of due.results) {
      try {
        await deletePlayerAccount(env, action.player_id);
        dueDeleted += 1;
      } catch (error) {
        failures += 1;
        console.error(JSON.stringify({
          event: "scheduled_account_delete_failed",
          errorType: error instanceof Error ? error.name : "unknown",
        }));
      }
    }
  } catch (error) {
    failures += 1;
    console.error(JSON.stringify({ event: "scheduled_due_scan_failed", errorType: error instanceof Error ? error.name : "unknown" }));
  }

  let reconciliation = { inspected: 0, accountsDeleted: 0, tombstonesCompleted: 0, failures: 0 };
  try {
    reconciliation = await reconcileTombstones(env, 1_000);
    failures += reconciliation.failures;
  } catch (error) {
    failures += 1;
    console.error(JSON.stringify({ event: "scheduled_reconcile_failed", errorType: error instanceof Error ? error.name : "unknown" }));
  }

  try {
    const abandoned = await env.DB.prepare(
      `SELECT p.id
       FROM players p JOIN cloud_saves cs ON cs.player_id = p.id
       WHERE p.status = 'active' AND p.created_at < ? AND cs.payload_json IS NULL
         AND NOT EXISTS (
           SELECT 1 FROM sessions s WHERE s.player_id = p.id AND s.revoked_at IS NULL
             AND s.idle_expires_at > ? AND s.absolute_expires_at > ?
         )
       LIMIT 25`,
    ).bind(now - 30 * 86_400, now, now).all<AbandonedPlayerRow>();
    for (const player of abandoned.results) {
      try {
        await deletePlayerAccount(env, player.id);
        abandonedDeleted += 1;
      } catch (error) {
        failures += 1;
        console.error(JSON.stringify({
          event: "scheduled_abandoned_delete_failed",
          errorType: error instanceof Error ? error.name : "unknown",
        }));
      }
    }
  } catch (error) {
    failures += 1;
    console.error(JSON.stringify({ event: "scheduled_abandoned_scan_failed", errorType: error instanceof Error ? error.name : "unknown" }));
  }

  try {
    const cleanup = await env.DB.batch([
      env.DB.prepare("DELETE FROM save_mutations WHERE created_at < ?").bind(now - 7 * 86_400),
      env.DB.prepare(
        `DELETE FROM save_snapshots
         WHERE id IN (
           SELECT older.id FROM save_snapshots older
           WHERE (
             SELECT COUNT(*) FROM save_snapshots newer
             WHERE newer.player_id = older.player_id
               AND (newer.created_at > older.created_at
                 OR (newer.created_at = older.created_at AND newer.id > older.id))
           ) >= 5
         )`,
      ),
      env.DB.prepare(
        `UPDATE security_actions SET status = 'cancelled', cancelled_at = ?
         WHERE kind = 'recovery_reset' AND status = 'pending' AND created_at < ?`,
      ).bind(now, now - 30 * 86_400),
      env.DB.prepare(
        `DELETE FROM sessions
         WHERE absolute_expires_at < ?
            OR idle_expires_at < ?
            OR (revoked_at IS NOT NULL AND revoked_at < ?)`,
      ).bind(now - 30 * 86_400, now - 30 * 86_400, now - 30 * 86_400),
      env.DB.prepare(
        `DELETE FROM devices
         WHERE kind = 'web_deletion' AND last_seen_at < ?
           AND NOT EXISTS (
             SELECT 1 FROM sessions s WHERE s.device_id = devices.id AND s.revoked_at IS NULL
               AND s.idle_expires_at > ? AND s.absolute_expires_at > ?
           )`,
      ).bind(now - 3_600, now, now),
    ]);
    console.log(JSON.stringify({
      event: "scheduled_cleanup",
      mutationsDeleted: cleanup[0]?.meta.changes ?? 0,
      snapshotsDeleted: cleanup[1]?.meta.changes ?? 0,
      staleActionsCancelled: cleanup[2]?.meta.changes ?? 0,
      sessionsDeleted: cleanup[3]?.meta.changes ?? 0,
      webDevicesDeleted: cleanup[4]?.meta.changes ?? 0,
    }));
  } catch (error) {
    failures += 1;
    console.error(JSON.stringify({ event: "scheduled_primary_cleanup_failed", errorType: error instanceof Error ? error.name : "unknown" }));
  }

  try {
    await env.DELETIONS_DB.prepare("DELETE FROM deletion_tombstones WHERE expires_at < ?")
      .bind(now).run();
  } catch (error) {
    failures += 1;
    console.error(JSON.stringify({ event: "scheduled_tombstone_expiry_failed", errorType: error instanceof Error ? error.name : "unknown" }));
  }

  console.log(JSON.stringify({
    event: "scheduled_complete",
    dueDeleted,
    abandonedDeleted,
    reconciled: reconciliation.inspected,
    restoredAccountsDeleted: reconciliation.accountsDeleted,
    failures,
    durationMs: Date.now() - startedAt,
  }));
}
