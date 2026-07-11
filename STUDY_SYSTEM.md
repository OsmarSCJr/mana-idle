# Sistema de Estudos e progressão estendida

Este documento registra a implementação do eixo **jogar enquanto estuda** do
Maná Idle. O sistema foi desenhado a partir do GDD, do balanceamento do projeto,
das diretrizes visuais e das telas importadas do Stitch.

## Experiência do jogador

O jogo continua produzindo enquanto a pessoa alterna entre quatro áreas:

- **Jornada:** compra geradores, inicia ciclos e contrata profetas.
- **Bênçãos:** adquire upgrades econômicos.
- **Estudo:** lê passagens, responde quizzes, consulta a Bíblia e compra
  Conhecimentos.
- **Santos:** realiza a Ressurreição e administra bônus permanentes.

Ao alcançar 10 unidades de um gerador, o estudo correspondente é desbloqueado.
Cada estudo possui quatro estados persistentes: bloqueado, novo, lido e
dominado. A leitura libera o quiz; uma resposta errada pode ser refeita e uma
resposta correta encerra o estudo.

## Conteúdo entregue

- 36 geradores distribuídos em nove eras.
- 36 estudos, um por gerador.
- 9 Páginas Iluminadas, uma por grupo de quatro estudos.
- 36 quizzes com três alternativas e explicação da resposta.
- 66 livros da Bíblia disponíveis offline.
- 1.189 capítulos e 31.102 versículos.
- 5 Conhecimentos permanentes adquiridos com Sabedoria.
- 3 jornadas: Jornada Principal, Vida de Cristo e Igreja & Apocalipse.

## Recompensas e balanceamento

Concluir uma leitura concede 1% do alvo econômico do estudo, com mínimo de 10
de Fé. Acertar o quiz concede 2%, com mínimo de 20 de Fé, e 1 ponto de
Sabedoria. Recompensas usam um livro-razão no save e, portanto, nunca podem ser
recebidas duas vezes.

Dominar os quatro estudos de uma era concede uma Página Iluminada, 2 de
Sabedoria e +2% de produção aos quatro geradores daquela era. Dominar todos os
36 estudos concede mais 3 de Sabedoria e o título **Leitor da Jornada
Completa**.

Os Conhecimentos disponíveis são:

| Conhecimento | Custo | Efeito permanente |
| --- | ---: | --- |
| Boa Semente | 2 | +5% de produção offline |
| Memória Fiel | 3 | +30 min ao limite offline |
| Discernimento | 4 | -1% no custo dos geradores |
| Constância | 5 | +2% de produção global |
| Trabalho Diligente | 7 | +3% de produção global |

## Jornadas longas

Os geradores G13–G24 formam **Vida de Cristo** e G25–G36 formam **Igreja &
Apocalipse**. O acesso é permanente após pagar o custo de entrada e cumprir a
meta de Fé histórica.

| Jornada | Fé histórica | Entrada | Conclusão |
| --- | ---: | ---: | --- |
| Vida de Cristo | 1e13 | 1e13 Fé | comprar G24 |
| Igreja & Apocalipse | 1e26 | 1e26 Fé e concluir Vida de Cristo | comprar G36 |

Vida de Cristo concede 50 Relíquias e aumenta em 50% o valor de cada Santo.
Igreja & Apocalipse concede 100 Relíquias e duplica a produção global.

## Leitor bíblico

O leitor funciona sem conexão. Ele permite escolher livro e capítulo, aumentar
ou reduzir a fonte, destacar a passagem de um estudo, marcar capítulos como
lidos, favoritar passagens e retomar a última leitura. O progresso de leitura é
preservado durante a Ressurreição.

O texto utilizado é a **Bíblia Livre (BLIVRE)**, versão de fonte 2025-12-12,
sob licença Creative Commons Atribuição 4.0. A atribuição aparece no leitor e no
aviso legal do jogo. Detalhes e licença integral estão em
`assets/bible/ATTRIBUTION.md` e `assets/bible/LICENSE.txt`.

Para atualizar os dados a partir da fonte oficial:

```powershell
powershell -ExecutionPolicy Bypass -File tools/import_bible.ps1
```

O importador valida os 66 livros, referências essenciais, UTF-8 e o checksum do
arquivo-fonte antes de substituir o acervo.

## Persistência

O save está na versão 2 e migra automaticamente saves da versão 1. Os campos
novos incluem Fé histórica, maiores quantidades já alcançadas, Sabedoria,
progresso dos estudos, recompensas resgatadas, Conhecimentos, leitura bíblica,
jornadas e Relíquias.

Estudos desbloqueados, Sabedoria, Conhecimentos, Páginas Iluminadas, capítulos
lidos e jornadas permanecem após a Ressurreição. O save usa escrita temporária
e uma cópia de segurança `save.json.bak`.

Testes e prévias devem chamar
`SaveSystem.set_persistence_enabled(false)` antes de carregar a cena principal.
Com a persistência desativada, o jogo não lê nem grava `user://save.json`.

## Arquivos centrais

- `scripts/data/EstudosBiblicos.gd`: catálogo editorial dos 36 estudos.
- `scripts/data/BibleTextProvider.gd`: acesso sob demanda ao acervo offline.
- `scripts/data/Conhecimentos.gd`: catálogo de bônus de Sabedoria.
- `scripts/autoload/StudySystem.gd`: regras, estados e recompensas.
- `scripts/autoload/GameState.gd`: progressão, aventuras e save v2.
- `scripts/autoload/Economy.gd`: aplicação dos bônus de estudo.
- `scripts/ui/StudyPanel.gd`: navegação, estudos e quizzes.
- `scripts/ui/BibleReaderPanel.gd`: leitor bíblico.
- `scenes/StudySmokeTest.tscn`: teste integrado do novo sistema.
- `scenes/UISmokeTest.tscn`: instancia a interface completa sem acessar o save.

## Validação

O teste integrado verifica catálogos, desbloqueio por gerador, leitura
idempotente, resposta errada e nova tentativa, recompensa única, compra de
Conhecimento, os 66 livros, marcação de capítulo, round-trip do save v2,
desbloqueio de aventura e migração de save v1.

```powershell
& "C:\Users\Servo de Deus\Downloads\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64.exe" --headless --path . scenes/StudySmokeTest.tscn
& "C:\Users\Servo de Deus\Downloads\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64.exe" --headless --path . scenes/SmokeTest.tscn
& "C:\Users\Servo de Deus\Downloads\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64.exe" --headless --path . scenes/UISmokeTest.tscn
```
