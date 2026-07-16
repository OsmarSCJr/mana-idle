import { siteConfig } from "./config";

interface ApiErrorEnvelope {
  error?: {
    code?: string;
    message?: string;
    requestId?: string;
  };
}

interface RecoverySession {
  playerId: string;
  deviceId: string;
  sessionToken: string;
  sessionExpiresAt: number;
  purpose: "account_deletion";
}

export type ServiceState = "online" | "degraded" | "offline" | "unconfigured";

export interface ServiceHealth {
  state: ServiceState;
  checkedAt: Date;
}

export class PublicApiError extends Error {
  readonly code: string;
  readonly requestId?: string;
  readonly status: number;

  constructor(status: number, code: string, message: string, requestId?: string) {
    super(message);
    this.name = "PublicApiError";
    this.status = status;
    this.code = code;
    this.requestId = requestId;
  }
}

async function parseError(response: Response): Promise<PublicApiError> {
  let envelope: ApiErrorEnvelope = {};
  try {
    envelope = (await response.json()) as ApiErrorEnvelope;
  } catch {
    // A resposta pode não conter JSON em indisponibilidades de borda.
  }

  const requestId =
    envelope.error?.requestId ?? response.headers.get("X-Request-Id") ?? undefined;
  return new PublicApiError(
    response.status,
    envelope.error?.code ?? "REQUEST_FAILED",
    envelope.error?.message ?? "Não foi possível concluir a solicitação.",
    requestId,
  );
}

export async function checkServiceHealth(signal?: AbortSignal): Promise<ServiceHealth> {
  if (!siteConfig.apiUrl) {
    return { state: "unconfigured", checkedAt: new Date() };
  }

  try {
    const response = await fetch(`${siteConfig.apiUrl}/health`, {
      method: "GET",
      headers: { Accept: "application/json" },
      cache: "no-store",
      signal,
    });
    return {
      state: response.ok ? "online" : response.status >= 500 ? "degraded" : "offline",
      checkedAt: new Date(),
    };
  } catch {
    return { state: "offline", checkedAt: new Date() };
  }
}

async function logoutEphemeralSession(token: string): Promise<void> {
  try {
    await fetch(`${siteConfig.apiUrl}/v1/sessions/logout`, {
      method: "POST",
      headers: { Authorization: `Bearer ${token}` },
      cache: "no-store",
    });
  } catch {
    // A sessão expira em 15 minutos; falha de limpeza não bloqueia a resposta ao usuário.
  }
}

export async function deleteAccountWithRecoveryCode(
  recoveryCode: string,
  signal?: AbortSignal,
): Promise<void> {
  if (!siteConfig.apiUrl) {
    throw new PublicApiError(
      503,
      "SERVICE_NOT_CONFIGURED",
      "O serviço de exclusão ainda não está configurado neste ambiente.",
    );
  }

  let sessionToken = "";
  let deleted = false;
  try {
    const recoveryResponse = await fetch(`${siteConfig.apiUrl}/v1/sessions/recover`, {
      method: "POST",
      headers: {
        Accept: "application/json",
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        recoveryCode: recoveryCode.trim().toUpperCase(),
        installationId: crypto.randomUUID(),
        deviceLabel: "Página de exclusão",
        purpose: "account_deletion",
      }),
      cache: "no-store",
      signal,
    });

    if (!recoveryResponse.ok) {
      throw await parseError(recoveryResponse);
    }

    const session = (await recoveryResponse.json()) as RecoverySession;
    if (!session.sessionToken || session.purpose !== "account_deletion") {
      throw new PublicApiError(
        502,
        "INVALID_RECOVERY_RESPONSE",
        "O serviço retornou uma resposta inesperada. Tente novamente.",
      );
    }
    sessionToken = session.sessionToken;

    const deletionResponse = await fetch(`${siteConfig.apiUrl}/v1/account`, {
      method: "DELETE",
      headers: {
        Authorization: `Bearer ${sessionToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        recoveryCode: recoveryCode.trim().toUpperCase(),
        confirmation: "EXCLUIR",
      }),
      cache: "no-store",
      signal,
    });

    if (!deletionResponse.ok) {
      throw await parseError(deletionResponse);
    }
    deleted = true;
  } finally {
    if (sessionToken && !deleted) {
      await logoutEphemeralSession(sessionToken);
    }
  }
}
