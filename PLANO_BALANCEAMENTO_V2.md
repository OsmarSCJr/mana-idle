# Plano de Balanceamento V2 — Corrida aos 10.000

> **Status (2026-07-17): IMPLEMENTADO** (Fases 1–3 + loja cosmética). Save v9 e
> LiveOps schema v2 alinhados entre jogo, Worker e painel administrativo. Smoke tests: 4/4 PASS.
> Pendências: assets de arte (cosméticos "EM BREVE", sprite da Estrela Nova),
> validação de calendário com telemetria/sim de cadência limitada.

Sucede o [PLANO_BALANCEAMENTO.md](PLANO_BALANCEAMENTO.md) (fases A–E). Diagnóstico do alpha 4:
o jogo ficou lento demais no meio (1º Santo em ~5–8h reais vs meta de 3h), o prestige não
recompensa (+6% após horas de jogo), Relíquias não têm função e falta conteúdo de sessão.

**Visão:** a primeira aventura vira uma corrida de longo prazo — levar TODOS os 12
geradores a 10.000 unidades — sustentada por quatro motores que se encaixam:

1. **Softcap de growth** torna 10.000 matematicamente possível.
2. **Milestones 1.5/3/7** pagam a subida unidade a unidade.
3. **Marcos gerais** ("todos em N") distribuem a compra entre geradores e marcam o calendário.
4. **Prestige consertado + Dádivas infinitas** entregam o crescimento diário que fecha a conta.

Aventuras 2 e 3 viram economias isoladas com moeda própria (seção 8).

---

## 1. Marco temporal do jogo (a régua de tudo)

Alvos em dias de jogador engajado (2–4 sessões/dia + offline). Toda mudança de constante
deve ser validada contra esta tabela.

| Momento | Alvo | Evento |
|---|---|---|
| 30 min | Era 1 completa | primeiros profetas, ~50 unidades no g1 |
| 2–3 h | **1º Prestige** | 2–4 Santos → +40–80% de produção (sentido!) |
| Dia 1 | 2–3 prestiges | primeiras Dádivas da escada |
| Dia 2–3 | **Todos em 25** | 1º marco geral: velocidade global ×1.5 |
| Semana 1 | Todos em 50 e 100 | entrada na Vida de Cristo (economia própria) |
| Semana 2–3 | Todos em 250 | Igreja & Apocalipse acessível |
| Dia ~30 | Todos em 500–1.000 | primeiros pacotes de gemas/relíquias por marco |
| Dia ~45 | Todos em 2.500 | |
| Dia ~60 | Todos em 5.000 | |
| **Dia 60–90** | **Todos em 10.000** | troféu da aventura + chuva de Relíquias |

Regra de saúde do ritmo: o motor de prestige deve entregar **×2–3 de renda por dia** nas
primeiras semanas, decaindo até ~×1.5/dia no mês 2. É esse fator diário que preenche o
"gap" entre custo e milestone (seção 4).

---

## 2. Softcap de growth (pré-requisito de tudo)

**Problema:** custo = base × 1.11^N estoura o float64 em N≈6.800 (custo vira `inf`) e
1.11^10000 ≈ 10^453 é inalcançável. Sem softcap, 10.000 unidades e milestone 9.500 são
impossíveis.

**Solução:** growth por faixa de quantidade, contínuo nos limiares (sem salto de preço):

| Faixa de unidades | Growth | Custo acumulado no teto da faixa (g12) |
|---|---|---|
| 1–300 | 1.11 | ×10^13.6 — early game intocado |
| 301–1.500 | 1.05 | ×10^39 |
| 1.501–4.000 | 1.012 | ×10^52 |
| 4.001–10.000 | 1.008 | ×10^73 |

- Preço unitário do g12 na unidade 10.000 ≈ 10^85 — **cabe em double** (limite 1.8e308).
- `NumberFormat` precisa de sufixos até ~1e95.
- `custo_unitario`, `custo_lote` e `max_compravel` passam a somar por segmento
  (soma geométrica fechada por trecho; lote que cruza limiar soma os pedaços).
