import { asServiceUnavailable } from "../errors";
import type { OperationalSettings } from "../types";

interface SettingsRow {
  maintenance_mode: number;
  read_only_uploads: number;
  allow_new_accounts: number;
  min_client_version: string | null;
  updated_at: number;
}

export async function getOperationalSettings(db: D1Database): Promise<OperationalSettings> {
  try {
    const row = await db
      .prepare(
        `SELECT maintenance_mode, read_only_uploads, allow_new_accounts,
                min_client_version, updated_at
         FROM system_settings WHERE id = 1`,
      )
      .first<SettingsRow>();
    if (row === null) return defaultSettings();
    return {
      maintenanceMode: row.maintenance_mode === 1,
      readOnlyUploads: row.read_only_uploads === 1,
      allowNewAccounts: row.allow_new_accounts === 1,
      minClientVersion: row.min_client_version,
      updatedAt: row.updated_at,
    };
  } catch (error) {
    asServiceUnavailable(error);
  }
}

export function defaultSettings(): OperationalSettings {
  return {
    maintenanceMode: false,
    readOnlyUploads: false,
    allowNewAccounts: true,
    minClientVersion: null,
    updatedAt: 0,
  };
}
