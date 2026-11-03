# Filesystem, permissões e PRIVILÉGIO — root vira usuário real, path é absoluto

> O software local roda **com os privilégios do usuário que o invocou** — e o usuário leigo invoca
> de qualquer jeito: por menu, por `sudo`, por SSH, por script. Este reference é a materialização
> desktop do piso **"prever macacos"** (`schematize-engineering` → `references/anti-padroes.md` §37, *"Culpar o usuário / exigir que ele saiba de internals"* item
> 48): o software **detecta o ambiente e faz o certo sozinho**, nunca culpa o usuário. Dois bugs
> reais da casa moram aqui: **gravar em `/root` sob sudo** e **launcher que abre o binário errado
> por depender do PATH do DE**.

## 1. Rodou como root/sudo → descubra o usuário REAL e grave PRA ELE

O usuário leigo roda o instalador/app com `sudo` "porque deu erro de permissão". Se o app grava
config/dados **como root**, o dado vai pra **`/root/.config`** e **"some"** quando ele abre normal —
e os arquivos ficam **inacessíveis** (donos como root no `$HOME` dele). Anti-padrão vetado.

**Regra:** detecte que está sob elevação e **resolva o usuário real**:

- **Linux/macOS:** sob `sudo`, o usuário real está em **`$SUDO_USER`** (e o home via `getpwnam`).
  Rodando como root "puro" (`$SUDO_USER` vazio, `EUID==0`), descubra o usuário logado real (dono da
  sessão gráfica / `logname` / dono do `$XDG_RUNTIME_DIR`) — **não** assuma root como dono do dado.
- **Grave PRA ELE:** resolva `$HOME`, dirs XDG (`offline-estado.md`) e **`chown` os arquivos criados
  pro usuário real** (uid:gid dele), com permissões dele. Nunca deixe o dado do usuário como root.
- **Windows:** processo elevado (UAC) tem o mesmo risco — grave em `%APPDATA%` do **usuário real**,
  não do perfil administrador. Use o token do usuário interativo quando elevado.
- **Piso `prever macacos`:** o usuário **não precisa saber** que não devia usar sudo. O software
  **conserta sozinho** e **não avisa "você fez errado"** — faz o certo e segue. A casa codificou
  isso ("detecta o usuário real sob root, faz o certo sozinho").

## 2. Eleve SÓ onde precisa — nunca o app inteiro como root

- **Privilégio mínimo:** o app roda como **usuário comum**. Precisa de privilégio pontual (instalar
  serviço, escrever em `/usr/local`, abrir porta privilegiada)? **Eleve só aquela operação**
  (helper elevado por `pkexec`/`sudo` pontual, serviço com escopo), nunca peça `sudo` pro processo
  todo nem rode a GUI como root (rodar GUI como root é risco de segurança e quebra o dir de dados).
- **Peça elevação com contexto:** diga **por que** precisa ("preciso instalar o serviço em X"), e
  faça o mínimo elevado, largando o privilégio em seguida.
- **Nunca** guarde o app instalado num lugar que exija root pra atualizar se dá pra instalar no
  espaço do usuário (per-user install) — casa com o updater (`auto-update.md`).

## 3. Launcher com path ABSOLUTO — o PATH do DE não te salva (bug real)

Bug concreto e recorrente (visto duas vezes num produto da casa; o postmortem completo mora no archive do projeto, não aqui): o app aberto **pelo
menu do desktop** não achava `claude` em `~/.local/bin`, e **abria um binário errado/antigo** (egui
velho coexistindo com Slint novo). Causa: **o `PATH` do desktop environment é mínimo** — não inclui
`~/.cargo/bin`, `~/.local/bin`, `/usr/local/bin` como o shell interativo inclui.

**Pisos:**

- **`.desktop` `Exec=` com caminho ABSOLUTO** pro binário (idem atalho no macOS/Windows). Nunca
  `Exec=meuapp` contando com o PATH — **`Exec=/caminho/absoluto/meuapp`**. O fix da casa foi
  exatamente "Exec absoluto pro Slint + doctor detecta".
- **Ao spawnar subprocessos, resolva o binário você mesmo:** não confie no `PATH` herdado. Varra uma
  lista de **diretórios de fallback** (`~/.local/bin`, `~/.cargo/bin`, `/usr/local/bin`, `/opt/...`,
  `%LOCALAPPDATA%`), ache o executável e **spawne pelo caminho absoluto**. *(Este é o conserto que um produto da casa
  precisou fazer depois de o app aberto pelo menu do sistema não achar um binário que existia — o
  ambiente do lançador gráfico tem um `PATH` mínimo, diferente do terminal.)*
- **Coexistência de instalações = launcher confuso:** pacote do SO + build do fonte convivendo é o
  que faz o menu abrir a versão errada. O instalador deve **remover a
  anterior** (`empacotamento.md`, idempotente) e um **doctor** deve detectar duplicidade.
- **PATH mínimo é caminho de macaco previsto:** app pelo menu com PATH pelado tem de **funcionar** —
  resolvendo binários por conta própria, não estourando "command not found".

## 4. Single-instance — um app, uma instância

Abrir o app duas vezes (o usuário clica de novo porque "não abriu") não pode gerar duas instâncias
brigando pelo mesmo estado/lock/porta.

- **Lock de instância:** um **lockfile** (com PID) no dir de runtime, ou um **socket/named pipe**
  local nomeado. A segunda invocação **detecta** a primeira, **traz a janela existente pra frente**
  (passando os args, ex.: arquivo a abrir) e **sai** — não sobe outra.
- **Libere o lock ao sair de verdade** — e cuidado com o **processo órfão pós-update**
  (`auto-update.md`): se o processo antigo não morre, ele **segura o lock** e a nova instância acha
  que já há uma rodando. Matar o processo antigo (não só fechar a janela) resolve os dois.
- **Lock robusto a crash:** se o dono do lock morreu (PID não existe mais), a nova instância
  **assume** — lock estático que sobrevive a crash trava o app pra sempre (`prever macacos`).

## 5. IPC local — a segunda instância, o helper elevado, o tray

Comunicação entre processos locais (segunda invocação → instância viva; GUI → helper elevado; app →
daemon/tray) é **fronteira de confiança**, não canal ingênuo:

- **Socket/named pipe com permissão restrita ao usuário** (`0600`/ACL do usuário) — não um socket
  world-writable que qualquer processo local abusa.
- **Valide toda mensagem** como entrada hostil (outro processo local pode ser malicioso): parse
  estrito, tamanho limitado, **sem executar comando arbitrário** vindo do IPC.
- **Path/URL vindos de fora** (arquivo passado pra "abrir", deep-link/URI scheme, drag-and-drop) são
  entrada hostil: **canonicalize e valide** (path traversal, `..`, symlink), nunca execute/abra cego
  (casa com a `schematize-pentest`).

## 6. DoD de privilégio/FS

- [ ] sob **sudo/root**, dado do usuário vai pro **home do usuário real** com **dono correto**
      (nunca `/root`);
- [ ] app roda como **usuário comum**; elevação **só pontual** e com contexto;
- [ ] `.desktop`/atalho com **`Exec` absoluto**; subprocessos resolvidos por **fallback dirs +
      caminho absoluto** (funciona com **PATH mínimo** do DE);
- [ ] **single-instance** (lock/socket) robusto a crash e a processo órfão pós-update;
- [ ] **IPC local** com permissão restrita, mensagens validadas, path/URL externos canonicalizados.