- Tabela de faixas vai para o LiveOps (`economy.growthSegments`) — tunável sem update.

## 3. Milestones individuais — ciclo 1.5 / 3 / 7

Trilho: **a cada 25 até 100** (25/50/75/100), **a cada 100 até 1.000**, **a cada 250 até
9.500**. Total 47 milestones por gerador.

- Multiplicador em ciclo crescente **×1.5 → ×3 → ×7**, repetindo. O ×7 deve cair nos
  números redondos (100, 500, 1.000…) — ajustar o alinhamento do ciclo para isso.
- O milestone 25 dá bônus REAL (hoje é ×1.0 — meta vazia; conserta junto).
- Produto total aos 9.500 ≈ ×10^24 por gerador. É o que paga a subida.
- Tabela no LiveOps (`economy.milestones`), como hoje.

## 4. Marcos gerais — "todos os geradores em N"

Novo sistema. Recompensa quando **todos os 12 geradores da aventura** atingem N unidades.
Progresso re-conquistado a cada prestige (como milestones), mas **recompensas de gemas e
relíquias são pagas 1x via ledger** (usar `maior_qtd_gerador`, que já existe).

| Marco | Recompensa recorrente (por run) | Recompensa única (ledger) |
|---|---|---|
| 25 | velocidade global ×1.5 | — |
| 50 | velocidade global ×1.5 | — |
| 100 | velocidade global ×2 | 10 gemas |
| 250 | produção ×3 | — |
| 500 | produção ×5 | 20 gemas |
| 1.000 | produção ×7 | 25 Relíquias |
| 2.500 | produção ×10 | 30 gemas |
| 5.000 | produção ×15 | 50 Relíquias |
| 10.000 | produção ×20 | troféu + 100 Relíquias + 100 gemas |

- Velocidade só nos 3 primeiros (clamp de `tempo_min` já segura; evita estourar o teto).
- UI: barra "próximo marco geral" com o gerador-gargalo destacado — dá motivo pra comprar
  o gerador "ruim" e vira o objetivo permanente da tela.

### A identidade de balanceamento (por que os números acima fecham)

Para o ritmo ficar estável, por trecho de 250 unidades no late game:

```
custo do trecho (growth^250) ÷ milestones do trecho ≈ ×2 a ×6  ← "gap"
gap é pago pelo motor de prestige (×1.5–3/dia) → ~0.5–1.5 dia por marco
```

Com growth 1.012: custo ×20.6 por 250, milestone médio ×4.6 → gap ×4.5 ✓
Com growth 1.008: custo ×7.4 por 250 → gap ×1.6 ✓ (reta final acelera de propósito —
recompensa por chegar lá).

Válvula de ajuste fino: **um único knob por segmento** (o growth da faixa). Ficou lento →
baixa o growth da faixa onde o jogador travou. Rápido → sobe. Não mexer em milestones e
growth ao mesmo tempo.

## 5. Prestige consertado + Dádivas infinitas

| Constante | Hoje | Novo | Efeito |
|---|---|---|---|
| `prestigeDivisor` | 2e12 | **2e11** | 1º Santo em ~1.5–2h; prestige a cada sessão |
| `saintBonus` | 0.06 | **0.20** | 1º prestige (2–4 santos) = +40–80% |
| Base do bônus | santos atuais | **santos totais ganhos** | gastar em Dádiva não reduz produção (gastar não pode doer) |

- Fórmula `cbrt(fe_run / divisor)` mantida — a curva cúbica está boa quando o bônus por
  santo é relevante.

**Dádivas (escada infinita + tiers altos):**

- Manter as 6 atuais como estão.
- Nova escada repetível **"Frutos do Espírito N"**: custo `10 × 1.8^N` santos, efeito
  **×1.3 produção global permanente** por nível. Sempre existe um próximo degrau — é o
  incentivo eterno que o jogador pediu e o motor matemático dos ×2–3/dia.
