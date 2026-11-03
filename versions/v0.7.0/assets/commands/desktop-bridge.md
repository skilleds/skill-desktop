---
description: schematize-desktop — audita a ponte web↔nativo (capabilities/permissions/scopes do Tauri 2, isolamento + sandbox + fuses do Electron) e roda o gate
argument-hint: "[diretório do app]"
---

# /desktop-bridge — a ponte é a fronteira de confiança

No browser, um XSS rouba a sessão. **Aqui ele chama o sistema operacional.** Toda a diferença está
em quanto de SO o webview alcança — e é isso que este comando audita
(`references/web-in-native.md`).

## 1. Rode o gate primeiro

```bash
bash .claude/skills/schematize-desktop/scripts/check-web-in-native.sh .
```

`0` passa · `1` reprova · `2` **não há projeto Tauri nem Electron** (não é aprovação).

## 2. A regra que vale para os dois toolkits

**Deny-by-default, e o frontend pede uma AÇÃO, não acesso.** Exponha `salvarRelatorio(dados)`, nunca
`escreverArquivo(caminho, bytes)`: com a primitiva, o caminho vem do lado hostil e vira leitura de
`~/.ssh/id_rsa`; com o comando de domínio, o caminho é decidido no lado nativo. Todo argumento vindo
do webview é **entrada hostil** e se valida no nativo — validar no JS é UX, não controle.

## 3. Tauri 2 — o que olhar

Capability **por janela** com o mínimo (a janela de login não precisa de `fs`) · scope restrito, com
`deny` para `**/.ssh/**`, `**/.env`, `**/id_*` — porque `allow` amplo com `deny` explícito falha de
forma segura quando alguém alargar o `allow` depois · nenhuma chave `dangerous*` sem ADR · CSP
definida em `app.security.csp` · `#[tauri::command]` é superfície pública. **Cheiro de migração
incompleta:** bloco `allowlist` (v1) com `src-tauri/capabilities/` vazio.

## 4. Electron — o que olhar

`contextIsolation: true` · `nodeIntegration: false` · `sandbox: true` · `webSecurity` intocado ·
`contextBridge` expondo **funções nomeadas**, nunca `ipcRenderer` nem `send`/`invoke` crus ·
`will-navigate` e `setWindowOpenHandler` negando por default · `shell.openExternal` só com allowlist
de esquema · **fuses aplicadas** (`RunAsNode` off, `OnlyLoadAppFromAsar` on): sem elas,
`ELECTRON_RUN_AS_NODE=1 seu-app` roda código arbitrário **com a assinatura do seu app**.

## 5. Feche pela DoD

`references/web-in-native.md` §5. E rode o vermelho do gate antes de confiar nele:
`bash .claude/skills/schematize-desktop/scripts/check-web-in-native.test.sh` (16 casos).
