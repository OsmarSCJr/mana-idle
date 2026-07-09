# Design Guidelines — Maná Idle: Bíblia Clicker

> Documento de orientação para designers e artistas criarem os assets visuais
> do jogo. O MVP atual usa cores sólidas e placeholders. Este documento especifica
> o que precisa ser substituído por arte profissional.

---

## 1. Direção de Arte Geral

### Estilo recomendado
- **Flat illustration com vetores estilizados** (não pixel art, não realista)
- Referências: *AdVenture Capitalist* (estilo cartoon limpo), *Vampire Survivors*
  (silhuetas legíveis), apps de meditação como *Calm* / *Abide* (paleta serena)
- Linhas claras, formas arredondadas, silhuetas reconhecíveis a 64x64px
- Tom: leve e acolhedor, reverente sem ser solene, divertido sem ser satírico

### O que EVITAR
- Pixel art (difícil de escalar, muito trabalho para 36+ ícones)
- Realismo/fotorealismo (pesado, fora do tom do jogo)
- Representações de Deus/Pai (sempre simbólico: luz, mão, voz, nunca figura humana)
- Jesus representado de forma caricata (manter digno, mesmo no humor)
- Sangue/violência gráfica (mesmo em Sansão, Fornalha, Apocalipse)

### Paleta de cores — atual (placeholder) vs. desejada

| Elemento            | Placeholder atual        | Direção desejada                      |
|---------------------|--------------------------|---------------------------------------|
| Fundo               | `#101030` (navy escuro)  | Gradiente suave: noite estrelada →   |
|                     |                          | aurora → dia, mudando por era        |
| Top bar             | `#0f1a3b` (azul)         | Madeira/pergaminho estilizado         |
| Painel de gerador   | `#16213e` (navy)         | Pergaminho/cardstock envelhecido     |
| Botões de compra    | `#e94560` (coral)        | Dourado (`#f0a500`) com brilho sutil  |
| Texto principal     | `#f0f0ff` (branco)       | Manter, ou creme (`#fdf6e3`)         |
| Texto secundário    | `#808088` (cinza)        | Manter                                |
| Fé (moeda)          | `#f0a500` (dourado)      | Manter — ouro/luz                    |
| Santos (prestige)   | `#b0c4de` (azul claro)   | Branco-prata com brilho              |

### Paleta por era (sugerida)

| Era           | Tema cromático         | Cor de fundo          | Cor de destaque        |
|---------------|------------------------|------------------------|------------------------|
| 1 Gênesis     | Criação, luz, natureza | Azul-noite → dourado   | Branco-luz             |
| 2 Êxodo       | Deserto, areia, sol    | Bege-alaranjado        | Vermelho-telha         |
| 3 Reino       | Ouro, templo, realeza  | Dourado-escuro         | Púrpura-real           |
| Av.1 Cristo   | Acolhimento, milagres  | Verde-água suave       | Branco-pérola          |
| Av.2 Apoc.    | Fogo, transcendência   | Roxo-profundo → dourado| Laranja-fogo           |

---

## 2. Tipografia

### Fontes recomendadas

| Uso               | Fonte sugerida                | Tamanho  | Peso     |
|-------------------|-------------------------------|----------|----------|
| Título/logo       | *Cinzel* ou *Trajan Pro*      | 48-64px  | Bold     |
| Números (Fé)      | *Roboto Mono* ou *Oswald*     | 24-28px  | Bold     |
| Texto de UI       | *Inter* ou *Noto Sans*        | 14-18px  | Regular  |
| Flavors/piadas    | *Lora* ou *Merriweather*      | 13px     | Italic   |
| Nomes de gerador  | *Cinzel* ou *Playfair Display*| 22px     | SemiBold |

- **Licença:** usar fontes Open Font License (OFL) ou Google Fonts
- **Idiomas:** suportar caracteres acentuados (PT-BR) desde o início
- **Fallback:** Noto Sans para garantir cobertura completa