- 4–6 Dádivas fixas de tier alto (custos 1e3 → 1e12 santos) com efeitos especiais:
  +unidades iniciais pós-prestige, +cap offline, auto-tap de 1 gerador, etc.
  "Valor extremamente alto" garantido.

## 6. Profetas e automação

- `prophetCostMultiplier` **20 → 10** — idle destrava ~2× mais cedo em cada gerador.
- **Profeta agora dá velocidade: ciclo ×0.8** ao contratar. Um botão que liga automação E
  acelera — momento memorável, 36 vezes no jogo.
- Recalibrar `tempo_min` dos geradores das eras 5–6 junto (bases 512–4096s continuam
  telas mortas): cortar bases para ≤300s OU baixar os requisitos das bênçãos de
  velocidade (100/200/350/550/900 → 50/100/250/500/1000 — o último tier vira parte da
  corrida aos 10.000, alcançável de verdade com o softcap).

## 7. Estrela Nova (micro-conteúdo de sessão)

- Aparição aleatória a cada 5–15 min, atravessa a tela em ~8s.
- Clique: recompensa aleatória — 1–2 min da produção atual em Fé, ou boost curto grátis
  (Fervor 5 min / Passo Ligeiro 5 min).
- **1x ao dia**: a primeira estrela clicada do dia dá +2 gemas (cooldown compartilha o
  padrão do vídeo diário).
- Tudo parametrizado via LiveOps (frequência, recompensas, gemas/dia) — é ferramenta de
  live ops para eventos ("chuva de estrelas" no fim de semana).

---

## 8. Aventuras isoladas — esboço do plano de moedas

**Princípio:** cada aventura é uma economia fechada com moeda própria, curva própria e
corrida própria aos 10.000. Resolve a inflação cruzada (hoje g13 rende 7.4e12/s e
trivializa a jornada principal) e faz os números voltarem a ser pequenos e legíveis no
início de cada aventura.

| Aventura | Moeda | Entrada | Prestige? | Meta de longo prazo |
|---|---|---|---|---|
| Jornada Principal | **Fé** | — | Sim (Santos) | corrida aos 10.000 (seções 1–4) |
| Vida de Cristo | **Graça** | requisito histórico de Fé (2e14), paga 1x | não | marcos pagam **Relíquias** + poucas gemas |
| Igreja & Apocalipse | **Glória** | 120 gemas (mantém) | não | marcos pagam **Relíquias** + poucas gemas |

Regras do desenho:

1. **Geradores 13–24 custam e produzem Graça; 25–36, Glória.** Custos/receitas
   rebalanceados em escala própria começando pequeno (custo_base ~4, como o g1) — cada
   aventura recomeça a jornada numérica do zero.
2. **O que cruza aventuras:** Santos/Dádivas (multiplicador global — mantém o prestige
   relevante em tudo), Conhecimentos, boosts e a Estrela Nova. **O que NÃO cruza:** a
   moeda, os upgrades de Fé e os milestones/marcos (cada aventura tem os seus).
3. **Prestige não reseta aventuras.** Ressurreição é evento da Jornada Principal; o
   progresso de Graça/Glória persiste — as aventuras são a camada de progresso permanente
   entre resets (hoje o prestige zera os 36 geradores; isso muda).
4. **Marcos das aventuras pagam Relíquias** (via ledger, 1x cada): marcos de Graça/Glória
   acumulada (1e6 / 1e9 / 1e12 / 1e15) e marcos gerais das aventuras entregam Relíquias
   como recompensa principal, mais pacotes PEQUENOS de gemas (10–30, finitos, só no
   ledger). Nunca câmbio livre moeda→gema — protege a moeda premium. Mesmo padrão
   anti-duplo do livro-razão dos estudos.
