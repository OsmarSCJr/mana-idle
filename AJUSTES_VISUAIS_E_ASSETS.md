# Ajustes necessários — visual, imagens e assets

> **Data:** 2026-09-18 · **Base:** branch `feat/jogabilidade-v3`, depois da execução do
> [PLANO_JOGABILIDADE_V3.md](PLANO_JOGABILIDADE_V3.md)
> **Sucede:** [ASSET_REPORT.md](ASSET_REPORT.md) (17/07/2026), que continua válido para o
> inventário anterior. Este documento lista **o que falta**, não o que existe.

## Como esta revisão foi feita

A revisão não foi por leitura de código: o jogo foi renderizado de verdade. A cena
[`scenes/ScreenshotTool.tscn`](scenes/ScreenshotTool.tscn) abre `Main`, monta um estado de
demonstração (recursos, seis geradores com profeta, três campanhas abertas), percorre as
seis abas e as subseções novas, e grava um PNG de cada uma:

```bash
godot --path . --resolution 1080x1920 scenes/ScreenshotTool.tscn -- --screenshots --shots-dir=./shots
```

Precisa rodar **com janela** (não `--headless`): no modo headless o renderizador é dummy e
a textura do viewport volta vazia. A ferramenta não é teste, não afirma nada e não entra na
suíte de smoke — serve para olhar.

Uma ressalva sobre as capturas desta rodada: a janela foi limitada pela resolução do
desktop e saiu em 1080×1061 em vez de 1080×1920, então a proporção está achatada em
relação ao aparelho. Os problemas de tipografia, contraste e ordem de leitura aparecem
mesmo assim; medidas de altura devem ser reconferidas num aparelho real.

---

## 1. Já corrigido nesta rodada

Entrou no código porque era barato e visível em toda a interface:

| Item | O que era | O que virou |
|---|---|---|
| **Acentuação dos catálogos** | 172 strings exibidas sem diacríticos: "producao", "Bencaos", "Salomao", "Pao dos Anjos", "Ressurreicao", "Primicias", "Vigilia"… | reacentuadas em `Upgrades.gd`, `Dadivas.gd`, `Geradores.gd`, `Conhecimentos.gd` |
| **Badge das abas** | com a sexta aba, o "!" na borda direita encostava no rótulo da aba seguinte | virou um ponto menor, colado no canto do próprio botão |
| **Barra do Selo do Dia** | barra de largura total com valor zero — lia como divisor | some quando não há selo ativo |
| **Barras de progresso em cartas escuras** | fundo pergaminho do tema virava um risco branco sobre o painel azul | fundo escuro explícito em metas, selo, conquistas e provações |
| **Tipografia das metas diárias** | nome 20 px / descrição 16 px, muito abaixo do resto da tela | 24 px / 19 px, nome em semibold |
| **Rótulos das seções devocionais** | "REFLEXÃO", "ORAÇÃO", "PARA HOJE" em 17 px | 20 px |

O reacentuador usado está em `scratchpad/acentos.py` e vale a pena virar utilitário de
`tools/`: ele só toca strings que **não** parecem identificador (`^[a-z0-9_]+$`), o que
protege ids como `"fe"`, `"graca"`, `"d_jo"`, `"prod"` e `"u1_1"`.

---

## 2. Ajustes de layout ainda pendentes

### 2.1 A aba SANTOS ficou longa demais *(prioridade alta)*

Ordem atual do scroll: Ressurreição → Frutos do Espírito → 13 Dádivas → **Camadas
permanentes (Aliança, Provações, Conquistas)** → Loja de Relíquias → aviso legal.

Nas capturas, `05-santos.png`, `05b-santos-provacoes.png` e `05c-santos-conquistas.png`
saíram **byte a byte idênticas**: trocar a seção do `ProgressoPanel` não muda nada na
primeira tela, porque o painel inteiro está abaixo da dobra, depois de treze cartas de
Dádiva. A camada que deveria ser a meta de longo prazo do jogo é a menos visível dele.

