# Plano — Gemas, Boosts e Monetização

Gemas são a moeda premium. Regra de ouro: **gema compra tempo, nunca poder
exclusivo** — tudo que gema faz, paciência também faz. Fé continua sendo a
moeda de progresso; Santos, a de prestígio; Sabedoria, a de estudo.

## Estado atual (implementado nesta versão)

- `GameState.gemas` / `gemas_total` persistidos no save.
- Aventuras independentes (sem sequência obrigatória):
  - **Vida de Cristo**: paywall de Fé — 2e14 (histórico e entrada).
  - **Igreja & Apocalipse**: paywall de Gemas — **120 💎**, sem outros requisitos.
- Ícones de capítulo na coluna lateral do painel Jornada (com cadeado e preço).
- Aba **GEMAS**: saldo, fontes, pacotes IAP desabilitados ("em breve") e botão
  de vídeo recompensado **simulado** (+5 💎, cooldown 5 min).
- Fontes gratuitas ativas:
  | Fonte | Gemas |
  |---|---|
  | 1ª Ressurreição | +10 |
  | Ressurreições seguintes | +2 |
  | Concluir Vida de Cristo | +50 |
  | Concluir Igreja & Apocalipse | +100 |
  | Vídeo (simulado) | +5 / 5 min |

Caminho gratuito até a aventura 3: 1ª ressurreição (10) + ~10 ressurreições ou
vídeos ao longo de dias (~2/dia jogando + 20-30/dia de vídeos). Meta: jogador
assíduo desbloqueia em ~3-4 dias sem pagar; comprador pula a espera.

## Pacotes IAP (proposta de preço)

| Pacote | Gemas | Preço | R$/gema |
|---|---|---|---|
| Punhado | 80 | R$ 9,90 | 0,124 |
| Bolsa | 500 | R$ 39,90 | 0,080 |
| Baú | 1200 | R$ 79,90 | 0,067 |

Âncora: aventura 3 (120 💎) fica entre o 1º e o 2º pacote — o comprador do
Punhado quase chega, o da Bolsa desbloqueia e sobra p/ boosts. Preços em BRL;
na Play Store usar tiers equivalentes.

## Boosts (a implementar — coluna lateral)

Local: coluna lateral do painel Jornada, abaixo dos ícones de capítulo
(`_build_future_boost_space` em Main.gd já reserva o espaço). Cada boost é um
ícone com timer visível quando ativo.

| Boost | Efeito | Duração | Gemas | Vídeo |
|---|---|---|---|---|
| Fervor | Produção ×2 | 4 h | 20 💎 | 1 vídeo = 30 min |
| Pentecoste | Produção ×5 | 15 min | 10 💎 | — |
| Colheita | Ganha 2 h de produção offline instantânea | imediato | 15 💎 | 1 vídeo = 15 min |
| Passo Ligeiro | Ciclos 2× mais rápidos | 1 h | 12 💎 | — |
| Mãos Santas | Toque manual conta ×10 | 30 min | 8 💎 | 1 vídeo |

Regras:
- Boosts de mesmo tipo não acumulam (renovam a duração).
- Duração persiste no save como timestamp de expiração (`boosts: {id: unix_expira}`).
- Multiplicadores entram em `Economy.get_multiplicador_global()` (um ponto só).
- Vídeo: máx. 6 recompensas/dia (contador diário no save) — protege o valor da gema.

## Integração de anúncios (rewarded video)

1. Plugin AdMob para Godot 4 (ex.: `godot-admob-plugin`, build Gradle obrigatório
   — mudar `gradle_build/use_gradle_build=true` no preset e instalar template).
2. Trocar `_on_video_pressed` (Main.gd): hoje simula com timer de 2 s e comenta
   onde o SDK entra. Fluxo real: carregar rewarded ad → mostrar → callback
   `on_user_earned_reward` → `GameState.add_gemas(5, "vídeo")`.
3. Anti-abuso: recompensa só no callback do SDK; cooldown + cap diário persistidos.
4. IDs de teste do AdMob durante o alpha; IDs reais só no release assinado.

## Integração IAP (pacotes)

1. Plugin oficial Google Play Billing para Godot.
2. Produtos consumíveis: `gemas_80`, `gemas_500`, `gemas_1200`.
3. Validação: mínimo viável = confirmação local do Billing; ideal = backend
   (Cloudflare Worker) validando o purchase token antes de creditar.
4. Restaurar compras não se aplica (consumíveis), mas registrar `gemas_total`
   e recibos no save ajuda suporte.

## Pendências de design
- Ícone/arte própria para gema (hoje usa emoji 💎).
- Badge na aba GEMAS quando houver vídeo disponível.
- Oferta única "starter pack" (gemas + boost) pós 1ª ressurreição.
