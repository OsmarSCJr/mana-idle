# Contrato HTTP — Mana Idle Cloud Save

Base path: `/v1`.

Todos os timestamps são inteiros Unix em segundos. IDs de jogador, aparelho, ação e operação usam UUID. Respostas de `/v1/*` recebem `X-Request-Id`. Por padrão usam `Cache-Control: no-store`; `GET /v1/config` é a exceção revalidável descrita abaixo.

## Autenticação e cabeçalhos

- Rotas do jogo: `Authorization: Bearer S1...` (ou `S2...` após rotação).
- Escritas e leituras sensíveis do jogo: `X-Client-Version: 0.1.8-alpha`.
- Upload/restore: `If-Match: "save-N"`.
- GET de save: `If-None-Match: "save-N"` é opcional e pode retornar `304`.
- GET de LiveOps: `If-None-Match: W/"liveops-N-hash"` é opcional e pode retornar `304` com `X-Server-Now` fresco.
- Admin em staging/produção: JWT injetado por Cloudflare Access no cabeçalho `Cf-Access-Jwt-Assertion`.
- Admin local: `Authorization: Bearer <DEV_ADMIN_TOKEN>`, somente com `ENVIRONMENT=development` e `ENABLE_DEV_ADMIN=true`.

O APK nativo não envia `Origin`. A landing page pode chamar apenas status, recuperação, logout e exclusão. A origem do admin pode chamar somente `/v1/admin/*`.

## Erros