---

## 3. Ícones de Geradores (PRIORIDADE MÁXIMA)

### Especificação técnica
- **Formato:** PNG com transparência (alpha)
- **Tamanho:** 128x128px (exibido a 64x64px em telas retina)
- **Estilo:** flat illustration, silhueta reconhecível, paleta consistente
- **Nomenclatura:** `g01_haja_luz.png`, `g02_eden.png`, etc.

### Ícones necessários — Jornada Principal (12)

| #  | Gerador            | O que representar                           | Cor temática    |
|----|--------------------|---------------------------------------------|-----------------|
| 1  | Haja Luz           | Raio de luz / sol nascente / "fiat lux"     | Amarelo-dourado |
| 2  | Jardim do Éden     | Árvore estilizada (da vida) com frutos      | Verde           |
| 3  | Arca de Noé        | Barco/arca com animais em silhueta          | Marrom          |
| 4  | Torre de Babel     | Torre em construção, nuvens no topo         | Bege-telha      |
| 5  | Maná do Céu        | Pão redondo caindo do céu / flocos dourados | Branco-dourado  |
| 6  | Mar Vermelho       | Água se abrindo em duas paredes             | Azul + vermelho |
| 7  | Muralhas de Jericó | Muralha de pedra com trombeta                | Marrom-pedra    |
| 8  | Sansão             | Músculo/portão arrancado / força            | Vermelho        |
| 9  | Davi vs Golias     | Fundada com pedra / silhueta de gigante     | Roxo            |
| 10 | Templo de Salomão  | Templo com colunas de ouro                  | Dourado         |
| 11 | Jonas e a Baleia   | Peixe grande com homem dentro (silhueta)    | Azul-petróleo   |
| 12 | Fornalha Ardente   | Fornalha com chamas douradas                | Laranja-fogo    |

### Ícones necessários — Aventura 1: Vida de Cristo (12)

| #  | Gerador                | O que representar                           |
|----|------------------------|---------------------------------------------|
| 13 | Nascimento em Belém    | Estrela + manjedoura                        |
| 14 | Fuga para o Egito      | Burro com família em silhueta noturna       |
| 15 | Batismo no Jordão      | Água + pomba descendo                       |
| 16 | Bodas de Caná          | Ânfora/talha de vinho                       |
| 17 | Sermão do Monte        | Figura em colina com multidão              |
| 18 | Multiplicação dos Pães | Cesta com pães e peixes                     |
| 19 | Caminhar sobre Águas   | Pés sobre ondas                             |
| 20 | Transfiguração         | Figura brilhante no monte                   |
| 21 | Ressurreição de Lázaro | Túmulo aberto com pedra rolada              |
| 22 | Entrada em Jerusalém   | Jumentinho com ramos                        |
| 23 | Última Ceia            | Cálice e pão sobre a mesa                   |
| 24 | Ressurreição           | Túmulo vazio com luz radiante               |

### Ícones necessários — Aventura 2: Igreja & Apocalipse (12)

| #  | Gerador                | O que representar                           |
|----|------------------------|---------------------------------------------|
| 25 | Pentecostes            | Línguas de fogo descendo                    |
| 26 | Conversão de Saulo     | Luz do céu + figura caída                   |
| 27 | Viagens Missionárias   | Barco/rota no mapa estilizado              |
| 28 | Cartas às Igrejas      | Pergaminho com lacre                        |
| 29 | Mártires da Fé         | Coroa de martyrio / palma                   |
| 30 | Édito de Milão         | Selo/imperador estilizado                   |
| 31 | Reforma Protestante    | Martelo + porta com teses                   |
| 32 | Grande Comissão        | Mundo/globo com raios saindo                |
| 33 | Evangelismo Mundial    | Satélite/antena/globo digital              |
| 34 | Sete Igrejas da Ásia   | 7 candelabros                               |
| 35 | Apocalipse             | Livro selado com 7 selos                    |
| 36 | Nova Jerusalém         | Cidade dourada descendo do céu             |

