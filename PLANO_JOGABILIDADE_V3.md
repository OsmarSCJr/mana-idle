# Plano de Jogabilidade V3 — De idle linear a idle em camadas

> **Data:** 2026-09-18 · **Base:** `v0.1.13-alpha`, commit `11d20e8`
> **Sucede:** [PLANO_BALANCEAMENTO_V2.md](PLANO_BALANCEAMENTO_V2.md) (Corrida aos 10.000)
> **Status:** **EXECUTADO** em 2026-09-18 na branch `feat/jogabilidade-v3`.
> Ver a seção 12 para o que entrou, o que mudou em relação ao plano e o que ficou de fora.
> Revisão visual e pendências de arte em [AJUSTES_VISUAIS_E_ASSETS.md](AJUSTES_VISUAIS_E_ASSETS.md).

Este plano parte de uma verificação completa do aplicativo (seção 1), de uma simulação
numérica da economia implementada (seção 2) e de uma comparação com os jogos idle de
referência do mercado (seção 3). A conclusão central é que **a meta de longo prazo do V2
— levar todos os geradores a 10.000 unidades — não é alcançável por ajuste de constantes,
e não é um problema de tuning: é a arquitetura da curva.** A seção 4 propõe a substituição
dessa meta por progressão em camadas, que é o padrão do gênero, e as seções 5 a 10
detalham o plano de execução.

---

## 1. Verificação executada

| Verificação | Resultado |
|---|---|
| `godot --headless scenes/SmokeTest.tscn` | **PASS** — 23 asserções (T0–T22) |
| `godot --headless scenes/StudySmokeTest.tscn` | **PASS** — 9 asserções (S0–S8) |
| `godot --headless scenes/UISmokeTest.tscn` | **PASS** — 36 geradores, 5 abas, 3 aventuras |
| `godot --headless scenes/CosmeticSmokeTest.tscn` | **PASS** |
| `backend/cloud-save`: `npm run typecheck` | **PASS** |
| `backend/cloud-save`: `npm run lint` | **PASS** (`--max-warnings 0`) |
| `backend/cloud-save`: `npm run test` | **PASS** — 16 testes, 2 arquivos |
| `backend/cloud-save`: `npm run types:check` | **FALHA** — `worker-configuration.d.ts` desatualizado |

A única falha é cosmética e pré-existente: `wrangler types --check` acusa que os tipos
gerados estão defasados. Resolve com `npx wrangler types` e um commit dos tipos.

**Conclusão de engenharia: o app está saudável.** Save v10 com migrações v1→v9, validador
de save, sincronização por ETag/CAS, LiveOps com validação de envelope e cache offline,
economias isoladas por aventura, compras em lote atômicas. A base técnica não é o gargalo.

Além dos testes, foi construído um simulador em Python que reimplementa
`Economy.gd` (segmentos de growth, soma fechada por trecho, milestones, marcos gerais,
profetas) e `GameState.prestige()`, e roda duas políticas de jogador. Os números das
seções 2 e 5 vêm dele.

---

## 2. Diagnóstico da economia

### 2.1 A parede: milestones não pagam o custo

O V2 definiu a identidade de saúde do ritmo: **custo do trecho ÷ milestones do trecho
deve ficar entre ×2 e ×6** (o "gap", pago pelo motor de prestígio). A tabela enviada tem
9 milestones (produto total ×288). A tabela que o V2 especificou tinha 47 (produto ×3,5e19).

| Trecho | Custo ×  | Milestones (enviado) | **Gap real** | Milestones (V2) | Gap V2 |
|---|---|---|---|---|---|
| 0 → 25 | 13,6 | 1,5 | **9,1** | 1,5 | 9,1 |
| 25 → 50 | 13,6 | 1,5 | **9,1** | 3,0 | 4,5 |
| 50 → 100 | 185 | 2,0 | **92** | 21 | 8,8 |
| 100 → 250 | 6,3e6 | 2,0 | **3,1e6** | 1,5 | 4,2e6 |
| 250 → 500 | 3,2e6 | 2,0 | **1,6e6** | 31,5 | 1,0e5 |
| 500 → 1.000 | 3,9e10 | 2,0 | **2,0e10** | 71 | 5,5e8 |
| 1.000 → 2.500 | 6,0e15 | 2,0 | **3,0e15** | 213 | 2,8e13 |
| 2.500 → 5.000 | 1,7e11 | 2,0 | **8,5e10** | 2,3e4 | 7,3e6 |
| 5.000 → 10.000 | 2,0e17 | 2,0 | **1,0e17** | 2,2e7 | 9,0e9 |

O gap fica dentro da meta (×2–6) **apenas até 50 unidades**. De 100 em diante ele salta
para 10⁶ e nunca volta. Mesmo a tabela completa do V2 não fecha a conta a partir de 100.