Formato comum:

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Os dados enviados são inválidos.",
    "requestId": "f7b94153-3fbe-44b3-a9f9-6c0123456789"
  }
}
```

Alguns erros acrescentam dados no nível raiz, como `conflict`, `serverNow`, `action`, `freeBalance` ou `required`. O cliente deve decidir pelo campo estável `error.code`, não pelo texto traduzido.

Status relevantes: `401` sessão/código inválido, `403` propósito/origem/acesso, `409` estado incompatível, `412` conflito de revisão, `422` conteúdo inválido, `428` `If-Match` ausente, `429` limite, `503` indisponibilidade/manutenção.

## Rotas públicas

### `GET /health`

```json
{ "status": "ok", "serverNow": 1784088000 }
```

### `GET /v1/status`

```json
{
  "maintenanceMode": false,
  "readOnlyUploads": false,
  "allowNewAccounts": true,
  "minClientVersion": null,
  "serverNow": 1784088000
}
```

### `GET /v1/config`

Entrega somente balanceamento e campanhas publicados. Não exige sessão e pode ser chamado pelo APK sem `Origin` ou pela origem exata da landing. Responde com `Cache-Control: public, max-age=0, must-revalidate`, ETag fraco e `X-Server-Now`.

```json
{
  "schemaVersion": 2,
  "revision": 1,
  "versionId": "balance-baseline-v1",
  "publishedAt": 1784210400,
  "serverNow": 1784212800,
  "config": {
    "economy": {
      "growthSegments": [
        { "maxQuantity": 300, "rate": 1.11 },
        { "maxQuantity": 1500, "rate": 1.05 },
        { "maxQuantity": 4000, "rate": 1.012 },
        { "maxQuantity": 0, "rate": 1.008 }
      ],
      "saintBonus": 0.2,
      "prestigeDivisor": 200000000000,
      "prophetUnlockQuantity": 25,
      "prophetCostMultiplier": 10,
      "prophetSpeedMultiplier": 0.8,
      "offlineCapSeconds": 28800,
      "dadivaLadderBaseCost": 10,
      "dadivaLadderCostGrowth": 1.8,
      "dadivaLadderMultiplier": 1.3,
      "milestones": [{ "quantity": 25, "multiplier": 1.5 }],
      "generalMilestones": [{ "quantity": 25, "type": "speed", "multiplier": 1.5, "gems": 0, "relics": 0 }]
    },
    "boosts": {
      "fervorProductionMultiplier": 2,
      "pentecostProductionMultiplier": 5,
      "holyHandsManualMultiplier": 10,
      "swiftStepTimeMultiplier": 0.5,
      "harvestSeconds": 7200
    },
    "rewards": {
      "videoGems": 5,
      "offlineTripleGemCost": 3,
      "novaStarMinSeconds": 300,
      "novaStarMaxSeconds": 900,
      "novaStarProductionSeconds": 120,
      "novaStarDailyGems": 2
    }
  },
  "campaigns": []
}
```

Cada campanha publicada inclui `id`, `key`, `versionId`, `version`, `name`, janela efetiva e os efeitos normalizados: produção global/offline/manual, fé de estudos, gemas gratuitas e multiplicadores por gerador. O servidor entrega até 15 dias de histórico efetivo para que o cliente segmente corretamente o período offline.

### `POST /v1/players`

Cria conta anônima. Deve ser chamada pelo jogo nativo.

```json
{
  "installationId": "d50268c4-141d-4aef-b878-6a18734f466b",
  "deviceLabel": "Celular principal",
  "clientVersion": "0.1.8-alpha"
}
```

Resposta `201`:

```json
{
  "playerId": "2db22f6b-698c-4ddf-a171-f4ab76ec341c",
  "deviceId": "a1cc8590-701c-4333-8224-4df8f19e1011",
  "sessionToken": "S1.token-exibido-apenas-agora",
  "sessionExpiresAt": 1815624000,
  "recoveryCode": "R1-XXXX-XXXX-XXXX-XXXX-XXXX-XXXX-XXX",
  "save": { "hasPayload": false, "revision": 0, "etag": "\"save-0\"" },
  "wallet": { "freeBalance": 0, "paidBalance": 0, "revision": 0 },
  "serverNow": 1784088000
}
```

O jogo deve guardar `sessionToken` e mostrar/solicitar confirmação segura do `recoveryCode`. O servidor nunca volta a expor o mesmo código.

### `POST /v1/sessions/recover`

```json
{
  "recoveryCode": "R1-XXXX-XXXX-XXXX-XXXX-XXXX-XXXX-XXX",
  "installationId": "209ef0f2-08d7-40c3-98e3-a38dc0ced8c9",
  "deviceLabel": "Segundo celular",
  "clientVersion": "0.1.8-alpha",
  "purpose": "game"
}
```

`purpose` é opcional e assume `game`. A landing page usa `account_deletion`, segura o token somente em memória e recebe uma sessão restrita de 15 minutos.

Resposta `200`:

```json
{
  "playerId": "2db22f6b-698c-4ddf-a171-f4ab76ec341c",
  "deviceId": "02e22367-0789-44ce-af04-0148dbd371a8",
  "sessionToken": "S1.nova-sessao",
  "sessionExpiresAt": 1815624000,
  "purpose": "game",
  "save": { "hasPayload": true, "revision": 4, "etag": "\"save-4\"" },
  "serverNow": 1784088000
}
```

## Save online

### `GET /v1/save`

Resposta `200`:

```json
{
  "hasPayload": true,
  "revision": 4,
  "etag": "\"save-4\"",
  "schemaVersion": 9,
  "payloadJson": "{...json exato do jogo...}",
  "sha256": "64 caracteres hexadecimais",
  "serverUpdatedAt": 1784088000,
  "serverNow": 1784088001
}
```

### `PUT /v1/save`

Requer `If-Match: "save-<revisão conhecida>"`.

```json
{
  "mutationId": "3956fae1-e4e7-4854-9036-1cc83c11ea7d",
  "schemaVersion": 9,
  "clientSavedAt": 1784087999,
  "resolution": "normal",
  "payloadSha256": "sha256 do UTF-8 de payloadJson",
  "payloadJson": "{...}"
}
```

`resolution` pode ser `normal` ou `keep_device`. A segunda opção preserva uma cópia adicional do estado substituído.

Resposta `200`:

```json
{
  "mutationId": "3956fae1-e4e7-4854-9036-1cc83c11ea7d",
  "revision": 5,
  "etag": "\"save-5\"",
  "sha256": "64 caracteres hexadecimais",
  "serverUpdatedAt": 1784088000,
  "serverNow": 1784088000
}
```

Em conflito retorna `412` com:

```json
{
  "error": { "code": "SAVE_CONFLICT", "message": "...", "requestId": "..." },
  "conflict": {
    "hasPayload": true,
    "revision": 6,
    "etag": "\"save-6\"",
    "schemaVersion": 9,
    "payloadJson": "{...estado atual da nuvem...}",
    "sha256": "...",
    "serverUpdatedAt": 1784088010,
    "serverNow": 1784088011
  }
}
```

O jogo deve oferecer "manter este aparelho" (novo PUT com a revisão recebida e `keep_device`) ou "usar a nuvem" (aplicar `conflict.payloadJson` localmente). Nunca sobrescrever silenciosamente.

### `POST /v1/save/restore-previous`

Requer `If-Match` e:

```json
{
  "mutationId": "6acbc2be-67e2-4247-b275-87f36baa5ad6",
  "reason": "user_restore"
}
```

Retorna o mesmo formato resumido de uma escrita de save.

## Sessões, aparelhos e segurança

| Método e rota | Corpo | Resultado |
| --- | --- | --- |
| `POST /v1/sessions/logout` | sem corpo | `204`; revoga a sessão atual |
| `POST /v1/sessions/revoke-others` | sem corpo | `{ revokedSessions, serverNow }` |
| `GET /v1/devices` | — | `{ items, serverNow }` |
| `DELETE /v1/devices/:deviceId` | — | revoga aparelho e suas sessões |
| `POST /v1/recovery-code/rotate` | `{ recoveryCode }` | novo código, cancela pendências e revoga outras sessões |
| `POST /v1/security/recovery-reset` | sem corpo | `202` com ação executável após 24 h |
| `GET /v1/security/actions` | — | até 20 ações recentes |
| `DELETE /v1/security/actions/:actionId` | — | `204`; cancela ação pendente |
| `POST /v1/security/actions/:actionId/complete` | sem corpo | conclui reset vencido no aparelho iniciador |

Itens de `GET /v1/devices`:

```json
{
  "id": "uuid",
  "label": "Celular",
  "clientVersion": "0.1.8-alpha",
  "kind": "game",
  "createdAt": 1784000000,
  "lastSeenAt": 1784088000,
  "revokedAt": null,
  "isCurrent": true,
  "activeSessions": 1
}
```

### `DELETE /v1/account`

Corpo sempre exige `confirmation`:

```json
{ "confirmation": "EXCLUIR", "recoveryCode": "R1-..." }
```

- Com código correto: exclusão imediata, resposta `204`.
- Sem `recoveryCode`, usando uma sessão normal do jogo: `202` e ação atrasada por sete dias.
- A sessão web `account_deletion` sempre exige o código.

## Carteira gratuita

Não existe compra nem crédito pago.

| Método e rota | Corpo |
| --- | --- |
| `GET /v1/wallet` | — |
| `POST /v1/wallet/migrate` | `{ operationId, localFreeBalance }` |
| `POST /v1/wallet/claim-daily` | `{ operationId }` |
| `POST /v1/wallet/spend` | `{ operationId, sku }` |

SKUs aceitos pelo servidor: `boost_fervor`, `boost_passo_ligeiro` e `study_slot`. Custos e concessões ficam no catálogo do Worker; o cliente não envia valor.

Resposta típica de uma operação:

```json
{
  "operationId": "uuid",
  "freeBalance": 25,
  "paidBalance": 0,
  "revision": 3,
  "delta": 5,
  "grantKey": "daily:2026-07-15",
  "serverNow": 1784088000
}
```

## Administração

Todas as rotas abaixo usam `/v1/admin` e Cloudflare Access:

| Método e rota | Finalidade |
| --- | --- |
| `GET /overview` | totais de contas, saves, sessões, tombstones e gemas gratuitas |
| `GET /players?query=&cursor=&limit=` | busca paginada por prefixo do UUID |
| `GET /players/:playerId` | metadados, aparelhos, sessões, wallet e ações; nunca o payload |
| `POST /players/:playerId/devices/:deviceId/revoke` | revoga aparelho; corpo `{ reason }` |
| `POST /players/:playerId/sessions/revoke-all` | revoga sessões; corpo `{ reason }` |
| `POST /players/:playerId/save/restore-previous` | restaura save anterior; corpo `{ reason }` |
| `GET /operations` | flags operacionais atuais |
| `PUT /operations` | altera flags; corpo parcial + `reason` |
| `GET /deletions?status=&cursor=&limit=` | consulta tombstones pseudonimizados |
| `POST /deletions/reconcile` | reaplica exclusões; corpo `{ reason }` |
| `GET /audit?cursor=&limit=` | auditoria paginada |
| `GET /liveops` | snapshot administrativo, versões, campanhas e ETag `"liveops-N"` |
| `POST /liveops/balance/drafts` | cria versão de balanceamento; corpo `{ config, reason }` |
| `POST /liveops/balance/:versionId/publish` | publica versão; corpo `{ reason }` |
| `POST /liveops/balance/:versionId/rollback` | restaura conteúdo de versão anterior; corpo `{ reason }` |
| `POST /liveops/campaigns` | cria campanha e primeira versão |
| `POST /liveops/campaigns/:id/drafts` | cria nova versão de campanha |
| `POST /liveops/campaigns/:id/versions/:versionId/publish` | publica versão de campanha |
| `POST /liveops/campaigns/:id/cancel` | encerra a versão publicada no instante atual |
| `POST /liveops/campaigns/:id/versions/:versionId/rollback` | republica conteúdo histórico como nova versão |
| `GET /liveops/audit?cursor=&limit=` | auditoria LiveOps paginada; `limit` inteiro de 1 a 100 |

Flags aceitas em `PUT /operations`:

```json
{
  "maintenanceMode": false,
  "readOnlyUploads": false,
  "allowNewAccounts": true,
  "minClientVersion": "0.1.8-alpha",
  "reason": "motivo auditável"
}
```

Todas as mutações LiveOps exigem `If-Match: "liveops-N"`. Todos os comandos administrativos que alteram estado gravam ator Access, ação, alvo pseudonimizado, motivo, request ID e horário.