### Ícones de UI

| Ícone           | Uso                              | Tamanho    |
|-----------------|----------------------------------|------------|
| Fé (Maná)       | Top bar — moeda principal        | 32x32px    |
| Santos          | Top bar — moeda de prestige      | 32x32px    |
| Relíquias       | Inventário/eventos               | 32x32px    |
| Ouro            | Loja/doações (pós-MVP)           | 32x32px    |
| Profeta (selo)  | Indicador de automação           | 24x24px    |
| Cadeado         | Gerador bloqueado                | 24x24px    |
| Configurações   | Menu                             | 24x24px    |
| Salvar          | Botão de save manual             | 24x24px    |

---

## 4. Ícones de Profetas (36 retratos)

### Especificação
- **Formato:** PNG circular com transparência
- **Tamanho:** 96x96px (exibido a 48x48px)
- **Estilo:** retrato estilizado (busto), sem rosto detalhado (silhueta + elemento icônico)
- **Nomenclatura:** `p01_gabriel.png`, `p02_adao.png`, etc.

### Abordagem recomendada
NÃO desenhar rostos realistas (evita controvérsia de representação). Em vez disso,
usar **silhuetas com elemento icônico**:
- Arcanjo Gabriel → asa + trombeta
- Adão → figo/figueira
- Noé → arco-íris
- Moisés → tábuas dos mandamentos
- Davi → funda
- Salomão → coroa
- etc.

Cada profeta tem um elemento visual único listado na coluna "Profeta (auto)" do
arquivo `Upgrades_Profetas.md`.

---

## 5. Backgrounds por Era

### Especificação
- **Formato:** PNG ou JPG (sem transparência)
- **Tamanho:** 1080x1920px (portrait, full screen)
- **Estilo:** ilustração ambiente, desfocada no terço inferior (para legibilidade da UI)
- **Nomenclatura:** `bg_era1_genesis.png`, etc.

| Era           | Cena de fundo                                          |
|---------------|--------------------------------------------------------|
| 1 Gênesis     | Céu estrelado → aurora → jardim paradisíaco ao fundo   |
| 2 Êxodo       | Deserto ao pôr do sol, montanhas ao longe              |
| 3 Reino       | Jerusalém antiga / templo ao entardecer                |
| Av.1 Cristo   | Galileia / cenário pastoral suave                      |
| Av.2 Apoc.    | Céu dramático com nuvens, luz celestial               |

- Versão **escura** de cada fundo para contraste com a UI
- Overlay semitransparente (`#00000060`) no terço inferior para legibilidade

---

## 6. Logo e Splash

### Logo do jogo
- **Texto:** "Maná Idle" (ou nome final escolhido)
- **Subtítulo:** "Bíblia Clicker" (opcional, menor)
- **Tamanhos:** 512x512px (Play Store), 1024x500px (banner), 192x192px (in-app)
- **Estilo:** fonte serifada clássica (Cinzel/Trajan) com elemento luminoso
- **Variações:** versão clara (fundo escuro) e versão escura (fundo claro)

### Splash screen
- **Tamanho:** 1080x1920px
- **Conteúdo:** logo centrado, fundo escuro com sutil gradiente dourado
- **Animação desejada (pós-MVP):** "Haja Luz" → luz expande do centro → logo aparece
- **Duração:** 1.5-2s

---

## 7. Animações e Juice

### Animações por gerador (opcional, pós-MVP)
- **Ícone:** pequena animação de "produção" ao completar ciclo (ex.: luz pisca,
  partículas douradas sobem do ícone)
- **Progress bar:** preenchimento suave com cor da era
- **"+Fé" flutuante:** número dourado sobe e fade ao comprar/completar ciclo

