<!-- cross-skill: seguranca-frontend.md -> schematize-web -->

# Web-in-native — o modelo de capacidades (Tauri 2) e o de isolamento (Electron)

> A skill sanciona Tauri e Electron, declara **8 pisos VETADOS** e entregava **13 linhas** sobre
> web-in-native, com `grep 'allowlist|capabilit|permissions'` = **0** (vistoria de 2026-08-21).
> Faltava justamente a parte que decide se o app é seguro: **o que o frontend pode chamar**.
>
> A tese em uma frase: no browser, um XSS rouba a sessão; **aqui, um XSS chama o sistema
> operacional**. Toda a diferença está em quanto de SO você deixou alcançável a partir do webview.
>
> ✔ Verificado em 2026-10-14 contra Tauri 2 e Electron 42–44 (flags e fuses inalterados; o Electron suportado é sempre as 3 últimas majors). Números de versão e nomes de flag são
> voláteis — veja `stack-versoes.md`.

## 1. A regra que vale para os dois

**Deny-by-default, e o frontend nunca pede "acesso"; ele pede uma AÇÃO.** A ponte expõe comandos de
domínio (`salvarRelatorio(dados)`), não primitivas (`escreverArquivo(caminho, bytes)`). A diferença
não é estética: com a primitiva, o caminho vem do lado hostil e vira leitura de `~/.ssh/id_rsa`; com
o comando de domínio, o caminho é decidido no **lado nativo**, onde o atacante não escreve.

Corolários, nos dois toolkits:

- **Validação no lado nativo, sempre.** Argumento vindo do webview é entrada hostil — mesma régua da
  `schematize-pentest`. Validar no JS é conveniência de UX, nunca controle.
- **Escopo mínimo e explícito** para arquivo, shell, rede e IPC. Escopo com `*` é ausência de escopo.
- **Nada de "abrir o que o frontend mandar"**: `shell.open`/`openExternal` com URL controlada pelo
  conteúdo é execução remota disfarçada de conveniência (`file://`, `smb://`, `.desktop`).
- **CSP também aqui.** O webview carrega HTML: sem CSP, um `innerHTML` mal-feito já é o começo.
- **Conteúdo remoto é o caso perigoso.** App que carrega URL da internet dentro do webview privilegiado
  não tem modelo de segurança — tem esperança. Se precisa mesmo, é janela **separada e sem ponte**.

## 2. Tauri 2 — capabilities, permissions, scopes

Tauri **1** tinha `allowlist` no `tauri.conf.json` (e o `"all": true` que anulava tudo). Tauri **2**
trocou por um modelo de três peças, e é ele que precisa estar no repo:

| Peça | Onde | O que é |
|---|---|---|
| **Permission** | plugin ou `src-tauri/permissions/` | a unidade: "pode chamar este comando", às vezes com escopo embutido (ex.: `fs:allow-read-text-file`) |
| **Capability** | `src-tauri/capabilities/*.json` | um conjunto de permissions concedido a **janelas específicas** (`windows: ["principal"]`) e, no mobile/multi-plataforma, a plataformas específicas |
| **Scope** | dentro da permission/capability | os **argumentos** aceitos: quais caminhos, quais URLs, quais comandos. `allow` e `deny` — e **`deny` ganha** |

Piso da casa:

- **Uma capability por janela**, com o mínimo. A janela de login não precisa de `fs`; a de relatório
  não precisa de `shell`.
- **Nunca `fs:default` na janela que renderiza conteúdo de terceiro.** Prefira permissions
  específicas (`fs:allow-app-write`) com scope em `$APPDATA/...`, jamais `$HOME/**`.
- **Scope de `fs` sempre com `deny` para os suspeitos de sempre** — `**/.ssh/**`, `**/.env`,
  `**/.git/**`, `**/id_*` — porque `allow` amplo com `deny` explícito falha de forma segura quando
  alguém alarga o `allow` depois.
- **`core:default` é ponto de partida, não destino.** Revise o que ele traz.
- **`dangerousRemoteDomainIpcAccess` (e qualquer chave com `dangerous` no nome) exige ADR.** O nome
  não é decorativo: é a chave que dá IPC a conteúdo remoto.
- **CSP em `app.security.csp`.** `null` desliga a proteção e é o default de conveniência que fica.
- **Comando `#[tauri::command]` é superfície pública:** valide todo argumento, e não devolva erro com
  caminho absoluto/stack para o webview.

