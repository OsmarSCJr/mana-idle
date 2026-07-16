import { ApiError } from "../errors";

export function tokenPepper(env: Env, version: number): string {
  if (version === 1) return env.TOKEN_PEPPER_V1;
  if (version === 2 && env.TOKEN_PEPPER_V2) return env.TOKEN_PEPPER_V2;
  throw new ApiError(401, "INVALID_SESSION", "A sessão é inválida ou expirou.");
}

export function recoveryPepper(env: Env, version: number): string {
  if (version === 1) return env.RECOVERY_PEPPER_V1;
  if (version === 2 && env.RECOVERY_PEPPER_V2) return env.RECOVERY_PEPPER_V2;
  throw new ApiError(401, "INVALID_RECOVERY", "O código de recuperação é inválido.");
}
