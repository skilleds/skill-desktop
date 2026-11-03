#!/usr/bin/env bash
# schematize-desktop — gate de assinatura/updater (references/auto-update.md).
# Reprova: Tauri com plugin updater sem plugins.updater.pubkey / bundle.createUpdaterArtifacts;
# workflow que roda `cargo update` ou `cargo build/install` de release sem --locked.
# uso: check-update-signing.sh [dir]  ·  0 = passa · 1 = REPROVA
# strict-ok: coletor — soma todos os erros em `erros[]` e reporta de uma vez; com `-e` pararia no primeiro grep sem match
set -uo pipefail
raiz="${1:-.}"
erros=()
while IFS= read -r c; do
  [ -n "$c" ] || continue
  grep -q '"updater"' "$c" || continue   # só quem declara o plugin updater
  grep -qE '"pubkey"\s*:\s*"[^"]+"' "$c" || erros+=("$c: plugins.updater.pubkey ausente/vazio")
  grep -qE '"createUpdaterArtifacts"\s*:\s*(true|"v1Compatible")' "$c" || erros+=("$c: bundle.createUpdaterArtifacts ausente")
done < <(find "$raiz" -type f -name 'tauri.conf.json' -not -path '*/node_modules/*' -not -path '*/.git/*' -not -path '*/target/*' -not -path '*/versions/*')
while IFS= read -r w; do
  [ -n "$w" ] || continue
  grep -nE '^\s*[^#]*cargo update' "$w" >/dev/null && erros+=("$w: 'cargo update' dentro de workflow — o lock é atualizado em commit explícito, fora do release")
  grep -nE '^\s*[^#]*cargo (build|install)[^#]*--release' "$w" | grep -qv -- '--locked' && erros+=("$w: build de release sem --locked")
done < <(find "$raiz" -type f \( -path '*/.github/workflows/*.yml' -o -path '*/.github/workflows/*.yaml' \) -not -path '*/.git/*' -not -path '*/versions/*')
if [ ${#erros[@]} -gt 0 ]; then
  echo "✖ update-signing REPROVADO — ${#erros[@]} problema(s):" >&2
  for e in "${erros[@]}"; do echo "  · $e" >&2; done
  exit 1
fi
echo "✔ update-signing: ok."
