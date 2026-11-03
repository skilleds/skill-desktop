---
description: schematize-desktop — força/audita a escolha de toolkit de GUI (um só por produto, viés Slint, egui não como principal, web-in-native com justificativa) e caça a mistura de dois toolkits
argument-hint: "[dir do app / crate de UI]"
---

Force/audite a escolha de **toolkit de GUI** deste produto (`references/toolkits-gui.md`). Premissa
dura: **um produto = um toolkit de GUI**. Misturar dois é a causa-raiz do **"fantasma de layout"** e
do launcher que abre o binário errado.

## 1. Qual toolkit — por fit + ADR
- Viés da casa: **Slint (Rust)** é o default de produto. **Tauri** entra com **justificativa** (é
  web-in-native — herda superfície web, depende do webview do SO). **GTK/Qt** por fit
  (Linux-nativo / widgets ricos maduros; Qt exige ADR de licença). **egui NÃO como principal** —
  serve ferramenta interna/protótipo; como principal exige **ADR de exceção** encarando o histórico
  de fantasma de layout.
- Registre a escolha em **ADR (§27)**: superfície de plataforma, cross-OS, origem do time,
  performance/render, longevidade. Sem ADR, a escolha é dívida.

## 2. Caça à mistura (o pecado capital)
- Varra o projeto: há **dois toolkits/event-loops de GUI** no mesmo produto (ex.: `egui` **e**
  `slint`, ou `gtk` **e** `qt`)? → **VETADO**. Um segundo toolkit só atrás de **fronteira de
  processo explícita** e **ADR de exceção**, nunca dois loops no mesmo thread de UI.
- Há **instalações/binários coexistindo** (pacote + build de fonte, versão antiga em um toolkit +
  nova em outro) que fazem o launcher abrir a errada? → aponte pra remoção (`empacotamento.md`
  idempotente, `privilegio-fs.md` doctor).

## 3. Arquitetura interna
- Confirme **domínio sem toolkit** (testável headless, `testes-locais.md`): a regra de negócio não
  importa Slint/Qt/GTK. Camadas UI → apresentação → domínio → dados, dependência apontando pra
  dentro.
- **Thread de UI livre**: IO/rede/compute em worker/async; travar a UI = ANR local = usuário mata o
  app (`prever macacos`).

## 4. Web-in-native (se for o caso)
- Tauri > Electron (Electron só com ADR). **Ponte JS↔nativo**: comandos **mínimos e validados**,
  nunca shell arbitrário; conteúdo web tratado como hostil (CSP, sem HTML não sanitizado). Se o
  produto é essencialmente uma página, questione se **não é um site** (`schematize-web`).

## Saída
Reporte: toolkit escolhido + ADR (ou pendência de ADR), **veredito da caça a mistura** (limpo /
achou N toolkits → conserto), estado da arquitetura (domínio headless? thread de UI livre?). Cada
item como **FEITO com prova** ou **EM ABERTO** (entra na DoD, §35).
