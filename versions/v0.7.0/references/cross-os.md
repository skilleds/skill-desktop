# Cross-OS de verdade — Linux, macOS e Windows não são "o mesmo com outro ícone"

> "Cross-platform" só é verdade se **cada SO foi testado naquele SO** (`testes-locais.md`, smoke por
> SO). Assumir path com `/`, `fork`, um único servidor gráfico ou fonte latina é como 2 dos 3 SOs
> quebram calados. Este reference lista as divergências que **têm** de ser tratadas por design.

## 1. Path e filesystem

- **Separador e forma:** use a **abstração de path** da linguagem (`Path`/`PathBuf` em Rust,
  `std::path`), nunca concatene com `/` ou `\` na mão. Windows usa `\`, drives (`C:\`),
  case-insensitive (mas case-preserving); Linux é case-sensitive; macOS é case-insensitive por
  padrão (mas pode ser sensível). Não dependa de case.
- **Dirs por SO:** já normativo em `offline-estado.md` (XDG / `~/Library` / `%APPDATA%`). Não
  hard-code `~/.config` no macOS/Windows.
- **Tamanho/caracteres de nome:** Windows proíbe `: * ? " < > |` e nomes reservados (`CON`, `NUL`,
  `COM1`...); caminho longo tem limite histórico. Sanitize nomes de arquivo que venham do usuário/
  dado.
- **Permissões:** modo Unix (`chmod`/bits) não existe igual no Windows (ACLs). Não assuma `0755`
  cross-OS; use a API de permissão certa por SO.

## 2. Processo, launcher e ciclo de vida

- **Sem `fork` no Windows:** o modelo é `CreateProcess`/spawn. Use uma abstração de spawn
  (`std::process::Command`), **resolvendo o binário por caminho absoluto** (`privilegio-fs.md`).
- **Sinais:** `SIGTERM`/`SIGKILL` são Unix; Windows tem seu mecanismo (console ctrl events / job
  objects). Matar o processo antigo pós-update (`auto-update.md`) tem código **por SO**.
- **Autostart/serviço:** systemd/user units (Linux), `launchd`/LaunchAgents (macOS), Serviços/
  Registro Run (Windows) — cada um com seu jeito. Não improvise um por todos.
- **Tray/indicador:** AppIndicator/StatusNotifier (Linux, varia por DE), `NSStatusItem` (macOS),
  notification area (Windows) — comportamentos e disponibilidade diferentes.

## 3. Servidor gráfico e janela (Linux especialmente)

- **Wayland E X11:** no Linux, **ambos** existem — o app tem de rodar nos dois (nativo Wayland +
  fallback XWayland/X11). Assumir só X11 quebra em sessões Wayland modernas; assumir só Wayland
  quebra em X11. Toolkits (Slint/GTK/Qt) abstraem, mas **teste nos dois**.
- **HiDPI/scaling:** fator de escala por monitor, multi-monitor com DPIs diferentes — o app não pode
  renderizar minúsculo ou borrado. Respeite o scale do SO.
- **Foco/raise de janela:** trazer a janela pra frente (single-instance, `privilegio-fs.md`) tem
  regras diferentes por compositor (Wayland restringe raise programático).

## 4. FONTES — cobertura CJK/árabe ou o render quebra pra meio mundo

Bug clássico de app "internacional": texto em **chinês/japonês/coreano** vira **caixinhas (tofu)**,
**árabe/hebraico** não faz shaping/RTL, e o app parece quebrado pra bilhões de usuários.

- **Não embuta só fonte latina.** Ou **use as fontes do SO** com **fallback chain** que cobre CJK e
  RTL (o SO tem Noto/Segoe/PingFang/etc.), ou **embuta uma fonte com ampla cobertura** (família Noto)
  se o app precisa de render idêntico cross-OS (comum em Slint/render próprio, que não herda a stack
  de fontes do SO automaticamente).
- **Shaping e bidi:** árabe (junção de glifos) e RTL (bidi) exigem um motor de shaping
  (HarfBuzz/rustybuzz) — não é "desenhar glifo por glifo". Confirme que o toolkit faz shaping e
  fallback de fonte.
- **Emoji e símbolos:** cobertura de emoji/símbolo idem — senão vira tofu.
- **Teste com strings reais** CJK/árabe/emoji no smoke de UI (`testes-locais.md`), não só "Lorem
  ipsum".

## 5. Encoding, locale, tempo

- **UTF-8 em tudo** internamente; cuidado com o Windows (console/API legada em UTF-16/codepage).
  Leia/escreva arquivos como UTF-8 explícito.
- **Locale:** formatação de número/data/moeda pelo locale do usuário (mas **tempo em UTC** no store,
  `schematize-database`); não hard-code `.` decimal ou `MM/DD`.
- **Fim de linha:** `\n` vs `\r\n` — normalize ao ler/gravar arquivos de texto do usuário.

## 6. DoD cross-OS

- [ ] path/permissão via **abstração do SO** (sem `/`/`\` na mão, sem `0755` assumido);
- [ ] processo/spawn/sinais/autostart com código **por SO** (sem `fork` no Windows);
- [ ] Linux roda em **Wayland E X11**; HiDPI/multi-monitor respeitado;
- [ ] **fontes cobrem CJK + RTL + emoji** (fallback chain ou fonte ampla embutida); shaping/bidi ok;
- [ ] UTF-8/locale/EOL tratados; **smoke por SO** com strings reais (não só latino) no CI.
