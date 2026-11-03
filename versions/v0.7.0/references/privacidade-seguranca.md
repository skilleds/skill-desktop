<!-- cross-skill: cadeia-suprimentos.md, iam.md -> schematize-engineering -->
# Privacidade e segurança do software local

> Na máquina do usuário **não há servidor pra segurar a barra**: o binário É o produto e roda no
> computador do adversário. Duas frentes: **privacidade** (o dado do usuário é dele — sem telemetria
> por padrão) e **segurança** (supply chain de deps nativas, assinatura de binário, e o piso
> herdado — **nunca segredo embutido no cliente**). A segurança ofensiva (extrair segredo do
> binário, sequestrar update, escalar privilégio) é a `schematize-pentest`.

## 1. Privacidade — sem telemetria por padrão, opt-in explícito, local-first

- **Sem telemetria por padrão.** O app **não** manda uso/analytics/crash pra fora sem o usuário
  **ligar explicitamente**. Nada de "opt-out escondido" nem "aceitou nos termos". Default = **nada
  sai da máquina**.
- **Opt-in explícito e granular:** se houver telemetria, o usuário **liga** conscientemente, vê **o
  que** é coletado, e pode **desligar** a qualquer momento. Preferência **local-first**.
- **Sem PII saindo:** telemetria (quando ligada) é **agregada/anônima** — nunca conteúdo do usuário,
  path com nome, ou identificador pessoal. PII **nunca** em log/crash report (mesma regra do
  `schematize-mobile`).
- **Crash report idem:** stack trace pode conter dados sensíveis; **só envia com opt-in**, e
  **scrub** de PII/segredo antes. Local por padrão.
- **Transparência:** documente o que o app guarda localmente e o que (se ligado) sai — casa com a
  base legal/retenção da `schematize-data` (LGPD) se houver qualquer coleta.

## 2. NUNCA segredo embutido no cliente (piso herdado)

Extrair strings/recursos de um binário é **trivial** (`strings`, desmontador, dump do webview).
Portanto:

- **Nada de API key privada, `client_secret`, senha de banco, service-role key, token de serviço**
  no binário, recurso embutido, `config` distribuído ou string compilada. Mesma regra do
  `NEXT_PUBLIC_` do `schematize-web` e do bundle do `schematize-mobile`.
- **Segredo que precisa existir mora no servidor** atrás de um **BFF**; o app é **public client**
  (OIDC/PKCE contra `auth.<domain>`, `iam.md`). O app **delega** authz e segredo.
- **Segredo do próprio usuário** (token que ele obteve, senha de um cofre local) fica em
  **keychain/credential store do SO** (Keychain/Secret Service/Credential Manager) ou cifrado em
  repouso com chave derivada do usuário — **nunca** em texto claro no config nem em log.
- **Chave de assinatura de release** (item 4) fica em **cofre/CI**, jamais no repo/binário.

## 3. Autorização é do servidor — o cliente não decide (quando há backend)

- **Esconder botão/feature no app é UX, não segurança.** Quem autoriza é o **servidor** (deny-default,
  ReBAC, token fino — `iam.md`). Um binário local pode ser **patchado** pra ignorar qualquer check
  de cliente; portanto nenhuma decisão de autorização/preço/licença **crítica** pode depender só do
  cliente.
- **Licenciamento local** (se houver) é conveniência, não muralha: assuma que um cliente
  determinado contorna; o que **importa** (dado, feature server-side) é gated no servidor.

## 4. Assinatura de binário e integridade

- **Assine os artefatos** de release: macOS **Developer ID + notarization + staple**; Windows
  **Authenticode**; Linux **assinatura do pacote** (dpkg-sig/rpm sign) e/ou checksum publicado
  (`empacotamento.md`). Sem isso o SO assusta ou bloqueia o usuário.
- **Verifique no update:** o updater confere **assinatura/hash** antes de trocar o binário
  (`auto-update.md`) — update não verificado é vetor de RCE.
- **Chave privada de assinatura em cofre/CI**, com rotação; comprometê-la é incidente crítico.

## 5. Supply chain de deps nativas

- **Deps travadas e verificadas:** lockfile commitado; nome/versão/licença/hash conferidos
  (`cadeia-suprimentos.md`). **Typosquatting de crate/pacote nativo é real** — confirme o nome
  exato.
- **`cargo audit`/scanner de vulnerabilidade** no CI (RUSTSEC e equivalentes); dep com CVE conhecido
  não entra em release.
- **`unsafe`/FFI sob escrutínio:** código `unsafe`, FFI pra C/C++, e libs nativas do sistema ampliam
  a superfície — justifique, isole, teste. Vendorizar uma lib C sem manutenção é dívida de
  segurança.
- **Sem baixar-e-executar sem verificação** pós-install (plugin, componente) — verifique
  assinatura/hash antes de rodar (`empacotamento.md`).

## 6. Superfície de ataque local

- **Entrada externa é hostil:** arquivo aberto, URI scheme/deep-link, argumento de linha de comando,
  IPC local, drag-and-drop, conteúdo de rede — **valide tudo** (path traversal, injeção, tamanho).
  Ver `privilegio-fs.md` (IPC/path) e `toolkits-gui.md` (ponte web em Tauri).
- **Sandbox quando dá:** Flatpak/MAS sandbox, permissões mínimas do manifesto — não peça acesso a
  tudo.
- **Dado sensível em repouso cifrado**; memória com segredo zerada quando possível.
- **Pentest local (`schematize-pentest`):** segredo extraível do binário, update sequestrável,
  escalada por privilégio mal-gerido, path traversal em IPC/deep-link são **achados de 1ª linha**.

## 7. DoD de privacidade/segurança

- [ ] **zero telemetria por padrão**; se houver, **opt-in explícito**, sem PII, local-first;
- [ ] **nenhum segredo** no binário/recurso/config distribuído (varredura de segredo no artefato);
      segredo do usuário em **keychain do SO**;
- [ ] artefatos **assinados/notarizados**; update **verifica assinatura/hash**; chave de assinatura
      em **cofre**;
- [ ] deps nativas **travadas/auditadas** (`cargo audit`), `unsafe`/FFI justificado;
- [ ] entrada externa (arquivo/URI/IPC/args) **validada**; autorização crítica **no servidor**, não
      no cliente.
