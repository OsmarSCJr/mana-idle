import { env, exports as workerExports } from "cloudflare:workers";
import { applyD1Migrations } from "cloudflare:test";
import { beforeEach, describe, expect, it } from "vitest";
import { z } from "zod";

import { sha256Hex } from "../src/security/crypto";
import { reconcileTombstones } from "../src/services/deletion";
import { runScheduledMaintenance } from "../src/scheduled";
import { validateSavePayload } from "../src/validation/save";
import { makeSaveV10 } from "./fixtures/save-v10";

const worker = workerExports.default;

const createResponseSchema = z.object({
  playerId: z.uuid(),
  deviceId: z.uuid(),
  sessionToken: z.string().startsWith("S1."),
  recoveryCode: z.string().startsWith("R1-"),
  sessionExpiresAt: z.number(),
});
const revisionResponseSchema = z.object({ revision: z.number() });

async function createAccount() {
  const response = await worker.fetch("https://api.test/v1/players", {
    method: "POST",
    headers: {
      "content-type": "application/json",
      "cf-connecting-ip": `198.51.100.${crypto.getRandomValues(new Uint8Array(1))[0] ?? 1}`,
    },
    body: JSON.stringify({
      installationId: crypto.randomUUID(),
      deviceLabel: "Teste",
      clientVersion: "0.1.8-alpha",
    }),
  });
  expect(response.status).toBe(201);
  return createResponseSchema.parse(await response.json());
}

async function upload(
  token: string,
  revision: number,
  payload: string,
  mutationId = crypto.randomUUID(),
  resolution: "normal" | "keep_device" = "normal",
  clientSavedAt = Math.floor(Date.now() / 1000),
) {
  const sha = await sha256Hex(payload);
  const response = await worker.fetch("https://api.test/v1/save", {
    method: "PUT",
    headers: {
      authorization: `Bearer ${token}`,
      "content-type": "application/json",
      "if-match": `"save-${revision}"`,
      "x-client-version": "0.1.8-alpha",
    },
    body: JSON.stringify({
      mutationId,
      schemaVersion: 10,
      clientSavedAt,
      resolution,
      payloadSha256: sha,
      payloadJson: payload,
    }),
  });
  return { response, sha, mutationId };
}

beforeEach(async () => {
  await applyD1Migrations(env.DB, env.MAIN_MIGRATIONS);
  await applyD1Migrations(env.DELETIONS_DB, env.DELETION_MIGRATIONS);
  await applyD1Migrations(env.LIVEOPS_DB, env.LIVEOPS_MIGRATIONS);
});

