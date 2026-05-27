---
date: 2026-05-27
topic: m1-completion-pipeline
---

# M1 Completion Pipeline — Master Plan

## What We're Building

Doc-mestre que coordena as **quatro tarefas restantes** para fechar M1 do
1-Bit Dice depois que GH-10 (E12 dice animations) for merged. Não é
implementação — é o roteiro de orquestração para Ralph (e para o humano em
paralelo), com ordem, dependências, escopo e critério de aceite por etapa.

Cada etapa abaixo terá seu próprio brainstorm doc dedicado nesta mesma
sessão. Este doc-mestre é a fonte de verdade da ordem e dos invariantes do
pipeline.

## Estado atual (snapshot 2026-05-27)

- **Em voo:** GH-10 / E12 dice roll animations (branch
  `gh-10-dice-animations`, ainda não merged).
- **Concluído e merged:** E01–E10, E13. Cobertura 100% line, analyzer 0.
- **Restante M1:** E11 (Analytics + Crashlytics), E14 (Assets visuais —
  launcher icons + native splash refresh), E15 (Publicação — signing,
  manifests, builds, política de privacidade). Mais um pacote de débito
  técnico acumulado das PRs anteriores.
- **6 bloqueios humanos pendentes** (decidido nesta sessão: serão
  resolvidos antes do Ralph retomar):
  - `0.6` Firebase setup (`flutterfire configure`)
  - `4.4` Substituir placeholders de áudio (3 `.mp3` reais em
    `assets/sounds/`) — adicionado durante o brainstorm do E15
  - `14.1` Ícone do app: `icon.png` (1024×1024 opaco) +
    `icon-foreground.png` (1024×1024 com safe zone 25%)
  - `15.1` Keystore Android + `key.properties` + backup
  - `15.7` Screenshots nas resoluções das lojas
  - `15.8` Records no Play Console + App Store Connect

## Why This Approach

Quatro decisões estruturais foram tomadas no brainstorm:

1. **Humano resolve bloqueios em paralelo ao Ralph fechar GH-10.** Quando
   Ralph voltar do E12, todos os 5 bloqueios estão resolvidos. Ralph anda
   em linha reta sem precisar inventar stubs ou placeholders descartáveis.
2. **Ordem do pipeline pós-GH-10: E11 → débito → E14 → E15.** Analytics
   primeiro porque precisa instrumentar todos os call sites (controllers já
   existem e estão estáveis). Débito vem antes do polish visual para
   garantir codebase limpo para a release. E14 (assets) e E15
   (publicação) são polish + release final.
3. **Doc-mestre + brainstorm individual por epic.** Cada um aprovado
   antes do próximo (regra `approve-each-plan`).
4. **M1 done = builds verdes localmente, sem upload.** `flutter build
   appbundle --release` + `flutter build ipa --release` rodam limpo com
   signing wired, manifests corretos, política publicada. Upload nas
   lojas é trabalho humano subsequente (fora do escopo do Ralph).

## Pipeline Pós-GH-10

```
GH-10 (E12)          ← Ralph atualmente aqui
   ↓ merge
[Humano resolve 0.6, 4.4, 14.1, 15.1, 15.7, 15.8 em paralelo]
   ↓
GH-NEXT-1 — E11 Analytics & Crash Reporting
   ↓ merge
GH-NEXT-2 — Débito Técnico (refactor consolidado)
   ↓ merge
GH-NEXT-3 — E14 Assets Visuais (launcher icons + native splash refresh)
   ↓ merge
GH-NEXT-4 — E15 Publicação (signing, manifests, builds, privacy page)
   ↓ merge
M1 DONE — builds locais verdes
```

## Key Decisions

### D1 — Bloqueios humanos: pre-flight, não inline

Os 5 bloqueios (`[!]` em `progress.md`) são resolvidos pelo humano antes
do Ralph atacar o epic correspondente. Ralph não cria stubs descartáveis
nem branches paralelos com placeholders.

- **Por quê:** evita PRs de "swap depois" e mantém cada PR do Ralph com
  contexto completo. Pequenas latências humanas valem a pena diante do
  custo de PRs adicionais só para trocar placeholder por real.
- **Operacional:** quando os 5 estiverem resolvidos, o humano
  marca os `[!]` correspondentes em `progress.md` como `[x]` (com nota
  da resolução) e adiciona as 4 issues `ready-for-agent` no GitHub na
  ordem do pipeline. Ralph então roda contra `.ralph/prd.json` atualizado.

### D2 — Ordem fixa: E11 → débito → E14 → E15

- **E11 primeiro:** instrumentar analytics toca todos os controllers
  (`DiceController`, `ThemeProvider`, `AnimationSettingsController`,
  `AudioController`, `HapticController`, `HistoryRepository`,
  `PresetsRepository`). Mais barato fazer enquanto não há refactor
  pendente movendo estes arquivos.
- **Débito depois:** com analytics instrumentada e estável, o refactor de
  movimentação de `TypeSelector`/`QuantitySelector` e
  `AnimationStyle`/`AnimationSpeed` toca menos arquivos críticos (call
  sites de analytics já estão isolados via service injetada).
