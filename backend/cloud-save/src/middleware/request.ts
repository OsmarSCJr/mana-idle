import type { MiddlewareHandler } from "hono";

import { ApiError, errorHandler } from "../errors";
import type { AppHonoEnv } from "../types";

const PUBLIC_BROWSER_PATHS = new Set([
  "/health",
  "/v1/status",
  "/v1/config",
  "/v1/sessions/recover",
  "/v1/sessions/logout",
  "/v1/account",
]);

function allowedBrowserOrigin(path: string, origin: string, env: Env): boolean {
  if (path.startsWith("/v1/admin")) return origin === env.ADMIN_WEB_ORIGIN;
  return origin === env.PUBLIC_WEB_ORIGIN && PUBLIC_BROWSER_PATHS.has(path);
}

export const requestMiddleware: MiddlewareHandler<AppHonoEnv> = async (c, next) => {
  const requestIdHeader = c.req.header("x-request-id");
  const requestId = requestIdHeader !== undefined && /^[A-Za-z0-9._-]{8,80}$/u.test(requestIdHeader)
    ? requestIdHeader
    : crypto.randomUUID();
  const startedAt = Date.now();
  c.set("requestId", requestId);
  c.set("requestStartedAt", startedAt);

  const origin = c.req.header("origin");
  const path = new URL(c.req.url).pathname;
  const originAllowed = origin !== undefined && allowedBrowserOrigin(path, origin, c.env);
  try {
    if (origin !== undefined && !originAllowed) {
      throw new ApiError(403, "ORIGIN_NOT_ALLOWED", "Esta origem não pode acessar a API.");
    }
    if (c.req.method === "OPTIONS") {
      if (origin === undefined) throw new ApiError(403, "ORIGIN_REQUIRED", "A origem é obrigatória.");
      c.res = new Response(null, { status: 204 });
    } else {
      await next();
    }
  } catch (error) {
    c.res = await errorHandler(error instanceof Error ? error : new Error("Unknown error"), c);
  }
  c.res.headers.set("X-Request-Id", requestId);
  c.res.headers.set("X-Content-Type-Options", "nosniff");
  c.res.headers.set("Referrer-Policy", "no-referrer");
  c.res.headers.set("Permissions-Policy", "camera=(), microphone=(), geolocation=(), payment=()");
  if (path.startsWith("/v1/") && !c.res.headers.has("Cache-Control")) {
    c.res.headers.set("Cache-Control", "no-store");
  }
  if (origin !== undefined && originAllowed) {
    for (const [name, value] of Object.entries(corsHeaders(origin))) c.res.headers.set(name, value);
  }

  console.log(
    JSON.stringify({
      event: "request_complete",
      requestId,
      method: c.req.method,
      path,
      status: c.res.status,
      durationMs: Date.now() - startedAt,
    }),
  );
  return c.res;
};

function corsHeaders(origin: string): Record<string, string> {
  return {
    "Access-Control-Allow-Origin": origin,
    "Access-Control-Allow-Credentials": "true",
    "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
    "Access-Control-Allow-Headers": "Authorization, Content-Type, If-Match, If-None-Match, X-Client-Version, X-Request-Id",
    "Access-Control-Expose-Headers": "ETag, X-Request-Id, X-Server-Now, Retry-After",
    "Access-Control-Max-Age": "600",
    Vary: "Origin",
  };
}
