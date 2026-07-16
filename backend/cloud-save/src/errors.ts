import type { ErrorHandler } from "hono";

import type { AppHonoEnv } from "./types";

export class ApiError extends Error {
  readonly status: 400 | 401 | 403 | 404 | 409 | 412 | 413 | 415 | 422 | 428 | 429 | 500 | 503;
  readonly code: string;
  readonly details?: Record<string, unknown>;

  constructor(
    status: ApiError["status"],
    code: string,
    message: string,
    details?: Record<string, unknown>,
  ) {
    super(message);
    this.name = "ApiError";
    this.status = status;
    this.code = code;
    if (details !== undefined) this.details = details;
  }
}

export const errorHandler: ErrorHandler<AppHonoEnv> = (error, c) => {
  const requestId = c.get("requestId") || crypto.randomUUID();
  if (error instanceof ApiError) {
    const body: Record<string, unknown> = {
      error: { code: error.code, message: error.message, requestId },
    };
    if (error.details !== undefined) Object.assign(body, error.details);
    return c.json(body, error.status);
  }

  console.error(
    JSON.stringify({
      event: "unhandled_error",
      requestId,
      path: new URL(c.req.url).pathname,
      errorType: error instanceof Error ? error.name : "unknown",
    }),
  );
  return c.json(
    {
      error: {
        code: "INTERNAL_ERROR",
        message: "O servidor não conseguiu concluir a solicitação.",
        requestId,
      },
    },
    500,
  );
};

export function asServiceUnavailable(error: unknown): never {
  console.error(
    JSON.stringify({
      event: "database_error",
      errorType: error instanceof Error ? error.name : "unknown",
    }),
  );
  throw new ApiError(503, "SERVICE_UNAVAILABLE", "O save online está temporariamente indisponível.");
}