O custo unitário do g12 na unidade 10.000 é **2,0e85** de Fé; o acumulado, **2,5e87**.
Para isso ser pagável em tempo humano, o multiplicador global precisaria valer cerca de
**1e70**. O teto realista dos motores existentes (Santos + escada Frutos + marcos + bênçãos)
fica em torno de **1e10**. São sessenta ordens de grandeza de diferença.

### 2.2 Simulação: onde o jogo realmente para

Política "jogador guiado pela UI" (profeta ao atingir 25 → destravar o próximo gerador →
bênção barata → subir o gerador-gargalo), com compra contínua 24 h/dia e toque manual
contínuo nos geradores sem profeta. **É um limite otimista**: um jogador real, com 2–3
sessões por dia e teto offline de 8 h, é bem mais lento.

| Configuração | 1º Santo | 12 gens | todos 25 | todos 100 | todos 500 | todos 1k | todos 2,5k | todos 10k | min final |
|---|---|---|---|---|---|---|---|---|---|
| **A. atual (enviado)** | 22,8 h | 10,4 d | 11,4 d | 13,6 d | 32,8 d | — | — | — | **680** |
| B. `saintBonus` 0,20 | 22,8 h | 6,5 d | 6,8 d | 7,9 d | 11,5 d | — | — | — | 760 |
| C. B + milestones V2 (47) | 22,8 h | 6,5 d | 6,8 d | 7,9 d | 8,5 d | **21 d** | — | — | 1.200 |
| D. C + escada ×1,5 / custo 1,5^N | 22,8 h | 6,5 d | 6,8 d | 7,7 d | 7,7 d | 8,4 d | 11 d | **13,3 d** | 10.000 |

Metas do V2, lado a lado com a configuração enviada (coluna A):

| Momento | Meta V2 | Medido (A) | Desvio |
|---|---|---|---|
| 1º Prestígio | 2–3 h | **22,8 h** | ~8× mais lento |
| Todos em 25 | dia 2–3 | **11,4 d** | ~4× mais lento |
| Todos em 500–1.000 | dia ~30 | 32,8 d / **nunca** | parede |
| Todos em 10.000 | dia 60–90 | **nunca** | inalcançável |

O jogador otimista chega a **680 unidades** no gerador-gargalo depois de um ano. O conteúdo
jogável termina por volta de 500–700 unidades.

### 2.3 O problema mais grave: a escada é um penhasco, não um botão

O V2 prometia "um único knob por segmento: ficou lento, baixa o growth da faixa". Isso
falha porque o motor de crescimento real não é o growth — é a escada infinita **Frutos do
Espírito** (custo `10 × g^N` Santos, efeito `m^N` global). O que importa é o expoente
`r = ln(m) / ln(g)`, porque `Santos ∝ ∛(Fé acumulada)` realimenta a própria produção.

| Escada | `r` | todos 500 | todos 1k | todos 2,5k | todos 5k | todos 10k | min final |
|---|---|---|---|---|---|---|---|
| ×1,30 / 1,8^N *(atual)* | 0,446 | 9 d | 21 d | — | — | — | 1.200 |
| ×1,35 / 1,7^N | 0,566 | 8 d | 11 d | — | — | — | 1.350 |
| ×1,40 / 1,6^N | 0,716 | 8 d | 9 d | — | — | — | 1.700 |
| ×1,45 / 1,6^N | 0,791 | 8 d | 9 d | **143 d** | — | — | 4.780 |
| ×1,50 / 1,6^N | 0,863 | 8 d | 9 d | 24 d | 39 d | — | — |
| ×1,50 / 1,5^N | 1,000 | 8 d | 8 d | 11 d | 13 d | **13 d** | 10.000 |

*(com `saintBonus` 0,20 e a tabela de milestones do V2)*

Não existe ajuste intermediário. Abaixo de `r ≈ 0,86` a corrida trava; em `r = 1,0` o jogo
inteiro colapsa para **13 dias**. Entre 0,79 e 0,86 a resposta pula de "143 dias para 2.500"
para "39 dias para 5.000". **Um alvo de 60–90 dias não é estável nesse espaço de parâmetros** —
é uma realimentação exponencial que só tem dois regimes, subcrítico e explosivo.

É por isso que a recomendação da seção 4 não é "ajustar as constantes".

### 2.4 ROI invertido entre geradores

Em jogos do gênero, cada tier novo tem **melhor** retorno por moeda — é o que torna
"destravar o próximo" emocionante. Aqui é o contrário:

