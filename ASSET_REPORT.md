# Relatório de assets — 17/07/2026

## Resultado

O catálogo visual de runtime está íntegro: 147 referências encontradas no código e nenhuma referência ausente. A identidade Android, as moedas de aventura, as novas dádivas, a Nova Star, o marco de 10.000 e os previews cosméticos foram criados e integrados.

## Entregas desta rodada

- Identidade Android/Google Play: 6 arquivos em `assets/branding/`.
  - launcher 192×192;
  - adaptive foreground, background e monochrome 432×432;
  - ícone da loja 512×512;
  - feature graphic 1024×500.
- Moedas: Graça e Glória em `assets/icons/currencies/`, 256×256 com transparência.
- Dádivas: 8 novos ícones em `assets/icons/dadivas/`, 96×96.
  - Primícias I, II e III;
  - Vigília Constante;
  - Sopro Divino;
  - Coroa da Perseverança;
  - Frutos do Espírito;
  - Aliança Eterna, mantida como reserva de catálogo.
- Destaques: `nova_star.png` e `milestone_10000.png` em `assets/icons/special/`, 256×256.
- Cosméticos: 20 previews em `assets/icons/cosmetics/`, 256×256.
  - 5 temas de fundo;
  - 3 skins da Nova Star;
  - 6 títulos;
  - 5 itens especiais que continuam “EM BREVE” por dependerem de implementação visual;
  - 1 selo de coleção de reserva.

## Integração

- `export_presets.cfg` aponta para todos os ícones Android.
- A topbar usa o ícone correto para Fé, Graça ou Glória.
- Todas as dádivas cadastradas têm ícone; Frutos do Espírito também aparece com arte própria.
- A Nova Star usa o sprite final e preserva cor/rastro das skins.
- O emblema de 10.000 aparece quando esse é o próximo marco ou quando todos os marcos foram concluídos.
- A loja de Relíquias exibe preview em todos os cards.
- Os cinco cards especiais foram reclassificados de “aguardando arte” para “aguardando implementação”, que é o estado real.

## Otimização

Nove PNGs de runtime superdimensionados foram reduzidos para o tamanho útil. O lote caiu de 14,63 MB para 2,93 MB, redução aproximada de 80%:

- avatar e ícones de conhecimento/UI: 512×512;
- oliveira do conhecimento: 432×768.

Os atlas-fonte ficam em `assets/icons/atlases/`, protegidos por `.gdignore`, e não entram no export.

## Inventário principal

| Grupo | Quantidade | Situação |
|---|---:|---|
| Geradores | 36 | Completo |
| Profetas regulares | 36 | Completo |
| Profetas especiais | 12 | Completo |
| Dádivas em uso | 13 | Completo |
| Moedas visuais | 3 | Completo: Fé, Graça e Glória |
| Cosméticos compráveis | 14 | Preview e aplicação prontos |
| Cosméticos especiais | 5 | Preview pronto; aplicação pendente |
| Identidade Android/Play | 6 | Completo, exceto screenshots |

## Pendências reais

1. Capturar screenshots finais da versão Android para a ficha da Google Play. Essa etapa deve usar uma build final em dispositivo/emulador, não mockups.
2. Implementar o comportamento dos cinco cosméticos especiais: troca de retratos, molduras de cards, celebração com pombas e tema do leitor.
3. Produzir áudio. `assets/audio/` ainda está vazio; não há música, ambiência ou efeitos de interface/jogabilidade no catálogo atual.

## Geração visual

Modo utilizado: `stylized-concept`, com fundo chroma e remoção de chave para transparência. Direção comum dos prompts: ícone premium de jogo mobile bíblico, contorno azul-marinho espesso, acabamento dourado quente, silhueta legível em escala pequena, sem texto e sem marca d’água. Foram geradas quatro folhas por categoria: moedas; expansão de dádivas; Nova Star/marco de 10.000; cosméticos especiais. A identidade Android e os previews procedurais foram derivados por código da linguagem visual existente.

## Validação

- Importação headless do Godot: passou.
- SmokeTest: passou.
- StudySmokeTest: passou.
- UISmokeTest: passou.
- CloudSmokeTest: passou.
- Auditoria de referências: 147 referências, 0 ausentes.
