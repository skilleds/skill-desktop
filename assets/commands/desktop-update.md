---
description: schematize-desktop — audita/planeja o auto-update DESACOPLADO (pin/rollback, git-dep no Cargo.lock, trocar binário em uso, matar processo antigo + re-exec, canal verificado) e gera teste de update ponta-a-ponta
argument-hint: "[updater / pipeline de release]"
---

Audite/planeje o **auto-update** deste app (`references/auto-update.md`). Premissa: o update é a
operação mais perigosa que um app faz — **troca o próprio binário em uso**. Dois pisos: **updater
DESACOPLADO** e **versão embutida sempre coerente**.

## 1. Desacoplamento
- O updater é **componente/binário separado** (modelo `schematize-updater`): **app quebrado não trava
  o update** (updater roda mesmo se a versão instalada crasha no boot) e **update quebrado não
  derruba o app** (valida antes de trocar, rollback se não sobe). Confirme a fronteira.

## 2. A ARMADILHA do git-dep pinado (anti-padrão concreto)
- Se há dep por **git** no `Cargo.toml`, o **`Cargo.lock` pina o commit** → o build recompila contra
  o commit **VELHO** e o binário **embute versão/comportamento antigo** (o `--version` mente).
- **Piso:** `cargo update -p <dep>` é passo **explícito, commitado e pushado** (commit separado do
  Cargo.lock; fora do build de release). git-deps com `rev =`/`tag =`; o release roda
  `cargo build --locked` do SHA/tag e **falha** se a versão/hash do git-dep diverge do esperado (não publica versão que mente). Vale pra qualquer lockfile
  que pina fonte VCS.

## 3. Troca de binário + matar processo antigo + re-exec
- **Linux/macOS:** baixa temp → valida → `rename` atômico por cima → **re-exec** (`execv`).
- **Windows:** executável em uso fica **travado** → troca por processo auxiliar/`MoveFileEx`/no
  reboot.
- **MATAR o processo antigo, não só fechar a janela**: encerra processo/tray/daemon de verdade
  (sinal + espera + kill), libera o **lock de single-instance** (`privilegio-fs.md`), e **re-exec** a
  nova versão. Bug real: janela fecha, processo fica órfão segurando o binário/lock.

## 4. Pin, rollback, self-check e canal seguro
- **Pin** respeitado; **rollback automático** se a nova versão falha o **self-check pós-update**
  (abre? `--version` coerente? estado íntegro?) — com **backup pré-migração** (`offline-estado.md`).
- Canal **HTTPS + verificação de assinatura/hash** do artefato antes de instalar (update não
  verificado = RCE; `privacidade-seguranca.md`, `schematize-pentest`).

## Saída — teste de update ponta-a-ponta
Gere/planeje o teste **vN → vN+1 → rollback** (`testes-locais.md`): versão coerente (pega git-dep
mentiroso), estado do usuário preservado, **processo antigo morto** (sem órfão), rollback em falha,
artefato inválido recusado, caso Windows travado. Reporte cada garantia como **FEITO com teste** ou
**EM ABERTO** (DoD, §35).
