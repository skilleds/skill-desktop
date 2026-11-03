# Testes de app local — GUI headless, smoke de empacotamento, update ponta-a-ponta

> O piso da casa é **"verde de verdade"** (`schematize-qa`): teste que prova comportamento, não
> checkbox. No desktop há três provas que **só o software local exige** e que costumam faltar: **a
> GUI roda headless no CI**, **o pacote instala e abre naquele SO**, e **o update vN→vN+1→rollback
> funciona**. Sem elas, "cross-platform" e "auto-update" são fé, não fato.

## 1. A pirâmide vale — e o domínio testa SEM abrir janela

- **Unit/domínio sem toolkit:** o domínio não conhece Slint/Qt/GTK (`toolkits-gui.md`), então
  **testa headless, rápido, sem device gráfico**. A maior parte da lógica (estado, casos de uso,
  migração de schema, outbox) tem cobertura aqui.
- **Integração:** store local (SQLite/arquivo) com migração real; cliente de rede com backend fake;
  IPC local. Sem tela.
- **Componente/e2e de UI:** só o que **exige** a UI — e aí entra o headless (item 2).

## 2. GUI headless no CI (o teste que "não dá pra rodar sem tela" — dá)

- **Servidor gráfico virtual:** rode a GUI sob **Xvfb**/`weston --headless`/backend headless do
  toolkit (Slint tem backend de teste/`skia`+offscreen; Qt tem `-platform offscreen`). O CI **abre o
  app sem monitor**.
- **Smoke de UI mínimo:** o app **sobe**, a janela principal **renderiza**, os elementos-chave
  existem, uma interação básica (clicar, digitar) **responde**. Isso já pega crash de boot, painel
  em branco, e o **"fantasma de layout"** (`toolkits-gui.md`) — dois toolkits brigando estouram
  aqui.
- **Snapshot/render test** onde o render importa: renderize offscreen e compare com baseline (pega
  regressão visual, tofu de fonte CJK — teste com **strings CJK/árabe/emoji reais**, `cross-os.md`).
- **Por SO:** o headless roda **em cada SO da matriz** (runner Linux/macOS/Windows no CI), senão só
  o Linux está testado.

## 3. Smoke test de EMPACOTAMENTO (o pacote instala e abre?)

Bug que só aparece no usuário: compilou, mas o **pacote** não instala/não abre naquele SO
(dependência faltando, assinatura recusada, `.desktop` errado, binário no lugar errado).

- **Ambiente limpo por SO:** container/VM **sem toolchain e sem o app** → **instala o pacote**
  (.deb/.rpm/AppImage/Flatpak, .dmg, MSI/MSIX) → **abre o app** (headless) → **fecha limpo**. Se não
  abre num ambiente limpo, **não** está distribuível (`empacotamento.md`).
- **Verifica assinatura/notarization:** o smoke do macOS confirma que o `.app` passa o Gatekeeper
  (notarizado+stapled); o do Windows, Authenticode; senão o usuário toma bloqueio.
- **`.desktop`/atalho:** confirma `Exec` **absoluto** e que o launcher abre **o binário certo** (não
  a versão antiga coexistindo — `privilegio-fs.md`, o launcher do menu apontando para o binário errado).
- **Idempotência/desinstalação:** reinstalar por cima não duplica; desinstalar **preserva dados** do
  usuário.

## 4. Teste de UPDATE ponta-a-ponta (o mais esquecido)

O update troca o próprio binário — tem de ser testado como fluxo, não só "o updater compila":

- **vN → vN+1:** instala a versão N, roda o updater, confirma que **virou N+1**, que o **`--version`
  bate** (pega o **git-dep pinado mentiroso** — `auto-update.md`: o release roda `cargo build --locked`
  e **falha se a versão embutida não bate** com o `rev`/`tag` do git-dep), e que o **estado do usuário
  sobreviveu** (migração de schema, `offline-estado.md`).
- **Processo antigo morto + re-exec:** confirma que **não sobrou processo órfão** segurando o
  binário/lock (`privilegio-fs.md`) — não basta a janela ter fechado.
- **Rollback:** força a nova versão a **falhar o self-check** e confirma **rollback automático** pra
  N com estado íntegro (backup pré-migração restaurado).
- **Windows travado:** cobre o caso do executável em uso (troca agendada/por processo auxiliar).
- **Update sequestrável:** artefato com assinatura/hash **inválido** é **recusado** (não instala) —
  casa com a `schematize-pentest`.

## 5. Gates e disciplina (herda schematize-qa)

- **Nada de teste silenciado** pra passar CI (`.skip`, comentar assert, baixar threshold) — conserta
  o código (§37).
- **Flaky de UI** (timing/animação) é caçado, não tolerado: espere por condição, não por `sleep`.
- **CI por SO** (em tag/hml/pedido, §7) é obrigatório pra tudo que é cross-OS (headless + smoke de pacote + update em
  Linux/macOS/Windows). Um SO sem esses gates **não** está suportado.
- **Cobertura útil** no domínio; caminhos críticos (migração, update, privilégio root→usuário) com
  teste **explícito**.

## 6. DoD de testes locais

- [ ] domínio testado **headless** (sem toolkit); pirâmide respeitada;
- [ ] **GUI headless no CI** por SO (sobe, renderiza, interage; snapshot com strings CJK/árabe);
- [ ] **smoke de empacotamento** por SO em ambiente limpo (instala+abre+assinatura+`.desktop`
      absoluto);
- [ ] **update ponta-a-ponta** (vN→vN+1, versão coerente, estado preservado, processo antigo morto,
      **rollback**, artefato inválido recusado);
- [ ] sem teste silenciado; flaky de UI caçado; **CI dos 3 SOs roda em tag/hml/pedido**.

## 7. Gatilho de CI (piso 27)

Headless + smoke de pacote + update nos **3 SOs** rodam **só em tag/hml/pedido do usuário**
(`workflow_dispatch` + `push: tags: ["hml-*","v*"]`, `concurrency` `cancel-in-progress: true`,
`paths-ignore` docs/md; vetado `pull_request`/push em branch). Por commit vale o **gate local**
(`scripts/check-*.sh`, testes de domínio headless).