| Gerador | receita/custo | Fé/s por unidade de custo | vs g1 |
|---|---|---|---|
| g1 Haja Luz | 0,250 | 6,3e-2 | — |
| g4 Torre de Babel | 0,250 | 1,3e-2 | 5× pior |
| g8 Sansão | 0,100 | 1,0e-3 | 63× pior |
| g12 Fornalha Ardente | 0,101 | 2,8e-4 | **224× pior** |

Custo por tier cresche ×12; receita por segundo por unidade cresce ×8–9; o tempo de ciclo
cresce de 4 s para 360 s (×90). Matematicamente, **o jogador ótimo nunca deveria comprar
g5–g12** — só os compra porque os marcos gerais exigem e porque a UI os apresenta como
progresso. A política greedy do simulador confirma: ela para em g6 e passa um ano
empilhando g1 e g2.

### 2.5 Deriva entre documento e código

`PLANO_BALANCEAMENTO_V2.md` está marcado **IMPLEMENTADO**, mas o commit `41a518c`
("feat: rebalance progression and add milestone buyer", sem corpo de mensagem) desfez as
duas decisões centrais do plano, sem registro:

- `saintBonus`: **0,20 → 0,02** (um décimo). Era exatamente a correção do diagnóstico do
  alpha 4 ("o prestígio não recompensa: +6% depois de horas"). Com 0,02, o 1º prestígio de
  2–4 Santos vale +4% a +8% — o problema original, de volta.
- `milestones`: **47 entradas → 9** (produto ×3,5e19 → ×288). É a tabela que deveria pagar
  a subida unidade a unidade.

Outros itens de deriva:

- `GameState.gd:798` — o toast diz "ciclos 25% mais rápidos"; `prophetSpeedMultiplier` é
  0,8, ou seja 20%.
- `Dadivas.gd:29` — `d_jo2` tem o texto fixo "8h -> 16h", que mente se
  `offlineCapSeconds` for alterado por LiveOps.
- `Economy.next_milestone()` devolve o último alvo quando a quantidade já o passou, então
  o modo de compra MARCO fica sem sentido acima de 10.000 (latente hoje, ativo se a meta mudar).

---

## 3. Estrutura de jogabilidade e comparação com o mercado

### 3.1 O loop atual

O jogo tem **um único loop**, e ele é curto:

```
tocar o gerador → 25 unidades → profeta (automatiza) → destravar o próximo
    → repetir 12× → Ressurreição (prestígio) → repetir
```

Em volta dele existem sistemas satélites que **não realimentam o loop**: estudos bíblicos
(recompensa única), conhecimentos (compra única), cosméticos (sem efeito mecânico), boosts
(consumíveis de gema), Estrela Nova (evento aleatório pequeno).

### 3.2 O que o mercado faz de diferente

Os idles que retêm jogadores por meses encaixam **4 a 5 loops em escalas de tempo
diferentes**, cada um com sua própria moeda e seu próprio ralo:

| Escala | AdVenture Capitalist | Cookie Clicker | Egg Inc | Realm Grinder | **Maná Idle hoje** |
|---|---|---|---|---|---|
| Segundos | tap / combo | golden cookie | tap + drones | — | toque no gerador |
| Minutos | multiplicadores | upgrades | contratos | bônus de facção | bênçãos |
| Horas | unlocks de tier | minigames | pesquisa (2 trilhas) | mercenários | geradores / eras |
| Dias | Angel Investors | ascensão | **prestígio de fazenda** | reencarnação | Ressurreição |
| Semanas+ | Mega Tickets, eventos | heavenly upgrades, dragão | co-ops, missões | **desafios com modificadores** | **— (nada)** |
| Sempre | achievements | 600+ achievements | achievements | achievements | **— (nada)** |

Três ausências saltam:

1. **Nenhuma camada acima do prestígio.** A Ressurreição é o teto. Em AdCap, Cookie Clicker,
   Egg Inc e Realm Grinder a camada de cima é justamente o que sustenta os meses 2 a 6.
   O V2 registrou "segunda camada de prestígio" como **fora de escopo** — é a decisão que
   este plano propõe reverter, porque é ela que deveria ocupar o lugar da corrida aos 10.000.
2. **Nenhuma conquista.** É o sistema mais barato do gênero (dados + UI de lista), gera
   centenas de micrometas, e nos jogos de referência costuma dar bônus permanente pequeno,
   fechando o ciclo entre "explorar" e "ficar mais forte".
3. **Nenhum loop diário estruturado.** Hoje existem o vídeo diário e a gema diária da
   Estrela Nova. Não existem missões diárias, streak de dias, nem notificação push — e
   notificação push é o mecanismo de retorno padrão de idle mobile.

### 3.3 Conteúdo que morre

