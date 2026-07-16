import { ApiError } from "../errors";

export async function enforceRateLimit(limiter: RateLimit, key: string): Promise<void> {
  const result = await limiter.limit({ key });
  if (!result.success) {
    throw new ApiError(429, "RATE_LIMITED", "Muitas tentativas. Aguarde um minuto e tente novamente.");
  }
}
