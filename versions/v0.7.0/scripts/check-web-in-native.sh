#!/usr/bin/env bash
# schematize-desktop — gate de web-in-native (references/web-in-native.md).
#
# A tese: no browser um XSS rouba a sessao; aqui ele chama o sistema operacional. Este gate cobra o
# que decide isso — quanto de SO o webview alcanca.
#
# uso: check-web-in-native.sh [dir]  ·  0 = passa · 1 = REPROVA · 2 = nao ha projeto web-in-native
# EXCEÇÃO DECLARADA de strict mode (`schematize-shell` -> `references/piso.md` secao 1):
# este script é um COLETOR — ele varre tudo e SOMA os achados. Com `set -e` abortaria no
# primeiro problema e reportaria um, escondendo os outros. Por isso `set -uo pipefail` sem `-e`.
set -uo pipefail
raiz="${1:-.}"
erros=(); avisos=()
sem_comentario() { sed 's|//.*$||' "$1"; }   # tira comentario de linha antes de casar

achar() { find "$raiz" -type f "$@" \
  -not -path '*/node_modules/*' -not -path '*/.git/*' -not -path '*/target/*' \
  -not -path '*/dist/*' -not -path '*/versions/*' 2>/dev/null; }

confs_tauri=$(achar -name 'tauri.conf.json' -o -name 'tauri.conf.json5' -o -name 'Tauri.toml')
caps_dir=$(find "$raiz" -type d -name capabilities -not -path '*/node_modules/*' -not -path '*/.git/*' 2>/dev/null | head -1)
fontes_electron=$(grep -rl --include='*.js' --include='*.mjs' --include='*.cjs' --include='*.ts' \
  --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=dist --exclude-dir=versions \
  -E "require\(['\"]electron['\"]\)|from ['\"]electron['\"]|new BrowserWindow" "$raiz" 2>/dev/null)

if [ -z "$confs_tauri" ] && [ -z "$fontes_electron" ]; then
  echo "✖ nenhum projeto Tauri ou Electron em $raiz — nada de web-in-native para verificar." >&2
  exit 2
fi

# ------------------------------------------------------------------------------------ Tauri
for c in $confs_tauri; do
  nome="${c#$raiz/}"
  txt="$(sem_comentario "$c")"
  grep -qE '"all"\s*:\s*true' <<<"$txt" && erros+=("$nome: allowlist com \"all\": true — concede tudo e anula o modelo inteiro")
  grep -qE '"dangerousRemoteDomainIpcAccess"' <<<"$txt" && erros+=("$nome: dangerousRemoteDomainIpcAccess — IPC para conteudo remoto exige ADR; o nome nao e decorativo")
  grep -qE '"dangerousDisableAssetCspModification"\s*:\s*true' <<<"$txt" && erros+=("$nome: dangerousDisableAssetCspModification: true")
  grep -qE '"csp"\s*:\s*null' <<<"$txt" && erros+=("$nome: csp: null — o webview renderiza HTML; sem CSP um innerHTML mal-feito ja e o comeco")
  grep -qE '"csp"' <<<"$txt" || avisos+=("$nome: nenhuma CSP declarada em app.security.csp")
  # v1 residual em projeto v2: allowlist presente E nenhuma capability concedida.
  if grep -qE '"allowlist"' <<<"$txt"; then
    if [ -z "$caps_dir" ] || [ -z "$(ls -A "$caps_dir" 2>/dev/null)" ]; then
      erros+=("$nome: bloco allowlist (Tauri 1) sem nenhuma capability em src-tauri/capabilities/ — migracao pela metade: a permissao do v1 nao vale e ninguem concedeu nada no v2")
    else
      avisos+=("$nome: allowlist residual do Tauri 1 convivendo com capabilities — remova o bloco morto")
    fi
  elif [ -z "$caps_dir" ] || [ -z "$(ls -A "$caps_dir" 2>/dev/null)" ]; then
    erros+=("$nome: projeto Tauri sem NENHUMA capability — ou o app nao usa a ponte (entao remova a dependencia) ou alguem vai conceder tudo depois")
  fi
done

