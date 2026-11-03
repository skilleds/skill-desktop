---
description: schematize-desktop — lista todos os comandos disponíveis e o que cada um faz
---

Liste os comandos do **schematize-desktop** instalados (`/desktop-*`), com 1 linha cada:

- `/desktop-help` — esta lista.
- `/desktop-load` — carrega à força TODO o corpo normativo (toolkits de GUI, empacotamento, auto-update, estado local, privilégio/FS, cross-OS, privacidade/segurança, testes) e passa a aplicá-lo.
- `/desktop-toolkit` — força/audita a escolha de **toolkit de GUI**: **um só por produto**, viés **Slint (Rust)**, **egui não como principal** (fantasma de layout), Tauri/GTK/Qt por fit, web-in-native só com justificativa; caça **mistura de dois toolkits** no mesmo produto.
- `/desktop-bridge` — audita a **ponte web↔nativo** (Tauri 2: capability/permission/scope; Electron: contextIsolation/sandbox/**fuses**) e roda o gate `check-web-in-native.sh`.
- `/desktop-package` — audita/planeja **empacotamento e distribuição cross-OS**: .deb/.rpm/AppImage/Flatpak (Linux), .dmg+**notarization** (macOS), MSI/MSIX+**assinatura** (Windows); binário pré-compilado por SO vs compilar-do-fonte (**híbrido**, como o `schematize-updater`); smoke test de pacote.
- `/desktop-update` — audita/planeja o **auto-update DESACOPLADO** (app quebrado não trava o update e vice-versa): pin/rollback, a armadilha do **git-dep no `Cargo.lock`** (`cargo update -p <dep>` explícito e commitado + release `--locked`, pra versão embutida não mentir), **trocar binário em uso**, **matar processo antigo** (não só fechar a janela) + re-exec, artefato verificado.
- `/desktop-privilege` — audita **privilégio e ambiente**: root/sudo → **usuário real** (nunca `/root`), elevar **só onde precisa**, **`.desktop` `Exec` ABSOLUTO** (o PATH do DE não acha o binário), single-instance por lock/socket, IPC local validado.
- `/desktop-claude` — cria ou mescla o `CLAUDE.md` sempre-on de desktop na raiz do repo.
- `/desktop-cc` — context compact: gera handoff no archive e roda `/compact`.
- `/desktop-handoff` — gera o handoff (context.md + checklist.md) sem compactar.

Depois da lista, lembre a **regra de ouro**: *o piso da casa é o MESMO — o desktop só muda o
"como".* Na máquina do usuário **não há servidor pra segurar a barra** e o usuário é **leigo**: por
isso **prever macacos** (o software se adapta e nunca culpa o usuário — root vira usuário real, PATH
mínimo se resolve, toolchain ausente se instala), **um só toolkit por produto**, **updater
desacoplado com versão embutida coerente** (a armadilha do git-dep), **launcher com path absoluto**,
e **segredo nunca no cliente**. Detalhe normativo em `references/` da skill `schematize-desktop`; a
base (UX de massa/segurança/DoD/archive/índice) é a `schematize-engineering`.
