# Plano de Balanceamento — Ritmo do Jogo

Objetivo declarado (feedback do alpha 1):

| Marco | Hoje | Meta |
|---|---|---|
| 1ª Ressurreição | < 1h | ~3h |
| Aventura Vida de Cristo | < 1h | +2–3h após a 1ª ressurreição (~5–6h totais) |
| Aventura Igreja & Apocalipse | < 1h | +~10h (~15h+ totais) |
| Santos | fáceis desde o início | caros no começo, acelerando depois |

## Diagnóstico (por que está rápido)

1. **Fé inicial 1000** (valor de teste) pulava metade da Era 1. *Corrigido: agora 10.*
2. **GROWTH_RATE 1.07**: custo unitário cresce só 7% por unidade. Com "Max", o jogador
   compra 50–100 níveis de uma vez e os milestones (x2 aos 50/100/200...) chegam de graça,
   multiplicando a renda mais rápido do que os custos crescem → bola de neve.
3. **receita_base ≈ 50% do custo_base** em quase todos os geradores: cada tier novo
   se paga em ~2 ciclos. Não há "muro" no meio do jogo.
4. **PRESTIGE_DIVISOR 1e9**: 1º Santo com 1e9 de fé acumulada — atingível em minutos
   na Era 2. Como `santos = sqrt(fe_total / 1e9)`, os Santos ficam baratos cedo demais.
5. **Aventura 2 em 1e13**: alcançável na mesma run inicial, sem precisar de ressurreição.

## Mudanças propostas

### Fase A — Início (aplicada)
- [x] Fé inicial 1000 → 10 (`GameState.FE_INICIAL`).
- [x] Tempos da Era 1 +30% (0.78 / 3.9 / 7.8 / 15.6s).
- [x] Bug: ressurreição zerava a Fé e travava o jogo → volta com `FE_INICIAL`.

### Fase B — Freio na bola de neve (aplicada)
- [x] `Economy.GROWTH_RATE`: **1.07 → 1.11**.
  Efeito: comprar do nível 0 ao 50 fica ~5× mais caro em relação ao hoje; do 0 ao 100,
  ~40× mais caro. Milestones passam a ser objetivos de médio prazo, não brinde do Max.
- [x] `receita_base` dos geradores **5 a 12** (Eras 2–3): **×0.6**.
  Estica o meio da run inicial sem tocar na Era 1 (primeira meia hora continua fluida).
- [x] Manter custos de profeta e milestones como estão (são as "válvulas" de aceleração
  que o jogador sente ao voltar de uma ressurreição).

### Fase C — Ressurreição como investimento
- [x] `Economy.PRESTIGE_DIVISOR`: **1e9 → 4e11** (400×).
  Com o freio da Fase B, estimativa de ~3h para o 1º Santo. A fórmula
  `sqrt(fe_total / divisor)` já entrega a curva pedida: 2 Santos custam 4× o
  primeiro, 3 custam 9×... caro no começo; nas runs seguintes (com bônus
  acumulado) o crescimento exponencial da fé torna os Santos progressivamente
  mais rápidos.
- [x] `Economy.SANTO_BONUS`: **0.02 → 0.06** (+6% de produção por Santo).
  O 1º prestige precisa ser *sentido* — se der +2%, o jogador não percebe e o
  sacrifício de 3h não compensa.
- [x] UI: no painel Santos, mostrar "faltam X de Fé para o próximo Santo"
  (barra de progresso), para o objetivo de 3h ficar visível e não parecer bug.

### Fase D — Aventuras como capítulos
- [ ] `GameState.ADVENTURES`:
  - `vida_cristo`: 1e13 → **2e14** (histórico e entrada).
    Pensado para exigir 1–2 ressurreições antes (~5–6h de jogo).
  - `igreja_apocalipse`: 1e26 → **1e28** (mantida a exigência de concluir
    Vida de Cristo). Concluir Vida de Cristo (gen 24, custo 3.3e25) já leva
    horas com o novo growth; 1e28 dá o fôlego extra de ~10h.

## Ordem de aplicação e validação

1. Aplicar **B + C** juntas (são o núcleo do ritmo). D depois de medir.
2. Sessão de teste: anotar `fe_total_historica` em 30min / 1h / 2h / 3h
   (o save já guarda `estatisticas.tempo_jogado` — dá pra logar no toast ou tela Santos).
3. Critérios de aceite:
   - 30min: jogador ainda na Era 1–2, sem prestige disponível.
   - ~3h: 1º Santo alcançável.
   - Pós-prestige: progresso visivelmente mais rápido que a run 1 (bônus +6%/Santo + dádivas).
4. Ajuste fino com um único botão: se ficou lento demais, baixar GROWTH_RATE para 1.09–1.10;
   se rápido, subir PRESTIGE_DIVISOR (não mexer em tudo ao mesmo tempo).

## Fora do escopo (ideias futuras)
- Upgrades de "velocidade de ciclo" comprados com Sabedoria (integra estudos ao ritmo).
- Metas diárias/offline para retenção além das 15h planejadas.
