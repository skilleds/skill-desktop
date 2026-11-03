---
description: Context Compact — gera handoff (context.md + checklist.md) no <projeto>_archive e compacta
---

Antes de compactar, **arquive o handoff** (não perca o estado do trabalho de desktop):

1. `<projeto>_archive/context/<YYYY-MM-DD-HH-MM-SS>-context.md` — estado: toolkit de GUI escolhido
   (e ADR), o que já foi feito em empacotamento / auto-update / estado local / privilégio / cross-OS,
   decisões pendentes, telas/comandos/SOs tocados, onde parou.
2. `<projeto>_archive/context/<YYYY-MM-DD-HH-MM-SS>-checklist.md` — **FEITO vs EM ABERTO** (pisos
   verificados vs pendentes: um só toolkit? updater desacoplado + versão coerente (git-dep)? launcher
   com Exec absoluto? root→usuário real? sem segredo no binário? smoke por SO?).
3. Só então rode `/compact` (foco na tarefa corrente).