5. **Relíquias = moeda de coleção. Loja de Relíquias é 100% cosmética** — zero poder,
   zero rebalanceamento, sink de longo prazo sem risco. O poder das aventuras fica nos
   bônus de conclusão que já existem (×1.5 valor do Santo, ×2 produção global); QoL de
   poder (unidades iniciais, auto-tap) mora nas Dádivas de tier alto (seção 5).

### 8.1 Catálogo cosmético (ordem de implementação)

Raridades: comum 15–30, rara 75, épica 250, lendária 500–1.000 Relíquias. Catálogo
permanente, sem rotação FOMO. 2–3 itens exclusivos NÃO compráveis (ganhos por feito)
para dar valor de status ao sistema.

1. **Temas do Santuário** — paletas do fundo procedural (`SacredBackground` +
   `ManaTheme`): Aurora da Criação, Noite de Belém, Travessia do Mar, Vitral Gótico,
   Nova Jerusalém. Barato: troca de paleta + variação de estrelas/horizonte.
2. **Retratos Iluminados dos Profetas** — versão dourada/iluminura dos 36 profetas.
   O colecionável central: um por gerador, espelha a corrida aos 10.000.
3. **Temas do Leitor Bíblico** — pergaminho, papiro, couro, iluminura; fontes. Alto
   apelo devocional, diferencial do jogo.
4. **Molduras dos geradores** — Madeira da Arca, Pedra de Jericó, Ouro do Templo.
5. **Efeitos de ciclo/tap** — skins do `FastCycleWave` e partícula do toque (pombas,
   maná, onda dourada).
6. **Skins da Estrela Nova** — rastro dourado, cometa de Belém (sinergia, seção 7).
7. **Títulos** — expansão do campo `titulo` existente, exibido no HUD.
8. **Auras de 10.000** — aura permanente no gerador que chegou a 10.000. Exclusivo
   ganhável, não comprável.
6. Marco temporal das aventuras: Vida de Cristo abre na semana 1 e tem sua corrida de
   ~30–45 dias; Igreja & Apocalipse abre ~semana 2–4 e leva ~45–60 dias. Total do
   conteúdo atual: ~4–6 meses de jogo engajado.

---

## 9. Ordem de implementação

Fase 1 — fundação (destrava o resto):
1. Softcap por segmentos em `Economy.custo_unitario/custo_lote/max_compravel` + LiveOps.
2. Milestones novos (tabela LiveOps) + bônus real no 25.
3. Prestige: divisor 2e11, saintBonus 0.20, bônus sobre santos totais.
4. Dádivas: escada infinita + tiers altos.
5. `NumberFormat` até 1e95; `SaveValidator` para campos novos.

Fase 2 — estrutura:
6. Marcos gerais + UI da barra de gargalo + ledger de recompensas únicas.
7. Profetas 10× + velocidade ×0.8; recalibrar tempo_min/bênçãos eras 5–6.
8. Estrela Nova.

Fase 3 — aventuras (maior, planejar à parte):
9. Moedas Graça/Glória, rebalanceamento dos gens 13–36, prestige sem reset de aventura.
10. Conversão por marcos + Loja de Relíquias.

## 10. Validação

- Simulador de referência: `tools/` (portar o sim de balanceamento para o repo). O sim
  greedy com jogador perfeito COMPRIME o calendário (prestige instantâneo infinito) — usar
  versão com cadência limitada: máx. 3 prestiges/dia, 2 sessões ativas de 30 min + offline.
- Critérios de aceite por âncora da tabela da seção 1, com tolerância de ±30%.
- Telemetria (LiveOps já tem infra): registrar `min_qtd` por dia de jogo dos testers —
  é a curva que valida os marcos gerais.
- Ajuste fino: growth do segmento onde travou (seção 4). Nunca dois knobs ao mesmo tempo.

## Fora de escopo (registrado)

- Segunda camada de prestige acima dos Santos.
- Conquistas/achievements (bom candidato pós-V2; os marcos gerais já cobrem parte).
- Metas diárias estruturadas (a Estrela Nova + vídeo diário seguram a sessão por ora).