Cheiro de migração incompleta: `tauri.conf.json` com bloco `allowlist` **e** `src-tauri/capabilities/`
vazio — é v1 rodando em v2, com o pior dos dois (a permissão do v1 não vale mais, e ninguém concedeu
nada no v2; o app quebra ou alguém "resolve" concedendo tudo).

## 3. Electron — isolamento, sandbox e fuses

Electron não tem capabilities: tem **isolamento de contexto** e um punhado de flags que precisam
estar todas certas ao mesmo tempo. O default histórico era inseguro, então **tudo aqui é explícito**.

Em **cada** `new BrowserWindow({ webPreferences: ... })`:

| Flag | Valor | Por quê |
|---|---|---|
| `contextIsolation` | **`true`** | sem isto, o preload e a página compartilham `window`: a página reescreve o que o preload expôs |
| `nodeIntegration` | **`false`** | `require('child_process')` a partir de um XSS é RCE local, sem mais nada |
| `sandbox` | **`true`** | o renderer roda no sandbox do Chromium; o preload passa a precisar de IPC para tudo — que é o ponto |
| `webSecurity` | **`true`** (nunca desligar) | desligar é o atalho de CORS em dev que viaja para produção |
| `nodeIntegrationInSubFrames` | **`false`** | iframe de terceiro herdando Node é o furo lateral |
| `allowRunningInsecureContent` | **`false`** | conteúdo misto anula o TLS |

E na aplicação:

- **`contextBridge.exposeInMainWorld`** expõe **funções nomeadas**, nunca `ipcRenderer` inteiro.
  Expor `send`/`invoke` cru é reabrir a ponte que o `contextIsolation` fechou.
- **Handler de IPC valida o canal e os argumentos** no main, e **nunca** interpola argumento em
  comando de shell.
- **`setWindowOpenHandler` + `will-navigate`**: nega navegação e janela para qualquer origem que não
  seja a sua. Sem isso, um link basta para carregar site arbitrário **dentro** do app.
- **`shell.openExternal`** só com URL validada por allowlist de esquema (`https:`) — nunca a string
  que veio da página.
- **CSP por header/meta**, sem `unsafe-inline` no que executa.
- **Fuses** (`@electron/fuses`), aplicadas no build — são o que impede transformar o **binário
  assinado** do usuário em interpretador Node: desligue `RunAsNode`,
  `EnableNodeCliInspectArguments`, `EnableNodeOptionsEnvironmentVariable`; ligue `OnlyLoadAppFromAsar`
  e `EnableEmbeddedAsarIntegrityValidation`. Sem elas, `ELECTRON_RUN_AS_NODE=1 seu-app.exe
  script.js` roda código arbitrário **com a assinatura e a reputação do seu app**.
- **Versão do Electron é dívida de segurança com prazo:** o Chromium embutido é seu, não do SO.
  Sair das 3 majors suportadas é rodar um browser sem patch (`stack-versoes.md`).

## 4. O gate

`scripts/check-web-in-native.sh` cobra este capítulo no repo:

```bash
bash scripts/check-web-in-native.sh .          # ou /desktop-bridge
```

Reprova: `allowlist` com `"all": true`; projeto Tauri 2 **sem nenhuma capability**; scope de `fs`
alcançando `$HOME/**` ou `**`; qualquer chave `dangerousRemoteDomainIpcAccess`; `csp: null`;
`nodeIntegration: true`; `contextIsolation: false`; `sandbox: false`; `webSecurity: false`;
`exposeInMainWorld` entregando `ipcRenderer` inteiro; e projeto Electron **sem configuração de
fuses**. E **repo sem nenhum dos dois** sai `2`, não `0` — não há o que aprovar.

## 5. DoD de web-in-native

- [ ] A ponte expõe **ações de domínio**, não primitivas de SO; todo argumento validado no nativo.
- [ ] **Tauri:** capability por janela, com o mínimo; scope de `fs` restrito + `deny` dos sensíveis;
      sem `allowlist` residual; sem chave `dangerous*` sem ADR; CSP definida.
- [ ] **Electron:** `contextIsolation: true`, `nodeIntegration: false`, `sandbox: true`,
      `webSecurity` intocado; `contextBridge` com funções nomeadas; `will-navigate` e
      `setWindowOpenHandler` negando por default; **fuses aplicadas**; versão atual.
- [ ] Nenhum conteúdo remoto dentro da janela privilegiada.
- [ ] O gate do §4 roda no CI e **foi visto reprovando** (`scripts/check-web-in-native.test.sh`).