- **E14 antes de E15:** native splash regen precisa do ícone real (14.1).
  E15 (signing) precisa dos assets finais para o build.
- **E15 por último:** depende de tudo. Privacy page precisa listar todos
  os eventos de analytics (E11). Signing precisa dos launcher icons
  (E14).

### D3 — Cada etapa abre 1 PR

Quatro PRs sequenciais. Ralph não paraleliza branches. Cada PR rebaseia
em main após o merge da anterior. Justificativa: o histórico de PRs do
Ralph mostra que `feedback.sh --all` (analyzer + testes + coverage 100%)
é o gate confiável; manter linearidade evita conflitos em
`lib/app.dart`, `lib/main.dart` e nos ARBs.

### D4 — Definition of M1 done = build local verde

Ralph encerra o pipeline quando:

- `flutter analyze` → 0 issues
- `flutter test --coverage` → 100% line (excl. `main.dart` + `*.g.dart`
  + `app_localizations*.dart`)
- `flutter build appbundle --release` → AAB gerado sem erros
- `flutter build ipa --release` → IPA gerado sem erros (ou `xcodebuild
  archive` para CI macOS)
- `docs/legal/privacy-policy.md` publicado (commit em `gh-pages` ou
  arquivo servido em URL fixa)
- `progress.md` com todos os `[ ]` viraram `[x]` ou `[!]` documentado
  com motivo

Upload nas lojas, smoke test em device físico e propagação para
testers humanos são responsabilidade humana subsequente — fora do
escopo do pipeline do Ralph.

### D5 — Débito técnico = PR única consolidada

Os 4 itens diferidos das PRs anteriores entram em uma única PR de
refactor (não dispersos em 4 PRs):

1. Mover `TypeSelector` + `QuantitySelector` de
   `lib/features/dice/widgets/` para `lib/shared/widgets/`.
2. Mover `AnimationStyle` + `AnimationSpeed` de
   `lib/core/storage/models/` para `lib/core/models/`.
3. Extrair `_NoopCanvas` para `test/helpers/noop_canvas.dart`.
4. Limpar instanciação inline de repositórios em `lib/app.dart`
   (extrair para factory function ou composition root explícito).

- **Por quê 1 PR só:** os itens são todos cosméticos/movimentação. PR
  consolidada minimiza overhead de review e mantém o pipeline em 4 PRs.

## Riscos e Mitigações

| Risco | Mitigação |
|---|---|
| Conflitos entre PRs sequenciais (`lib/app.dart`, ARBs) | Ordem fixa + cada PR rebaseia em main após merge anterior |
| Bloqueios humanos atrasam o pipeline | Resolução em paralelo ao GH-10 dá ~24h de janela |
| Firebase quebrar testes (Crashlytics em widget tests) | Pattern já comprovado: interface + No-Op impl injetada via Provider (espelha audio/haptic seam) |
| Coverage 100% impossível em código Firebase | Mockar `FirebaseAnalytics`/`FirebaseCrashlytics` via seam; testar No-Op + interface, deixar bridge Firebase com exclusão documentada (igual `main.dart`) |
| Privacy policy precisa listar 9 eventos | E11 gera lista canônica em código; E15 lê dessa fonte para gerar Markdown |
| Build IPA local sem máquina/conta Apple | Confirmar com humano: se houver Mac dev disponível, Ralph roda; se não, `flutter build ipa` fica `[!]` e M1 fecha só com AAB |

## Open Questions

- **Q1:** A política de privacidade pode ser arquivo Markdown no repo
  (servido via GitHub Pages do próprio repo) ou precisa ser site
  separado? — assumir GitHub Pages até o humano dizer o contrário.
- **Q2:** Existe Mac dev/Xcode disponível para `flutter build ipa
  --release`? Se não, M1 fecha só com AAB e IPA fica como `[!]`.
- **Q3:** Bundle ID definitivo (`com.am2studio.onebitdice`?) precisa
  ser confirmado antes do E15 — humano confirma junto com o Apple
  developer account.
- **Q4:** O domínio `coverage 100%` aceita exclusão de
  `firebase_options.dart` (gerado por `flutterfire configure`)? —
  assumir sim, mesmo padrão de `app_localizations*.dart`.

## Próximos passos

1. **Agora (esta sessão):** brainstorm individual de cada etapa, na
   ordem do pipeline, com aprovação humana entre cada:
   - `2026-05-27-e11-analytics-crashlytics-brainstorm-doc.md`
   - `2026-05-27-debito-tecnico-cleanup-brainstorm-doc.md`
   - `2026-05-27-e14-assets-launcher-icons-brainstorm-doc.md`
   - `2026-05-27-e15-publicacao-brainstorm-doc.md`
2. **Quando GH-10 mergear:** humano resolve os 5 bloqueios, atualiza
   `progress.md`, cria as 4 issues `ready-for-agent` no GitHub e
   atualiza `.ralph/prd.json`.
3. **Cada brainstorm acima vira `/plan` em sessão própria** quando a
   issue correspondente for criada — não bater todos os planos agora
   para evitar drift (regra `approve-each-plan`).
