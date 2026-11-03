---
name: schematize-desktop
metadata:
  version: 0.6.0
description: >-
  App desktop/nativo: toolkit de GUI (Slint, Tauri), empacotamento cross-OS, auto-update, estado local, privilégio. Use ao revisar app desktop, instalador, updater ou tauri.conf.json.
---

# Engenharia de software local/nativo/desktop da casa (schematize-desktop)

Disciplina normativa para **software que roda NA MÁQUINA do usuário** — apps de desktop nativos,
GUIs, CLIs com interface, instaladores, updaters, daemons locais. A tese é a mesma das irmãs
(`schematize-mobile`, `schematize-web`): o **piso da casa não muda**. Segurança, IAM, testes,
operação, Definition of Done (§35), archive (§28), índice/MAPA (§39) são **os mesmos** de qualquer
software da casa. O que o desktop acrescenta é o **como**, sob três verdades novas:

1. **Não há servidor pra segurar a barra.** No web, o servidor é a fronteira de confiança; no
   desktop, o binário É o produto e roda no computador do adversário. Segredo embutido é segredo
   entregue; autorização "no cliente" é sugestão.
2. **O ambiente é caótico e cada SO é diferente.** Linux/macOS/Windows divergem em path, processo,
   launcher, servidor gráfico, fontes e privilégio. Rodou por menu do desktop, por `sudo`, por SSH,
   com `PATH` mínimo, com toolchain ausente — tudo é caminho real de um usuário real.
3. **O usuário é leigo e não tem quem o socorra.** Não há suporte on-call atrás do app instalado.
   O software **se adapta e conserta sozinho**, ou vira lixo desinstalado. Edge case que um leigo
   atinge é **BUG do software, não erro do usuário**.

