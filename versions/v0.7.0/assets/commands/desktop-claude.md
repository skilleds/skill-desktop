---
description: schematize-desktop — cria ou mescla o CLAUDE.md sempre-on de software local/desktop na raiz do repo (não sobrescreve blocos de outras skills)
---

Instale/atualize a regra **sempre-on** de engenharia de software local/desktop na raiz do
repositório.

1. Pegue `assets/CLAUDE.md` da skill `schematize-desktop` (projeto ou `~/.claude/skills/...`).
2. Se **não existe** `CLAUDE.md` na raiz: crie com esse conteúdo.
3. Se **já existe** (de outra skill — engineering/rust/web/pentest/...): **mescle** — adicione a
   seção de Engenharia de Software Local/Desktop **sem sobrescrever** os blocos das outras skills. Em
   repo multi-skill (ex.: monorepo GUI + backend), cada CLAUDE convive; o piso do desktop é aditivo.
4. Se houver customização local, salve `./CLAUDE.md.bak` e reaplique por cima.
5. Confirme a versão aplicada e destaque o **piso**: o piso da casa é o mesmo; **prever macacos**
   (root→usuário real, PATH mínimo→resolve, toolchain ausente→configura, nunca culpa o usuário); um
   só toolkit por produto; updater desacoplado + versão embutida coerente (git-dep); launcher com
   path absoluto; sem segredo no cliente.