### Juice global
| Evento               | Animação                                     |
|----------------------|----------------------------------------------|
| Comprar gerador      | Pop-up de "+Fé" dourado, leve bounce no item |
| Contratar profeta    | Brilho no item, confete dourado discreto     |
| Prestige (Ressurreição) | Flash branco → confete → tela de "Santos +X" |
| Desbloquear era      | Fade transition no background, música muda   |
| Comprar upgrade      | Brilho verde no item afetado                 |
| Notificação          | Slide-in suave de baixo, fade-out            |

### Partículas
- **Comprar:** 5-8 partículas douradas pequenas sobem do botão
- **Ciclo completo:** 2-3 partículas sobem do ícone do gerador
- **Prestige:** chuva de partículas prata/dourado por 2s

### Haptics (Android)
- Compra leve: 20ms vibration
- Compra cara (>1% da Fé atual): 50ms vibration
- Prestige: duplo toque 50ms+100ms
- Desbloquear era: 80ms vibration

---

## 8. Áudio (referência para sound designer)

### Música por era
| Era           | Estilo musical                          |
|---------------|-----------------------------------------|
| 1 Gênesis     | Ambient etéreo, pads suaves, harpa      |
| 2 Êxodo       | Percussão tribal leve, flauta           |
| 3 Reino       | Cordas orquestrais, trompetes suaves    |
| Av.1 Cristo   | Guitarra acústica suave, calma          |
| Av.2 Apoc.    | Coro + orquestra crescente              |

### SFX
| Evento               | Som sugerido                     |
|----------------------|----------------------------------|
| Clique no gerador    | "Pluck" suave (harpa/lira)       |
| Compra gerador       | "Coin" metálico leve             |
| Contratar profeta    | "Chime" celestial                |
| Prestige             | "Coral swell" + "whoosh"         |
| Desbloquear era      | "Trumpet fanfare" curto          |
| Notificação          | "Bell" suave                     |
| Erro (sem Fé)        | "Thud" abafado                   |

- **Formato:** OGG Vorbis (menor tamanho, boa qualidade)
- **Bitrate:** 96kbps (música), 64kbps (SFX)
- **Loop:** músicas devem fazer loop perfeito (crossfade 1s entre eras)

---

## 9. Assets de Loja/Transparência (pós-MVP)

### Tiers de doação — ícones
| Tier                | Ícone (96x96px)               |
|---------------------|-------------------------------|
| Oferta do Pobre     | Duas moedas pequenas          |
| Oferta da Viúva     | Moeda + mão                   |
| Dízimo              | Saco de moedas                |
| Oferta Generosa     | Baú com moedas                |
| Fundação            | Templo/catedral dourado       |

### Página de transparência
- Layout HTML/CSS responsivo
- Mesma identidade visual do app
- Ícones de gráficos (pizza, barras) estilizados

---

## 10. Especificações Técnicas de Entrega

### Formatos
| Tipo de asset       | Formato       | Notas                          |
|---------------------|---------------|--------------------------------|
| Ícones de gerador   | PNG (alpha)   | Otimizados (pngquant)          |
| Ícones de UI        | SVG ou PNG    | SVG preferível (escalável)     |
| Backgrounds         | JPG ou WebP   | Compressed, <500KB cada        |
| Retratos de profeta | PNG circular  | Com alpha                      |
| Logo                | SVG + PNG     | Vetor + raster                 |
| Fontes              | TTF/OTF       | OFL licensed                   |
| Música              | OGG           | 96kbps, loopable               |
| SFX                 | OGG/WAV       | 64kbps, <50KB cada             |
| Animações           | Sprite sheets | PNG + JSON (Aseprite format)   |

