import type { z } from "zod";

import { ApiError } from "./errors";
import type { AppContext, SaveRow } from "./types";

export const MAX_SAVE_BYTES = 64 * 1024;
export const MAX_ENVELOPE_BYTES = 96 * 1024;
export const MAX_STANDARD_BODY_BYTES = 8 * 1024;

export async function readBoundedJson<T extends z.ZodType>(
  c: AppContext,
  schema: T,
  limit = MAX_STANDARD_BODY_BYTES,
): Promise<z.infer<T>> {
  const contentType = c.req.header("content-type")?.replace(/;.*$/u, "").trim().toLowerCase();
  if (contentType !== "application/json") {
    throw new ApiError(415, "UNSUPPORTED_MEDIA_TYPE", "Envie o corpo como application/json.");
  }

  const declaredLength = Number(c.req.header("content-length") ?? "0");
  if (Number.isFinite(declaredLength) && declaredLength > limit) {
    throw new ApiError(413, "BODY_TOO_LARGE", "O corpo da solicitação excede o limite permitido.");
  }

  const body = c.req.raw.body;
  if (body === null) throw new ApiError(400, "INVALID_JSON", "O corpo JSON é obrigatório.");
  const reader = body.getReader();
  const decoder = new TextDecoder("utf-8", { fatal: true });
  let bytes = 0;
  let text = "";
  try {
    let chunk = await reader.read();
    while (!chunk.done) {
      bytes += chunk.value.byteLength;
      if (bytes > limit) {
        await reader.cancel("body limit exceeded");
        throw new ApiError(413, "BODY_TOO_LARGE", "O corpo da solicitação excede o limite permitido.");
      }
      text += decoder.decode(chunk.value, { stream: true });
      chunk = await reader.read();
    }
    text += decoder.decode();
  } catch (error) {
    if (error instanceof ApiError) throw error;
    throw new ApiError(400, "INVALID_ENCODING", "O corpo deve usar UTF-8 válido.");
  }

  let parsed: unknown;
  try {
    parsed = JSON.parse(text);
  } catch {
    throw new ApiError(400, "INVALID_JSON", "O corpo contém JSON inválido.");
  }
  const result = schema.safeParse(parsed);
  if (!result.success) {
    throw new ApiError(422, "VALIDATION_ERROR", "Os dados enviados são inválidos.", {
      fields: result.error.issues.slice(0, 12).map((issue) => ({
        path: issue.path.join("."),
        code: issue.code,
      })),
    });
  }
  return result.data;
}

export function parseIfMatch(c: AppContext): number {
  const value = c.req.header("if-match");
  if (value === undefined) {
    throw new ApiError(428, "IF_MATCH_REQUIRED", "Envie a revisão conhecida no cabeçalho If-Match.");
  }
  const match = /^"save-(0|[1-9]\d*)"$/.exec(value.trim());
  if (match?.[1] === undefined) {
    throw new ApiError(400, "INVALID_IF_MATCH", "O cabeçalho If-Match deve usar o formato \"save-N\".");
  }
  const revision = Number(match[1]);
  if (!Number.isSafeInteger(revision)) {
    throw new ApiError(400, "INVALID_IF_MATCH", "A revisão enviada não é válida.");
  }
  return revision;
}

export function saveEtag(revision: number): string {
  return `"save-${revision}"`;
}

export function parseLiveOpsIfMatch(c: AppContext): number {
  const value = c.req.header("if-match");
  if (value === undefined) {
    throw new ApiError(428, "IF_MATCH_REQUIRED", "Envie a revisão do LiveOps no cabeçalho If-Match.");
  }
  const match = /^"liveops-(0|[1-9]\d*)"$/u.exec(value.trim());
  if (match?.[1] === undefined) {
    throw new ApiError(400, "INVALID_IF_MATCH", "O cabeçalho If-Match deve usar o formato \"liveops-N\".");
  }
  const revision = Number(match[1]);
  if (!Number.isSafeInteger(revision)) {
    throw new ApiError(400, "INVALID_IF_MATCH", "A revisão enviada não é válida.");
  }
  return revision;
}

export function liveOpsStateEtag(revision: number): string {
  return `"liveops-${revision}"`;
}

export function saveRepresentation(row: SaveRow, serverNow: number): Record<string, unknown> {
  return {
    hasPayload: row.payload_json !== null,
    revision: row.revision,
    etag: saveEtag(row.revision),
    schemaVersion: row.schema_version,
    payloadJson: row.payload_json,
    sha256: row.payload_sha256,
    serverUpdatedAt: row.updated_at,
    serverNow,
  };
}

export function noStoreHeaders(etag?: string): Record<string, string> {
  return {
    "Cache-Control": "no-store",
    ...(etag === undefined ? {} : { ETag: etag }),
  };
}

export function unixNow(): number {
  return Math.floor(Date.now() / 1000);
}
