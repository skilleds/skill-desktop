#!/usr/bin/env bash
# Vermelho primeiro do gate de web-in-native. Cada fixture e um app de mentira com UM furo.
# EXCEÇÃO DECLARADA de strict mode (`schematize-shell` -> `references/piso.md` secao 1):
# harness de teste roda sem `-e` de propósito — ele precisa continuar depois de um caso
# vermelho para reportar TODOS, em vez de parar no primeiro.
set -u
AQUI="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
G="$AQUI/check-web-in-native.sh"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
ok=0; fail=0
checa() { local nome="$1" esp="$2" agulha="$3"; shift 3
  local saida; saida="$("$@" 2>&1)"; local rc=$?
  if [ "$rc" != "$esp" ]; then echo "  ✖ $nome: exit $rc, esperado $esp"; sed 's/^/      /' <<<"$saida"; fail=$((fail+1)); return; fi
  if [ -n "$agulha" ] && ! grep -qF -- "$agulha" <<<"$saida"; then echo "  ✖ $nome: exit certo, saida sem \"$agulha\""; sed 's/^/      /' <<<"$saida"; fail=$((fail+1)); return; fi
  echo "  ✔ $nome"; ok=$((ok+1)); }

tauri_ok() { # $1 = raiz
  mkdir -p "$1/src-tauri/capabilities"
  cat > "$1/src-tauri/tauri.conf.json" <<'C'
{ "productName": "app",
  "app": { "security": { "csp": "default-src 'self'" } } }
C
  cat > "$1/src-tauri/capabilities/principal.json" <<'C'
{ "identifier": "principal",
  "windows": ["principal"],
  "permissions": [
    "core:default",
    { "identifier": "fs:allow-app-write",
      "allow": [{ "path": "$APPDATA/relatorios/*" }],
      "deny":  [{ "path": "**/.ssh/**" }, { "path": "**/.env" }] }
  ] }
C
}
electron_ok() { # $1 = raiz
  mkdir -p "$1/src"
  cat > "$1/src/main.js" <<'E'
const { app, BrowserWindow, shell } = require('electron')
function criar() {
  const w = new BrowserWindow({
    webPreferences: { contextIsolation: true, nodeIntegration: false, sandbox: true, preload: 'preload.js' },
  })
  w.webContents.setWindowOpenHandler(({ url }) => { shell.openExternal(url); return { action: 'deny' } })
  w.webContents.on('will-navigate', (e) => e.preventDefault())
}
E
  cat > "$1/src/preload.js" <<'E'
const { contextBridge, ipcRenderer } = require('electron')
contextBridge.exposeInMainWorld('api', { salvarRelatorio: (d) => ipcRenderer.invoke('relatorio:salvar', d) })
E
  cat > "$1/forge.config.js" <<'E'
const { FusesPlugin } = require('@electron-forge/plugin-fuses')
const { FuseV1Options, FuseVersion } = require('@electron/fuses')
module.exports = { plugins: [ new FusesPlugin({
  version: FuseVersion.V1,
  [FuseV1Options.RunAsNode]: false,
  [FuseV1Options.EnableNodeCliInspectArguments]: false,
  [FuseV1Options.EnableNodeOptionsEnvironmentVariable]: false,
  [FuseV1Options.OnlyLoadAppFromAsar]: true,
  [FuseV1Options.EnableEmbeddedAsarIntegrityValidation]: true,
}) ] }
E
}

echo "== verde de partida =="
d="$TMP/ok"; mkdir -p "$d"; tauri_ok "$d"; electron_ok "$d"
checa "app Tauri+Electron no piso passa" 0 "ponte verificada" bash "$G" "$d"

d="$TMP/nada"; mkdir -p "$d"; echo "# so prosa" > "$d/README.md"
checa "repo sem web-in-native sai 2 (nao 0)" 2 "nada de web-in-native" bash "$G" "$d"

echo "== Tauri =="
d="$TMP/t-all"; mkdir -p "$d"; tauri_ok "$d"
python3 -c "
import json;p='$d/src-tauri/tauri.conf.json';j=json.load(open(p));j['tauri']={'allowlist':{'all':True}};json.dump(j,open(p,'w'))"
checa 'allowlist "all": true reprova' 1 'anula o modelo inteiro' bash "$G" "$d"

