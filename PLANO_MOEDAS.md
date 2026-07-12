# Plano — Moedas por Aventura (economias isoladas)

Pedido: cada aventura com moeda própria, isolada — progresso em um capítulo
não financia o outro. Gemas continuam transversais (premium).

## Ideias de moeda (escolher 1 por aventura)

| Aventura | Recomendada | Alternativas | Por quê |
|---|---|---|---|
| I · Jornada (AT) | **Fé** (mantém) | Maná, Aliança | Já estabelecida na UI e no save |
| II · Vida de Cristo | **Graça** | Pão, Vinho, Luz, Compaixão | "Graça" é a marca teológica do NT; curto e soa como recurso |
| III · Igreja & Apocalipse | **Glória** | Chama (Espírito), Coroa, Selo, Testemunho | Fecha o arco Fé → Graça → Glória; "Selos" combina com Apocalipse |

Trio recomendado: **Fé / Graça / Glória** — progressão natural, 1 palavra cada,
ícones fáceis (✦ / pomba ou pão / coroa).

## Modelo de isolamento

- Cada gerador produz e custa a moeda da SUA aventura (campo `adventure` já
  existe em Geradores).
- Saldo separado: `fe`, `graca`, `gloria` (+ totais de vida/históricos por moeda).
- Topbar mostra a moeda da aventura ativa (pill muda com o capítulo).
- Bênçãos custam a moeda da aventura do gerador-alvo; globais custam Fé.
- Profetas: moeda da aventura do gerador.
- Ressurreição: reseta as 3 moedas; Santos calculados sobre a soma ponderada?
  NÃO — Santos continuam vindo só de Fé (Jornada é o "core loop" de prestígio);
  aventuras II/III são conteúdo paralelo com metas próprias (concluir = relíquias
  + gemas). Mais simples e evita balancear 3 curvas de prestígio.
- Desbloqueio: aventura II paga em Fé (2e14) — ponte entre economias; III em Gemas.
- Save: campos novos com migração (saves antigos: `graca = 0`, `gloria = 0`).

## Pontos de código (quando implementar)

1. `GameState`: dicionário `moedas = {"fe": .., "graca": .., "gloria": ..}` ou
   campos separados; helpers `get_moeda(adventure_id)` / `spend/add`.
2. `Economy`: custo/receita não mudam — só o SALDO alvo muda conforme
   `Geradores.get_adventure_for_id(gen_id)`.
3. `Main`: pill da topbar dinâmica; painel Santos referencia só Fé.
4. `NumberFormat`: igual para todas.
5. `SaveSystem`: versão de save +1 com migração.
6. Modal offline: reporta por moeda (produção offline separada por aventura).

## Status
- [ ] Aguardando escolha dos nomes para implementar.
