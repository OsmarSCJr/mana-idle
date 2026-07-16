# Plano de publicação Android — APK online e Google Play

**Projeto:** Maná Idle  
**Plano atualizado em:** 15 de julho de 2026  
**Objetivo:** disponibilizar primeiro uma beta pública por APK assinado em infraestrutura Cloudflare, com save online em Worker + D1 e sem transações financeiras; depois fazer o lançamento público do mesmo aplicativo na Google Play e só então preparar monetização. Para preservar assinatura e save, haverá um upload técnico prévio em uma faixa interna da Play antes do APK público — isso não é lançamento público nem habilita cobranças.

## 1. Resumo executivo

A rota recomendada é:

1. Criar e verificar a conta Play Console agora, sem publicar em produção e sem ativar pagamentos.
2. Fixar o pacote e a assinatura definitiva antes de entregar o APK ao público.
3. Endurecer e testar uma variante beta sem compras, doações, checkout ou anúncios reais.
4. Implementar e testar o save online offline-first em Cloudflare Worker + D1.
5. Preparar o site no Cloudflare Pages e o bucket versionado no Cloudflare R2, sem publicar o APK ainda.
6. Enviar um primeiro AAB à faixa interna, ativar Play App Signing e baixar o APK universal assinado pela Play.
7. Hospedar esse APK no R2, rodar uma beta direta pequena e corrigir falhas do jogo e da sincronização.
8. Se a conta pessoal for nova, cumprir o teste fechado da Play com pelo menos 12 pessoas por 14 dias contínuos.
9. Lançar a versão 1.0 gratuita e sem transações por rollout gradual.
10. Em uma versão posterior, integrar Play Billing ao Worker e ao D1 já existentes.

### Arquitetura recomendada

~~~text
FASE APK ONLINE

Jogador Android
  ├─ baixa o APK ───────────────> Cloudflare R2
  ├─ lê instruções/políticas ───> Cloudflare Pages
  └─ sincroniza o progresso ────> Cloudflare Worker ──> D1

O jogo continua offline-first e salva primeiro em user://save.json.
Há conta anônima recuperável e save online, mas não há compra,
doação, checkout, anúncio real ou outra transação financeira.


FASE PÓS-GOOGLE PLAY, QUANDO HOUVER MONETIZAÇÃO

Google Play entrega o app a partir do AAB
             │
             ▼
       App Android
             │ HTTPS
             ▼
    Mesmo Cloudflare Worker
       ├─ D1: save, carteira, ledger e idempotência
       └─ Google Play Developer API: validação do purchase token
~~~

O plano executável do backend está em [Plano de save online — Worker + D1](./PLANO_CLOUD_SAVE.md).

## 2. Estado atual verificado

O projeto já está mais perto do APK público do que parecia:

- Engine: Godot 4.7, GDScript, tela vertical.
- Versão do projeto: 0.1.8-alpha.
- Pacote: com.osmarscjr.manaidle.
- APK release existente: 45.740.497 bytes, aproximadamente 43,6 MiB.
- versionCode 9 e versionName 0.1.8-alpha.
- minSdk 24, targetSdk 36 e compileSdk 36.
- Arquitetura: arm64-v8a.
- Assinatura release válida, RSA 4096, esquemas APK v2 e v3.
- Alinhamento ZIP de 16 KiB do APK verificado; isso não prova sozinho a compatibilidade dos segmentos ELF nem do AAB gerado pela Play.
- Nenhuma permissão Android declarada.
- Save totalmente local em user://save.json, com arquivo temporário e backup local.
- No estado atual do repositório, ainda não há backend, login, banco, analytics, anúncios reais ou Billing; Worker + D1 são a próxima implementação planejada.
- Os pacotes IAP estão desabilitados, mas ainda aparecem como “EM BREVE”.
- Os botões de “vídeo” são simulações que dão recompensa após uma espera; não há vídeo nem SDK real.
- O preset atual gera APK, não AAB, usa apenas arm64 e deixa os ícones Android específicos vazios.
- O backup Android está desabilitado; uma desinstalação apaga o progresso.
- Há três conjuntos de smoke tests, mas ainda não há CI e um deles não retorna erro ao processo quando falha.
- A atribuição da Bíblia Livre, licenciada em CC BY 4.0, já existe no app e nos arquivos do projeto.

Arquivos de referência:

- [Configuração do projeto](./project.godot)
- [Preset Android local](./export_presets.cfg)
- [Save local](./scripts/autoload/SaveSystem.gd)
- [Estado e moedas](./scripts/autoload/GameState.gd)
- [UI da tenda e vídeos simulados](./scripts/ui/Main.gd)
- [Plano atual de gemas](./PLANO_GEMAS.md)
- [Atribuição da Bíblia Livre](./assets/bible/ATTRIBUTION.md)

## 3. Decisões que precisam ser congeladas

### 3.1 Tipo de conta Play

Escolher o tipo que corresponde à realidade jurídica:

- **Conta pessoal:** usar se o responsável publica como pessoa física. Uma conta pessoal nova precisa, em regra, manter pelo menos 12 testadores inscritos por 14 dias contínuos antes de pedir acesso à produção.
- **Conta de organização:** usar somente se o app pertence de fato a uma organização/CNPJ. Exige dados legais e D‑U‑N‑S; o D‑U‑N‑S é gratuito, mas pode levar até 30 dias.

