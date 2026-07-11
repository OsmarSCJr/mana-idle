# Arte de jogo — ícones

Assets criados para o Maná Idle a partir da direção visual do Stitch e de
`DESIGN_GUIDELINES.md`.

## Entrega de runtime

- `geradores/`: 36 PNGs RGBA, 128×128.
- `profetas/`: 36 PNGs RGBA, 96×96.
- `profetas/especiais/`: 12 PNGs RGBA, 96×96.
- `dadivas/`: 6 PNGs RGBA, 96×96.
- `ui/`: medalhas de Santos e Relíquias, 64×64.

`atlases/` contém as fontes de geração e as versões com alpha. A pasta possui
`.gdignore`: esses arquivos não entram no import/export do Godot; somente os
PNGs finais otimizados são usados no jogo.

## Direção aplicada

Prompt-base dos geradores:

> Atlas 2×2 de ícones para jogo mobile, tiles quadrados arredondados com aro
> dourado, contorno navy espesso, ilustração flat vetorial premium, silhueta
> legível a 64 px, paleta bíblica vibrante e reverente, sem texto, violência,
> rostos detalhados ou marcas d'água.

Prompt-base dos Profetas & Mensageiros:

> Atlas 2×2 de medalhões circulares com moldura dupla dourada, fundo navy,
> busto sem rosto detalhado e um emblema bíblico único em creme e ouro, flat
> vetorial premium, reverente, sem texto ou marcas d'água.

Os geradores foram agrupados pelas nove eras do jogo. Os retratos usam os
emblemas definidos nos documentos; variantes II/III preservam a silhueta-base e
trocam o elemento narrativo. Santos permanece uma moeda abstrata branco-prata,
sem inventar uma pessoa não definida pelo GDD.

## Pipeline reproduzível

1. Geração built-in com a arte Stitch como referência de estilo e chroma plano.
2. Remoção do chroma com o helper oficial da skill de image generation.
3. Restauração segura do interior com `tools/repair_chroma_alpha.py`.
4. Recorte, enquadramento e redução com `tools/slice_icon_atlas.py`.
5. Validação de tamanho, alpha nos cantos, opacidade central e ausência de
   resíduos chroma.

