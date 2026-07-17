# Contrato do painel LiveOps

O frontend usa o proxy same-origin em `/api/v1/admin/liveops`. O Worker do painel remove
`/api` e encaminha as chamadas para `/v1/admin/liveops` no backend.

## Concorrência e resposta

`GET /liveops` e todas as mutações retornam o snapshot completo com `schemaVersion`, `revision`,
`etag`, `activeBalance`, `balanceVersions`, `campaigns` e `serverNow`.

Toda mutação envia `If-Match` com o ETag do snapshot. O formato administrativo esperado é
`"liveops-N"`. Uma resposta `412` coloca a tela em estado obsoleto, preserva os campos locais
visíveis e bloqueia novas gravações até o operador recarregar.

## Balanceamento

- POST /liveops/balance/drafts: corpo { config, reason }
- POST /liveops/balance/:versionId/publish: corpo { reason }
- POST /liveops/balance/:versionId/rollback: corpo { reason }

O snapshot e o envelope público usam `schemaVersion: 2`. `config` possui:

- economy: growthSegments, saintBonus, prestigeDivisor, prophetUnlockQuantity,
  prophetCostMultiplier, prophetSpeedMultiplier, offlineCapSeconds, parâmetros da escada de
  Dádivas, milestones [{ quantity, multiplier }] e generalMilestones
- boosts: fervorProductionMultiplier, pentecostProductionMultiplier,
  holyHandsManualMultiplier, swiftStepTimeMultiplier e harvestSeconds
- rewards: videoGems, offlineTripleGemCost e frequência/recompensas da Estrela Nova

## Campanhas

- POST /liveops/campaigns: corpo { key, name, startsAt, endsAt, effects, reason }
- POST /liveops/campaigns/:id/drafts: corpo { name, startsAt, endsAt, effects, reason }
- POST /liveops/campaigns/:id/versions/:versionId/publish: corpo { reason }
- POST /liveops/campaigns/:id/cancel: corpo { reason }
- POST /liveops/campaigns/:id/versions/:versionId/rollback: corpo { reason }

Os efeitos esperados são globalProductionMultiplier, offlineProductionMultiplier,
manualProductionMultiplier, studyFaithMultiplier, freeGemRewardMultiplier e
generatorProductionMultipliers, este último como Record<string, number>.

Os campos datetime-local são interpretados no fuso do navegador e convertidos para epoch Unix
em segundos antes do envio. A interface deriva os estados operacionais pelo serverNow:

- draft: sem versão ativa
- scheduled: versão publicada com startsAt maior que serverNow
- active: serverNow entre startsAt, inclusive, e endsAt, exclusivo
- ended: endsAt menor ou igual a serverNow
- cancelled: versão ativa cancelada, ou campanha sem versão ativa cuja última versão foi cancelada

Versões publicadas possuem `publishedAt` e `retiredAt`. A API pública usa a janela efetiva
`max(startsAt, publishedAt)` até `min(endsAt, retiredAt)` e entrega até 15 dias de histórico,
permitindo calcular o offline sem aplicar uma edição ou cancelamento retroativamente. No máximo
64 versões podem compor o envelope público e multiplicadores combinados são limitados.

O cliente público usa ETag fraco `W/"liveops-N-hash"`; o ETag administrativo permanece forte
`"liveops-N"` para concorrência. Respostas públicas `200` e `304` incluem `X-Server-Now`.

## Histórico

`GET /liveops/audit?cursor=&limit=` retorna `items` e `nextCursor`; `limit` deve ser inteiro de 1 a 100. Cada item possui `id`, `actor`,
action, targetType, targetId, beforeHash, afterHash, reason, requestId, metadata e createdAt.
O cursor é opaco e o frontend o devolve sem interpretar.
