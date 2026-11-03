---
description: schematize-desktop — audita privilégio e ambiente (root→usuário real nunca /root, elevar só onde precisa, launcher com Exec absoluto, single-instance, IPC local) — a materialização desktop do "prever macacos"
argument-hint: "[dir do app / instalador / launcher]"
---

Audite **privilégio e ambiente** deste app (`references/privilegio-fs.md`). Este é o piso **UX de
massa — "prever macacos"** (`schematize-engineering`) no desktop: o software **detecta o ambiente e
faz o certo sozinho**, **nunca culpa o usuário**. Edge case que um leigo atinge = **BUG do
software**.

## 1. Root/sudo → usuário REAL (nunca /root)
- Rodou sob `sudo`/root e o app grava config/dados **como root**? → dado vai pra `/root` e **"some"**
  pro usuário. **VETADO.** Detecte `SUDO_USER`/usuário logado real, resolva `$HOME`/dirs XDG **dele**
  e **`chown`** os arquivos pro uid:gid dele. Windows elevado (UAC): grava em `%APPDATA%` do usuário
  real, não do admin.
- O usuário **não precisa saber** que não devia usar sudo — o software conserta sozinho e **não
  avisa "você fez errado"**.

## 2. Elevar SÓ onde precisa
- App roda como **usuário comum**; nunca a GUI inteira como root. Privilégio pontual (instalar
  serviço, escrever em `/usr/local`) por **helper elevado** (`pkexec`/`sudo` pontual), com contexto
  ("preciso de X"), largando o privilégio em seguida.

## 3. Launcher com path ABSOLUTO (bug real da casa)
- O `PATH` do desktop environment é **mínimo** (não tem `~/.cargo/bin`/`~/.local/bin`) → `.desktop`
  `Exec=meuapp` abre **binário errado/antigo**. **Piso:** `Exec=/caminho/absoluto/meuapp` (idem
  atalho macOS/Windows).
- Ao **spawnar** subprocessos, **resolva o binário** varrendo **fallback dirs** e spawne por
  **caminho absoluto** (padrão `resolve_bin`), nunca só o nome no PATH. App aberto pelo menu com
  **PATH pelado tem de funcionar**.
- Instalações **coexistindo** (pacote + fonte) que confundem o launcher → conserto
  (`empacotamento.md` idempotente + doctor).

## 4. Single-instance e IPC local
- **Single-instance** por **lock (com PID)/socket/named pipe**: 2ª invocação **traz a janela à
  frente** e sai; lock **robusto a crash** (PID morto → assume) e a **processo órfão pós-update**
  (`auto-update.md`).
- **IPC local** com permissão **restrita ao usuário** (`0600`/ACL), mensagens **validadas** como
  hostis, sem executar comando arbitrário; **path/URI/deep-link/args externos canonicalizados** (path
  traversal/symlink) — casa com `schematize-pentest`.

## Saída
Reporte cada ponto como **FEITO com prova** ou **EM ABERTO** (DoD, §35): grava pro usuário real sob
sudo? eleva só o pontual? `Exec` absoluto + spawn resolvido? single-instance robusto? IPC/entrada
externa validados? Gere um roteiro de teste que rode o app **sob sudo**, **pelo menu com PATH
mínimo**, e **duas vezes** (single-instance).
