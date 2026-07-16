import { createRemoteJWKSet, jwtVerify } from "jose";
import type { MiddlewareHandler } from "hono";

import { ApiError } from "../errors";
import { secureStringEqual } from "../security/crypto";
import type { AppHonoEnv } from "../types";

const JWKS_BY_TEAM = new Map<string, ReturnType<typeof createRemoteJWKSet>>();

function accessJwks(teamDomain: string): ReturnType<typeof createRemoteJWKSet> {
  const existing = JWKS_BY_TEAM.get(teamDomain);
  if (existing !== undefined) return existing;
  const created = createRemoteJWKSet(new URL(`${teamDomain}/cdn-cgi/access/certs`));
  JWKS_BY_TEAM.set(teamDomain, created);
  return created;
}

export const requireAdmin: MiddlewareHandler<AppHonoEnv> = async (c, next) => {
  if (c.env.ENVIRONMENT === "development" && c.env.ENABLE_DEV_ADMIN === "true"
    && c.env.DEV_ADMIN_TOKEN.length >= 32 && !c.env.DEV_ADMIN_TOKEN.startsWith("dev-only")) {
    const authorization = c.req.header("authorization") ?? "";
    const provided = authorization.startsWith("Bearer ") ? authorization.slice(7).trim() : "";
    if (provided !== "" && await secureStringEqual(provided, c.env.DEV_ADMIN_TOKEN)) {
      c.set("admin", { actor: "local-development" });
      await next();
      return;
    }
  }

  const token = c.req.header("cf-access-jwt-assertion");
  if (token === undefined) throw new ApiError(403, "ADMIN_ACCESS_REQUIRED", "Acesso administrativo não autorizado.");
  if (c.env.ACCESS_TEAM_DOMAIN.includes("replace-me") || c.env.ACCESS_AUD.startsWith("replace-after")) {
    throw new ApiError(503, "ADMIN_ACCESS_NOT_CONFIGURED", "O Cloudflare Access ainda não foi configurado.");
  }
  try {
    const { payload } = await jwtVerify(token, accessJwks(c.env.ACCESS_TEAM_DOMAIN), {
      issuer: c.env.ACCESS_TEAM_DOMAIN,
      audience: c.env.ACCESS_AUD,
    });
    const actor = typeof payload.email === "string"
      ? payload.email
      : typeof payload.sub === "string" ? payload.sub : "access-user";
    c.set("admin", { actor: actor.slice(0, 254) });
  } catch (error) {
    console.warn(
      JSON.stringify({
        event: "admin_access_rejected",
        requestId: c.get("requestId"),
        errorType: error instanceof Error ? error.name : "invalid_jwt",
      }),
    );
    throw new ApiError(403, "ADMIN_ACCESS_REQUIRED", "Acesso administrativo não autorizado.");
  }
  await next();
};
