---
description: schematize-desktop — audita/planeja empacotamento e distribuição cross-OS (.deb/.rpm/AppImage/Flatpak, .dmg+notarization, MSI/MSIX+assinatura; binário pré-compilado vs fonte, híbrido) + smoke de pacote
argument-hint: "[SO alvo / pipeline de release]"
---
<!-- cross-skill: ops.md -> schematize-engineering -->

Audite/planeje o **empacotamento e a distribuição cross-OS** deste app
(`references/empacotamento.md`). Premissa: um SO "suportado" sem **pacote testado naquele SO** não
está suportado. Build assinado no **CI** (`ops.md`), nunca à mão.

## 1. Formato por SO
- **Linux:** ≥1 portátil (**AppImage**) + conforme público **Flatpak** (sandbox/Flathub) e/ou
  **.deb/.rpm**. `.desktop` com `Exec` **absoluto** (`privilegio-fs.md`), ícone/nome corretos.
- **macOS:** **.dmg/.pkg** com app **assinado (Developer ID) + notarizado + stapled** — sem isso o
  Gatekeeper bloqueia.
- **Windows:** **MSI/MSIX** com binário **assinado (Authenticode)** — sem isso o SmartScreen
  assusta.
- **Chave de assinatura em cofre/CI**, nunca no repo (`privacidade-seguranca.md`).

## 2. Binário pré-compilado vs fonte — modelo HÍBRIDO
- Default: **CI compila por SO/arquitetura** (Linux x86_64/aarch64, macOS arm64/x86_64, Windows
  x86_64) e publica artefatos **assinados** na Release — usuário baixa e roda **sem toolchain**
  (`prever macacos`).
- Fallback: sem binário pro alvo → bootstrapper **detecta**, **instala/configura o toolchain
  sozinho** e compila (modelo do `schematize-updater`). Fallback, não o caminho normal.

## 3. Instalação que prever macacos
- **Idempotente** (reexec não corrompe, atualiza no lugar, não deixa duas versões que confundem o
  launcher); **root/sudo → grava pro usuário real** (`privilegio-fs.md`); **dependência de sistema
  faltando → detecta e orienta com ação**; **desinstalação preserva dados** por padrão.

## 4. Smoke de empacotamento (a prova)
- Em **ambiente limpo por SO** (sem toolchain, sem o app): **instala o pacote → abre (headless) →
  fecha limpo**; confirma assinatura/notarization e `.desktop`/atalho absoluto (`testes-locais.md`).

## Saída
Gere/atualize a **matriz de release** (SO × formato × assinatura × smoke) e reporte cada célula como
**FEITO com prova** (pacote gerado no CI, assinado, smoke passou) ou **EM ABERTO** (entra na DoD,
§35). Aponte SOs sem smoke como **não suportados** até provar.