describe("cloud save API", () => {
  it("aceita os 1.189 capítulos da Bíblia e mantém um teto defensivo", () => {
    const completeBible = makeSaveV10();
    const chapters = Array.from({ length: 1_189 }, (_, index) => {
      const book = `B${String(Math.floor(index / 19)).padStart(2, "0")}`;
      return `${book}:${index % 19 + 1}`;
    });
    const study = completeBible.estudo as { progresso: { capitulosLidos: string[] } };
    study.progresso.capitulosLidos = chapters;
    expect(validateSavePayload(JSON.stringify(completeBible), 10, 10).bytes).toBeGreaterThan(1_189);

    study.progresso.capitulosLidos = Array.from(
      { length: 1_201 },
      (_, index) => `C${String(Math.floor(index / 19)).padStart(2, "0")}:${index % 19 + 1}`,
    );
    expect(() => validateSavePayload(JSON.stringify(completeBible), 10, 10)).toThrow();
  });

  it("aceita o save v10 realista com sentinela -1 e rejeita relógio futuro", async () => {
    const payload = JSON.stringify(makeSaveV10());
    expect(validateSavePayload(payload, 10, 10).bytes).toBeGreaterThan(100);
    const expanded = makeSaveV10();
    expanded.graca = 100;
    expanded.gracaTotal = 1_000_000;
    expanded.dadivaFrutosNivel = 3;
    expanded.dadivasCompradas = ["d_comprador_marcos", "d_primicias", "d_vigilia", "d_coroa"];
    expanded.marcosLedger = { jornada: [25, 50], vida_cristo: [25] };
    expanded.moedaMarcosLedger = { vida_cristo: ["1e6"] };
    expanded.cosmeticosComprados = ["fundo_aurora", "titulo_peregrino"];
    expanded.cosmeticosAtivos = { tema_fundo: "fundo_aurora", titulo: "titulo_peregrino" };
    expect(validateSavePayload(JSON.stringify(expanded), 10, 10).bytes).toBeGreaterThan(100);

    const invalidCosmetic = structuredClone(expanded);
    invalidCosmetic.cosmeticosAtivos = { titulo: "fundo_aurora" };
    expect(() => validateSavePayload(JSON.stringify(invalidCosmetic), 10, 10)).toThrow();
    const future = makeSaveV10();
    future.lastSeen = Math.floor(Date.now() / 1000) + 3_600;
    const account = await createAccount();
    const rejected = await upload(account.sessionToken, 0, JSON.stringify(future));
    expect(rejected.response.status).toBe(422);
  });

  it("inclui CORS, request id, no-store e cabeçalhos de segurança também nos erros", async () => {
    const response = await worker.fetch("https://api.test/v1/sessions/recover", {
      method: "POST",
      headers: { "content-type": "application/json", origin: "http://localhost:5173" },
      body: JSON.stringify({ recoveryCode: "inválido", installationId: "inválido" }),
    });
    expect(response.status).toBe(422);
    expect(response.headers.get("access-control-allow-origin")).toBe("http://localhost:5173");
    expect(response.headers.get("x-request-id")).toBeTruthy();
    expect(response.headers.get("cache-control")).toBe("no-store");
    expect(response.headers.get("x-content-type-options")).toBe("nosniff");
    const body = z.object({ error: z.object({ requestId: z.string(), code: z.string() }) }).parse(await response.json());
    expect(body.error.requestId).toBe(response.headers.get("x-request-id"));
  });

  it("mantem rotas administrativas fora da autenticacao de jogador", async () => {
    const withoutAccess = await worker.fetch("https://api.test/v1/admin/overview");
    expect(withoutAccess.status).toBe(403);
    expect(
      z.object({ error: z.object({ code: z.literal("ADMIN_ACCESS_REQUIRED") }) })
        .parse(await withoutAccess.json()).error.code,
    ).toBe("ADMIN_ACCESS_REQUIRED");

    const placeholderAccess = await worker.fetch("https://api.test/v1/admin/overview", {
      headers: {
        origin: "http://localhost:5174",
        "cf-access-jwt-assertion": "probe",
      },
    });
    expect(placeholderAccess.status).toBe(503);
    expect(
      z.object({ error: z.object({ code: z.literal("ADMIN_ACCESS_NOT_CONFIGURED") }) })
        .parse(await placeholderAccess.json()).error.code,
    ).toBe("ADMIN_ACCESS_NOT_CONFIGURED");
  });

  it("cria conta, grava, detecta conflito e mantém retries antigos idempotentes", async () => {
    const account = await createAccount();
    const firstPayload = JSON.stringify(makeSaveV10(20));
    const first = await upload(account.sessionToken, 0, firstPayload);
    expect(first.response.status).toBe(200);
    expect(revisionResponseSchema.parse(await first.response.json()).revision).toBe(1);

    const secondPayload = JSON.stringify(makeSaveV10(30));
    const second = await upload(account.sessionToken, 1, secondPayload);
    expect(second.response.status).toBe(200);
    expect(revisionResponseSchema.parse(await second.response.json()).revision).toBe(2);

    const retry = await upload(account.sessionToken, 0, firstPayload, first.mutationId);
    expect(retry.response.status).toBe(200);
    expect(revisionResponseSchema.parse(await retry.response.json()).revision).toBe(1);

    const conflict = await upload(account.sessionToken, 1, JSON.stringify(makeSaveV10(40)));
    expect(conflict.response.status).toBe(412);
    const conflictBody = z.object({ conflict: z.object({ revision: z.number(), payloadJson: z.string() }) })
      .parse(await conflict.response.json());
    expect(conflictBody.conflict.revision).toBe(2);
    expect(conflictBody.conflict.payloadJson).toBe(secondPayload);
  });

  it("mantém restore-previous idempotente mesmo depois de outra escrita", async () => {
    const account = await createAccount();
    await upload(account.sessionToken, 0, JSON.stringify(makeSaveV10(20)));
    await upload(account.sessionToken, 1, JSON.stringify(makeSaveV10(30)));
    const mutationId = crypto.randomUUID();
    const restoreRequest = () => worker.fetch("https://api.test/v1/save/restore-previous", {
      method: "POST",
      headers: {
        authorization: `Bearer ${account.sessionToken}`,
        "content-type": "application/json",
        "if-match": '"save-2"',
        "x-client-version": "0.1.8-alpha",
      },
      body: JSON.stringify({ mutationId, reason: "teste_restore" }),
    });
    const restored = await restoreRequest();
    expect(restored.status).toBe(200);
    expect(revisionResponseSchema.parse(await restored.json()).revision).toBe(3);
    await upload(account.sessionToken, 3, JSON.stringify(makeSaveV10(50)));
    const retry = await restoreRequest();
    expect(retry.status).toBe(200);
    expect(revisionResponseSchema.parse(await retry.json()).revision).toBe(3);
  });

  it("recupera em segundo aparelho e o CAS impede overwrite silencioso", async () => {
    const account = await createAccount();
    const recoveredResponse = await worker.fetch("https://api.test/v1/sessions/recover", {
      method: "POST",
      headers: { "content-type": "application/json", "cf-connecting-ip": "198.51.100.200" },
      body: JSON.stringify({
        recoveryCode: account.recoveryCode,
        installationId: crypto.randomUUID(),
        deviceLabel: "Segundo",
        clientVersion: "0.1.8-alpha",
      }),
    });
    expect(recoveredResponse.status).toBe(200);
    const recovered = z.object({ sessionToken: z.string(), deviceId: z.uuid() })
      .parse(await recoveredResponse.json());
    expect((await upload(account.sessionToken, 0, JSON.stringify(makeSaveV10(20)))).response.status).toBe(200);
    expect((await upload(recovered.sessionToken, 0, JSON.stringify(makeSaveV10(30)))).response.status).toBe(412);
  });

  it("oferece wallet grátis idempotente, sem saldo pago ou grant duplicado", async () => {
    const account = await createAccount();
    const operationId = crypto.randomUUID();
    const claim = () => worker.fetch("https://api.test/v1/wallet/claim-daily", {
      method: "POST",
      headers: {
        authorization: `Bearer ${account.sessionToken}`,
        "content-type": "application/json",
        "x-client-version": "0.1.8-alpha",
      },
      body: JSON.stringify({ operationId }),
    });
    const first = await claim();
    expect(first.status).toBe(200);
    const firstBody = z.object({ freeBalance: z.number(), paidBalance: z.literal(0), revision: z.number() })
      .parse(await first.json());
    expect(firstBody.freeBalance).toBe(5);
    const retry = await claim();
    expect(retry.status).toBe(200);
    expect(revisionResponseSchema.parse(await retry.json()).revision).toBe(firstBody.revision);
    const duplicate = await worker.fetch("https://api.test/v1/wallet/claim-daily", {
      method: "POST",
      headers: {
        authorization: `Bearer ${account.sessionToken}`,
        "content-type": "application/json",
        "x-client-version": "0.1.8-alpha",
      },
      body: JSON.stringify({ operationId: crypto.randomUUID() }),
    });
    expect(duplicate.status).toBe(409);
  });

  it("permite cancelar e recriar ações atrasadas sem colisão de histórico", async () => {
    const account = await createAccount();
    const createAction = () => worker.fetch("https://api.test/v1/security/recovery-reset", {
      method: "POST",
      headers: { authorization: `Bearer ${account.sessionToken}`, "x-client-version": "0.1.8-alpha" },
    });
    for (let index = 0; index < 2; index += 1) {
      const created = await createAction();
      expect(created.status).toBe(202);
      const body = z.object({ action: z.object({ id: z.uuid() }) }).parse(await created.json());
      const cancelled = await worker.fetch(`https://api.test/v1/security/actions/${body.action.id}`, {
        method: "DELETE",
        headers: { authorization: `Bearer ${account.sessionToken}` },
      });
      expect(cancelled.status).toBe(204);
    }
  });

  it("exclui pela sessão web efêmera e reconcilia tombstone após restore", async () => {
    const account = await createAccount();
    const playerRow = await env.DB.prepare("SELECT deletion_hmac, recovery_hash FROM players WHERE id = ?")
      .bind(account.playerId).first<{ deletion_hmac: string; recovery_hash: string }>();
    expect(playerRow).not.toBeNull();
    if (playerRow === null) throw new Error("missing player fixture");
    const webSessionResponse = await worker.fetch("https://api.test/v1/sessions/recover", {
      method: "POST",
      headers: {
        "content-type": "application/json",
        origin: "http://localhost:5173",
        "cf-connecting-ip": "198.51.100.220",
      },
      body: JSON.stringify({
        recoveryCode: account.recoveryCode,
        installationId: crypto.randomUUID(),
        purpose: "account_deletion",
      }),
    });
    expect(webSessionResponse.status).toBe(200);
    const webSession = z.object({ sessionToken: z.string() }).parse(await webSessionResponse.json());
    const deleted = await worker.fetch("https://api.test/v1/account", {
      method: "DELETE",
      headers: {
        authorization: `Bearer ${webSession.sessionToken}`,
        "content-type": "application/json",
        origin: "http://localhost:5173",
      },
      body: JSON.stringify({ recoveryCode: account.recoveryCode, confirmation: "EXCLUIR" }),
    });
    expect(deleted.status).toBe(204);
    expect(await env.DB.prepare("SELECT 1 AS present FROM players WHERE id = ?").bind(account.playerId).first()).toBeNull();

    await env.DB.prepare(
      `INSERT INTO players
         (id, recovery_hash, recovery_key_version, deletion_hmac, deletion_key_version, status, created_at)
       VALUES (?, ?, 1, ?, 1, 'active', unixepoch())`,
    ).bind(account.playerId, playerRow.recovery_hash, playerRow.deletion_hmac).run();
    const reconciled = await reconcileTombstones(env, 100);
    expect(reconciled.accountsDeleted).toBe(1);
    expect(await env.DB.prepare("SELECT 1 AS present FROM players WHERE id = ?").bind(account.playerId).first()).toBeNull();
  });

  it("scheduled limita snapshots a cinco por conta", async () => {
    const account = await createAccount();
    const payload = JSON.stringify(makeSaveV10(20));
    const accepted = await upload(account.sessionToken, 0, payload);
    expect(accepted.response.status).toBe(200);
    for (let index = 0; index < 7; index += 1) {
      await env.DB.prepare(
        `INSERT INTO save_snapshots
           (player_id, revision, reason, schema_version, payload_json, payload_sha256, payload_bytes, created_at)
         VALUES (?, ?, ?, 9, ?, ?, ?, ?)`,
      ).bind(
        account.playerId, index + 10, `test_${index}`, payload, accepted.sha,
        new TextEncoder().encode(payload).byteLength, index + 1,
      ).run();
    }
    await runScheduledMaintenance(env);
    const count = await env.DB.prepare("SELECT COUNT(*) AS value FROM save_snapshots WHERE player_id = ?")
      .bind(account.playerId).first<{ value: number }>();
    expect(count?.value).toBe(5);
  });
});
