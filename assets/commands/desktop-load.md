---
description: schematize-desktop — carrega à força TODO o corpo normativo (toolkits, empacotamento, auto-update, estado local, privilégio/FS, cross-OS, privacidade/segurança, testes) e passa a aplicá-lo
---
<!-- cross-skill: offline-sync.md -> schematize-mobile -->

Carregue **à força** e passe a aplicar **integralmente** os Padrões de Engenharia de Software
Local/Desktop da Casa (skill `schematize-desktop`) neste projeto. A partir de agora, nesta sessão,
isto **não é opcional**.

1. **Leia agora, na íntegra, TODOS os references** — não trabalhe de memória. Caminho:
   `.claude/skills/schematize-desktop/references/*.md` (projeto) ou
   `~/.claude/skills/schematize-desktop/references/*.md` (global):
   - `toolkits-gui.md` — rol de toolkits (Slint default, Tauri por fit, **egui não como principal**,
     GTK/Qt), **um só toolkit por produto** (fantasma de layout), web-in-native só com justificativa,
     arquitetura interna em camadas (domínio sem toolkit).
   - `web-in-native.md` — a **ponte como fronteira de confiança**: no browser um XSS rouba a
     sessão, aqui ele chama o SO. Modelo de **capacidades** do Tauri 2 (capability por janela,
     permission, **scope** com `deny` dos sensíveis) e de **isolamento** do Electron
     (`contextIsolation`/`nodeIntegration`/`sandbox`, `contextBridge` com funções nomeadas,
     `will-navigate`, **fuses**). Gate: `scripts/check-web-in-native.sh`.
   - `empacotamento.md` — formato por SO (.deb/.rpm/AppImage/Flatpak, .dmg+notarization, MSI/MSIX+
     assinatura), **binário pré-compilado vs compilar-do-fonte (híbrido)**, build assinado no CI,
     smoke de empacotamento.
   - `auto-update.md` — updater **DESACOPLADO** do app, a armadilha do **git-dep pinado no
     `Cargo.lock`** (`cargo update -p` explícito e commitado; release `--locked`), **trocar binário em uso**, **matar
     processo antigo + re-exec**, pin/rollback, canal de update verificado.
   - `offline-estado.md` — dirs por SO (XDG/`~/Library`/`%APPDATA%`), estado ≠ cache, **migração de
     schema local reversível**, backup/escrita atômica, sync eventual (herda `offline-sync.md`).
   - `privilegio-fs.md` — root/sudo → **usuário real** (nunca `/root`), elevar só onde precisa,
     **launcher com `Exec` absoluto** (PATH do DE), single-instance por lock/socket, IPC local
     validado.
   - `cross-os.md` — path/processo/launcher por SO, **Wayland E X11**, **fontes CJK/árabe** (senão
     tofu), encoding/locale/EOL.
   - `privacidade-seguranca.md` — **sem telemetria por padrão** (opt-in), **nunca segredo no
     cliente**, assinatura de binário, supply chain de deps nativas, entrada externa hostil.
   - `testes-locais.md` — **GUI headless no CI**, **smoke de empacotamento**, **update ponta-a-ponta
     (vN→vN+1→rollback)**, por SO.

2. **Confirme ao usuário** que leu (1 linha por arquivo).

3. Deste ponto, aplique como regra inegociável: **o piso da casa é o mesmo** (segurança/IAM/testes/
   ops/DoD §35/archive §28/índice §39), **UX de massa — prever macacos** (o software se adapta e
   nunca culpa o usuário; root→usuário real, PATH mínimo→resolve, toolchain ausente→configura), **um
   só toolkit por produto**, **updater desacoplado + versão embutida coerente** (git-dep), **launcher
   com path absoluto**, **sem segredo no cliente**, **privilégio mínimo + privacidade por padrão**,
   **cross-OS testado por SO**.

4. **Atualize o `CLAUDE.md` da raiz** com `assets/CLAUDE.md` da skill (mescla se já houver de outra
   skill) — é o `/desktop-claude`.
