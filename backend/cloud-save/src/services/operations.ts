import { getOperationalSettings } from "../db/settings";
import { ApiError } from "../errors";

type OperationKind = "read" | "upload" | "new_account" | "security" | "wallet" | "deletion";

function versionParts(version: string): number[] {
  return (version.match(/\d+/gu) ?? []).slice(0, 4).map(Number);
}

function compareVersions(left: string, right: string): number {
  const a = versionParts(left);
  const b = versionParts(right);
  const length = Math.max(a.length, b.length);
  for (let index = 0; index < length; index += 1) {
    const difference = (a[index] ?? 0) - (b[index] ?? 0);
    if (difference !== 0) return difference;
  }
  return 0;
}

export async function enforceOperationalState(
  env: Env,
  kind: OperationKind,
  clientVersion?: string,
): Promise<void> {
  const settings = await getOperationalSettings(env.DB);
  if (kind === "deletion") return;
  if (settings.maintenanceMode) {
    throw new ApiError(503, "MAINTENANCE", "O save online está em manutenção. Seu progresso local continua seguro.");
  }
  if (kind === "new_account" && !settings.allowNewAccounts) {
    throw new ApiError(503, "NEW_ACCOUNTS_PAUSED", "Novas contas online estão temporariamente pausadas.");
  }
  if ((kind === "upload" || kind === "wallet") && settings.readOnlyUploads) {
    throw new ApiError(503, "READ_ONLY", "A nuvem está temporariamente somente para leitura.");
  }
  if (settings.minClientVersion !== null
    && (clientVersion === undefined || compareVersions(clientVersion, settings.minClientVersion) < 0)) {
    throw new ApiError(422, "CLIENT_UPDATE_REQUIRED", "Atualize o jogo para continuar usando o save online.", {
      minClientVersion: settings.minClientVersion,
    });
  }
}