Esta skill especializa a `schematize-engineering` (a base agnóstica) para esse recorte, **sem
afrouxar nenhum piso**. Um app local não é ilha: quando fala com backend, delega authz e segredo a
um serviço do **rol sancionado** (Go/Rust/Elixir/C#/Zig/Ruby) e ao **IAM como app separada** em
`auth.<domain>` (`iam.md`). O binário local é conveniência de UX, nunca o guardião do segredo.

> **Toolkits:** o rol, o viés (Slint default; egui não como principal) e a licença de cada um moram em `references/toolkits-gui.md` (dono único). O `schematize-updater` é o modelo de updater híbrido (binário|fonte) desacoplado.

**Versão:** skill `schematize-desktop` v0.6.0. Changelog em `CHANGELOG.md`.

> <!-- herdado:engineering/pisos-22-29:bloco -->**Herda os pisos 22–29 da `schematize-engineering`** (texto completo em `assets/CLAUDE.md` dela): 22 tudo no git — sem remote, push falho ou HEAD≠origin a demanda NÃO se conclui; 23 deploy só do git (VETADO scp/rsync/tar|ssh/docker save|load/git bundle); 24 o ops é o gate da IA — a IA nunca muda a VPS direto nem escreve SQL, só operação nomeada (`ssh vps "ops <op>"`); 25 sem agents inúteis (entregou, morreu); 26 relatório a cada 30 min e handoff a cada 6 h; 27 CI remoto só antes do hml, a pedido ou em tag (`workflow_dispatch` + `hml-*`/`v*`; VETADO `pull_request`, `push` em branch, `workflow_run`, cron sem justificativa); 28 microserviço autônomo (fila durável + 7 testes de resiliência); 29 build/teste na máquina dev/hml quando existe (ponte só no workspace de build, nunca prd) + higiene (`scripts/higiene.sh`).<!-- /herdado -->

## Comandos (Claude Code)

Digite `/desktop-help` pra ver todos. Em resumo:

| Comando | O que faz |
|---|---|
| `/desktop-help` | lista todos os comandos do schematize-desktop |
| `/desktop-load` | carrega à força TODO o corpo normativo (toolkits, empacotamento, auto-update, estado local, privilégio/FS, cross-OS, privacidade/segurança, testes) e passa a aplicá-lo |
| `/desktop-toolkit` | força/audita a escolha de toolkit de GUI: **um só por produto**, viés Slint, egui não como principal, web-in-native só com justificativa; caça mistura de dois toolkits (fantasma de layout) |
| `/desktop-bridge` | audita a **ponte web↔nativo**: capabilities/permissions/scopes do **Tauri 2**, isolamento + sandbox + **fuses** do Electron — com gate que reprova |
| `/desktop-package` | audita/planeja empacotamento e distribuição cross-OS: .deb/.rpm/AppImage/Flatpak, .dmg+notarization, MSI/MSIX+assinatura; binário pré-compilado por SO vs fonte (híbrido); smoke test de pacote |
| `/desktop-update` | audita/planeja o auto-update **desacoplado**: pin/rollback, a armadilha do **git-dep no Cargo.lock** (`cargo update -p` explícito e commitado, build `--locked`), trocar binário em uso, **matar processo antigo** + re-exec |
| `/desktop-privilege` | audita privilégio e ambiente: root → **usuário real** (nunca /root), elevar só onde precisa, **.desktop Exec absoluto** (PATH do DE), single-instance por lock/socket, IPC local |
| `/desktop-claude` | cria ou mescla o `CLAUDE.md` sempre-on de desktop na raiz do repo |
| `/desktop-cc` | context compact: gera handoff no archive e roda `/compact` |
| `/desktop-handoff` | gera o handoff (context.md + checklist.md) sem compactar |

Os comandos ficam em `assets/commands/` e são instalados em `.claude/commands/`.

## Como usar esta skill

1. **Escolha o toolkit de GUI primeiro, com ADR** (`references/toolkits-gui.md`): **um só toolkit
   por produto**; viés da casa é **Slint (Rust)**; Tauri/GTK/Qt por fit; **egui não como
   principal**; web-in-native (Tauri/Electron) só com justificativa registrada. Misturar dois
   toolkits no mesmo produto é o **fantasma de layout** — vetado.
2. **Desenhe empacotamento e distribuição cross-OS** (`references/empacotamento.md`): formato certo
   por SO, **assinatura/notarization** onde a plataforma exige, e a decisão **binário pré-compilado
   por SO vs compilar-do-fonte** (o modelo **híbrido** do `schematize-updater`).
3. **Auto-update desacoplado** (`references/auto-update.md`): o updater é **separado do app** (app
   quebrado não trava o update; update quebrado não trava o app), com pin/rollback, e sem a
   armadilha do **git-dep pinado no `Cargo.lock`** (o binário embute versão VELHA se você não
   `cargo update -p <dep>` explícito e commitado; release `--locked`). Trocar binário em uso, **matar o processo antigo** e
   re-exec — só fechar a janela não basta.
4. **Offline-first & estado local** (`references/offline-estado.md`): dados na máquina do usuário,
   cache, sync eventual, **migração de schema local reversível**, backup, e **dirs XDG/por SO** (o
   layout `.schematize/` da casa é exemplo).
5. **Filesystem, permissões e PRIVILÉGIO** (`references/privilegio-fs.md`): rodou como root/sudo →
   **descubra o usuário REAL e grave PRA ELE** (nunca em `/root`); eleve **só onde precisa**;
   **`.desktop` `Exec` com path ABSOLUTO** (o PATH do DE não tem `~/.cargo/bin` → abre binário
   errado); **single-instance** por lock/socket; IPC local.
6. **Cross-OS de verdade** (`references/cross-os.md`): diferenças de path/processo/launcher, fontes
   com cobertura **CJK/árabe** (senão o render quebra), servidor gráfico **Wayland/X11**.
7. **Privacidade e segurança do software local** (`references/privacidade-seguranca.md`): **sem
   telemetria por padrão** (opt-in explícito, local-first); supply chain de deps nativas,
   **assinatura de binário**, e o piso herdado — **nunca segredo embutido no cliente**.
8. **Testes de app local** (`references/testes-locais.md`): GUI **headless/CI**, **smoke test de
   empacotamento** (o pacote instala e abre?), **teste de update ponta-a-ponta**.
9. **Não trabalhe de memória** — os pisos abaixo valem independentemente do reference carregado.

Mapa de references — leia o que casa com a tarefa:

| Tarefa | Reference |
|---|---|
| Escolher toolkit de GUI (Slint/Tauri/egui/GTK/Qt), um só por produto, web-in-native, arquitetura interna | `references/toolkits-gui.md` |
| **Web-in-native**: o modelo de **capacidades** do Tauri 2 (capability/permission/scope) e o de **isolamento** do Electron (contextIsolation/sandbox/fuses); a ponte como fronteira de confiança | `references/web-in-native.md` |
| Empacotar/distribuir por SO (.deb/.rpm/AppImage/Flatpak, .dmg/notarization, MSI/MSIX/assinatura), binário vs fonte (híbrido) | `references/empacotamento.md` |
| Auto-update desacoplado, pin/rollback, git-dep no Cargo.lock, trocar binário em uso, matar processo antigo, re-exec | `references/auto-update.md` |
| Estado local, cache, sync eventual, migração de schema local, backup, dirs XDG/por SO | `references/offline-estado.md` |
| Privilégio (root→usuário real), elevar só onde precisa, launcher com path absoluto, single-instance, IPC local | `references/privilegio-fs.md` |
| Diferenças Linux/macOS/Windows: path, processo, launcher, fontes CJK/árabe, Wayland/X11 | `references/cross-os.md` |
| Privacidade (sem telemetria por padrão, opt-in), supply chain de deps nativas, assinatura de binário, sem segredo no cliente | `references/privacidade-seguranca.md` |
| Testes: GUI headless/CI, smoke de empacotamento, update ponta-a-ponta | `references/testes-locais.md` |

## Pisos inegociáveis (VETADO — sem ADR de exceção)

Independente do reference, estes limites nunca são cruzados:

1. **O piso da casa é o MESMO — muda o "como".** Segurança, IAM, testes, ops, DoD (§35), archive
   (§28), índice (§39) valem inteiros. "É um app local, relaxa" **não** afrouxa nada; é o mesmo
   piso realizado na máquina do usuário, onde não há servidor pra corrigir depois.
2. **UX de massa — "prever o usuário leigo" ("prever macacos").** Piso herdado da
   `schematize-engineering` (v0.20.0), aqui **especializado pro desktop**. O software se **ADAPTA e
   NUNCA culpa o usuário** por como ele invocou/usou. Todo caminho que um leigo pode tomar é
   **previsto e tratado com graça**, o software **se conserta sozinho**: rodou como **root/sudo** →
   descobre o **usuário real** e instala/grava **pra ele** (nunca em `/root`); **PATH mínimo** (app
   aberto pelo menu não acha `claude` em `~/.local/bin`) → **resolve** varrendo fallbacks e usando
   **caminho absoluto**; **toolchain ausente** → instala/configura; **fechou/reordenou** inesperado
   → previsto. Edge case que um leigo atinge = **BUG do software**, não erro do usuário. Mensagem é
   **acionável e sem culpa** ("faço X pra você" > "você fez errado").
3. **UM só toolkit de GUI por produto.** Misturar dois toolkits (ex.: egui + Slint) no mesmo
   produto é a causa-raiz de **"fantasma de layout"** (janela/render de um vazando no outro) e de
   binário errado sendo aberto. Um produto = um toolkit. Segundo toolkit exige **ADR de exceção**
   com fronteira de processo explícita. Viés da casa: **Slint**; **egui não como principal**.
4. **Updater DESACOPLADO + versão embutida sempre coerente.** O updater é um **componente separado**
   do app (crate/binário próprio, como o `schematize-updater`): **app quebrado não trava o update, e
   update quebrado não derruba o app**. E a versão que o binário **reporta** tem de bater com o que
   ele **é** — a armadilha real: **git-dep pinado no `Cargo.lock` faz o build embutir versão/
   comportamento VELHO**; o `cargo update -p <dep>` é **passo explícito, commitado e pushado** (fora do build de release), git-deps com `rev`/`tag`, e o release roda `cargo build --locked`. Updater **monotônico** (recusa versão menor; downgrade só por rollback assinado). Pós-update:
   **trocar o binário em uso, MATAR o processo antigo** (só fechar a janela não basta) e **re-exec**
   o novo. Suporta **pin/rollback**.
5. **Launcher com path ABSOLUTO — não depender do PATH do DE.** O `.desktop` `Exec=` (e o atalho no
   macOS/Windows) aponta pro **binário por caminho absoluto**. O `PATH` do desktop environment
   **não** inclui `~/.cargo/bin`/`~/.local/bin` → sem path absoluto o menu abre um **binário errado
   ou antigo** (bug real da casa). Ao **spawnar** subprocessos, resolva o binário varrendo diretórios
   de fallback e use o **caminho absoluto**, nunca só o nome no PATH.
6. **NUNCA segredo embutido no cliente.** API key privada, `client_secret`, chave de assinatura,
   credencial de serviço — nada no binário, recurso embutido, `config` distribuído ou string
   compilada. Extrair o binário é trivial. Segredo que precisa existir mora no **servidor** atrás de
   um BFF; o app é **public client** (mesma regra do `NEXT_PUBLIC_` do `schematize-web` e do bundle
   do `schematize-mobile`). Chave de **assinatura de release** fica em **cofre/CI**, jamais no repo.
7. **Privilégio mínimo e privacidade por padrão.** Eleve **só onde precisa** (não peça `sudo` pro
   app inteiro); grave dado do usuário nos **dirs certos por SO** (XDG/`~/Library`/`%APPDATA%`),
   nunca em `/root` nem espalhado. **Sem telemetria por padrão** — se houver, é **opt-in explícito**
   e **local-first**; nada de PII/telemetria saindo da máquina sem consentimento.
8. **Cross-OS é requisito, não "depois".** Não assuma `/`-paths, `fork`, um único servidor gráfico
   nem fonte latina. Path por API do SO, processo por abstração, **fontes com cobertura CJK/árabe**
   (senão o render quebra pra metade do mundo), **Wayland e X11** ambos suportados no Linux. Um SO
   suportado sem **smoke test de empacotamento** naquele SO **não** está suportado.
9. <!-- herdado:engineering/orquestracao:bullet -->**Orquestrador não desenvolve; subagent barato executa** (`schematize-engineering` → `references/orquestracao.md` §9). O principal só planeja/decompõe/despacha/supervisiona/revisa; ação onerosa vira micro-tasks; principal = Claude Opus; executor mais barato que resolve: `haiku` (mecânico) / `sonnet` (código, até 2 rodadas de correção pelo mesmo subagent) → Codex `gpt-5.6-terra` → Cursor → subagent `opus` (motivo no checkpoint) → `park`; **visual direto ao Codex; imagem nunca pelo Claude (pergunta ao usuário: Codex sugerido, ou Gemini), API de imagem paga PROIBIDA**; papéis configuráveis em `agentes.toml` (aba "Agentes" do overdev). No `overdev`, cada item do checklist é executado pelo papel adequado e revisado pelo principal (diff + gate) antes do `- [x]`. **Sem frota ociosa:** agent idle com pendência executável volta ao trabalho; pendência que depende de outro agent → mata e enfileira com gatilho de dependência; terminou → mata (§9.6).<!-- /herdado -->

> Regra de bolso: se a justificativa começa com "no meu Linux funciona", "o usuário é só rodar
> certo" ou "depois eu troco o toolkit" e o resultado mexe em privilégio, path, update ou toolkit —
> é anti-padrão vetado. Pare e faça certo.

## Precedência e herança (leia antes de divergir)

<!-- herdado:engineering/precedencia:dominio intro="Esta skill é o recorte **Engenharia de app desktop/nativo** da `schematize-engineering`: **disciplina de domínio**, não linguagem de backend." cmd="desktop" -->Esta skill é o recorte **Engenharia de app desktop/nativo** da `schematize-engineering`: **disciplina de domínio**, não linguagem de backend.

1. **Onde esta skill divergir da base, a BASE MANDA.** Aqui mora a especialização do domínio ou da
   ferramenta — o como, o padrão, o gate. Divergência de *piso* é defeito desta skill, não variante local.
2. **O que não está repetido aqui é HERDADO, não dispensado.** Esta skill herda os pisos da base e
   os comandos dela cobrem o **domínio**, não o piso geral. Valem integralmente, sem cópia local:
   - **§28 Archive** — `<projeto>/<projeto>_archive/` é **repositório git próprio, PRIVADO e
     obrigatório**, criticidade 0 (`schematize-archive`).
   - **§35 Definition of Done** e a lista de anti-padrões (citada por **título**, nunca por número).
   - **§39 Índice/MAPA** — enumeração exaustiva (uma entrada por unidade chamável, `M == N`) e grafo
     com arestas em ASCII (`A -> B`), nunca a seta unicode.
   - **IAM** (`schematize-engineering` → `references/iam.md`): identidade ≠ email, ≥2 fatores, ReBAC
     multi-tenant, argon2id-only para senha nova, sessão longa e logout irreversível.
   - **Efeito externo** nunca sai de não-produção (`schematize-engineering` →
     `references/efeitos-externos.md`).
   - **Orquestração** (`schematize-engineering` → `references/orquestracao.md` §9): o principal não
     desenvolve (é Claude Opus); executor mais barato que resolve — `haiku`/`sonnet` → Codex Terra → Cursor → `opus` só após falha; visual direto ao Codex; imagem nunca pelo Claude: detecta Codex/Gemini e pergunta ao usuário qual usar (Codex é a sugestão, não automática), nunca API paga.
3. **QA, ops, IAM e índice não têm comando próprio aqui:** vêm da base `/eng-*`. Para trabalho
   contínuo use `/eng-overdev`; para planejar `/eng-plan`; para varrer a base `/eng-scan`; para
   revisão geral `/eng-review` (e `/eng-ops`, `/eng-iam`, `/eng-index`). Os comandos
   `/desktop-*` cobrem o domínio desta skill; o piso geral é o da base.<!-- /herdado -->

## Relação com as outras skills

- **schematize-engineering** — a **BASE** agnóstica. Esta skill herda e não afrouxa: **UX de massa**
  ("prever macacos" — o piso central aqui: `schematize-engineering` → `references/anti-padroes.md` §37, *"Culpar o usuário / exigir que ele saiba de internals / quebrar por invocação não-prevista"*), **segurança**
  (segredo nunca no cliente), **IAM** (`iam.md`), **DoD (§35)**, **archive (§28)**, **índice/MAPA
  (§39)**, **cadeia de suprimentos**, **ops**, e o fluxo (scan/plan/refactor/overdev/auditoria) — no laço do overdev cada item é executado por subagent `sonnet` e revisado pelo principal (`schematize-engineering` → `references/orquestracao.md` §9).
- **schematize-rust** — a linguagem em que a GUI desktop da casa (**Slint**, **Tauri**) e o `schematize-updater` são escritos —
  o modelo híbrido binário|fonte. Os pisos de código (arquivo/função/índice)
  saem de lá.
- **schematize-mobile / schematize-web** — as **irmãs**: mesmo piso, cliente diferente. Web = o
  servidor segura a barra; mobile = cliente hostil na loja; **desktop = cliente hostil na máquina do
  usuário, sem loja pra mediar**. "Segredo nunca no cliente" é o mesmo nos três.
- **schematize-pentest** — o **oráculo do cliente hostil**: segredo extraído do binário, update
  não assinado/sequestrável, escalada por privilégio mal-gerido, path traversal em IPC/deep-link
  local. O app local vira superfície de ataque testável.
- **schematize-audit** — fecha o loop: os checklists de desktop (toolkit/empacotamento/update/
  privilégio) viram itens **provados**, não marcados na fé.

- **schematize-qa** — a **disciplina de teste**, herdada inteira. O recorte desktop é o *onde roda*
  (GUI headless em CI com display virtual, smoke de **empacotamento** por SO, teste de update
  ponta a ponta partindo da versão anterior instalada) — mas a pirâmide, o "verde de verdade", o
  smoke com self-check, o tratamento de **flaky** e os **gates que travam o merge** são da
  `schematize-qa`. Instalador que só foi testado na máquina de quem compilou não foi testado.
