import type { Context } from "hono";

export interface AuthContext {
  sessionId: string;
  playerId: string;
  deviceId: string;
  purpose: "game" | "account_deletion";
  absoluteExpiresAt: number;
}

export interface AdminContext {
  actor: string;
}

export interface AppVariables {
  requestId: string;
  requestStartedAt: number;
  auth: AuthContext;
  admin: AdminContext;
}

export interface AppHonoEnv {
  Bindings: Env;
  Variables: AppVariables;
}

export type AppContext = Context<AppHonoEnv>;

export interface SaveRow {
  player_id: string;
  revision: number;
  schema_version: number | null;
  payload_json: string | null;
  payload_sha256: string | null;
  payload_bytes: number | null;
  previous_revision: number | null;
  previous_schema_version: number | null;
  previous_payload_json: string | null;
  previous_payload_sha256: string | null;
  previous_payload_bytes: number | null;
  previous_updated_at: number | null;
  updated_at: number | null;
}

export interface MutationRow {
  mutation_id: string;
  base_revision: number;
  resulting_revision: number;
  payload_sha256: string;
  device_id: string;
  server_updated_at: number;
}

export interface OperationalSettings {
  maintenanceMode: boolean;
  readOnlyUploads: boolean;
  allowNewAccounts: boolean;
  minClientVersion: string | null;
  updatedAt: number;
}