Não escolher organização apenas para evitar o teste fechado. A documentação oficial explica os [tipos de conta](https://support.google.com/googleplay/android-developer/answer/13634885?hl=en) e os [dados de verificação](https://support.google.com/googleplay/android-developer/answer/13628312?hl=pt-br).

**Decisão padrão deste plano:** conta pessoal, até que exista uma organização responsável confirmada.

### 3.2 Nome de pacote

Manter com.osmarscjr.manaidle se esse identificador e o nome do responsável estiverem corretos. O identificador não deve mudar depois que o app for publicado.

### 3.3 Assinatura

Esta é a decisão de maior risco porque o save não sobrevive a uma desinstalação.

**Caminho recomendado:**

1. Criar o app no Play Console antes da beta pública.
2. Criar e proteger uma upload key dedicada.
3. Escolher a app signing key definitiva e ativar Play App Signing.
4. Assinar o AAB inicial com a upload key e enviá-lo à faixa interna.
5. Baixar no App Bundle Explorer o APK universal assinado pela app signing key da Play.
6. Conferir pacote, versionCode e fingerprint do signer; então hospedar esse APK no R2.

Assim, o APK direto e a versão da Play terão o mesmo certificado, pacote e caminho de atualização. A orientação oficial cobre a [distribuição fora da Play com a mesma chave](https://support.google.com/googleplay/android-developer/answer/9842756?hl=en-GB).

**Alternativa:** usar a chave release atual como app signing key e transferir uma cópia ao Play App Signing. Só fazer isso depois de confirmar que a chave nunca foi exposta.

**Regras de segurança:**

- Não guardar senha ou keystore no Git.
- O preset atual contém credenciais em texto claro no computador; mover senhas para secrets/variáveis do processo de release.
- Criar duas cópias criptografadas e offline da chave, em locais separados.
- Registrar certificado SHA-256, alias, data, responsável e procedimento de recuperação.
- Usar a upload key separada desde o primeiro AAB; ela não substitui a app signing key.
- Nunca publicar o APK antigo assinado com certificado Android Debug.
- Todo release novo recebe versionCode maior que o anterior.

## 4. Fase 0 — Conta e fundações

**Prazo ativo:** 2 a 6 horas.  
**Tempo externo possível:** reservar alguns dias para conta pessoal; o pagamento inicial pode levar até 48 horas, mas identidade, telefone, documentos e aparelho não têm esse prazo como SLA. Reservar até 30 dias se a organização precisar obter D‑U‑N‑S.  
**Custo:** US$ 25 uma vez para o Play Console; reservar aproximadamente R$ 150–200 com câmbio, imposto e arredondamento.

### O que fazer

- [ ] Criar um e-mail de suporte dedicado.
- [ ] Escolher conta pessoal ou organização conforme a situação real.
- [ ] Pagar a taxa única de US$ 25 do Play Console.
- [ ] Verificar identidade, e-mail, telefone e perfil de pagamentos.
- [ ] Se pessoal e solicitado, verificar um aparelho físico não rooteado com Android 10 ou superior pelo app Play Console.
- [ ] Criar o app “Maná Idle” no console sem publicar em produção.
- [ ] Reservar o pacote com.osmarscjr.manaidle.
- [ ] Definir a estratégia de Play App Signing descrita acima.
- [ ] Registrar o pacote e o certificado para a verificação Android de 2026.

O Google documenta a [taxa de cadastro de US$ 25](https://support.google.com/googleplay/android-developer/answer/6112435?hl=en), a [verificação de aparelho](https://support.google.com/googleplay/android-developer/answer/14316361?hl=en) e o [cronograma de verificação Android](https://support.google.com/android-developer-console/answer/16561738?hl=en). A aplicação começa no Brasil em 30 de setembro de 2026, portanto não convém deixar o registro para o fim.

### Critério de conclusão

- Conta verificada.
- App criado no Play Console.
- Pacote e certificado documentados.
- Estratégia de assinatura aprovada.
- Nenhuma configuração de comerciante, produto ou cobrança ativada.

## 5. Fase 1 — Tornar o jogo seguro para a beta direta

**Prazo:** 2 a 5 dias.  
**Custo de infraestrutura:** R$ 0.  
**Esforço estimado:** 16 a 40 horas.

### 5.1 Criar canais de build

Criar duas variantes lógicas:

- **direct-beta:** APK para download externo, sem Billing, sem links de pagamento e sem SDK de anúncios.
- **play:** AAB para a Google Play, inicialmente também sem monetização.

Não é necessário mudar o pacote entre as variantes se a assinatura for a mesma. Se a assinatura ainda não estiver resolvida, não distribuir a beta.

Dentro das configurações do app, mostrar versionName, versionCode, canal direct-beta/play, e-mail de suporte e link HTTPS da política de privacidade.

### 5.2 Remover a aparência de monetização

Antes do APK público:

- [ ] Ocultar pacotes com preço e o texto “EM BREVE”.
- [ ] Ocultar doação, PIX, checkout, assinatura e qualquer link de compra.
- [ ] Não instalar Play Billing.
- [ ] Não instalar AdMob de produção.
- [ ] Renomear os “vídeos simulados” para “bônus gratuito da alpha” ou desativá-los.
- [ ] Manter as gemas obtidas gratuitamente como moeda de jogo, sem venda.
- [ ] Incluir na tela legal e no site: “Esta versão beta não realiza compras nem transações financeiras”.

Não basta desabilitar um botão: nenhuma rota, intent ou endpoint de pedido deve existir na variante direct-beta.

### 5.3 Fechar o preset Android

- [ ] Fixar minSdk 24 e targetSdk 36 explicitamente no preset.
- [ ] Manter arm64-v8a; decidir se vale incluir armeabi-v7a para aparelhos antigos.
- [ ] Ativar o build Gradle e instalar o template Android do Godot para gerar AAB e permitir plugins futuros.
- [ ] Criar preset APK release e preset AAB release.
- [ ] Preencher ícone normal, adaptive foreground, adaptive background e monochrome.
- [ ] Validar os recursos themed/monochrome e eliminar referências de ícone ausentes.
- [ ] Confirmar orientação portrait, modo imersivo e categoria game.
- [ ] Manter apenas permissões realmente necessárias.
- [ ] Gerar um preset sanitizado e reproduzível para CI, sem caminhos pessoais e sem segredos.
- [ ] Fazer o SmokeTest retornar exit code 1 quando falhar.
- [ ] Decidir e documentar se android/build será versionado ou regenerado de modo determinístico.
- [ ] Separar fisicamente artefatos debug e release; o diretório de publicação nunca recebe build Debug.

O projeto já mira API 36. Isso é a escolha correta porque a Play passará a exigir Android 16/API 36 em agosto de 2026; a página de [requisitos de target API](https://developer.android.com/google/play/requirements/target-sdk) deve ser reconferida no dia do envio.

### 5.4 Versionamento e CI de release

- [ ] Definir uma única fonte para versionName e versionCode.
- [ ] Sincronizar projeto Godot, preset, tag Git, nome do APK/AAB e manifest.json do R2.
- [ ] Fixar no CI: Godot 4.7, export templates, JDK 17, Android SDK/Build Tools e Gradle.
- [ ] Executar SmokeTest, StudySmokeTest e UISmokeTest.
- [ ] Injetar keystore, alias e senhas somente por secrets do ambiente.
- [ ] Gerar APK e AAB a partir de commit limpo e tag versionada.
- [ ] Inspecionar automaticamente pacote, versões, ABI, targetSdk e permissões.
- [ ] Rodar apksigner e zipalign -P 16; rejeitar certificado Android Debug.
- [ ] Calcular SHA-256 do arquivo e fingerprint SHA-256 do signer.
- [ ] Só promover o artefato se todas as verificações passarem.

O APK release e o APK Debug encontrados hoje no mesmo diretório devem ser separados antes da primeira automação.

### 5.5 Proteger o progresso

- [ ] Testar atualização instalada sobre a versão anterior sem perder o save.
- [ ] Testar migrações de todos os SAVE_VERSION existentes.
- [ ] Confirmar que app signing, pacote e versionCode permitem atualização.
- [ ] Atualizar a documentação que ainda fala em save v2; o código atual usa SAVE_VERSION 8.
- [ ] Manter fixtures e testes de migração para todas as versões históricas suportadas.
- [ ] Se a continuidade do certificado não estiver comprovada, bloquear a beta pública ou implementar “Exportar backup” e “Importar backup” antes dela.
- [ ] Na importação, usar o seletor de documentos Android, validar schema/tamanho, rejeitar JSON inválido e executar migrações.
- [ ] Explicar no site que desinstalar a beta apaga o progresso enquanto não existir backup/exportação.

O save local é suficiente antes de existir dinheiro. Depois que houver compra real, saldo premium e recibos não podem depender somente desse JSON editável.

### 5.6 Licenças e identificação

- [ ] Manter acessíveis no app e no site: Bíblia Livre (CC BY 4.0), Godot (MIT), Inter e Noto Serif (OFL).
- [ ] Auditar e registrar proveniência/licença de assets Stitch, imagens geradas e demais recursos.
- [ ] Mostrar versão, canal e contato de suporte na tela de configurações.
- [ ] Adicionar nessa tela o link da política de privacidade antes do AAB final.

### 5.7 Fixar assinatura e obter o APK distribuível

- [ ] Gerar o primeiro AAB release com a upload key.
- [ ] Enviar esse AAB somente à faixa interna.
- [ ] Ativar/confirmar Play App Signing com a app signing key definitiva.
- [ ] Baixar o APK universal assinado no App Bundle Explorer.
- [ ] Conferir que pacote, versionCode e fingerprint são os esperados.
- [ ] Usar esse APK universal, e não uma build Debug ou assinada por outra chave, na beta do R2.
- [ ] Guardar o AAB, o APK universal, hashes e metadados sob a mesma tag de release.

### Critério de conclusão

- APK release assinado pela estratégia definitiva.
- AAB release gerado.
- Nenhum fluxo financeiro ou anúncio real presente.
- Atualização preserva o save.
- Ícones e manifesto sem avisos relevantes.
- Testes automatizados passam com código de saída confiável.

## 6. Fase 2 — QA Android

**Prazo:** 2 a 5 dias, podendo ocorrer em paralelo com o site.  
**Custo:** R$ 0 com aparelhos existentes; R$ 700–2.500 se for necessário comprar aparelho de teste.

### Matriz mínima

- Android 7/API 24: compatibilidade mínima.
- Android 10: aparelho usado também na verificação da conta, se aplicável.
- Android 13 ou 14: base instalada intermediária.
- Android 15 e 16: políticas atuais e páginas de memória de 16 KiB.
- Tela pequena, tela 1080×1920 e uma tela alta 9:19,5.
- Pelo menos um tablet ou emulador de tela grande para conferir layout.

### Casos obrigatórios

- [ ] Instalação limpa.
- [ ] Atualização por APK com versionCode maior.
- [ ] Atualização da beta direta para o APK universal assinado pela Play.
- [ ] Abrir, fechar, pausar e matar o processo.
- [ ] Reiniciar o aparelho.
- [ ] Jogar totalmente sem internet.
- [ ] Cálculo de ganho offline com relógio normal, adiantado e atrasado.
- [ ] Save normal, save temporário e recuperação do backup.
- [ ] Migrações de saves antigos.
- [ ] Reset de progresso e mensagens de confirmação.
- [ ] Todas as abas, aventuras, leitor bíblico e tamanhos de fonte.
- [ ] Ausência de compras, preços e vídeos falsos.
- [ ] Consumo de bateria e memória após 30–60 minutos.
- [ ] Verificação de APK/AAB com ferramentas Android e App Bundle Explorer.
- [ ] Validar no AAB e nos APKs gerados pela Play o alinhamento dos segmentos ELF das bibliotecas nativas.
- [ ] Executar o app em aparelho/emulador configurado com páginas de memória de 16 KiB.

Apps com código nativo precisam oferecer 64 bits e, ao mirar Android 15+, atender a páginas de [memória de 16 KiB](https://developer.android.com/guide/practices/page-sizes?hl=pt-BR). O zipalign aprovado no APK atual é apenas uma parte dessa validação.

### Critério de conclusão

- Nenhum crash bloqueador.
- Nenhuma perda de save durante atualização.
- Sem falha visual bloqueadora nos aparelhos-alvo.
- APK e AAB aprovados nas verificações locais.

## 7. Fase 3 — Colocar o APK online no Cloudflare

**Prazo:** 0,5 a 2 dias.  
**Custo de Pages + R2 esperado:** US$ 0/mês dentro dos free tiers. O save pode ficar no Free durante a alpha, mas o plano completo recomenda Workers Paid, a partir de US$ 5/mês, antes da beta pública.  
**Domínio:** R$ 0 apenas para alpha fechada em endereços temporários; para beta pública, reservar R$ 40–100/ano e usar domínio próprio no download.

### Por que Pages + R2

O APK atual tem 43,6 MiB e ultrapassa o limite de 25 MiB por asset do Pages. Portanto:

- Cloudflare Pages hospeda landing page, política, termos, créditos e changelog.
- Cloudflare R2 hospeda APKs, checksums e manifestos de versão.

Consulte os [limites do Pages](https://developers.cloudflare.com/pages/platform/limits/) e os [preços do R2](https://developers.cloudflare.com/r2/pricing/).

### 7.1 Estrutura do R2

- [ ] Ativar a assinatura R2 pelo checkout da Cloudflare; o free tier continua aplicável.
- [ ] Escolher armazenamento R2 Standard.
- [ ] Criar bucket mana-idle-releases.
- [ ] Manter escrita e listagem autenticadas; permitir leitura pública do APK somente pelo domínio de download.
- [ ] Publicar cada versão em caminho imutável:

~~~text
releases/0.1.9-alpha/mana-idle-0.1.9-alpha.apk
releases/0.1.9-alpha/sha256.txt
releases/0.1.9-alpha/manifest.json
latest.json
~~~

- [ ] Definir Content-Type como application/vnd.android.package-archive.
- [ ] Definir Content-Disposition como attachment no APK.
- [ ] Usar cache longo e immutable no arquivo versionado.
- [ ] Usar no-cache ou cache curto no latest.json.
- [ ] Publicar SHA-256 do arquivo, fingerprint SHA-256 do signer, tamanho, versionCode, versionName, data e notas.
- [ ] Conectar downloads.dominio.com a um domínio próprio antes de chamar a distribuição de beta pública.

O endereço r2.dev é útil para desenvolvimento, mas é limitado e não deve ser o endpoint final. A Cloudflare recomenda [domínio próprio para bucket público](https://developers.cloudflare.com/r2/buckets/public-buckets/).

### 7.2 Conteúdo da landing page

- [ ] Nome e apresentação do jogo.
- [ ] Selo “Beta pública”.
- [ ] Versão, data e changelog.
- [ ] Botão de download com tamanho do arquivo.
- [ ] SHA-256 e instrução simples para conferência.
- [ ] Requisitos: Android 7 ou superior e arm64.
- [ ] Instruções para permitir instalação apenas ao navegador usado.
- [ ] Aviso de que o Android/Play Protect pode analisar o APK.
- [ ] Explicação de que o save online exige ativação e código de recuperação; quem permanecer somente local perde o progresso ao desinstalar.
- [ ] Declaração clara de ausência de pagamentos e compras.
- [ ] Política de privacidade.
- [ ] Termos da beta.
- [ ] Créditos/licenças.
- [ ] E-mail de suporte.
- [ ] Link para feedback e relato de bugs.
- [ ] Fingerprint do certificado que deve assinar todas as atualizações.

### 7.3 Segurança operacional

- [ ] Token de R2 com escopo apenas no bucket de releases.
- [ ] Nenhum segredo no APK, site ou Git.
- [ ] Não permitir listagem pública do bucket.
- [ ] Fazer upload primeiro, conferir hash e só depois atualizar latest.json.
- [ ] Nunca sobrescrever um APK publicado; subir nova versão e novo versionCode.
- [ ] Testar o download em Wi-Fi e rede móvel.

### Custos do R2

O free tier inclui 10 GB-mês, 1 milhão de operações Class A e 10 milhões de Class B, com egress gratuito. Excedentes Standard custam US$ 0,015/GB-mês, US$ 4,50 por milhão Class A e US$ 0,36 por milhão Class B. Uma beta desse APK tende a ficar em US$ 0.

### Critério de conclusão

- URL HTTPS pública e estável.
- APK baixa e instala.
- Hash publicado confere.
- Políticas, créditos e suporte acessíveis.
- Nenhuma transação financeira possível.

## 8. Fase 4 — Beta direta

**Prazo:** 7 a 14 dias.  
**Grupo recomendado:** 10 a 30 testadores reais.  
**Custo:** R$ 0 com voluntários; incentivos opcionais de R$ 0–100 por pessoa, sem comprar avaliações ou atividade falsa.

Esta beta direta ajuda a encontrar bugs, mas **não conta** para a exigência da faixa fechada da Google Play.

### Como executar

- [ ] Formar grupo com diferentes versões Android e tamanhos de tela.
- [ ] Enviar link único da landing, nunca apenas o arquivo solto.
- [ ] Entregar roteiro de teste de 20–30 minutos e teste de retorno após 24 horas.
- [ ] Pedir versão Android, modelo, passos para reproduzir e captura de tela.
- [ ] Registrar bugs por severidade: bloqueador, alto, médio e baixo.
- [ ] Publicar no máximo uma atualização planejada por dia.
- [ ] Conferir atualização sobre a versão anterior em cada release.
- [ ] Manter changelog e hash de todas as builds.

### Critérios para sair da beta direta

- Zero bugs bloqueadores abertos.
- Zero perda de save em atualização.
- Smoke tests estáveis.
- Pelo menos 10 testadores concluíram o roteiro.
- Fluxo principal compreensível sem ajuda.
- AAB correspondente à build aprovada está pronto.

## 9. Fase 5 — Preparar a Google Play

**Prazo ativo:** 2 a 4 dias.  
**Custo:** R$ 0 se produzido internamente; artes terceirizadas podem custar R$ 300–1.500.

### 9.1 Artefato

- [ ] Gerar um AAB release candidate atualizado; o primeiro AAB técnico já foi usado na Fase 1 para fixar a assinatura.
- [ ] Incrementar versionCode.
- [ ] Assinar com upload key.
- [ ] Enviar à faixa interna já configurada; não recriar nem trocar Play App Signing.
- [ ] Conferir dispositivos, APKs gerados e avisos no App Bundle Explorer.

Apps novos são publicados como AAB e usam Play App Signing. Referências: [upload do bundle](https://developer.android.com/studio/publish/upload-bundle) e [requisito do AAB](https://support.google.com/googleplay/android-developer/answer/9844679?hl=en).

### 9.2 Página da loja

- [ ] Nome de até 30 caracteres.
- [ ] Descrição curta de até 80 caracteres.
- [ ] Descrição completa de até 4.000 caracteres.
- [ ] Ícone PNG 512×512.
- [ ] Feature graphic 1024×500.
- [ ] Pelo menos duas screenshots; para jogo, preparar preferencialmente três ou mais capturas reais em alta resolução, retrato ou paisagem conforme a experiência.
- [ ] E-mail de suporte.
- [ ] URL da política de privacidade.
- [ ] Categoria game e tags coerentes.
- [ ] Não citar preços, promoções, ranking ou recursos ainda inexistentes.

Veja os [requisitos gráficos oficiais](https://support.google.com/googleplay/android-developer/answer/9866151?hl=en).

### 9.3 Políticas e formulários

- [ ] Política de privacidade HTTPS pública, não editável por visitantes e não em PDF.
- [ ] Link da política também dentro do app.
- [ ] Data Safety preenchido conforme o código e todos os SDKs.
- [ ] Declaração “contém anúncios: não” na primeira versão, se nenhum SDK/anúncio for incluído.
- [ ] Questionário IARC de classificação indicativa.
- [ ] Público-alvo e faixas etárias definidos de acordo com o conteúdo real.
- [ ] Declaração de acesso ao app; sem login, informar que todo conteúdo é acessível.
- [ ] Revisar o texto bíblico e o humor ao responder perguntas sobre violência, temas adultos e conteúdo religioso.

Mesmo um app que não coleta dados precisa de política e formulário. Referências: [User Data](https://support.google.com/googleplay/android-developer/answer/10144311?hl=en), [Data Safety](https://support.google.com/googleplay/android-developer/answer/10787469?hl=en) e [classificação de conteúdo](https://support.google.com/googleplay/android-developer/answer/9898843?hl=en).

### Público infantil

Não classificar o jogo como dirigido a crianças apenas por ter tema bíblico. A faixa deve refletir o produto real. Se qualquer faixa infantil for selecionada, passam a valer as [políticas Families](https://support.google.com/googleplay/android-developer/answer/9893335?hl=en), inclusive restrições adicionais para anúncios e dados.

### Contas

O MVP não tem conta, então exclusão de conta não se aplica. Se cadastro ou login forem adicionados no futuro, será obrigatório oferecer exclusão dentro do app e também por uma página web, conforme a [política de exclusão de conta](https://support.google.com/googleplay/android-developer/answer/13327111?hl=en).

### Critério de conclusão

- Listing completo.
- AAB sem bloqueios nos checks.
- Data Safety corresponde exatamente à build.
- Política acessível dentro e fora do app.
- Teste interno disponível.

## 10. Fase 6 — Testes na Google Play

### 10.1 Teste interno

**Prazo:** 2 a 5 dias.  
**Capacidade:** até 100 testadores.

Esta é a rodada formal da release candidate. A faixa interna já terá sido criada tecnicamente antes da beta pública para resolver a assinatura.

- [ ] Subir o AAB aprovado.
- [ ] Instalar pelo link da Play em aparelhos físicos.
- [ ] Rodar o mesmo roteiro da beta direta.
- [ ] Conferir atualização do APK direto para a build Play.
- [ ] Analisar pre-launch report, crashes e ANRs.
- [ ] Corrigir todos os bloqueios de política e compatibilidade.

### 10.2 Teste fechado obrigatório para conta pessoal nova

**Prazo mínimo:** 14 dias contínuos.

- [ ] Convidar 15–20 testadores reais para manter margem acima do mínimo.
- [ ] Confirmar que pelo menos 12 permaneceram inscritos continuamente durante os 14 dias.
- [ ] Coletar feedback e registrar o que foi corrigido.
- [ ] Manter comunicação e engajamento; não usar fazenda de testadores.
- [ ] Após 14 dias, solicitar acesso à produção.
- [ ] Reservar até 7 dias ou mais para a análise do pedido.

A exigência oficial está em [Testing requirements for new personal developer accounts](https://support.google.com/googleplay/android-developer/answer/14151465?hl=en).

Convidar exatamente 12 é arriscado: uma desistência pode impedir a elegibilidade. A beta direta do R2 não substitui esta etapa.

### Critério de conclusão

- Requisitos de teste cumpridos.
- Acesso à produção aprovado.
- Nenhum erro bloqueador no pre-launch report.
- Release candidate congelada.

## 11. Fase 7 — Produção na Google Play, ainda sem dinheiro

**Prazo de revisão:** planejar até 7 dias ou mais.  
**Custo adicional Google:** R$ 0.

### Como lançar

- [ ] Criar AAB 1.0.0 com versionCode maior.
- [ ] Continuar sem Billing, checkout, doação, anúncios reais ou produtos.
- [ ] Ativar managed publishing para controlar a data.
- [ ] Publicar por rollout: 10% → 25% → 50% → 100%.
- [ ] Manter cada estágio por pelo menos 24–48 horas, conforme volume.
- [ ] Monitorar crashes, ANRs, avaliações e tickets.
- [ ] Pausar o rollout se surgir perda de save, crash de inicialização ou regressão grave.
- [ ] Manter a 1.0 sem transações por 7–14 dias depois de chegar a 100%.

O Google explica os [prazos de revisão](https://support.google.com/googleplay/android-developer/answer/9859751?hl=en).

Depois que o app é oferecido gratuitamente, ele não pode virar download pago. Manter o Maná Idle gratuito e, se desejado, monetizar depois com compras internas; cobrar pelo download exigiria outro app/pacote. Consulte a [regra de preço e distribuição](https://support.google.com/googleplay/android-developer/answer/6334373?hl=pt-BR).

### Critério de conclusão

- 100% do rollout alcançado.
- Sete dias sem incidente crítico.
- Base técnica pronta para a próxima release.

## 12. Fase 8 — Monetização somente depois da Play

Esta fase não deve bloquear o lançamento 1.0 e não deve ser incluída no APK direto.

### 12.1 Regra de produto

- Produtos digitais, como gemas, boosts, remoção de anúncios ou assinaturas, usam Google Play Billing no app distribuído pela Play.
- Não usar PIX, checkout web ou pagamento direto dentro do app para esses bens digitais.
- Não chamar venda de moeda virtual de “doação”. Doação filantrópica real exige análise jurídica, fiscal e da política Google separada.
- Fazer apenas testes sandbox com license testers antes de ativar valores reais.

Veja a [política de pagamentos](https://support.google.com/googleplay/android-developer/answer/9858738?hl=en).

### 12.2 Implementação recomendada

Antes de vender gemas, resolver quatro decisões:

- qual identidade vincula jogador, carteira e compras: conta própria, Play Games ou outra identidade recuperável;
- como recuperar compras/saldo após reinstalação e em um segundo aparelho;
- tornar saldo e gastos premium server-authoritative, pois o JSON local é editável;
- política para conflitos, gasto duplo, reembolso e perda de acesso.

Uma identidade apenas por instalação não recupera consumíveis depois da reinstalação. Se essa decisão não estiver resolvida, não ativar a venda de gemas.

1. Criar uma release 1.1 em canal interno.
2. Ativar Gradle e integrar plugin Godot compatível com Play Billing.
3. Usar Play Billing Library 9.1.x ou a versão estável aceita no momento do envio.
4. Criar produtos consumíveis, por exemplo gemas_80, gemas_500 e gemas_1200.
5. Manter a permissão de internet já necessária ao save online.
6. Estender o Cloudflare Worker existente com validação de compra e proteção contra replay.
7. Guardar a credencial da Google Play Developer API como secret do Worker.
8. Adicionar ao D1 existente recibos Play e restrição UNIQUE(token_hash); a carteira gratuita já deve estar separada do JSON conforme o plano de cloud save.
9. O app envia o purchase token e sua identidade ao Worker por HTTPS.
10. O Worker valida produto, pacote, estado e identidade na Google Play Developer API.
11. Em uma operação atômica, inserir o token exclusivo e creditar a carteira somente se o INSERT tiver sucesso.
12. Tratar o saldo local apenas como cache; toda concessão e gasto premium dependem do servidor.
13. Reter o token original de forma protegida somente pelo tempo/finalidade necessários; apenas o hash pode não bastar para reconsulta.
14. Reconhecer ou consumir a compra somente depois da concessão durável e dentro do prazo exigido.
15. Integrar RTDN/Voided Purchases ou reconciliação periódica para reembolsos, chargebacks e compras anuladas.
16. Testar compra, cancelamento, reembolso, retry, replay, dois aparelhos, reinstalação, rede ausente e resposta duplicada.
17. Atualizar política, Data Safety e declaração de anúncios antes de produção.

A documentação oficial cobre [integração](https://developer.android.com/google/play/billing/integrate.html), [ciclo de versões](https://developer.android.com/google/play/billing/deprecation-faq) e [segurança/validação](https://developer.android.com/google/play/billing/security).

### 12.3 D1 ou PostgreSQL

**Escolha recomendada para o primeiro backend: D1.**

Usar D1 para:

- contas, sessões, dispositivos e cloud save;
- ledger de recibos;
- idempotência;
- feature flags simples;
- configuração remota;
- carteira e entitlements.

Vantagens: quase nenhuma operação, Time Travel automático e custo inicial baixo. D1 usa semântica SQLite, executa cada banco primário de forma single-threaded e tem limite de 500 MB por banco no Free e 10 GB por banco no Paid. Time Travel retém 7 dias no Free e 30 no Paid.

Usar PostgreSQL da VPS apenas se surgir uma destas necessidades:

- SQL avançado ou ecossistema PostgreSQL já obrigatório;
- uma base lógica que pode ultrapassar 10 GB;
- relatórios e operações administrativas mais complexos;
- cloud save/contas com modelo mais rico;
- necessidade de portabilidade total para fora do D1.

Para PostgreSQL, escolher um método de conectividade em vez de misturar alternativas:

~~~text
Opção A — se a conectividade privada for aceita no estado vigente:
App -> Worker -> Hyperdrive -> Access/service token -> Tunnel
    -> cloudflared -> PostgreSQL com TLS

Opção B — se não quisermos depender de recurso privado em beta:
App -> API HTTPS na VPS atrás de Cloudflare Tunnel -> PostgreSQL local
~~~

Nunca conectar o APK diretamente à porta 5432. Fechar a porta pública, usar usuário mínimo, TLS, patching, monitoramento, backups e testes de restauração. A integração privada Hyperdrive + Tunnel/Workers VPC continua em beta nesta data e deve ser reconferida; a documentação atual do Hyperdrive lista PostgreSQL 9–17.x. Uma única VPS continua sendo ponto único de falha. Referências: [Hyperdrive](https://developers.cloudflare.com/hyperdrive/get-started/), [compatibilidade](https://developers.cloudflare.com/hyperdrive/reference/supported-databases-and-features/) e [conexão privada](https://developers.cloudflare.com/hyperdrive/configuration/connect-to-private-database/).

Não manter D1 e PostgreSQL em escrita dupla sem necessidade; isso duplica migrations, risco e suporte.

## 13. Custos esperados

Valores Cloudflare/Google foram conferidos em 15 de julho de 2026. Conversões para reais são reservas arredondadas, não cotação.

| Item | Quando | Obrigatório? | Custo esperado |
|---|---|---:|---:|
| Play Console | Fase 0 | Sim | US$ 25 uma vez; reservar R$ 150–200 |
| D‑U‑N‑S | Conta de organização | Só organização | US$ 0 |
| Cloudflare Pages | APK online | Sim | US$ 0 |
| Cloudflare R2 | APK online | Sim | US$ 0 dentro do free tier |
| SSL, DNS e CDN Cloudflare Free | APK online | Sim | US$ 0 |
| Domínio próprio | Beta pública/produção | Sim para download público em R2 | R$ 40–100 por ano |
| VPS atual | Só se Postgres entrar | Não no MVP | Custo já contratado |
| 15–20 convidados/12 contínuos | Conta pessoal nova | Sim | R$ 0 com voluntários |
| Incentivo legítimo a testadores | Testes | Opcional | R$ 0–1.200 |
| Artes da Play | Listing | Sim | R$ 0 interno ou R$ 300–1.500 terceirizado |
| Aparelho Android de teste | QA | Sim | R$ 0 existente ou R$ 700–2.500 |
| Política/revisão jurídica | Pré-Play | Política sim; advogado opcional | R$ 0 interno ou R$ 500–3.000 |
| Workers + D1 Free | Desenvolvimento/alpha do save | Sim inicialmente | US$ 0 dentro dos limites diários |
| Workers Paid + D1 | Antes da beta pública com save prometido | Recomendado | A partir de US$ 5/mês; reservar R$ 30–40/mês |
| Excedentes D1 | Pós-escala | Variável | Conforme linhas e armazenamento |
| Taxa Google sobre vendas | Só após venda | Sim quando houver receita | 0 sem vendas; 15% no primeiro US$ 1 milhão somente após inscrição/aprovação no tier reduzido, e 30% acima |
| Chargebacks | Só após venda | Variável | Custos compartilhados passam a valer em 3/08/2026; reconferir a regra antes de ativar vendas |

Preços oficiais: [Workers](https://developers.cloudflare.com/workers/platform/pricing/), [D1](https://developers.cloudflare.com/d1/platform/pricing/), [R2](https://developers.cloudflare.com/r2/pricing/) e [tier de serviço de 15% da Play](https://support.google.com/googleplay/android-developer/answer/10632485?hl=en).

Workers Paid inclui 10 milhões de requests e 30 milhões de CPU-ms por mês; excedentes custam US$ 0,30 por milhão de requests e US$ 0,02 por milhão de CPU-ms. D1 Paid inclui 25 bilhões de linhas lidas, 50 milhões escritas e 5 GB; excedentes custam US$ 0,001 por milhão de linhas lidas, US$ 1 por milhão escritas e US$ 0,75/GB-mês. Hyperdrive oferece 100 mil queries/dia no Free e queries sem cobrança específica no Paid. Para chargebacks, consultar a [regra vigente a partir de agosto de 2026](https://support.google.com/googleplay/android-developer/answer/17068375?hl=pt-BR).

### Faixas de orçamento

**Caminho enxuto, trabalho próprio:**

- Alpha fechada em endereço temporário: R$ 0 de domínio/infraestrutura.
- Beta pública com domínio: R$ 40–100.
- Play Console: R$ 150–200 reservados.
- Total inicial provável até beta pública + Play, incluindo o primeiro mês do Worker Paid: R$ 220–340.
- Mensal durante desenvolvimento/alpha do backend: R$ 0 dentro do Free.
- Mensal a partir da beta pública: reservar R$ 30–40 para Workers Paid + D1.

**Caminho recomendado com domínio e alguma terceirização:**

- Conta + domínio + artes/revisão pontual: aproximadamente R$ 500–3.500.
- Mensal antes de monetização: aproximadamente R$ 30–40 para o save online público.

**Depois da monetização:**

- Cloudflare: continua a partir de US$ 5/mês no começo, mais excedentes somente se houver escala.
- VPS: custo atual, se utilizada.
- Google: percentual apenas sobre vendas.
- Engenharia de Billing + validação: estimar 40–80 horas entre implementação, QA e casos de reembolso.

## 14. Cronograma realista

### Conta pessoal nova

| Semana | Resultado esperado |
|---|---|
| 1 | Conta Play iniciada; assinatura resolvida; Worker, D1 e migrations iniciados |
| 2 | Identidade, recovery, GET/PUT e validação do save |
| 3 | Integração Godot, modo offline, conflitos e exclusão |
| 4 | Carteira gratuita recomendada, hardening, Pages + R2 e QA |
| 5 | Alpha fechada do APK e início do teste interno Play |
| 6 | Beta direta; correções; listing e formulários Play |
| 7 | Início do teste fechado Play e observação do backend Paid |
| 8 | Continuação dos 14 dias de teste fechado |
| 9 | Pedido de acesso à produção e correções finais |
| 10 | Revisão e rollout inicial |
| 11 | Rollout completo e observação sem monetização |

Meta prudente: **7 a 11 semanas** até produção, com parte do preparo Play em paralelo ao backend. A exigência de 14 dias é calendário, não horas de trabalho.

### Organização

Com D‑U‑N‑S e verificação prontos, o processo pode cair para 5–9 semanas. Sem D‑U‑N‑S, acrescentar até 30 dias.

## 15. Servidor, banco e gatilhos de crescimento

O cloud save solicitado já é a necessidade concreta para adicionar servidor e banco antes da Play. A decisão atual é Worker + D1, mantendo o jogo offline-first. O desenho detalhado, incluindo autenticação, conflitos, exclusão e gemas, está em [PLANO_CLOUD_SAVE.md](./PLANO_CLOUD_SAVE.md).

PostgreSQL da VPS fica fora do MVP. Reavaliá-lo somente se D1 deixar de atender por volume, consultas complexas, ecossistema obrigatório ou requisito operacional concreto. Não manter os dois em escrita dupla.

### Gatilhos para sair do Cloudflare Free

Ativar Workers Paid antes de:

- prometer o save online numa beta pública;
- chegar perto de 100 mil requests dinâmicas por dia;
- D1 se aproximar de 100 mil escritas ou 5 milhões de linhas lidas por dia;
- precisar de Logpush ou 30 dias de Time Travel;
- o custo de indisponibilidade ser maior que US$ 5/mês.

## 16. Checklist de liberação

### APK online

- [ ] Conta Play/assinatura resolvida.
- [ ] Pacote congelado.
- [ ] APK release, nunca debug.
- [ ] versionCode novo.
- [ ] targetSdk 36 explícito.
- [ ] arm64, segmentos ELF e execução em ambiente de 16 KiB validados.
- [ ] Sem preços, compras, doações, checkout ou anúncios reais.
- [ ] Vídeos simulados removidos ou renomeados honestamente.
- [ ] Atualização preserva save.
- [ ] Worker + D1 do save concluídos conforme PLANO_CLOUD_SAVE.md.
- [ ] Save local funciona com backend indisponível.
- [ ] Recovery code, segundo aparelho e conflito testados.
- [ ] Exclusão dentro do app e pela web publicada.
- [ ] Contas cloud usam gemas server-authoritative; saldo local-only não será transferido para a futura carteira paga.
- [ ] Workers Paid ativo antes de prometer save online publicamente.
- [ ] Política, créditos e suporte publicados.
- [ ] APK universal assinado pela Play em R2, com SHA-256 do arquivo e do signer.
- [ ] Download R2 em domínio próprio.
- [ ] Landing em Pages.
- [ ] Teste de instalação e atualização em aparelhos físicos.

### Google Play

- [ ] AAB release.
- [ ] Play App Signing ativo.
- [ ] Ícone, feature graphic e screenshots.
- [ ] Listing completo.
- [ ] Política de privacidade.
- [ ] Data Safety.
- [ ] IARC.
- [ ] Público-alvo/Families revisado.
- [ ] Declaração de anúncios correta.
- [ ] Teste interno aprovado.
- [ ] Pelo menos 12 testadores contínuos por 14 dias, com 15–20 convidados, quando aplicável.
- [ ] Pre-launch report sem bloqueios.
- [ ] Produção 1.0 ainda sem transações.
- [ ] Rollout gradual e monitoramento.

### Pós-Play com dinheiro

- [ ] Merchant profile verificado.
- [ ] Play Billing em versão aceita.
- [ ] Produtos criados no Console.
- [ ] Identidade recuperável e carteira premium server-authoritative.
- [ ] Worker valida purchase token.
- [ ] D1 usa UNIQUE(token_hash) e concessão atômica para impedir crédito duplicado.
- [ ] Compra é reconhecida/consumida no prazo.
- [ ] RTDN/reconciliação de compras anuladas configurada.
- [ ] Reembolso, chargeback, reinstalação e segundo aparelho testados.
- [ ] Política e Data Safety atualizados.
- [ ] Apenas sandbox antes da ativação real.

## 17. Próximas cinco ações

1. Congelar domínio, UX de recovery e política das gemas no PLANO_CLOUD_SAVE.md.
2. Criar o esqueleto do Worker, os D1 de local/staging e a primeira migration.
3. Em paralelo, confirmar o tipo de conta Play e fechar a estratégia de assinatura.
4. Integrar o cloud save no Godot sem alterar o autosave local de 10 segundos.
5. Liberar alpha interna; Pages + R2 e APK público entram apenas após os testes de conflito, recuperação, exclusão e atualização.