### Estrutura de pastas esperada
```
assets/
├── icons/
│   ├── geradores/        # g01_haja_luz.png ... g36_nova_jerusalem.png
│   ├── profetas/         # p01_gabriel.png ... p36_cordeiro.png
│   └── ui/               # fe.png, santos.png, cadeado.png, etc.
├── backgrounds/
│   ├── bg_era1_genesis.jpg
│   ├── bg_era2_exodo.jpg
│   └── ...
├── logo/
│   ├── logo_full.svg
│   ├── logo_512.png      # Play Store icon
│   └── banner_1024x500.png
├── fonts/
│   ├── Cinzel-Regular.ttf
│   ├── Cinzel-Bold.ttf
│   ├── Inter-Regular.ttf
│   └── ...
├── audio/
│   ├── music/
│   │   ├── era1_genesis.ogg
│   │   └── ...
│   └── sfx/
│       ├── click.ogg
│       ├── buy.ogg
│       └── ...
└── animations/
    ├── particles/
    └── sprite_sheets/
```

### Otimização
- **Total de assets:** manter < 50MB (ideal para download mobile)
- **Atlas:** ícones pequenos podem ser combinados em atlas texture
- **Compressão:** Godot 4 VRZ compression para texturas
- **Fontes:** subset para PT-BR + EN (reduz tamanho)

---

## 11. Acessibilidade

- **Contraste:** mínimo 4.5:1 para texto (WCAG AA)
- **Daltonismo:** não usar só cor para diferenciar estados (usar ícone/texto também)
- **Tamanho de fonte:** suportar ajuste nas configurações (1.0x, 1.25x, 1.5x)
- **Toque:** áreas mínimas de 48x48dp (padrão Android)
- **Motion:** opção de reduzir animações nas configurações
- **Color blind mode:** paleta alternativa com alto contraste

---

## 12. Checklist de Entrega para o Designer

### MVP (Jornada Principal — Eras 1-3)
- [ ] Logo do jogo (SVG + 512px PNG)
- [ ] Ícone do app (512x512 PNG, maskable)
- [ ] 12 ícones de geradores (128x128 PNG)
- [ ] 12 retratos de profetas (96x96 PNG circular)
- [ ] 3 backgrounds de era (1080x1920 JPG)
- [ ] 8 ícones de UI (SVG ou PNG)
- [ ] 2-3 fontes (TTF, OFL)
- [ ] 5 SFX básicos (OGG)
- [ ] 1 música de fundo (OGG, loop)
- [ ] Paleta de cores final (HEX/RGB)
- [ ] Theme do Godot (.tres) se possível

### Pós-MVP (Aventuras + Filantropia)
- [ ] 24 ícones de geradores (Aventuras 1 e 2)
- [ ] 24 retratos de profetas
- [ ] 2 backgrounds de aventura
- [ ] Ícones de tiers de doação (5)
- [ ] Layout da página de transparência
- [ ] 4 músicas adicionais (uma por era/aventura)
- [ ] Animações de sprite sheet (partículas, juice)
- [ ] Splash animado

---

## 13. Referências Visuais

| Referência              | O que pegar                           |
|-------------------------|---------------------------------------|
| AdVenture Capitalist    | Layout, clareza de UI, cartoon clean  |
| Bible Tiles (Sophun)    | Arte em vitral, paleta bíblica        |
| TruPlay                 | Qualidade de produção cristã          |
| Calm / Abide            | Paleta serena, tipografia serifada    |
| Rebel Inc.              | UI de gestão com tema sério           |
| Idle Slayer             | Tipografia e layout mobile portrait   |
| Iluminuras medievais   | Inspiração para bordas e detalhes     |
| Arte de vitral         | Paleta de cores e icografia bíblica   |

---

## 14. Contato e Revisão

- **Entrega em lotes:** MVP primeiro (12 geradores), depois aventuras
- **Revisão iterativa:** cada lote revisado antes do próximo
- **Formato de entrega:** ZIP por pasta ou repositório Git
- **Nomenclatura:** seguir exatamente o padrão `g01_haja_luz.png` etc.
- **Comunicação:** dúvidas sobre representações sensíveis → consultar antes de finalizar

> **Lembrete:** o tom é leve e divertido, mas sempre respeitoso com o sagrado.
> Quando em dúvida, escolher a representação mais reverente. O humor está no
> texto (flavors), não na arte.
