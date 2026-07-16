# Web do Maná Idle

Dois projetos Vite + React + TypeScript independentes, publicados como Cloudflare Workers Static Assets:

- `landing/`: site público, documentos legais, status, CTA do APK e exclusão de conta;
- `admin/`: painel operacional e LiveOps privado, protegido por Cloudflare Access.

## Desenvolvimento local

Em cada pasta:

```powershell
npm install
npm run dev
npm run lint
npm run typecheck
npm run build
```

Copie `.env.example` para `.env.local` sem versioná-lo durante o desenvolvimento. Variáveis `VITE_*` são incorporadas ao JavaScript no momento do build, não no `wrangler deploy`. Para publicação, use arquivos locais não versionados `.env.staging.local` e `.env.production.local`, e rode respectivamente `npm run build:staging` ou `npm run build:production`.

### Landing

- `VITE_API_URL`: URL base do Worker, sem `/v1` e sem barra final;
- `VITE_DOWNLOAD_URL`: URL HTTPS do APK assinado; vazio mantém o CTA em “preparação”;
- `VITE_PRIVACY_EMAIL`: contato público exibido nos documentos; se ficar vazio, a landing usa
  `privacidade@manaidle.com` como fallback. Confirme uma caixa monitorada antes de publicar.

A exclusão pública usa `POST /v1/sessions/recover` com `purpose: "account_deletion"` e, em seguida, `DELETE /v1/account`. Código e token efêmero ficam apenas na memória da função: não há `localStorage`, cookie ou analytics.

### Admin

O navegador sempre chama `/api/v1/admin/*` no mesmo host. Em produção, `src/worker.ts` encaminha apenas esse prefixo ao binding `CLOUD_SAVE`, preservando `Cf-Access-Jwt-Assertion` para validação no backend e removendo cookies. Assim nenhum token ou secret é entregue ao JavaScript.

A área LiveOps edita balanceamento, marcos, impulsos e recompensas gratuitas; agenda campanhas globais ou por gerador; publica, cancela e faz rollback com motivo obrigatório, `If-Match` e auditoria. O contrato está em [`admin/LIVEOPS_API.md`](admin/LIVEOPS_API.md).

Para desenvolvimento, `VITE_ADMIN_API_URL` aponta para o Worker local e `ADMIN_DEV_TOKEN` fica somente no processo do Vite (não use prefixo `VITE_` no segredo). O proxy injeta o header localmente.

Em staging, o backend, o D1 LiveOps, o painel atualizado e o service binding já estão publicados. Falta criar a aplicação Cloudflare Access, autorizar os administradores e configurar `ACCESS_TEAM_DOMAIN`/`ACCESS_AUD`. Até lá, a interface estática abre, mas a API administrativa responde `403 ADMIN_ACCESS_REQUIRED`; um JWT de teste recebe `503 ADMIN_ACCESS_NOT_CONFIGURED`.

## Homologação publicada

- Landing: `https://mana-idle-landing-staging.spankk-bolter.workers.dev`
- Admin: `https://mana-idle-admin-staging.spankk-bolter.workers.dev`
- Backend usado pela landing: `https://mana-save-staging.spankk-bolter.workers.dev`
- Service binding do admin: `CLOUD_SAVE` → `mana-save-staging`

A landing foi compilada com a URL do backend e sem URL de APK. Os dois sites aplicam CSP, anti-frame e headers de segurança; o admin usa `no-store`. Durante a homologação, a landing também usa `X-Robots-Tag: noindex` e `robots.txt` com `Disallow: /`. Nenhum DNS ou domínio personalizado foi alterado.

## Produção ainda não publicada

Antes da produção, confirme o domínio público, o e-mail monitorado de privacidade, a política Access e a URL final da API. Remova o `noindex`, restaure `robots.txt`/`sitemap.xml`, gere o build de produção com as variáveis corretas e só então publique os Workers de produção. Se a API final estiver fora de `*.manaidle.com` ou `*.workers.dev`, inclua a origem HTTPS exata em `landing/public/_headers` na diretiva `connect-src`; não use `*`.

## Licenças de fontes

Os builds empacotam Noto Serif e, no admin, Inter. As licenças SIL OFL 1.1 acompanham cada distribuição em `public/licenses/` e são vinculadas nos rodapés.

Os arquivos web são subsets WOFF2 de Latin/Latin Extended gerados a partir dos TTF versionados do jogo. Para regenerá-los depois de atualizar as fontes:

```powershell
cd landing
npm run fonts:build
```
