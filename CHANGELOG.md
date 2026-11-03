# Changelog — schematize-desktop

Todas as mudanças relevantes deste pacote, no formato [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/),
com versionamento [SemVer](https://semver.org/lang/pt-BR/).


## [0.7.0] — 2026-11-03

### Corrigido
- P0-3: `cargo update -p <dep>` deixa de ser passo do build/CI de release; é passo explícito, commitado e pushado (piso 22); release usa `cargo build --locked` do SHA/tag e falha se versão/hash do git-dep divergir; git-deps com `rev`/`tag`. Coerente com `empacotamento.md` (Cargo.lock commitado).
- P0-2: seção "Gatilho de CI" (empacotamento, testes-locais): matriz de 3 SOs só em tag/hml/pedido; gate por commit local (piso 27).
- P1-21: updater monotônico (recusa versão menor; downgrade só por rollback assinado; freshness do manifesto).
- P1-20: gate `scripts/check-update-signing.sh` + teste (pubkey/createUpdaterArtifacts do Tauri, `cargo update`/sem `--locked` em workflow). Fonte oficial: https://v2.tauri.app/plugin/updater/ (2026-11-03).
- P1-1: bloco "Herda os pisos 22–29".

### Pendente
- [~] P1-22 (EV/SmartScreen, Electron 45/Trusted Signing): sem confirmação em fonte oficial Microsoft/Electron; texto mantido. notarytool/Hardened Runtime não citados (sem fonte oficial consultada).
- [~] P2-10/P2-12 (aspas em `$confs_tauri`): não triviais sem mudar o coletor; mantido.

## [0.6.0] — 2026-10-14
Integração com as 8 skills novas (skill-dev, iam, api, payments, postgres, incident, analytics, git) e saneamento pelo gate novo.

### Alterado
- Blocos herdados `engineering/precedencia:dominio` e `engineering/orquestracao:curto` (SKILL.md e assets/CLAUDE.md), exigidos pelo gate da `schematize-skill-dev`.
- Description reduzida a ≤190 caracteres para caber no orçamento do catálogo (45 skills).

## [0.5.1] — 2026-10-14
Ressincronização dos blocos herdados com a engineering v0.27.0; sem mudança de piso próprio.

### Alterado
- Description reduzida (≤235 chars) para caber no orçamento de listagem de skills (soma ≤8300); mesmo território, fronteiras com as irmãs preservadas.
- Blocos herdados ressincronizados com a `schematize-engineering` v0.27.0 (`tools/sync-herdados.mjs`): orquestração com a regra de imagem (nunca pelo Claude; detecta Codex/Gemini e pergunta ao usuário qual usar, Codex como sugestão) e `schematize overdev delegar` (comando do app) no lugar do falso nome de skill `schematize-overdev`.

## [0.5.0] — 2026-10-14
Electron/Tauri reverificados e tabela de toolkits com dono único.

### Corrigido
- `references/web-in-native.md`: "Electron 38" estava obsoleto; verificado em 2026-10-14 contra Electron 42-44 (suporte = 3 últimas majors; 45 prevista para 20/10/2026, quando a 42 sai) e Tauri 2.x. Flags e fuses seguem válidos.
- Tabela de toolkits estava em 3 lugares (`SKILL.md`, `stack-versoes.md`, `toolkits-gui.md`); dono único agora é `toolkits-gui.md`, os outros apontam. *Por quê:* três cópias divergem.
- `SKILL.md`: "linguagem principal da GUI" (rust) reescrito sem hierarquia de linguagens.
- `description` em `>-` (YAML antes inválido) com 350 caracteres ou menos.
- **Description** reduzida (~270 chars) para caber no orçamento de listagem (soma das 31 skills ≤ 8500; o Claude Code corta a listagem acima disso).

### Alterado
- `scripts/check-external-effects{,.test}.sh` viram arquivos herdados da engineering (cabeçalho "herdado de schematize-engineering — não edite aqui"); conteúdo inalterado.

## [0.4.2] — 2026-09-30
O piso de orquestração passa a ser **herdado** da base em vez de copiado à mão: uma mudança na engineering não exige mais editar 38 arquivos.

### Alterado
- Piso "Orquestrador não desenvolve; subagent barato executa" em `assets/CLAUDE.md` e `SKILL.md` agora é um bloco `<!-- herdado:engineering/orquestracao:… -->`, sincronizado de `schematize-engineering/assets/herdados/orquestracao.md` por `tools/sync-herdados.mjs` (checado no CI). Redação normalizada; conteúdo inalterado.

### Mantido (piso inalterado)
- Sonnet por default, escada até opus, sem frota ociosa (engineering `references/orquestracao.md` §9/§9.6).

## [0.4.1] — 2026-09-30
Pedido do dono: agents idle poluem a tela e seguram recurso.

### Adicionado
- Piso de orquestração ganha a regra de frota ociosa (idle com pendência volta ao trabalho; dependente de outro agent → mata e enfileira com gatilho; terminou → mata); detalhe na `schematize-engineering` §9.6.

## [0.4.0] — 2026-09-30
Pedido do dono: **custo** — orquestrador em modelo padrão não desenvolve; micro-tasks baratas; `sonnet` como default nos subagents, `opus` só após falha.

### Adicionado
- **Piso "Orquestrador não desenvolve; subagent barato executa"** (`assets/CLAUDE.md` e `SKILL.md`), com remissão à normativa em `schematize-engineering` → `references/orquestracao.md` §9. O agent principal só **planeja, decompõe, despacha, supervisiona e revisa**; ação onerosa vira **micro-tasks**; subagents em **`sonnet`** por padrão e a escada é *mesmo subagent corrige (até 2 rodadas) → re-decompõe → só então `opus`*, com motivo no checkpoint. No **overdev**, cada item do checklist é executado por subagent `sonnet` e revisado pelo principal.

### Mantido (piso inalterado)
- Todos os pisos anteriores seguem valendo sem afrouxamento; a regra nova só define **quem executa** e a que custo, não o que é exigido.

## [0.3.0] — 2026-08-21
Segunda leva do saneamento: o inventário da vistoria — quatro conselhos que envelheceram (e um que quebrava a base instalada), o rol de toolkits e a separação entre normativa e postmortem.

### Corrigido
- **macOS: o procedimento de update preservava a assinatura só por sorte.** Trocar o Mach-O dentro do `.app` **invalida** assinatura e notarização — *e às vezes não na hora, mas na próxima revalidação, que é pior, porque o app "funcionou" e depois parou*. Agora o texto manda baixar o **bundle completo**, **verificar** (`codesign --verify --deep --strict`, `spctl --assess`) e trocar **o diretório inteiro** por `rename` atômico.
- **Assinatura no Windows estava descrita em termos de 2022.** Desde **junho de 2023** o CA/B exige **chave em hardware**: `.pfx` em secret de CI **não é mais emissível**. Entraram as opções reais (serviço de assinatura na nuvem via API, ou HSM com runner self-hosted), EV vs OV e o impacto no prazo (validação leva dias).
- **Pinning de certificado em cliente autoatualizável saiu** — *o CDN rotaciona o certificado e o único caminho de conserto, o updater, é exatamente o que parou de funcionar*. No lugar: **assinar o artefato e o manifesto** e verificar antes de instalar, que protege mesmo com o transporte comprometido.
- **Linux sem folclore:** AppImage **não** "roda em qualquer distro" (glibc do build + FUSE); **Flatpak** exige **`xdg-desktop-portal`** para o app enxergar o mundo (sem portal, o usuário acha que está quebrado); e **Snap** entrou no rol — *é o default do Ubuntu, e ignorá-lo é abrir mão do caminho que o usuário já conhece*.

### Mudado
- **Rol de toolkits com C#**: **Avalonia / MAUI** (C# está no rol sancionado), com o critério de escolha entre os dois (*Linux importa? então Avalonia*).
- **Licença passou a ser exigida de todos, inclusive do default**: ✔ o **Slint é tri-licenciado** (GPLv3 · comercial · royalty-free com condições) — era desonesto cobrar ADR de licença só do Qt.
- **Postmortem saiu do corpo normativo.** As citações a memórias privadas (`gui-launcher-abs-path`, `fix v0.33.1`, `paths.rs`) viraram **o padrão** que elas ensinam — o ambiente do lançador gráfico tem `PATH` mínimo; coexistência de instalações abre a versão errada; uma função central resolve caminhos e migra layout sozinha. O caso específico continua no **archive do projeto**, que é onde ele pertence.

## [0.2.0] — 2026-08-21
O buraco que a vistoria de 2026-08-21 achou: a skill declara **8 pisos VETADOS** e sanciona Tauri/Electron, mas entregava **13 linhas** sobre web-in-native e **zero gates** — `grep 'allowlist|capabilit|permissions'` = **0**. Faltava justamente a parte que decide se o app é seguro: **o que o frontend pode chamar**.

### Adicionado
- **`references/web-in-native.md`** — os dois modelos, com a tese em uma frase: *no browser um XSS rouba a sessão; aqui ele chama o sistema operacional*. **Tauri 2**: capability (por janela) → permission → **scope**, com o piso da casa (capability mínima por janela; nada de `fs:default` onde há conteúdo de terceiro; `deny` para `**/.ssh/**`, `**/.env`, `**/id_*` — porque `allow` amplo com `deny` explícito falha de forma segura quando alguém alargar depois; chave `dangerous*` só com ADR; CSP definida) e o cheiro de **migração pela metade** (bloco `allowlist` do v1 com `capabilities/` vazio). **Electron**: a tabela de `webPreferences` com o porquê de cada flag, `contextBridge` com **funções nomeadas** (expor `ipcRenderer` ou `send`/`invoke` crus reabre a ponte que o `contextIsolation` fechou), `will-navigate`/`setWindowOpenHandler`, e as **fuses** — sem elas, `ELECTRON_RUN_AS_NODE=1 seu-app` roda código arbitrário **com a assinatura e a reputação do seu app**. ✔ verificado em 2026-08-21 contra Tauri 2 e Electron 38.
- **`scripts/check-web-in-native.sh`** + **`/desktop-bridge`** — o gate. Reprova `"all": true`, projeto Tauri sem nenhuma capability, scope em `$HOME/**`, `csp: null`, `dangerousRemoteDomainIpcAccess`, `nodeIntegration: true`, `contextIsolation: false`/não declarado (default não conta como decisão), `sandbox: false`, `webSecurity: false`, `exposeInMainWorld` com `ipcRenderer` ou `send`/`invoke` crus, e projeto Electron **sem fuses**. Repo sem nenhum dos dois sai **`2`, não `0`**.
- **`scripts/check-web-in-native.test.sh`** — **16 casos**, 14 vermelhos de propósito, medidos contra um app de fixture que passa.

### Mudado
- `references/toolkits-gui.md` §3 passa a apontar para o novo capítulo, com a fronteira escrita: aquela seção decide **se** você empacota web em nativo; a nova decide **o que o frontend pode chamar** depois.

## [0.1.0] — 2026-08-18

Primeira versão da skill de **engenharia de software local/nativo/desktop** da casa — o mesmo piso
da `schematize-engineering` (segurança, IAM, testes, ops, DoD §35, archive §28, índice §39) aplicado
ao software que roda **na máquina do usuário**, sob três verdades novas: **não há servidor pra
segurar a barra**, **cada SO é diferente** e **o usuário é leigo e sem suporte**. Irmã de
`schematize-mobile` e `schematize-web`; muda o "como", não o "o quê".

### Adicionado
- **SKILL.md** com 8 pisos inegociáveis (o piso da casa é o mesmo; **UX de massa — prever macacos**;
  **um só toolkit de GUI por produto**; **updater desacoplado + versão embutida coerente**;
  **launcher com path absoluto**; **nunca segredo no cliente**; privilégio mínimo + privacidade por
  padrão; cross-OS é requisito) + mapa de references + relação com engineering/rust/mobile/web/
  pentest/audit.
- **references/**:
  - `toolkits-gui.md` — rol de toolkits (Slint default, Tauri por fit/justificativa, **egui não como
    principal** — fantasma de layout, GTK/Qt), **um produto = um toolkit** (o pecado capital de
    misturar dois), web-in-native (Tauri>Electron, ponte validada), arquitetura em camadas com
    domínio sem toolkit.
  - `empacotamento.md` — formato por SO (AppImage/Flatpak/.deb/.rpm, .dmg+notarization,
    MSI/MSIX+Authenticode), **binário pré-compilado por SO vs compilar-do-fonte (híbrido**, modelo
    `schematize-updater`**)**, build assinado no CI, instalação idempotente que prever macacos, smoke
    de empacotamento.
  - `auto-update.md` — updater **DESACOPLADO** do app, a armadilha real do **git-dep pinado no
    `Cargo.lock`** (embute versão VELHA → `cargo update -p <dep>` antes de compilar; CI prova
    coerência), **trocar binário em uso** por SO, **matar processo antigo (não só fechar janela) +
    re-exec**, pin/rollback/self-check, canal verificado (assinatura/hash).
  - `offline-estado.md` — dirs por SO (XDG/`~/Library`/`%APPDATA%`), **estado ≠ cache**, **migração
    de schema local reversível/versionada**, backup automático + escrita atômica, export/import, sync
    eventual (herda `offline-sync.md`).
  - `privilegio-fs.md` — **root/sudo → usuário real** (nunca `/root`, `chown` correto), **elevar só
    onde precisa**, **launcher com `Exec` absoluto** + spawn por fallback dirs (o PATH do DE),
    **single-instance** por lock/socket robusto a crash e a órfão pós-update, **IPC local** validado
    e entrada externa canonicalizada.
  - `cross-os.md` — path/permissão/processo/launcher/sinais por SO (sem `fork` no Windows),
    **Wayland E X11**, HiDPI, **fontes com cobertura CJK/árabe/emoji + shaping/bidi** (senão tofu),
    UTF-8/locale/EOL.
  - `privacidade-seguranca.md` — **sem telemetria por padrão** (opt-in, sem PII, local-first),
    **nunca segredo no cliente** (public client, BFF, keychain do SO), autorização no servidor,
    **assinatura de binário** + verificação no update, **supply chain de deps nativas** (`cargo
    audit`, unsafe/FFI), superfície de ataque local.
  - `testes-locais.md` — domínio **headless**, **GUI headless no CI** por SO (snapshot com strings
    CJK/árabe), **smoke de empacotamento** em ambiente limpo, **update ponta-a-ponta**
    (vN→vN+1→rollback, versão coerente, processo antigo morto, artefato inválido recusado), gates por
    SO.
- **assets/commands/**: `/desktop-help`, `/desktop-load`, `/desktop-toolkit`, `/desktop-package`,
  `/desktop-update`, `/desktop-privilege`, `/desktop-claude`, `/desktop-cc`, `/desktop-handoff`.
- **assets/CLAUDE.md** — regra sempre-on: prever macacos; um só toolkit; updater desacoplado + versão
  coerente (git-dep); launcher com path absoluto; sem segredo no cliente; privilégio mínimo +
  privacidade por padrão; cross-OS testado; estado do usuário sagrado.