if [ -n "$caps_dir" ]; then
  for cap in "$caps_dir"/*.json "$caps_dir"/*.toml; do
    [ -e "$cap" ] || continue
    nome="${cap#$raiz/}"
    txt="$(sem_comentario "$cap")"
    grep -qE '"\$HOME/\*\*"|"\*\*"|"\*\*/\*"' <<<"$txt" && erros+=("$nome: scope alcancando \$HOME/** ou ** — escopo com curinga total e ausencia de escopo")
    grep -qE '"windows"' <<<"$txt" || avisos+=("$nome: capability sem \"windows\" — concedida a TODAS as janelas")
    grep -qE '"deny"' <<<"$txt" || avisos+=("$nome: sem lista deny (\`**/.ssh/**\`, \`**/.env\`, \`**/id_*\`) — allow amplo sem deny falha aberto quando alguem alargar")
  done
fi

# --------------------------------------------------------------------------------- Electron
if [ -n "$fontes_electron" ]; then
  janela=$(grep -rl 'new BrowserWindow' $fontes_electron 2>/dev/null)
  for f in $janela; do
    nome="${f#$raiz/}"
    txt="$(sem_comentario "$f")"
    grep -qE 'nodeIntegration\s*:\s*true' <<<"$txt" && erros+=("$nome: nodeIntegration: true — require('child_process') a partir de um XSS e RCE local")
    grep -qE 'contextIsolation\s*:\s*false' <<<"$txt" && erros+=("$nome: contextIsolation: false — pagina e preload compartilham window")
    grep -qE 'sandbox\s*:\s*false' <<<"$txt" && erros+=("$nome: sandbox: false")
    grep -qE 'webSecurity\s*:\s*false' <<<"$txt" && erros+=("$nome: webSecurity: false — o atalho de CORS do dev que viaja para producao")
    grep -qE 'allowRunningInsecureContent\s*:\s*true' <<<"$txt" && erros+=("$nome: allowRunningInsecureContent: true")
    grep -qE 'nodeIntegrationInSubFrames\s*:\s*true' <<<"$txt" && erros+=("$nome: nodeIntegrationInSubFrames: true")
    grep -qE 'contextIsolation\s*:' <<<"$txt" || erros+=("$nome: contextIsolation nao declarado — neste repo tudo e explicito, default nao conta como decisao")
    grep -qE 'sandbox\s*:' <<<"$txt" || avisos+=("$nome: sandbox nao declarado")
    grep -qE 'setWindowOpenHandler' <<<"$txt" || avisos+=("$nome: sem setWindowOpenHandler — um link basta para abrir site arbitrario no app")
    grep -qE "will-navigate" <<<"$txt" || avisos+=("$nome: sem handler de will-navigate")
  done
  for f in $fontes_electron; do
    nome="${f#$raiz/}"
    txt="$(sem_comentario "$f")"
    grep -qE 'exposeInMainWorld\s*\([^)]*,\s*ipcRenderer\s*\)' <<<"$txt" && erros+=("$nome: exposeInMainWorld expondo ipcRenderer inteiro — reabre a ponte que o contextIsolation fechou")
    grep -qE 'exposeInMainWorld[^)]*(send|invoke)\s*:\s*ipcRenderer\.(send|invoke)\s*[,}]' <<<"$txt" && erros+=("$nome: exposeInMainWorld expondo send/invoke cru — exponha FUNCOES NOMEADAS de dominio")
  done
  fuses=$(grep -rlE '@electron/fuses|flipFuses|FuseV1Options' "$raiz" --include='*.js' --include='*.mjs' --include='*.cjs' --include='*.ts' --include='*.json' --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null | head -1)
  [ -n "$fuses" ] || erros+=("projeto Electron sem configuracao de fuses — sem elas, ELECTRON_RUN_AS_NODE=1 transforma o binario ASSINADO do usuario em interpretador Node")
fi

for a in "${avisos[@]:-}"; do [ -n "$a" ] && echo "  ! $a" >&2; done
if [ ${#erros[@]} -gt 0 ]; then
  echo "✖ web-in-native REPROVADO — ${#erros[@]} problema(s):" >&2
  for e in "${erros[@]}"; do echo "  · $e" >&2; done
  exit 1
fi
echo "✔ web-in-native: ponte verificada (Tauri: ${confs_tauri:+sim}${confs_tauri:-nao} · Electron: ${fontes_electron:+sim}${fontes_electron:-nao})."