| Sistema | Tamanho | Repetível? | Vida útil |
|---|---|---|---|
| Estudos bíblicos | 36 estudos (leitura + quiz) | **Não** (`recompensasResgatadas`) | ~72 resgates, depois inerte |
| Conhecimentos | 30 nós, custo total 120 Sabedoria | Não | oferta de Sabedoria ≈ 57 → **menos da metade da árvore** |
| Bênçãos (Milagres) | 49 curadas + 360 geradas por tier = 409 | Não | requisitos até 1.000 unidades — **cobertura OK** (ver correção abaixo) |
| Cosméticos | 19 itens, custo total 3.335 Relíquias | Não | oferta realista **400** → 12% do catálogo |
| Marcos gerais | 9 por aventura | por run (multiplicador) | recompensas de Relíquia só em 1.000+ → **nunca pagam** |

> **Correção (2026-09-18, durante a execução):** a primeira versão desta tabela dizia que o
> requisito máximo de bênção era 200 unidades e que de 200 a 10.000 não havia conteúdo. Está
> errado: `Upgrades.gd` tem 49 entradas literais **e gera outras 360 em `_ready()`** (10 tiers
> por gerador, requisitos em 50/100/150/250/400/500/600/1.000). A leitura original veio de
> analisar só a tabela literal. A trilha de bênçãos já cobre a corrida até a meta, e a Fase 0.3
> do plano (criar 40 bênçãos novas) **não era necessária**.

O leitor bíblico com 66 livros offline é o maior diferencial do produto e é a peça com
menor integração mecânica: ler um capítulo marca `capitulosLidos` e não afeta nada.

### 3.4 Aventuras 2 e 3 são clones estruturais

`vida_cristo` e `igreja_apocalipse` têm a mesma escada de custo (4 → 3,71e12), os mesmos
tempos de ciclo, os mesmos marcos, a mesma tabela de milestones e, depois do commit
`957ec2c`, até prestígio e Dádivas próprios e isolados. Mudam o nome, a arte e a paleta.

Para o jogador, "Vida de Cristo" é a Jornada repintada. Isso custou muito código
(economias isoladas, ledgers, validação de save) e entrega pouca variedade percebida.

### 3.5 Economias sem torneira ou sem ralo

- **Gemas** — torneira: 10 na 1ª Ressurreição, 2 nas seguintes, 50/100 por aventura
  concluída, 10–100 por marcos (inalcançáveis), 2/dia pela Estrela Nova, vídeo diário.
  Os pacotes de IAP estão `EM BREVE` e desabilitados; o rewarded video é um *placeholder*
  sem SDK (`Main.gd:2326`). Ralo: boosts de 8 a 20 gemas e a entrada de 120 na 3ª aventura.
  **Resultado:** a moeda premium não tem receita nem fluxo sustentável.
- **Relíquias** — 400 de oferta contra 3.335 de catálogo. O item lendário de 1.000 custa
  2,5× tudo que o jogo pode pagar.
- **Sabedoria** — 57 de oferta contra 120 de custo, sem respec e sem fonte repetível.
- **Conhecimentos ativos vs. comprados** — `set_knowledge_active()` não tem limite de
  slots, então o jogador simplesmente ativa tudo que comprou. A UI promete uma decisão de
  build que a regra não cobra.

---

## 4. A decisão central da V3

**Trocar "mais unidades" por "mais camadas".**

A corrida aos 10.000 é uma ideia boa de fantasia e ruim de matemática: exige que os
multiplicadores cresçam como o custo, o custo cresce como uma exponencial em 10.000
passos, e o único motor capaz de acompanhar (a escada Frutos) só tem os regimes "trava" e
"explode" (seção 2.3). Nenhuma tabela de milestones razoável fecha esse gap.

A V3 adota, então, três decisões:

1. **A meta de unidades por gerador passa a ser 1.000**, e esse é o troféu da aventura.
   Validado: com `saintBonus` 0,20 e a tabela de milestones do V2, "todos em 500" cai em
   ~9 dias e "todos em 1.000" em ~21 dias (linha C da seção 2.2) — um arco de três semanas
   com gap saudável quase todo o caminho.
2. **Os meses 2 a 6 saem da contagem de unidades e entram em camadas novas**: segunda
   camada de prestígio, desafios com modificadores, conquistas, e mecânica própria por
   aventura.
3. **O leitor bíblico deixa de ser conteúdo e passa a ser loop**: uma leitura diária com
   payoff mecânico de 24 h. É o diferencial do produto no mercado (seção 3 da
   `Pesquisa_Mercado.md`: o nicho da interseção está virgem) e hoje ele está inerte.

O mapa de tempo que a V3 persegue:

