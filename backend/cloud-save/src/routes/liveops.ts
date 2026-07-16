import { Hono } from "hono";

import { ApiError, asServiceUnavailable } from "../errors";
import { getPublicLiveOps } from "../liveops/service";
import type { AppHonoEnv } from "../types";
import { unixNow } from "../http";

const PUBLIC_CONFIG_CACHE_CONTROL = "public, max-age=0, must-revalidate";

const liveOps = new Hono<AppHonoEnv>();

function etagMatches(value: string | undefined, etag: string): boolean {
  if (value === undefined) return false;
  const weakValue = (candidate: string) => candidate.replace(/^W\//iu, "");
  return value.split(",").some((candidate) => {
    const normalized = candidate.trim();
    return normalized === "*" || weakValue(normalized) === weakValue(etag);
  });
}

liveOps.get("/config", async (c) => {
  try {
    const representation = await getPublicLiveOps(c.env.LIVEOPS_DB, unixNow());
    const headers = {
      "Cache-Control": PUBLIC_CONFIG_CACHE_CONTROL,
      ETag: representation.etag,
      "X-Server-Now": String(representation.body.serverNow),
    };
    if (etagMatches(c.req.header("if-none-match"), representation.etag)) {
      return new Response(null, { status: 304, headers });
    }
    return c.json(representation.body, 200, headers);
  } catch (error) {
    if (error instanceof ApiError) throw error;
    asServiceUnavailable(error);
  }
});

export default liveOps;
