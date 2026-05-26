---
title: "feat: e06 history screen"
type: feat
date: 2026-05-26
epic: E06
status: planned
---

# feat: e06 history screen — Standard

## Overview

Entrega a tela de **Histórico** do 1-Bit Dice — lista cronológica (mais recente no topo) de todas as rolagens registradas, com botão "LIMPAR HISTÓRICO" que pede confirmação antes de apagar tudo. Consome [HistoryRepository.watch()](../../lib/core/storage/history_repository.dart) via `StreamBuilder`, então atualiza em tempo real sempre que uma rolagem nova é registrada — mesmo se o usuário estava na aba Rolar e voltou.

Esta epic é puramente UI. A domain inteira — `RollResult`, `RollEntry` Hive adapter, `HistoryRepository` (in-memory + Hive) — já existe desde E03/E04. Apenas precisa de uma tela que consuma o stream e exiba.

Zero estado novo. `HistoryScreen` é `StatelessWidget` consumindo `Provider<HistoryRepository>`. O dialog de confirmação é `AlertDialog` material padrão estilizado com `OneBitColors`.

## Problem Statement / Motivation

Hoje o app:

- Já registra cada rolagem em `HistoryRepository` automaticamente via `DiceController.roll()` ([dice_controller.dart:125](../../lib/features/dice/dice_controller.dart#L125)). **As entradas estão sendo persistidas mas o usuário não consegue vê-las.**
- Tem o stub [history_screen.dart](../../lib/features/history/history_screen.dart) renderizando "EM BREVE" desde E09.
- Tem as 4 chaves de l10n necessárias já adicionadas em E13: `historyTitle`, `historyEmpty`, `historyClearConfirmTitle`, `historyClearConfirmBody`, `commonClear`.

Sem E06, M1 não fecha — o roadmap exige histórico. Além disso, é a feature mais simples do M1 restante (puramente leitura + um botão de clear), então fechá-la cedo libera tempo para os mais complexos.

A escolha de **mostrar mais recente primeiro** é o oposto do que `HistoryRepository.snapshot()` devolve (oldest-first). A tela reverte a lista localmente — não mexer no contrato da repository.

A escolha de **um único `AlertDialog` material** (estilizado) para a confirmação, em vez de criar um novo `MacAlertDialog`, é YAGNI: o `AlertDialog` aceita `backgroundColor` + `shape` para virar 2-color via `OneBitColors`, e o app não tem outro lugar onde a chrome de dialog importa.

## Proposed Solution

```
lib/features/history/
├── history_screen.dart                # REWRITE — StreamBuilder + lista + clear
└── widgets/
    ├── history_entry_tile.dart        # NEW — uma linha da lista
    └── clear_history_button.dart      # NEW — MacButton + showDialog

test/features/history/
├── history_screen_test.dart
└── widgets/
    ├── history_entry_tile_test.dart
    └── clear_history_button_test.dart
```

### Responsibility map

| Componente | Responsabilidade | Não responsabiliza-se por |
|---|---|---|
| `HistoryEntryTile` | Renderiza uma `RollEntry`: data/hora formatada com `DateFormat`, notação `NxDM`, valores entre `[ ]` (e.g. `[3, 5, 1]`), total à direita. Layout em `Row` com `MacWindow` ou `PixelDivider` separando entradas. | Estado; navegação |
| `ClearHistoryButton` | `MacButton` "LIMPAR HISTÓRICO" (label de l10n `commonClear`). `onPressed` abre `AlertDialog` estilizado; no "Confirmar", chama `repository.clear()`. | Lógica de estado da lista |
| `HistoryScreen` | `Scaffold` + `AppBar` + `StreamBuilder<List<RollEntry>>` sobre `repository.watch()`. Renderiza: empty state OU `ListView.separated` (reverse=true não — usa `entries.reversed.toList()`) + `ClearHistoryButton` no rodapé quando a lista não está vazia. | Renderizar tile (delega) |

### Sequence: usuário rola um dado e abre a aba Histórico

```
DiceScreen          DiceController     HistoryRepository    HistoryScreen
    │                    │                    │                     │
    │ roll               │                    │                     │
    ├───────────────────▶│ append(result)     │                     │
    │                    ├───────────────────▶│ _controller.add(...)│
    │                    │                    │ ───────────────────▶│ StreamBuilder rebuilds
    │                    │                    │                     │ list grows; appears in-view
```

Quando o usuário muda de aba (graças ao `StatefulShellRoute.indexedStack`), o `StreamBuilder` mantém a subscription ativa porque o branch é preservado. Sem subscription leak — `StreamBuilder` cancela ao unmount.

### Empty state

Texto centralizado: `context.l10n.historyEmpty` ("Nenhuma rolagem ainda."). Sem ícone, sem ilustração — pixel art ficaria pesado e o roadmap não pede.

### Clear flow

```
ClearHistoryButton tap
        │
        ▼
showDialog(AlertDialog(
  title: historyClearConfirmTitle,
  content: historyClearConfirmBody,
  actions: [
    TextButton(historyCancel) → Navigator.pop(false),
    TextButton(commonClear)   → Navigator.pop(true),
  ],
))
        │
        ▼ (returns true)
repository.clear()  ← async; await before popping any further nav
        │
        ▼
StreamBuilder emits empty list → tela volta ao empty state
```

`historyCancel` é uma nova chave de l10n; ver § i18n delta.

## Acceptance criteria

- [ ] `HistoryScreen` renderiza empty state quando `entries.isEmpty`
- [ ] `HistoryScreen` renderiza lista (mais recente no topo) quando há entries
- [ ] Cada `HistoryEntryTile` mostra data/hora local, notação `NxDM`, valores, e total
- [ ] Tocar no botão "LIMPAR HISTÓRICO" abre `AlertDialog`; confirmar limpa a repository; cancelar não muda nada
- [ ] Após `clear()`, a tela volta ao empty state automaticamente (via stream)
- [ ] Lista reativa: rolar um dado em outra aba e voltar para Histórico mostra a nova entrada sem refresh manual
- [ ] Zero terceira cor; zero gradiente; zero sombra
- [ ] 100% line coverage no código novo
- [ ] `flutter analyze` zero issues

## Tasks

- [ ] **T1** Adicionar 1 chave nova `historyCancel` em `lib/l10n/app_pt_BR.arb` (template) — pt-BR: "Cancelar"
- [ ] **T2** Traduzir `historyCancel` nos 10 ARBs restantes
- [ ] **T3** `lib/features/history/widgets/history_entry_tile.dart` + teste — testa render dos 4 campos + parse de `RollEntry.toResult` (e propaga `StateError` em corruption — não silencia)
- [ ] **T4** `lib/features/history/widgets/clear_history_button.dart` + teste — testa render + showDialog + chamada de `repository.clear()` no confirm + no-op no cancel
- [ ] **T5** Reescrever `lib/features/history/history_screen.dart` — `StreamBuilder` + empty state + lista reversa + botão
- [ ] **T6** `test/features/history/history_screen_test.dart` — empty state, lista com 1+ entries, reatividade ao stream emission, integração com clear (já testado isoladamente em T4)
- [ ] **T7** Atualizar `progress.md` — marcar EPIC 9 (1–4) como `[x]`
- [ ] **T8** `feedback.sh --all` verde

## Implementation details

### Date formatting

`DateFormat.yMd().add_Hm()` (intl) com locale do `MaterialApp` atual:

```dart
final l10n = context.l10n;
final formatter = DateFormat.yMd(l10n.localeName).add_Hm();
final text = formatter.format(entry.timestamp);
```

`localeName` é exposto pelo `AppLocalizations.localeName` — gerado automaticamente pela codegen.

### HistoryEntryTile layout

```
┌─────────────────────────────────────────────┐
│  26/05/2026 14:32                       19  │  ← timestamp + total à direita
│  3D6 · [3, 5, 11]                           │  ← notação + valores
└─────────────────────────────────────────────┘
        ▲ PixelDivider entre tiles
```

Fonte Silkscreen para timestamp + total; VT323 para a notação. Padding interno 12px, altura mínima 56px (atende tap target 44pt do roadmap).

### Single-entry tile vs. List<RollEntry>

Decidir: `HistoryEntryTile` recebe `RollEntry` direto ou recebe `RollResult` (após `entry.toResult()`)? Receber `RollResult` é mais limpo (modelo de domínio puro) — `HistoryScreen` faz a conversão antes de passar adiante. Mas conversão lança `StateError` em data corruption: o erro deve propagar via tile (que falha silenciosamente em modo release? não — fail-loud é a política do projeto).

Decisão: `HistoryEntryTile` recebe `RollEntry` e chama `.toResult()` internamente, com `try/catch` retornando uma versão "corrompido" (renderiza `?` e log de erro). Mantém a tela útil mesmo se um único entry estiver quebrado. Aceitar a divergência com a política fail-loud — um histórico inutilizável por causa de um entry ruim é pior UX que entries individuais marcados.

### Stream vs snapshot performance

A repository emite a lista inteira a cada mutação. Para 10k+ entries isso é caro. Mitigação:
- M1: aceitar. Hive in-memory é O(N) e N realista < 1000 nos primeiros meses.
- Pós-M1: adicionar `watch(limit: N)` que emite só os últimos N. Anotar em risks abaixo.

## i18n delta

| Key | pt-BR |
|---|---|
| `historyCancel` | Cancelar |

Total: **1 chave nova**. `historyTitle`, `historyEmpty`, `historyClearConfirmTitle`, `historyClearConfirmBody`, `commonClear` já existem.

## Wiring changes

`HistoryRepository` já está injetado em `lib/app.dart` (linha 61) como `InMemoryHistoryRepository`. Nenhuma mudança nesta epic. A migração para `HiveHistoryRepository` no startup é um item separado (provavelmente em E14/E15 junto com presets).

## Out of scope

- Filtrar/buscar por tipo de dado — fora do M1
- Deletar uma única entry — fora do M1 (só limpar tudo)
- Exportar histórico (CSV, JSON) — fora do M1
- Paginação ou janela deslizante — performance ok até ~1k entries
- Agrupar por dia (header de seção) — fora do M1
- Animação na entrada de novos itens — fora do M1, conflita com a regra 1-bit estrita

## Risks

- **Stream emite a lista inteira em cada mutação**: ver § Implementation details. Risk aceito para M1.
- **`DateFormat.yMd(locale).add_Hm()` precisa que o locale tenha sido inicializado**: `initializeDateFormatting()` do `intl` não foi chamado em E13. Verificar se `AppLocalizations` carrega isso automaticamente; se não, adicionar `await initializeDateFormatting(localeName, null)` em `main.dart` ou no resolver de locale. Pode virar uma fix mid-task.
- **Visual do `AlertDialog`**: Material default usa M3 shapes + elevation. Forçar `RoundedRectangleBorder(side: BorderSide(color: colors.ink, width: 2), borderRadius: 0)` + `backgroundColor: colors.paper` + `surfaceTintColor: Colors.transparent` para neutralizar a elevation tint. Goldens fora do M1, mas verificar visualmente no run.
- **Conversão `RollEntry.toResult` pode lançar `StateError`**: ver § Implementation details. Decisão: tile mostra placeholder de erro em vez de derrubar a lista.

## References

- [docs/roadmap/08-epics-m1.md](../roadmap/08-epics-m1.md) — E06 line item
- [docs/roadmap/01-escopo-m1.md](../roadmap/01-escopo-m1.md) — feature 4 (Histórico)
- [lib/core/storage/history_repository.dart](../../lib/core/storage/history_repository.dart) — already-implemented API
- [lib/core/storage/models/roll_entry.dart](../../lib/core/storage/models/roll_entry.dart) — model + corruption policy
- [lib/features/dice/dice_controller.dart](../../lib/features/dice/dice_controller.dart) — emits to history on every roll
