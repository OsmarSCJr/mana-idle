# Cliente de save online (Godot)

O jogo continua **offline-first**. `SaveSystem` confirma `user://save.json` e o
backup local antes de `CloudSave` considerar qualquer upload. Conta e nuvem são
opcionais.

## Configuração de staging

O projeto está apontando para a API de homologação publicada em 16/07/2026:

```ini
[cloud_save]
api_base_url="https://mana-save-staging.spankk-bolter.workers.dev/v1"
```

O autoload `LiveOps` deriva `GET /config` dessa mesma URL; não existe chave ou secret de configuração no APK.

Antes do build destinado à Google Play, substitua esse endereço pelo domínio
HTTPS de produção. Não adicione token, recovery code, pepper ou outra credencial
ao projeto: o APK usa somente a URL pública e a sessão opaca emitida pela API.

O preset Android precisa incluir `android.permission.INTERNET`. O preset local
ignorado pelo Git já pode receber essa permissão; qualquer preset versionado deve
ser sanitizado e nunca conter caminho, usuário ou senha de keystore.

## Arquivos privados em `user://`

- `save.json`, `.tmp` e `.bak`: progresso local;
- `cloud_auth.json`, `.tmp` e `.bak`: instalação e sessão (sem recovery code);
- `cloud_sync_meta.json`: revisão, ETag, dirty, sequência e mutação em voo;
- `liveops_config.json`: último envelope remoto validado, ETag e horário de recebimento;
- `cloud_pending/<mutation>.json`: envelope exato reutilizado em retry;
- `cloud_conflicts/<id>/`: candidatos local/nuvem e manifesto imutável.

O token fica no sandbox privado nesta alpha. A troca por Android Keystore é um
hardening obrigatório antes de prometer proteção equivalente a credencial de
alto valor. O recovery code nunca é persistido pelo jogo e só é exibido uma vez.

## Comportamento

- autosave local: 10 s;
- upload normal: debounce de 2 min e intervalo mínimo de 5 min;
- retry: 5 s, 15 s, 60 s, 5 min e 15 min, com jitter;
- `If-Match` + ETag impedem sobrescrita silenciosa;
- o mesmo `mutationId` e os mesmos bytes sobrevivem a reinício;
- ACK antigo só limpa `dirty` se o hash local atual ainda for o confirmado;
- conflito preserva os dois candidatos e exige escolha explícita;
- `401`, `412`, `413`, `422`, `429` e `5xx` nunca apagam o pendente.

## LiveOps e campanhas

- o jogo carrega defaults seguros imediatamente e tenta revalidar a configuração no início;
- o cache validado permite jogar offline e nunca bloqueia a abertura por falha de rede;
- a configuração é atualizada a cada 15 minutos e antes de calcular ganhos ao retomar o app;
- `X-Server-Now` calibra o relógio também nas respostas `304`;
- balanceamento remoto cobre curva de custo, prestígio, marcos, impulsos e recompensas gratuitas;
- campanhas podem multiplicar produção global, offline, manual, fé de estudos, gemas gratuitas e geradores específicos;
- o cálculo offline é segmentado pelas versões efetivamente publicadas nos últimos 15 dias e pelas expirações de impulsos locais;
- fatores combinados têm limites finitos e o cliente rejeita envelopes desconhecidos ou inválidos;
- o servidor envia somente dados tipados; não há script, asset remoto ou execução arbitrária.

## Testes locais

Sempre use `--smoke-test`. A flag é lida pelos autoloads antes da primeira cena e
impede leitura/escrita do save, identidade, metadados e conflitos reais do usuário.

```powershell
godot --headless --path . res://scenes/SmokeTest.tscn -- --smoke-test
godot --headless --path . res://scenes/StudySmokeTest.tscn -- --smoke-test
godot --headless --path . res://scenes/UISmokeTest.tscn -- --smoke-test
godot --headless --path . res://scenes/CloudSmokeTest.tscn -- --smoke-test
```

`CloudSmokeTest` cobre serialização determinística, SHA-256, UUID v4, os 1.189
capítulos bíblicos, duas promoções atômicas consecutivas com `.bak`, bloqueio
local do domínio `.invalid`, isolamento efêmero dos autoloads, defaults/cache
LiveOps, validação, versões históricas, fronteiras e multiplicadores offline.