| Escala | Loop | Sistema |
|---|---|---|
| Segundos | tocar, colher ciclo | geradores, Estrela Nova |
| Minutos | comprar, decidir | bênçãos, marcos, metas de sessão |
| Horas | automatizar, avançar era | profetas, geradores, teto offline |
| **Diário** | ritual + missões | **devocional diário, missões diárias, streak** |
| **Semanal** | provação | **desafios com modificadores** |
| **Mensal** | camada nova | **2º prestígio (Aliança)** |
| Sempre | colecionar | **conquistas**, cosméticos, retratos |

---

## 5. Fase 0 — Consertar a economia (bloqueia todo o resto)

Sem esta fase, qualquer conteúdo novo é construído sobre uma curva que trava em 500 unidades.

### 5.1 Constantes (LiveOps, sem update de app)

| Constante | Hoje | V3 | Justificativa |
|---|---|---|---|
| `economy.saintBonus` | 0,02 | **0,20** | restaura a decisão do V2 desfeita em `41a518c`; 1º prestígio passa de +4% para +40–80% |
| `economy.milestones` | 9 entradas (×288) | **tabela V2 até 1.000** (25/50/75/100, a cada 100 até 1.000; ciclo ×1,5 → ×3 → ×7) | é o que paga a subida; ver gap da seção 2.1 |
| `economy.generalMilestones` | recompensas em 1.000/5.000/10.000 | **recompensas em 250/500/1.000** | hoje a torneira de Relíquias é literalmente zero |
| `economy.growthSegments` | 4 faixas até o infinito | **3 faixas terminando em 1.000** | acima da meta não precisa de faixa; simplifica o tuning |
| Escada Frutos | ×1,30 / 1,8^N | **manter** | com meta 1.000, `r = 0,446` é o regime estável correto |

A escada fica como está **de propósito**: ela é subcrítica, e com a meta em 1.000 isso
deixa de ser defeito e passa a ser o freio que impede o colapso visto em `r = 1,0`.

### 5.2 Meta da aventura

- `10.000 → 1.000` como alvo dos marcos gerais e do troféu.
- Último marco geral (1.000) vira o evento de conclusão da aventura: chuva de Relíquias,
  aura permanente nos 12 geradores, e **desbloqueio da 2ª camada de prestígio** (fase 8).
- `Economy.next_milestone()`: devolver vazio depois do último alvo e desabilitar o modo
  MARCO, em vez de repetir o alvo final.

### 5.3 ROI crescente por tier (requer update de app)

Alvo: a Fé por segundo por unidade de custo deve ficar **constante ou levemente crescente**
de g1 a g12, em vez de cair 224× (seção 2.4). Dois eixos, aplicados juntos:

- `receita_base` dos g5–g12 sobe para crescer ×14–15 por tier (hoje ×12 no custo contra
  ×8–9 na receita por segundo).
- `tempo` de ciclo passa a crescer no máximo até **60 s** no g12 (hoje 360 s). Telas com
  ciclo de 6 minutos são telas mortas — o próprio V2 já apontava isso na seção 6 e a
  correção ficou pela metade.

Isso muda o jogo qualitativamente: destravar um gerador volta a ser um salto de renda, e
não um imposto pago para satisfazer o marco geral.

### 5.4 Conteúdo de bênçãos até a meta

Hoje o requisito máximo de bênção é 200 unidades. A V3 estende a trilha até 1.000:
**+3 bênçãos por gerador** com requisitos em 300 / 500 / 1.000 unidades (36 novas na
Jornada), mais **4 bênçãos de era** com requisito no marco geral correspondente. Sem isso,
a faixa 200–1.000 continua sendo uma barra de progresso sem recompensa.

---

## 6. Fase 1 — Loop de sessão (segundos a minutos)

O que falta na sessão não é recompensa, é **motivo para estar presente**. Hoje o jogador
abre, compra o que dá, e fecha.

- **Metas de sessão** (3 por sessão, rotativas, expiram ao fechar): "compre 50 unidades",
  "conclua 10 ciclos manuais", "contrate 1 profeta". Recompensa pequena e imediata: 1–3
  gemas, uma carga de boost, ou 2 minutos de produção. Padrão dos "contratos" de Egg Inc.
- **Colheita de Maná** — barra de foco que enche com toques e, cheia, dá ×5 de produção
  por 30 s. Dá ao toque um propósito depois que os profetas automatizam tudo (hoje o toque
  se torna inútil, e com ele o único verbo ativo do jogo).
- **Estrela Nova**: subir a frequência (hoje 5–15 min) e variar a recompensa entre Fé,
  carga de boost e fragmento de conquista. O sistema já existe e já é parametrizado por
  LiveOps — está subutilizado.

---

## 7. Fase 2 — Loop diário

