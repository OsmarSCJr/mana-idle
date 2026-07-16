# Maná Idle — APK online e cloud save

Maná Idle com save offline-first, sincronização via Cloudflare Worker + D1, configuração remota LiveOps, landing page pública e painel administrativo. O ambiente de homologação em `workers.dev` foi publicado em 16/07/2026; produção, DNS e recursos Cloudflare preexistentes permaneceram intocados.

## O que está implementado

- Jogo Godot com criação e recuperação de Conta de Peregrino, sessão por aparelho, save atômico local, sincronização por ETag/CAS, retries, resolução explícita de conflitos, revogação de aparelhos e exclusão de conta.
- Worker com autenticação opaca, validação do save v8, idempotência, histórico curto, ações de segurança, exclusão com tombstone separado, carteira exclusivamente gratuita, rate limits, cron e auditoria administrativa.
- Três bancos D1 por ambiente: principal, tombstones de exclusão e LiveOps isolado.
- Landing responsiva com páginas de privacidade, termos e exclusão externa de conta.
- Painel administrativo sem acesso ao conteúdo dos saves, com editor versionado de balanceamento, campanhas, rollback e auditoria; protegido em produção por Cloudflare Access.
- Nenhum checkout, PIX, assinatura, Play Billing ou endpoint de pagamento.

## Pastas e documentos

- [`scripts/cloud/README.md`](scripts/cloud/README.md): integração do jogo e testes Godot.
- [`backend/cloud-save/README.md`](backend/cloud-save/README.md): Worker, D1, segurança, operação e roteiro de deploy.
- [`backend/cloud-save/API.md`](backend/cloud-save/API.md): contrato HTTP.
- [`web/README.md`](web/README.md): landing e admin.
- [`PLANO_CLOUD_SAVE.md`](PLANO_CLOUD_SAVE.md): arquitetura, decisões, riscos e custos.
- [`PLANO_PUBLICACAO_ANDROID.md`](PLANO_PUBLICACAO_ANDROID.md): caminho APK → Google Play.

## Verificação local

Backend:

```powershell
cd backend/cloud-save
npm ci
npm run db:migrate:local
npm run db:migrate:local:deletions
npm run db:migrate:local:liveops
npm run check
npm run build:dry
npm audit --omit=dev
```

Web, repetindo em `web/landing` e `web/admin`:

```powershell
npm ci
npm run lint
npm run typecheck
npm run build
npx wrangler deploy --dry-run --env staging
npm audit --omit=dev
```

Godot 4.7.1, sem tocar no save ou na identidade reais:

```powershell
godot --headless --editor --path . --quit
godot --headless --path . scenes/SmokeTest.tscn -- --smoke-test
godot --headless --path . scenes/StudySmokeTest.tscn -- --smoke-test
godot --headless --path . scenes/UISmokeTest.tscn -- --smoke-test
godot --headless --path . scenes/CloudSmokeTest.tscn -- --smoke-test
```

## Homologação publicada

- API: `https://mana-save-staging.spankk-bolter.workers.dev`
- Landing: `https://mana-idle-landing-staging.spankk-bolter.workers.dev`
- Admin: `https://mana-idle-admin-staging.spankk-bolter.workers.dev`
- D1 principal: `mana-save-staging`
- D1 de tombstones: `mana-delete-staging`
- D1 de LiveOps: `mana-liveops-staging`

O jogo já aponta para a API de homologação e busca o balanceamento/campanhas publicados, com cache local, ETag, fallback seguro e atualização periódica. A landing está conectada à API, sem URL de download e marcada `noindex`. O painel LiveOps está publicado com service binding interno, mas as rotas administrativas permanecem bloqueadas até a configuração do Cloudflare Access.

Para avançar à produção ainda são necessários:

1. domínio final e origens exatas de API, landing e admin;
2. Cloudflare Access, com team domain, `AUD` e administradores autorizados;
3. e-mail público real e monitorado de suporte/privacidade;
4. três D1 e Workers de produção, criados separadamente;
5. templates de exportação Godot 4.7.1 e Android SDK/Build Tools compatíveis.

Os dados de assinatura Android permanecem somente nos arquivos locais ignorados pelo Git. Não os copie para documentação, logs ou chat.

Antes da Google Play, as gemas da alpha não têm valor financeiro. O backend já separa uma carteira gratuita e mantém `paid_balance = 0`; qualquer futura venda deve usar Play Billing e uma carteira premium server-authoritative, sem converter automaticamente saldo local editável em saldo pago.