d="$TMP/t-semcap"; mkdir -p "$d/src-tauri/capabilities"
cat > "$d/src-tauri/tauri.conf.json" <<'C'
{ "app": { "security": { "csp": "default-src 'self'" } } }
C
checa "projeto Tauri sem NENHUMA capability reprova" 1 "sem NENHUMA capability" bash "$G" "$d"

d="$TMP/t-v1resid"; mkdir -p "$d/src-tauri/capabilities"
cat > "$d/src-tauri/tauri.conf.json" <<'C'
{ "tauri": { "allowlist": { "fs": { "readFile": true } } }, "app": { "security": { "csp": "x" } } }
C
checa "allowlist v1 + capabilities vazio = migracao pela metade" 1 "migracao pela metade" bash "$G" "$d"

d="$TMP/t-scope"; mkdir -p "$d"; tauri_ok "$d"
python3 -c "
import json;p='$d/src-tauri/capabilities/principal.json';j=json.load(open(p))
j['permissions'][1]['allow']=[{'path':'\$HOME/**'}];json.dump(j,open(p,'w'))"
checa "scope em \$HOME/** reprova" 1 "ausencia de escopo" bash "$G" "$d"

d="$TMP/t-csp"; mkdir -p "$d"; tauri_ok "$d"
python3 -c "
import json;p='$d/src-tauri/tauri.conf.json';j=json.load(open(p));j['app']['security']['csp']=None;json.dump(j,open(p,'w'))"
checa "csp: null reprova" 1 "csp: null" bash "$G" "$d"

d="$TMP/t-danger"; mkdir -p "$d"; tauri_ok "$d"
python3 -c "
import json;p='$d/src-tauri/tauri.conf.json';j=json.load(open(p))
j['app']['security']['dangerousRemoteDomainIpcAccess']=[{'domain':'exemplo.com'}];json.dump(j,open(p,'w'))"
checa "dangerousRemoteDomainIpcAccess reprova" 1 "nao e decorativo" bash "$G" "$d"

echo "== Electron =="
for par in "nodeIntegration: false|nodeIntegration: true|RCE local" \
           "contextIsolation: true|contextIsolation: false|compartilham window" \
           "sandbox: true|sandbox: false|sandbox: false" ; do
  IFS='|' read -r de para agulha <<<"$par"
  d="$TMP/e-$(echo "$para" | tr -cd 'a-zA-Z')"; mkdir -p "$d"; electron_ok "$d"
  sed -i "s/$de/$para/" "$d/src/main.js"
  checa "$para reprova" 1 "$agulha" bash "$G" "$d"
done

d="$TMP/e-websec"; mkdir -p "$d"; electron_ok "$d"
sed -i 's/sandbox: true/sandbox: true, webSecurity: false/' "$d/src/main.js"
checa "webSecurity: false reprova" 1 "viaja para producao" bash "$G" "$d"

d="$TMP/e-semctx"; mkdir -p "$d"; electron_ok "$d"
sed -i 's/contextIsolation: true, //' "$d/src/main.js"
checa "contextIsolation nao declarado reprova (default nao e decisao)" 1 "default nao conta como decisao" bash "$G" "$d"

d="$TMP/e-ipc"; mkdir -p "$d"; electron_ok "$d"
cat > "$d/src/preload.js" <<'E'
const { contextBridge, ipcRenderer } = require('electron')
contextBridge.exposeInMainWorld('api', ipcRenderer)
E
checa "exposeInMainWorld(ipcRenderer) reprova" 1 "reabre a ponte" bash "$G" "$d"

d="$TMP/e-cru"; mkdir -p "$d"; electron_ok "$d"
cat > "$d/src/preload.js" <<'E'
const { contextBridge, ipcRenderer } = require('electron')
contextBridge.exposeInMainWorld('api', { invoke: ipcRenderer.invoke, send: ipcRenderer.send })
E
checa "send/invoke cru reprova" 1 "FUNCOES NOMEADAS" bash "$G" "$d"

d="$TMP/e-semfuse"; mkdir -p "$d"; electron_ok "$d"; rm "$d/forge.config.js"
checa "Electron sem fuses reprova" 1 "interpretador Node" bash "$G" "$d"

echo; echo "check-web-in-native: $ok ok, $fail falha(s)"; [ "$fail" = 0 ]