Correção recomendada (não feita aqui porque muda a arquitetura da aba): dividir SANTOS em
subabas próprias, como já acontece em ESTUDO e DIÁRIO — `RESSURREIÇÃO · DÁDIVAS ·
ALIANÇA · PROVAÇÕES · CONQUISTAS · LOJA`. Enquanto isso não acontece, uma linha de âncoras
no topo que role o `ScrollContainer` até cada seção resolve 80% do problema.

### 2.2 A barra de seis abas está no limite

Com 1080 px de largura e seis abas, cada botão fica com ~172 px. O rótulo caiu de 23 para
20 px e cabe, mas não há folga para uma sétima aba nem para idiomas com palavras mais
longas. Se a sétima aba aparecer, trocar por barra rolável ou por ícone + rótulo curto.

### 2.3 "Nível" para quantidade de geradores

Os cartões dizem "Nível 40" onde o número é **quantidade de unidades**, não nível. Com a
meta de 1.000 unidades e os marcos "todos em N", o termo errado atrapalha a leitura do
objetivo. Sugestão: "40 unidades" ou apenas "×40".

### 2.4 Densidade do cartão de gerador

A barra de ciclo ocupa a largura inteira do cartão e é verde-chapada, o que a faz parecer
barra de vida de RPG — justamente uma das anti-referências do `PRODUCT.md`. Sugestão:
barra mais fina, cor da era do gerador, e o tempo restante alinhado à direita dela.

### 2.5 Toque longo no versículo

`DevocionalPanel` abre a anotação com botão direito (desktop). No aparelho, falta o gesto
de **toque longo**: hoje o toque destaca e não há como chegar à anotação sem passar pela
aba MARCADOS. Implementar `InputEventScreenTouch` com timer de ~500 ms no `_build_verso`.

---

## 3. Assets que faltam

Convenções do projeto: PNG com transparência, 96×96 para ícones de lista, 128×128 para
ícones de cartão, 256×256 para destaques e previews, 512×512 só para arte de tela cheia.
Pastas em `assets/icons/<grupo>/`.

### 3.1 Devocional — **nenhum asset existe** *(prioridade alta)*

A aba DIÁRIO é hoje 100% tipografia e cor. É a aba que o plano define como o diferencial
do produto e a que tem menos identidade visual.

| Arquivo | Tamanho | Descrição |
|---|---|---|
| `devocional/dev_selo_dia.png` | 256×256 | selo de cera dourado, o emblema do Selo do Dia; aparece no cabeçalho e no toast |
| `devocional/dev_sequencia.png` | 128×128 | chama/lamparina da sequência, com variação acesa e apagada |
| `devocional/dev_sequencia_off.png` | 128×128 | versão apagada, para sequência zerada |
| `devocional/dev_destaque.png` | 96×96 | marcador de versículo destacado |
| `devocional/dev_nota.png` | 96×96 | pena/anotação |
| `devocional/dev_lembrete.png` | 96×96 | sino discreto para o botão de lembrete |
| `devocional/plano_sete_dias.png` | 256×256 | capa do plano "Sete Dias de Fé" |
| `devocional/plano_jornada.png` | 256×256 | capa do plano "Do Gênesis ao Apocalipse" |
| `devocional/plano_palavra.png` | 256×256 | capa do plano perpétuo "Palavra do Dia" |
| `devocional/dev_marco_sequencia.png` | 256×256 | emblema dos marcos de 3/7/14/30/60/100 dias |

Além dos arquivos, falta **fundo próprio da aba**: hoje ela herda o `SacredBackground` da
Jornada. Uma variação mais calma (menos estrelas, horizonte mais baixo) separaria o tempo
de leitura do tempo de jogo.

### 3.2 Conquistas — **nenhum asset existe**

São 66 conquistas em 10 categorias. Arte por conquista é caro e desnecessário; arte por
**categoria** resolve.

