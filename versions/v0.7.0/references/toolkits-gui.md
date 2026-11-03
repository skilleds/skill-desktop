<!-- cross-skill: arquitetura.md, iam.md -> schematize-engineering -->
# Toolkit de GUI nativa — um só por produto, por fit + ADR (não por gosto)

> A casa **não tem "o toolkit único"** — tem um **rol de opções sancionadas** e um **viés
> explícito**, como a política de linguagem (`schematize-engineering`, `linguagens.md`). O piso —
> segurança, testes, ops, DoD, archive — é **o mesmo** em qualquer toolkit. O toolkit muda o
> **como** do render, nunca o **o quê**. A decisão vira **ADR (§27)**. **Regra dura: um produto,
> um toolkit.**

App desktop é software da casa como qualquer outro: entra no `_archive` (§28), passa pela DoD
(§35), tem índice/MAPA (§39). O que este reference define é a **primeira decisão estrutural** — qual
toolkit de GUI — e por que **misturar dois** é o pecado capital do desktop.

## 1. O rol de toolkits sancionados (viés da casa)

| Toolkit | Stack | Quando encaixa | Cautela |
|---|---|---|---|
| **Slint** (default da casa) | Rust + `.slint` (DSL declarativa) | GUI de produto da casa; binário nativo leve; render próprio consistente cross-OS; app do ecossistema (ver `schematize_gui_slint`) | ecossistema menor que Qt; componentes ricos às vezes se constroem à mão |
| **Tauri** | Rust core + webview do SO (frontend web) | UI com fit `schematize-web` (React/Astro), reuso de time web, telas ricas de conteúdo — **com justificativa** (é web-in-native) | depende do webview do SO (WebView2/WebKitGTK/WKWebView) → variação de render/versão por SO |
| **GTK** | Rust (gtk4-rs)/C/Vala | integração profunda com desktop Linux (GNOME), apps que têm de "ser" GTK | fora do Linux o suporte é secundário; look nativo só no GNOME |
| **Qt** | C++/Rust (cxx-qt) | app grande com necessidade de widgets ricos maduros, cross-OS pesado, ferramentas complexas | licenciamento (LGPL/comercial) exige ADR; peso do runtime |
| **Avalonia** / **MAUI** | C#/.NET | quando o time e o backend já são **C# — que está no rol sancionado** — e o app é de produto (Avalonia: cross-OS de verdade, inclusive Linux; MAUI: foco Windows/macOS/mobile da Microsoft) | runtime .NET no pacote (tamanho, AOT ajuda); MAUI tem cobertura de Linux **fraca** — se Linux importa, é Avalonia |
| **egui** | Rust (imediato) | ferramenta interna, overlay de debug, protótipo, painel de dev — **NÃO como principal de produto** | **imediato → estado de layout frágil; foi fonte concreta de "fantasma de layout" na casa** |

> **Licença é decisão de projeto, e ela vale para o default também.** ✔ Verificado em 2026-08-21:
> o **Slint** — o default desta casa — é **tri-licenciado**: **GPLv3**, **licença comercial** paga, e
> a **Royalty-free** (gratuita, com condições, para app *desktop/embarcado*). Isso significa que
> distribuir um produto **proprietário** em Slint exige escolher entre a comercial e a royalty-free,
> **lendo as condições vigentes** — não é "é open-source, então tudo bem". Era desonesto exigir ADR
> de licença só do **Qt** (LGPL/comercial) e tratar o default como se não tivesse a mesma pergunta:
> **todo toolkit entra com a licença registrada no ADR de escolha**, incluindo Slint, Qt, GTK
> (LGPL) e Avalonia/MAUI (MIT).
>
> **Viés registrado:** a casa constrói GUI de produto em **Slint**. **egui não é o toolkit
> principal** de um produto entregue ao usuário — serve pra ferramenta interna/protótipo. Adotar
> egui como principal exige **ADR de exceção** que encare o histórico de "fantasma de layout".

## 2. O PECADO CAPITAL — misturar dois toolkits no mesmo produto (VETADO)

