# Export do Stitch — Maná Idle: Bíblia Clicker

Fonte: projeto Stitch `1428224720717337199` (telas exportadas em 9 de julho de 2026).

## Sistema de design: Sacred Journey

O conceito é **Reverência Moderna**: progressão de jogo idle clara e serena, combinando o vazio cósmico com elementos físicos de pergaminho. A intenção é transmitir a passagem da escuridão para a luz, sem excesso de ornamentação.

- Fundo cósmico: `#10102e`; superfícies em camadas: `#181837`, `#1c1c3b`, `#272746` e `#323252`.
- Dourado da Fé: `#f0a500` (ação principal) e `#ffc56c` (realce). Nos painéis em pergaminho, a referência é `#fdf6e3`.
- Tipografia: **Noto Serif** em títulos e textos narrativos; **Inter** em números, controles e descrições.
- Grade de 8 px; margem segura de 16 px; cartões com 16 px de raio; botões principais em formato pílula.
- Hierarquia: barra de recursos escura flutuante, área central de cartões de geradores e navegação inferior em pergaminho.
- Ações de bênção/compra devem ter brilho dourado suave; barras de progresso têm preenchimento dourado e pontas arredondadas.

## Conteúdo exportado

`screens/` contém capturas PNG e os HTMLs originais das telas, adequados como referência de interface:

- `jornada` — jornada/geradores;
- `profetas` — coleção de profetas;
- `upgrades` — árvore/lista de melhorias.

Os HTMLs são protótipos independentes que carregam Tailwind, Google Fonts e Material Symbols por CDN. Eles não foram convertidos nem integrados ao Godot.

`references/` contém o logo e os dois spritesheets fornecidos pelo Stitch. Os arquivos são JPEG, apesar de o nome de origem não indicar a extensão.