| Arquivo | Tamanho | Categoria |
|---|---|---|
| `conquistas/cat_jornada.png` | 96×96 | Jornada |
| `conquistas/cat_profetas.png` | 96×96 | Profetas |
| `conquistas/cat_bencaos.png` | 96×96 | Bênçãos |
| `conquistas/cat_prestigio.png` | 96×96 | Ressurreição |
| `conquistas/cat_alianca.png` | 96×96 | Aliança |
| `conquistas/cat_campanhas.png` | 96×96 | Campanhas |
| `conquistas/cat_estudo.png` | 96×96 | Estudo |
| `conquistas/cat_devocional.png` | 96×96 | Devocional |
| `conquistas/cat_provacoes.png` | 96×96 | Provações |
| `conquistas/cat_colecao.png` | 96×96 | Coleção |
| `conquistas/selo_conquistada.png` | 64×64 | selo de "✓" para a linha desbloqueada |

As oito conquistas de peso (`BONUS_MARCO`, +3%) merecem emblema próprio 256×256 — são os
momentos que o jogador vai querer mostrar.

### 3.3 Aliança — **nenhum asset existe**

| Arquivo | Tamanho | Descrição |
|---|---|---|
| `alianca/ui_alianca.png` | 256×256 | ícone da moeda Aliança (par com `ui_santos.png`), prata/azul para contrastar com o dourado dos Santos |
| `alianca/no_*.png` (14 arquivos) | 128×128 | um por nó da árvore: Alicerce, Vigília Longa, Primeiro Chamado, Mãos Abertas, Selo Firme, Entendimento Dobrado, Mente Larga, Marcos Maiores, Primícias Eternas, Porta Aberta, Escada Suave, Sopro Constante, Colheita Dobrada, Coroa de Luz |
| `alianca/ascensao_fundo.png` | 1080×1080 | fundo da celebração de Ascensão |

Os ids dos nós estão em `AliancaSystem.NOS`; nomear os arquivos igual ao `id` permite
carregar por convenção, como em `GameArt.gift_icon()`.

### 3.4 Provações — **nenhum asset existe**

| Arquivo | Tamanho | Provação |
|---|---|---|
| `provacoes/p_deserto.png` | 128×128 | Deserto |
| `provacoes/p_cativeiro.png` | 128×128 | Cativeiro |
| `provacoes/p_sarepta.png` | 128×128 | Viúva de Sarepta |
| `provacoes/p_jejum.png` | 128×128 | Jejum |
| `provacoes/p_viuva_duas_moedas.png` | 128×128 | Duas Moedas |
| `provacoes/p_fornalha.png` | 128×128 | Fornalha |
| `provacoes/provacao_ativa.png` | 96×96 | selo de "em curso", também usado como badge na aba |

Falta também um **tratamento visual de tela** durante a Provação: hoje nada indica, fora
da aba SANTOS, que o jogador está sob modificadores. Uma tarja fina no topo com o nome da
Provação e o progresso resolveria, e é mais barato que mudar a paleta inteira.

### 3.5 Metas diárias

| Arquivo | Tamanho | Descrição |
|---|---|---|
| `metas/meta_pendente.png` | 64×64 | círculo vazio |
| `metas/meta_concluida.png` | 64×64 | círculo com marca |
| `metas/meta_resgatada.png` | 64×64 | círculo com selo |

### 3.6 Bênçãos sem arte própria *(prioridade média)*

