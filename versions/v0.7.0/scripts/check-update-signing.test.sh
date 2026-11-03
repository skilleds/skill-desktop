#!/usr/bin/env bash
# Vermelho primeiro do gate de update-signing.
# EXCEÇÃO DECLARADA de strict mode: harness sem `-e` para reportar todos os casos.
set -u
AQUI="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
G="$AQUI/check-update-signing.sh"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
ok=0; fail=0
checa() { local nome="$1" esp="$2"; shift 2; "$@" >/dev/null 2>&1; local rc=$?
  if [ "$rc" = "$esp" ]; then echo "  ✔ $nome"; ok=$((ok+1)); else echo "  ✖ $nome: exit $rc, esperado $esp"; fail=$((fail+1)); fi; }
novo() { mkdir -p "$TMP/$1/.github/workflows" "$TMP/$1/src-tauri"; }
bom() { novo "$1"
  echo '{"bundle":{"createUpdaterArtifacts":true},"plugins":{"updater":{"pubkey":"dW50cnVzdGVk"}}}' > "$TMP/$1/src-tauri/tauri.conf.json"
  printf 'jobs:\n  b:\n    steps:\n      - run: cargo build --release --locked\n' > "$TMP/$1/.github/workflows/r.yml"; }
bom ok;                    checa "projeto correto passa" 0 "$G" "$TMP/ok"
bom a; echo '{"bundle":{"createUpdaterArtifacts":true},"plugins":{"updater":{}}}' > "$TMP/a/src-tauri/tauri.conf.json"
checa "sem pubkey reprova" 1 "$G" "$TMP/a"
bom b; echo '{"bundle":{},"plugins":{"updater":{"pubkey":"x"}}}' > "$TMP/b/src-tauri/tauri.conf.json"
checa "sem createUpdaterArtifacts reprova" 1 "$G" "$TMP/b"
bom c; printf 'jobs:\n  b:\n    steps:\n      - run: cargo update -p dep\n      - run: cargo build --release --locked\n' > "$TMP/c/.github/workflows/r.yml"
checa "cargo update em workflow reprova" 1 "$G" "$TMP/c"
bom d; printf 'jobs:\n  b:\n    steps:\n      - run: cargo build --release\n' > "$TMP/d/.github/workflows/r.yml"
checa "release sem --locked reprova" 1 "$G" "$TMP/d"
echo "$ok ok, $fail falha(s)"; [ "$fail" = 0 ]
