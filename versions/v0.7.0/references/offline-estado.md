<!-- cross-skill: iam.md -> schematize-engineering -->
<!-- cross-skill: offline-sync.md -> schematize-mobile -->
# Offline-first & estado local — o dado vive na máquina do usuário

> No desktop **o normal é offline**: o app abre e funciona sem rede, e o estado do usuário mora na
> **máquina dele**. Isso impõe disciplina de **dados** (é `schematize-data`/`schematize-database`
> aplicada localmente): schema versionado, migração **reversível**, backup, e dir **certo por SO**.
> Perder o estado do usuário num update é o pior pecado de um app local.

## 1. Onde gravar — dirs por SO (nunca "ao lado do binário")

Grave nos diretórios que cada SO reserva pro app — **nunca** ao lado do executável (read-only em
pacote), nunca em `/root`, nunca espalhado no `$HOME`:

| Tipo | Linux (XDG) | macOS | Windows |
|---|---|---|---|
| **Config** | `$XDG_CONFIG_HOME` (`~/.config/<app>`) | **`~/Library/Application Support/<app>`** (ver nota) | `%APPDATA%\<app>` |
| **Dados** | `$XDG_DATA_HOME` (`~/.local/share/<app>`) | `~/Library/Application Support/<app>` | `%APPDATA%\<app>` |
| **Cache** | `$XDG_CACHE_HOME` (`~/.cache/<app>`) | `~/Library/Caches/<app>` | `%LOCALAPPDATA%\<app>\Cache` |
| **Estado/log** | `$XDG_STATE_HOME` (`~/.local/state/<app>`) | `~/Library/Logs/<app>` | `%LOCALAPPDATA%` |

> **macOS: `~/Library/Preferences` é território do `cfprefsd`, não seu.** Aquele diretório é o store
> do sistema de preferências (`NSUserDefaults`/`CFPreferences`), servido por um **daemon que mantém
> cache em memória e escreve quando quer**. Consequências práticas de gravar seu próprio arquivo
> ali: o que você escreve pode ser **sobrescrito** pelo daemon, o que você lê pode estar **velho**, e
> `defaults read` pode discordar do conteúdo do arquivo no disco. Se você quer o serviço de
> preferências do sistema, **use a API** (`NSUserDefaults`) e deixe o caminho com ele; se você quer
> **seu** arquivo de config (TOML/JSON versionado, editável pelo usuário, copiável entre máquinas),
> ele vai em **`~/Library/Application Support/<app>/`** — que é onde o SO espera dados de aplicação.
> O erro é o meio-termo: um `config.toml` seu dentro de `Preferences/`.

- Use uma **abstração de dirs** (ex.: crate `directories`/`dirs` em Rust) — não hard-code paths.
- **Respeite `$XDG_*`** quando setado; caia nos defaults quando não.
- **Rodou como root/sudo?** Resolva os dirs **do usuário real** (`privilegio-fs.md`), não do root —
  senão o dado do usuário vai parar em `/root/.config` e "some" quando ele roda normal. O padrão que
  funciona: **uma função central** que resolve os caminhos (nunca `$HOME` espalhado pelo código) e,
  quando o layout muda de lugar, **ler os dois e migrar automaticamente** — o usuário não deveria
  saber que a pasta mudou de nome.

## 2. Estado local, cache e a diferença entre eles

- **Estado (durável):** o que o usuário criou/configurou. **Nunca** descartável sem consentimento;
  entra no backup. Migração cuidadosa.
- **Cache (descartável):** derivável de novo; apagar só custa reprocessar. Pode ser limpo à
  vontade; **não** ponha aqui nada que o usuário perderia.
- **Não confunda:** meter estado em `Cache/` faz o app "esquecer" o usuário quando o SO limpa cache.
  Meter cache em backup incha o backup. Separe por diretório.

## 3. Migração de schema local — reversível, versionada, à prova de update

O app novo abre o banco/arquivo do app **velho** (o usuário atualizou). Logo:

- **Versão do schema gravada** no próprio store (tabela `schema_version`/campo de versão). Ao abrir,
  o app **migra pra frente** do que encontrar até a versão atual — passos idempotentes e ordenados
  (mesma disciplina expand-contract da `schematize-database`).
- **Reversível/segura:** migração que pode falhar no meio **não** deve deixar o store corrompido —
  faça em transação, ou **backup automático antes de migrar** (item 4) pra poder voltar. Nunca
  `DROP`/rename destrutivo num passo (`schematize-data`).
- **Compatibilidade com downgrade:** se o updater faz rollback (`auto-update.md`) pra versão
  anterior, o schema migrado **pra frente** pode não abrir na versão antiga → por isso o **backup
  pré-migração** é o que permite o rollback real. Registre a política no ADR.
- **Teste de migração:** carregue um store de versão N-2, N-1 e migre → tem de abrir íntegro
  (`testes-locais.md`).

## 4. Backup e integridade

- **Backup automático antes de operação destrutiva** (migração de schema, import grande): cópia
  datada no dir de dados/estado, com retenção. O usuário nunca deveria perder tudo porque um update
  migrou errado.
- **Escrita atômica:** grave em temp + `rename` atômico (não sobrescreva o arquivo bom no meio da
  escrita — queda de energia corrompe). Para SQLite, WAL + `fsync` na hora certa.
- **Export/import** do estado do usuário (formato aberto e documentado) — dá portabilidade e é o
  backup manual do usuário leigo ("exportar meus dados").
- **Detecte corrupção** e **recupere com graça** (abre backup, avisa sem culpar) — `prever macacos`:
  arquivo corrompido não pode virar crash-loop.

## 5. Sync eventual (quando há backend)

App local **pode** sincronizar com backend — e aí a disciplina é a mesma do `schematize-mobile`
(`offline-sync.md`), porque o problema é idêntico:

- **A UI lê do LOCAL**; a rede **alimenta** o local. Rede caindo não trava a tela.
- **Escrita otimista + outbox durável** (mutação persistida com `op_id`/idempotência) que sobrevive a
  fechar o app; sync **delta** com tombstones; **resolução de conflito explícita** (ADR:
  LWW/merge/CRDT/servidor-autoritativo). **Nenhuma escrita do usuário some em silêncio.**
- **Servidor é a fonte de verdade** pra dado compartilhado; authz sempre no servidor (`iam.md`).
- Detalhe operacional completo: reutilize `schematize-mobile/offline-sync.md` — o piso é o mesmo.

## 6. DoD de estado local

- [ ] dados/config/cache nos **dirs certos por SO** (XDG/`~/Library`/`%APPDATA%`), resolvidos pro
      **usuário real** mesmo sob sudo;
- [ ] **estado ≠ cache** separados (limpar cache não apaga o usuário);
- [ ] schema **versionado** + migração **reversível/testada** (abre store de versão anterior);
- [ ] **backup automático** antes de migração destrutiva; escrita **atômica**;
- [ ] **export/import** do estado; corrupção **recuperada** sem crash-loop;
- [ ] se há sync: outbox durável, delta, conflito explícito, servidor autoritativo (herda
      `offline-sync.md`).