Em `02-bencaos.png`, **todos** os cartões usam o mesmo losango dourado genérico. São 49
bênçãos curadas com nome e lore próprios ("Tábuas Extra", "Pão dos Anjos", "Vento
Oriental") e nenhuma tem ícone. As 360 bênçãos geradas por tier podem continuar usando o
ícone do gerador correspondente, que já existe — é uma linha em `GameArt`.

Proposta mínima: 49 ícones 96×96 para as bênçãos curadas, e reaproveitar
`GameArt.generator_icon()` para os tiers gerados.

### 3.7 Notificação Android

| Arquivo | Tamanho | Descrição |
|---|---|---|
| `branding/notification_icon.png` | 96×96 | silhueta branca sobre transparente — o Android exige ícone monocromático, o launcher colorido não serve |

---

## 4. Áudio — ausência total *(prioridade alta)*

`assets/audio/` está **vazia** e não há uma única referência a `AudioStreamPlayer` em todo
o código. O jogo é silencioso do começo ao fim.

Para um idle mobile isso é uma lacuna de sensação, não de conteúdo: o retorno sonoro é
metade do que faz a compra e o ciclo parecerem recompensa. Conjunto mínimo:

| Arquivo | Tipo | Uso |
|---|---|---|
| `audio/sfx/ciclo_completo.ogg` | curto, < 300 ms | conclusão de ciclo (com limite de frequência, senão vira ruído) |
| `audio/sfx/compra.ogg` | curto | compra de gerador/bênção |
| `audio/sfx/profeta.ogg` | médio | contratação de profeta |
| `audio/sfx/marco.ogg` | médio | marco individual |
| `audio/sfx/marco_geral.ogg` | longo | marco geral — o momento de celebração |
| `audio/sfx/prestige.ogg` | longo | Ressurreição |
| `audio/sfx/ascensao.ogg` | longo | Ascensão (Aliança) |
| `audio/sfx/selo_dia.ogg` | médio | conclusão do devocional |
| `audio/sfx/estrela_nova.ogg` | curto | Estrela Nova recolhida |
| `audio/sfx/conquista.ogg` | curto | conquista desbloqueada |
| `audio/amb/santuario.ogg` | loop 60–120 s | ambiente da Jornada |
| `audio/amb/leitura.ogg` | loop 60–120 s | ambiente do Devocional, mais silencioso |

Exigências do projeto: **opção de desligar** som e música separadamente nas
configurações, e ambiente pausado quando o app perde o foco. O `PRODUCT.md` pede
"movimentos cosméticos breves, que não bloqueiam interação" — o mesmo vale para o áudio.

---

## 5. Peso e organização

| Item | Situação | Ação |
|---|---|---|
| `assets/icons/atlases/` | **100 MB** de atlas-fonte, protegidos por `.gdignore` | não entra no APK, mas pesa o clone. Mover para armazenamento fora do repo ou Git LFS |
| Assets exportáveis | 17,0 MB (fontes 5,1 · Bíblia 4,7 · ícones ~7) | saudável para um APK de 38 MB |
| Dimensões | 66 arquivos 96×96, 36 em 128×128, 34 em 256×256, 8 em 512×512 | consistente; manter a convenção nos assets novos |
| `assets/audio/` | vazia | ver seção 4 |

---

## 6. Pendência técnica: plugin de notificação Android

[`scripts/autoload/Notificacoes.gd`](scripts/autoload/Notificacoes.gd) já decide **quando**
notificar (lembrete do devocional no horário escolhido, aviso de Selo vencendo em 1 h,
aviso de acúmulo offline cheio) e guarda o último agendamento pedido, testável sem o
plugin. Falta o lado nativo.

Contrato esperado do singleton `ManaNotifications`:

```java
void schedule(int id, String title, String body, int delaySeconds)
void cancel(int id)
void cancelAll()
boolean hasPermission()
void requestPermission()
```

Também é preciso: `POST_NOTIFICATIONS` no manifesto (Android 13+), pedido de permissão no
primeiro lembrete ativado, e o ícone monocromático da seção 3.7. Registrar no
[PLANO_PUBLICACAO_ANDROID.md](PLANO_PUBLICACAO_ANDROID.md).

Sem o plugin, tudo funciona e nada quebra: `Notificacoes.disponivel()` devolve `false`, a
UI do lembrete explica que o aviso só vale dentro do app, e o smoke test V20 cobre a
decisão de horário.

---

## 7. Ordem sugerida

1. **Áudio mínimo** (seção 4) — maior ganho de sensação por esforço; dez SFX curtos mudam o jogo inteiro.
2. **Assets do Devocional** (3.1) — é a aba do diferencial e a única sem identidade visual.
3. **Subabas da SANTOS** (2.1) — a camada de longo prazo está invisível.
4. **Ícones de Aliança e Provações** (3.3, 3.4) — as telas novas de maior peso narrativo.
5. **Ícones de categoria das Conquistas** (3.2) — barato, e a aba é longa.
6. **Plugin de notificação** (6) — destrava o loop diário fora do app.
7. **Ícones das 49 bênçãos curadas** (3.6) — melhora a aba mais visitada depois da Jornada.
8. **Toque longo no versículo** (2.5) e **"unidades" em vez de "Nível"** (2.3).
9. Atlas para fora do repo (5).