Rodar **egui e Slint** (ou Qt e GTK, ou dois event-loops de GUI) **no mesmo processo/produto** é a
causa-raiz do **"fantasma de layout"**: janela/render de um toolkit vazando no outro, dois
event-loops disputando o thread de UI, e — o bug real da casa — **o binário/atalho apontando pro
toolkit errado** (versão antiga em egui coexistindo com a nova em Slint, o launcher abrindo a
errada — o launcher do menu resolvendo um binário diferente do que você acabou de instalar).

**Piso:** **um produto = um toolkit de GUI.** Se há razão real pra um segundo (ex.: um overlay de
debug egui embutido num app Slint), ele vive **atrás de fronteira de processo explícita** e vira
**ADR de exceção**, nunca dois loops no mesmo thread. A migração de um toolkit pro outro é
**substituição completa** (remova o antigo), não coexistência indefinida — coexistência gera o
launcher que abre o binário errado.

## 3. Web-in-native (Tauri/Electron) — só com justificativa

> **O modelo de segurança está em `references/web-in-native.md`** (capabilities/permissions/scopes
> do Tauri 2; isolamento, sandbox e fuses do Electron), com gate em
> `scripts/check-web-in-native.sh` e comando `/desktop-bridge`. Esta seção decide **se** você
> empacota web dentro de nativo; aquela decide **o que o frontend pode chamar** depois que você
> decidiu que sim.

Empacotar web dentro de nativo (Tauri, Electron) é legítimo, mas **paga custo**: você embute um
webview/Chromium, herda a superfície de ataque web (XSS vira RCE local se a ponte for frouxa) e
depende da versão do webview do SO. Regras:

- **Tauri > Electron** na casa (binário menor, core Rust, webview do SO em vez de Chromium
  embutido) — quando web-in-native se justifica.
- A **ponte JS↔nativo** é fronteira de confiança: exponha **comandos mínimos e validados**, nunca
  "shell arbitrário" pro frontend. Trate o conteúdo web como hostil (mesma disciplina do
  `schematize-web`: sem `dangerouslySetInnerHTML` não sanitizado; CSP).
- **Electron** entra só com **ADR de exceção** (peso, memória, N cópias de Chromium). Não é o
  default da casa.
- Se o produto é essencialmente uma página, **talvez seja um site** (`schematize-web`) — vira app
  nativo só com requisito real (offline profundo, API de plataforma, tray, single-instance, IPC
  local).

## 4. Arquitetura interna (independe do toolkit)

Escolhido o toolkit, a arquitetura segue os pisos da engenharia (`arquitetura.md`):

- **Camadas explícitas:** UI (view/componente `.slint`/widget) → apresentação (state/view-model) →
  domínio (casos de uso, regras) → dados (repositórios: estado local, cliente de rede). A **regra de
  dependência** aponta pra dentro: o domínio **não** importa o toolkit.
- **Domínio sem toolkit:** a regra de negócio não conhece Slint/Qt/GTK — é **testável sem abrir
  janela** (headless, ver `testes-locais.md`). Só a camada de UI conhece o toolkit; trocar de
  toolkit não deveria reescrever o domínio.
- **Thread de UI é sagrado:** trabalho pesado (IO, rede, compute) sai do thread de UI pra worker/
  async (Tokio no mundo Rust); a UI só reage a mensagens. Travar o thread de UI = app "congelado" =
  o usuário mata o app (`prever macacos`: previna o ANR local).
- **Índice/MAPA (§39):** o app entra no índice global — telas, casos de uso, comandos, e os
  endpoints do backend que consome.

## 5. Backend do app é serviço da casa

Quando o app local fala com backend, fala com um **serviço do rol sancionado** (Go/Rust/Elixir/C#/
Zig/Ruby) e com **IAM como app separada** em `auth.<domain>` (`iam.md`). O app **delega** authz e
segredo ao servidor (`privacidade-seguranca.md`); é public client, nunca guardião do segredo. App
puramente local (sem backend) ainda segue todo o resto: estado local, update, privilégio, cross-OS.