- **Devocional diário** *(a peça mais importante do plano)*. Uma passagem por dia no leitor
  bíblico, marcada como lida, concede um **Selo do Dia**: +10% de produção global por 24 h,
  cumulativo com streak até +50%. Converte o maior diferencial do produto em razão de
  retorno diária, e transforma 66 livros de conteúdo morto em conteúdo perene.
- **Missões diárias**: 3 por dia, mais longas que as de sessão ("ganhe 1e9 de Fé", "conclua
  um marco geral", "responda 1 quiz"). Pagam gemas e Relíquias — é a torneira que falta.
- **Streak de dias consecutivos**: 7 dias com recompensa crescente e reinício suave
  (perde-se 1 dia, não a série inteira). Mecanismo de retenção mais barato do gênero.
- **Notificação push** quando o teto offline de 8 h encher, e quando o Selo do Dia expirar.
  Hoje não existe nenhuma notificação de sistema — para um idle mobile, é a lacuna de
  retenção mais custosa.
- **Vigília semanal**: um quiz de 5 passagens aleatórias por semana pagando **Sabedoria**.
  Resolve a oferta de 57 contra 120 da árvore de conhecimentos (seção 3.3) sem inflar a
  quantidade de estudos.

---

## 8. Fase 3 — Camada acima do prestígio: a Aliança

Substitui a corrida aos 10.000 como meta de meses. Desbloqueia ao concluir "todos em 1.000"
em qualquer aventura.

- **Reseta:** Santos, Dádivas, escada Frutos, geradores, bênçãos da aventura.
- **Preserva:** Relíquias, cosméticos, Conhecimentos, conquistas, progresso de estudo.
- **Paga:** **Alianças**, em função dos Santos totais já ganhos (`∛` como nos Santos, para
  a segunda aliança custar 8× a primeira).
- **Árvore da Aliança** (12–16 nós, distinta das Dádivas): começar com profetas já
  contratados, teto offline de 24 h, ganho de Sabedoria ×2, marcos gerais valendo mais,
  desconto na entrada das aventuras, slots de Conhecimento ativo (ver 9.3).
- **Nome e tema:** a Aliança fecha o arco narrativo das três aventuras — Criação, Caminho,
  Consumação — e dá ao reset uma leitura reverente, alinhada com `PRODUCT.md`.

**Provações** (desafios com modificadores), destravadas pela primeira Aliança, 6 a 8
variantes, uma ativa por vez, repetíveis com recompensa decrescente:

| Provação | Modificador | Recompensa |
|---|---|---|
| Deserto | sem profetas (só toque manual) | Relíquias + bônus permanente de toque |
| Cativeiro | ciclos ×3 mais lentos | Relíquias + redução permanente de ciclo |
| Viúva de Sarepta | só geradores ímpares | Relíquias + bônus de era |
| Jejum | sem boosts nem Estrela Nova | gemas + carga permanente de boost |

É o padrão de Realm Grinder: conteúdo de alta duração construído sobre a economia que já
existe, com custo de implementação baixo (um dicionário de modificadores aplicado em
`Economy.recompute_multiplicadores`).

---

## 9. Fase 4 — Diferenciar sistemas e consertar economias

### 9.1 Conquistas

60 a 100 conquistas, cada uma com **+1% de produção global permanente** (teto explícito,
por exemplo +60%). Categorias: unidades, marcos, prestígios, estudos, capítulos lidos,
cosméticos, provações, aventuras. Custo de implementação baixo (tabela + aba + verificação
em eventos que o `EventBus` já emite) e retorno alto: transforma qualquer atividade do jogo
em progresso mensurável.

### 9.2 Aventuras deixam de ser clones

Cada aventura recebe **uma mecânica exclusiva**, mantendo a economia isolada que já existe:

- **Jornada (Criação)** — a corrida por unidades. É a aventura "clássica"; fica como está.
- **Vida de Cristo (Caminho)** — **Discipulado**: um gerador pode "ensinar" o seguinte e
  transferir parte do seu multiplicador em cadeia. Cria uma decisão de ordem de investimento
  que a Jornada não tem, e casa com o tema.
- **Igreja & Apocalipse (Consumação)** — **Missão**: um mapa de 12 regiões que consomem
  Glória ao longo do tempo e pagam bônus por região mantida. Introduz gestão de fluxo
  (produção contra consumo), o oposto estrutural do acúmulo puro.

### 9.3 Consertar as três economias secundárias

| Moeda | Problema | Correção |
|---|---|---|
| **Relíquias** | oferta 400 × catálogo 3.335 | marcos gerais pagando em 250/500/1.000 (fase 0), provações, conquistas → oferta ~2.400; manter o tier lendário como aspiração |
| **Gemas** | sem receita e sem torneira sustentável | decidir entre (a) integrar AdMob + IAP de verdade, ou (b) remover os pacotes `EM BREVE` e assumir o jogo como 100% gratuito, publicando as fontes livres com honestidade. **Manter cartões desabilitados com preço visível é o pior dos dois mundos.** |
| **Sabedoria** | oferta 57 × árvore 120 | Vigília semanal (fase 2) + **limite de 5 slots de Conhecimento ativo**, ampliável pela Aliança — transforma a escolha falsa da seção 3.5 no sistema de build que a UI já promete |

---

## 10. Ordem de implementação e critérios de aceite

### Ordem

1. **Fase 0.1 (LiveOps, sem update):** `saintBonus` 0,20, tabela de milestones V2 até 1.000,
   recompensas dos marcos gerais em 250/500/1.000, `growthSegments` em 3 faixas.
   *É a mudança de maior impacto por unidade de esforço em todo o plano.*
2. **Fase 0.2 (código):** meta 1.000, `next_milestone` vazio após o último alvo, ROI por
   tier, `tempo` máximo 60 s, 40 bênçãos novas.
3. **Fase 2:** devocional diário + streak + push. Retenção antes de conteúdo.
4. **Fase 1:** metas de sessão + Colheita de Maná.
5. **Fase 4.1:** conquistas (barato, e alimenta tudo o que vem depois).
6. **Fase 3:** Aliança + provações.
7. **Fase 4.2:** mecânicas exclusivas por aventura.
8. **Fase 4.3:** decisão de monetização e conserto das moedas.

### Critérios de aceite

| Âncora | Alvo | Tolerância |
|---|---|---|
| 1º Prestígio | 2–3 h | ±50% |
| Todos em 25 | dia 1–2 | ±50% |
| Todos em 100 | dia 4–6 | ±40% |
| Todos em 500 | dia 12–18 | ±40% |
| Todos em 1.000 (troféu) | dia 25–35 | ±30% |
| 1ª Aliança | dia 30–40 | ±30% |
| Gap por trecho (seção 2.1) | ×2 a ×6 | nunca acima de ×20 |
| Bônus do 1º prestígio | +40% a +80% | — |

### Validação

- Portar o simulador para `tools/` e rodá-lo em CI contra `LiveOps.DEFAULT_CONFIG`,
  falhando o build quando qualquer gap passar de ×20 ou qualquer âncora sair da tolerância.
  **É o teste que teria pego o commit `41a518c` no dia em que ele entrou.**
- Rodar as duas políticas (greedy e guiada pela UI): se elas divergirem muito, o ROI por
  tier está invertido (seção 2.4).
- Telemetria já disponível no LiveOps: registrar `min_qtd` por dia de jogo dos testers.

---

## 11. Riscos e fora de escopo

**Riscos**

- Rebaixar a meta de 10.000 para 1.000 muda o texto de marketing e a fantasia central do
  V2. Mitigação: o troféu de 1.000 passa a ser a conclusão da aventura, e a Aliança assume
  o papel de "existe sempre um próximo degrau".
- `saintBonus` 0,20 acelera saves existentes em alpha. Como o save v10 já reseta em troca
  de versão (`load_save_data`), a janela de alpha é o momento correto para isso.
- Notificações push exigem plugin Android e revisão de permissões no
  `PLANO_PUBLICACAO_ANDROID.md`.

**Fora de escopo (registrado)**

- Terceira camada de prestígio acima da Aliança.
- Multiplayer, co-ops ou leaderboards.
- Eventos sazonais (a infraestrutura de campanhas do LiveOps já suporta; falta a UI).
- Localização para inglês (a `Pesquisa_Mercado.md` recomenda "Faith Idle" para o mercado
  global; é uma decisão de produto independente deste plano).

---

## 12. Status de execução (2026-09-18)

### Entrou

| Fase | Entrega | Onde |
|---|---|---|
| 0.1 | `saintBonus` 0,02 → **0,20**; milestones 9 → **15** (ciclo ×1,5/×3/×7, vão máximo de 100 unidades); marcos gerais em 25/50/100/250/500/800/1.000 com Relíquia a partir de 250; `growthSegments` em 3 faixas | `LiveOps.gd`, `schemas.ts`, `LiveOps.tsx` |
| 0.2 | `Geradores.META_UNIDADES = 1000` como teto duro de compra; `next_milestone()` devolve 0 após a meta; teto de ciclo em **60 s** (era 360 s no g12) | `Geradores.gd`, `Economy.gd`, `GameState.gd`, `GeradorItem.gd` |
| 1 | Metas diárias (3/dia, sorteio determinístico pelo número do dia, 15 tipos) | `MetasSystem.gd` |
| 2 | **Devocional**: 3 planos (7 dias, 36 dias, perpétuo com 72 passagens), Selo do Dia (+10% a +50% por 24 h), sequência com perdão de um dia, destaques, anotações, marcos de sequência, lembrete | `Devocional.gd`, `DevocionalPalavra.gd`, `DevocionalSystem.gd`, `DevocionalPanel.gd`, `Notificacoes.gd` |
| 3 | **Aliança** (2ª camada de prestígio, 14 nós) e **Provações** (6 corridas com modificadores, repetíveis com recompensa decrescente) | `AliancaSystem.gd`, `ProvacoesSystem.gd`, `ProgressoPanel.gd` |
| 4.1 | **Conquistas**: 66 em 10 categorias, bônus somado com teto de +100% | `Conquistas.gd` |
| 4.3 | Limite de **5 espaços** de Conhecimento ativo (+3 pelo nó "Mente Larga"); Sabedoria repetível pelo devocional; Relíquias com torneira real | `StudySystem.gd`, `LiveOps.gd` |
| — | Save **v11** com cinco campos novos, migração v10→v11, validação no cliente e no Worker, `SUPPORTED_SAVE_SCHEMA` 11 | `GameState.gd`, `SaveValidator.gd`, `save.ts`, `wrangler.jsonc` |
| — | `scenes/V3SmokeTest.tscn` com 21 asserções; UI smoke ampliado; `scenes/ScreenshotTool.tscn` para revisão visual | `scenes/` |

### Mudou em relação ao plano

- **Meta 1.000 mantida, `growthSegments` praticamente intocado.** O plano pedia rebalancear
  as faixas; abaixo de 1.000 a curva ficou **idêntica** à do alpha (1,11 até 300, depois
  1,05), de propósito: foi essa curva que o simulador validou. Mexer nela invalidaria a
  medição sem necessidade, já que os segmentos acima de 1.000 nunca são usados.
- **Correção de ROI feita só pelo tempo de ciclo.** O plano previa subir `receita_base` dos
  g5–g12 para deixar a Fé/s por unidade de custo constante. Testado no simulador: o troféu
  caía de ~8 dias para **2,4 dias** — rápido demais. Entrou apenas o teto de 60 s no ciclo,
  que recupera ~6× do fator e resolve as telas mortas sem colapsar o calendário. A
  degradação de ROI cai de 224× para ~37×; fechar o resto exige recalibrar o calendário
  inteiro e fica para uma rodada com telemetria.
- **Fase 0.3 cancelada**: as 400+ bênçãos já existem (ver correção na seção 3.3).
- **Fase 4.2 (mecânicas exclusivas por campanha) não entrou.** Discipulado e Missão são
  sistemas do tamanho da Aliança; ficaram para a próxima rodada. As campanhas 2 e 3
  continuam clones estruturais.
- **Monetização (4.3, gemas) não entrou.** Os pacotes seguem "EM BREVE" e o rewarded video
  segue placeholder. É decisão de produto — AdMob + IAP de verdade, ou assumir o jogo como
  100% gratuito e remover os cartões com preço. Manter como está é o pior dos dois mundos.

### Calendário medido depois das mudanças

Simulador com jogador otimista (compra contínua 24 h/dia, sem teto offline), a mesma régua
da seção 2.2 — os números continuam sendo um **limite inferior**, e as camadas novas
(conquistas, Selo do Dia, Aliança) não estão no modelo, então o jogo real é ainda mais rápido:

| Âncora | Alpha enviado | V3 |
|---|---|---|
| 1º Santo | 22,8 h | **17,9 h** |
| Todos em 25 | 11,4 d | **5,4 d** |
| Todos em 100 | 13,6 d | **5,6 d** |
| Todos em 500 | 32,8 d | **6,0 d** |
| Todos em 1.000 (troféu) | **nunca** | **7,7 d** |

Com 2–3 sessões por dia e teto offline de 8 h, isso deve cair na faixa de 3 a 5 semanas até
o troféu — dentro do alvo de 25–35 dias da seção 10, mas **não medido em aparelho**. A
próxima rodada precisa de telemetria de `min_qtd` por dia de jogo antes de qualquer novo
ajuste de constante.

### Verificação

`SmokeTest`, `StudySmokeTest`, `UISmokeTest`, `CosmeticSmokeTest`, `CloudSmokeTest` e
`V3SmokeTest`: **6/6 PASS**. Backend: `types:check`, `typecheck`, `lint` e 16 testes
Vitest passando.

### Ainda em aberto

- Portar o simulador para `tools/` e rodá-lo em CI (seção 10) — **não feito**; é o teste que
  teria pego o commit `41a518c` e continua sem existir.
- Fase 4.2, monetização e as pendências de arte/áudio de
  [AJUSTES_VISUAIS_E_ASSETS.md](AJUSTES_VISUAIS_E_ASSETS.md).
