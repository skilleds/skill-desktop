# Anexo volátil — toolkits, empacotamento e requisitos de SO

> Parte da skill **schematize-desktop**. **Fonte volátil:** versão de toolkit, requisito de
> assinatura e regra de notarization mudam. O corpo normativo diz **princípio**; o que tem prazo
> mora aqui. O lint do catálogo (regra `anexo-volatil`) reprova versão cravada fora daqui.
>
> **Verificado em: 2026-10-14** (Electron/Tauri; o resto da tabela de SO segue em 2026-08-21). Cadência: **revisão trimestral**, e sempre antes de um release.

## Toolkits de GUI

O rol, o viés da casa, a posição de cada toolkit e a licença estão em `toolkits-gui.md` (**dono único** — não repetir a tabela aqui).
O que é volátil e mora aqui são as versões e prazos dos web-in-native:

| Item | Estado (verificado em 2026-10-14) | Nota |
|---|---|---|
| **Electron** | suporte oficial = **3 últimas majors estáveis**, só a minor mais nova de cada; cadência de 8 semanas. Hoje **42, 43, 44** (44.7.2); a **45** estável é prevista para 20/10/2026, quando a **42** sai de suporte | travar em major fora do suporte é rodar Chromium sem patch; datas seguem o Chromium e podem mudar (`electronjs.org` → timelines) |
| **Tauri** | **2.x** (CLI 2.12.2) | modelo de capabilities da v2 (`web-in-native.md` §2) |
| **@electron/fuses** | 2.1.3 | fuses em `web-in-native.md` §3 |

> **UM toolkit por produto** é regra normativa (corpo da skill), não volátil.

## Empacotamento e assinatura — o que tem prazo

| Plataforma | Requisito | Nota (2026-08-21) |
|---|---|---|
| **macOS** | **notarization obrigatória** para distribuição fora da App Store; `.dmg`/`.pkg` assinados com Developer ID e **stapled** | sem notarizar, o Gatekeeper bloqueia com mensagem que o usuário lê como "vírus" |
| **Windows** | assinatura de código; **certificado EV/attestation em HSM** — a era do `.pfx` no CI acabou | MSIX ou MSI assinado; SmartScreen usa reputação, que **começa do zero** a cada troca de certificado |
| **Linux** | `.deb`/`.rpm` assinados, AppImage com assinatura destacada, Flatpak pelo runtime da distro | repositório próprio com chave publicada |

## A regra que NÃO é volátil

Updater **desacoplado** (app quebrado não pode travar o update), versão embutida **coerente** com
a publicada, launcher com **`Exec` absoluto**, **nunca segredo no cliente** (binário distribuído é
segredo publicado), e **UX de massa**: o software se adapta e **nunca culpa o usuário**.

> **A armadilha que já custou release aqui:** dependência de **git** no lockfile (`Cargo.lock`
> pinando um commit velho) faz o build embutir uma versão **antiga** sem avisar. Rode o
> `cargo update -p <crate>` como passo explícito e commitado (nunca dentro do build de release; o release usa `--locked`), e faça o `--version` do binário ser
> gerado do que foi **realmente** compilado.
