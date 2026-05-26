---
title: "feat: e07 presets screen"
type: feat
date: 2026-05-26
epic: E07
status: planned
---

# feat: e07 presets screen — Standard

## Overview

Entrega a tela de **Presets / Jogos** do 1-Bit Dice — duas seções de cards `MacWindow`:

1. **Jogos** (built-in) — 7 presets clássicos imutáveis (Ludo, Banco Imobiliário, War, Yahtzee, D&D Ataque, Magic Vida, Percentil). Definidos como `const` em `lib/features/presets/preset_data.dart`.
2. **Meus presets** (custom) — 0..10 cards persistidos via `PresetsRepository` (já implementado em E04). Botão "+ NOVO" aparece enquanto `canAddMore == true`; tocar abre um `BottomSheet` para criar um preset customizado.

Tocar em qualquer card (built-in ou custom) **navega para a aba Rolar** com a configuração pré-aplicada no `DiceController` (sem auto-roll — o usuário toca ROLAR). Esse padrão preserva controle e reusa toda a infra do `DiceScreen`/`DiceController` já em produção.

Zero domínio novo. Esta epic é puramente UI + um helper de navegação. Toda a persistência, validação e cap de 10 presets já moram em `PresetsRepository`. A integração entre presets e roll vive numa única chamada nova `DiceController.applyConfig(diceType, count)` que centraliza o "trocar tipo e quantidade atomicamente".

## Problem Statement / Motivation

Hoje o app:

- Tem a aba **Jogos** no `RetroTabBar` mas a tela é apenas um [stub "EM BREVE"](../../lib/features/presets/presets_screen.dart) desde E09.
- Já tem `PresetsRepository` (interface + `InMemoryPresetsRepository` + `HivePresetsRepository`) e o modelo `CustomPreset` com Hive adapter prontos desde E04 — `add`, `remove`, `rename`, `watch`, `canAddMore`, cap de 10. **Nada usa esses métodos** ainda.
- Tem o `MacWindow` ([lib/shared/widgets/mac_window.dart](../../lib/shared/widgets/mac_window.dart)) que é a estética escolhida para os cards.

Sem E07, M1 não fecha — o roadmap exige 7 presets clássicos + slots customizados. Além disso, a feature de presets é a principal alavanca de engajamento da aba "Jogos" (mais que 50% dos usuários fala da mesma rolagem repetida em jogos de mesa — o preset deixa salvar).

A escolha de **navegar à aba Rolar e aplicar a config** (em vez de rolar inline) preserva uma UX consistente: o resultado, o histórico, áudio, háptico, e animações (E12) já estão todos no `DiceScreen`. Rolar inline duplicaria essa lógica.

A escolha de **NÃO expor delete/rename no M1** — embora a API já exista em `PresetsRepository` — segue YAGNI: o roadmap não pede, o cap de 10 é largo o suficiente para um primeiro release, e adicionar gesto de long-press + diálogo de confirmação dobraria o escopo de testes. Os métodos da repository ficam disponíveis para uso futuro sem mudança de API.

## Proposed Solution

```
lib/features/presets/
├── preset_data.dart                    # NEW — 7 BuiltInPreset const + helpers
├── presets_screen.dart                 # REWRITE — 2 seções + + NOVO
└── widgets/
    ├── preset_card.dart                # NEW — MacWindow card (built-in OR custom)
    ├── preset_section.dart             # NEW — header listrado + lista de cards
    ├── add_preset_button.dart          # NEW — botão "+ NOVO" em estilo MacButton
    └── create_preset_sheet.dart        # NEW — BottomSheet para criar custom

lib/features/dice/dice_controller.dart  # MODIFY — adicionar applyConfig()

test/features/presets/
├── preset_data_test.dart
├── presets_screen_test.dart
└── widgets/
    ├── preset_card_test.dart
    ├── preset_section_test.dart
    ├── add_preset_button_test.dart
    └── create_preset_sheet_test.dart

test/features/dice/dice_controller_test.dart  # MODIFY — cobrir applyConfig()

lib/l10n/app_pt_BR.arb (+10 others)     # MODIFY — ~14 novas chaves
```

### Built-in preset registry

`preset_data.dart` expõe um `const List<BuiltInPreset> builtInPresets` com 7 entradas. O modelo:

```dart
@immutable
class BuiltInPreset {
  const BuiltInPreset({
    required this.id,
    required this.diceType,
    required this.diceCount,
    required this.nameKey,
  });

  /// Stable identifier — kebab-case, used as test fixture and analytics.
  final String id;

  /// Die type pre-applied when the user taps this card.
  final DiceType diceType;

  /// Number of dice (1..10) pre-applied when the user taps this card.
  final int diceCount;

  /// l10n key for the user-visible name (e.g. `'presetBuiltInLudo'`).
  /// Resolved at render time via `context.l10n` — never hard-code pt-BR.
  final String nameKey;
}
```

Lista canônica:

| id | diceType × count | nameKey | pt-BR |
|---|---|---|---|
| `ludo` | 1×D6 | `presetBuiltInLudo` | Ludo |
| `banco-imobiliario` | 2×D6 | `presetBuiltInBancoImobiliario` | Banco Imobiliário |
| `war` | 3×D6 | `presetBuiltInWar` | War |
| `yahtzee` | 5×D6 | `presetBuiltInYahtzee` | Yahtzee |
| `dnd-ataque` | 1×D20 | `presetBuiltInDndAtaque` | D&D Ataque |
| `magic-vida` | 1×D20 | `presetBuiltInMagicVida` | Magic Vida |
| `percentil` | 1×D100 | `presetBuiltInPercentil` | Percentil |

### Layered responsibility map

| Componente | Responsabilidade | Não responsabiliza-se por |
|---|---|---|
| `BuiltInPreset` (model) | Imutável; carrega `diceType`, `diceCount`, `nameKey`. | Renderização, l10n resolution |
| `preset_data.dart` (const list) | Define os 7 presets canônicos. | Custom presets (vivem em `PresetsRepository`) |
| `PresetCard` | Renderiza um `MacWindow` (sem close button) com nome em cima e notação "NxDM" em baixo. Tappable: chama `onTap()` que é provida pelo parent. Aceita um label resolvido (string) e a notação. Não conhece preset built-in vs custom. | Navegação; aplicação de config |
| `PresetSection` | Header listrado tipo title bar do MacWindow + `Wrap` de `PresetCard`s. Recebe `List<({String label, String notation, VoidCallback onTap})>` (lista de pseudo-presets renderizáveis). | Decisão de qual seção mostrar |
| `AddPresetButton` | `MacButton` "+ NOVO" (label de l10n). `onTap` abre o `BottomSheet`. | Validação; persistência |
| `CreatePresetSheet` | `StatefulWidget` com `TextField` (max 24 chars, validador não-vazio), chips de `DiceType`, quantity stepper 1..10. Botão "Salvar" chama `PresetsRepository.add(...)` e `Navigator.pop`. | Renderizar a lista; navegar para Rolar |
| `PresetsScreen` | `StreamBuilder<List<CustomPreset>>` em `repository.watch()`. Renderiza built-in section + custom section + (condicionalmente) `AddPresetButton`. No tap de qualquer card: chama `DiceController.applyConfig(...)` e `navigationShell.goBranch(0)` para Rolar. | Lógica de domínio |
| `DiceController.applyConfig` | Define `_selectedType` + `_count` num só `notifyListeners()` + persiste o config único; clear `_lastResult`. | Rolar (usuário ainda toca ROLAR) |

### Sequence: usuário toca em um preset (custom ou built-in)

```
PresetCard      PresetsScreen     DiceController     LastDiceConfig     RetroTabBar/Shell
    │                │                  │                  │                   │
    │ onTap()        │                  │                  │                   │
    ├───────────────▶│                  │                  │                   │
    │                │ applyConfig(d20,1)                  │                   │
    │                ├─────────────────▶│ _selectedType=...│                   │
    │                │                  │ _count=...       │                   │
    │                │                  │ notifyListeners()│                   │
    │                │                  │ await prefs.write(...)               │
    │                │                  ├─────────────────▶│                   │
    │                │ navigationShell.goBranch(0)         │                   │
    │                ├──────────────────────────────────────────────────────▶│ switch to Rolar
```

A ordem (`notifyListeners` antes do `await`) replica o padrão de `setType`/`setCount`/`setSoundEnabled`.

### CreatePresetSheet flow

```
   AddPresetButton
        │ tap
        ▼
   showModalBottomSheet ─▶ CreatePresetSheet
                              │ Salvar tapped (validation passes)
                              ▼
                          PresetsRepository.add(name, type, count)
                              │
                              ▼
                          watch() emits new snapshot
                              │
                              ▼
                       StreamBuilder rebuilds → new card appears
                              │
                          Navigator.pop()
```

Validação no `Salvar`:
- `name.trim().isEmpty` → desabilita o botão (não mostra erro inline; é descoberta).
- `name.length > customPresetMaxNameLength` (24) → o `TextField` recusa input via `LengthLimitingTextInputFormatter`.
- `count` clamp 1..10 garantido pelo `QuantityStepper` (reusa o de E05 se existir; senão é um novo widget local — verificar).

## Acceptance criteria

- [ ] `preset_data.dart` expõe `const builtInPresets` com 7 entradas na ordem listada acima
- [ ] `PresetsScreen` renderiza seção "Jogos" com 7 cards built-in e seção "Meus presets" com os custom presets vindos de `PresetsRepository.watch()`
- [ ] Tocar em qualquer card aplica a config no `DiceController` e navega para a aba Rolar
- [ ] Botão "+ NOVO" aparece somente quando `repository.canAddMore == true`; some quando 10 customs já existem
- [ ] `CreatePresetSheet` valida nome (não-vazio, ≤ 24 chars) e quantidade (1..10); botão Salvar fica desabilitado até a validação passar
- [ ] Após salvar, o sheet fecha e o novo preset aparece na seção "Meus presets" sem refresh manual (graças ao `watch()`)
- [ ] Zero terceira cor; zero gradiente; zero sombra; zero anti-aliasing (CustomPaint do MacWindow já cuida disso)
- [ ] 100% line coverage no código novo + cobertura mantida em `dice_controller.dart` após adição de `applyConfig`
- [ ] `flutter analyze` zero issues
- [ ] Out of scope: delete/rename de custom presets, reordenação, packs temáticos

## Tasks

- [ ] **T1** Adicionar ~14 chaves novas em `lib/l10n/app_pt_BR.arb` — ver [§ i18n delta](#i18n-delta) abaixo
- [ ] **T2** Traduzir as chaves nos 10 ARBs restantes
- [ ] **T3** `lib/features/presets/preset_data.dart` (`BuiltInPreset` class + `const builtInPresets` list) + teste
- [ ] **T4** Adicionar `DiceController.applyConfig({required DiceType diceType, required int count})` em `lib/features/dice/dice_controller.dart` + atualizar teste
- [ ] **T5** `lib/features/presets/widgets/preset_card.dart` + teste — testa render do nome + notação + callback de tap
- [ ] **T6** `lib/features/presets/widgets/preset_section.dart` + teste — testa header + ordem dos cards
- [ ] **T7** `lib/features/presets/widgets/add_preset_button.dart` + teste — testa render + callback
- [ ] **T8** `lib/features/presets/widgets/create_preset_sheet.dart` + teste — testa validação (vazio → botão off; 25 chars → input recusa), salvamento chama `repository.add`, fecha o sheet
- [ ] **T9** Reescrever `lib/features/presets/presets_screen.dart` — `StreamBuilder` + 2 seções + botão condicional + integração com `DiceController.applyConfig` + `StatefulNavigationShell.goBranch(0)`
- [ ] **T10** `test/features/presets/presets_screen_test.dart` — smoke das 2 seções, cap de 10, tap em card aplica config + troca de aba
- [ ] **T11** Atualizar `progress.md` — marcar EPIC 10 (1–5) como `[x]` + nota referenciando este plano
- [ ] **T12** `feedback.sh --all` verde

## Implementation details

### DiceController.applyConfig

```dart
/// Applies an external config (e.g. a preset tap) atomically: sets
/// [selectedType] and [count] in a single notification, clears
/// [lastResult], and persists. No-op when both fields already match.
Future<void> applyConfig({
  required DiceType diceType,
  required int count,
}) async {
  final clamped = count.clamp(1, 10);
  if (diceType == _selectedType && clamped == _count) return;
  _selectedType = diceType;
  _count = clamped;
  _lastResult = null;
  notifyListeners();
  await _lastDiceConfig.write(
    LastDiceConfig(diceType: diceType, count: clamped),
  );
}
```

Por que adicionar `applyConfig` em vez de chamar `setType` + `setCount` na sequência? Dois `notifyListeners` + dois `await prefs.write` é desperdício e pisca a UI. `applyConfig` é o helper atômico exatamente para o cenário "preset apply".

### Built-in section vs Custom section composition

`PresetsScreen` mapeia tanto built-in quanto custom para a mesma tupla renderizável:

```dart
final builtInItems = builtInPresets.map((p) => _PresetItem(
  label: p.localizedName(context),
  notation: '${p.diceCount}${p.diceType.label}',
  onTap: () => _applyAndGo(p.diceType, p.diceCount),
));

final customItems = customs.map((p) => _PresetItem(
  label: p.name,
  notation: '${p.diceCount}${p.diceType.label}',
  onTap: () => _applyAndGo(p.diceType, p.diceCount),
));
```

`PresetCard` recebe apenas o `_PresetItem` desconectado de built-in vs custom. Single render path.

### CreatePresetSheet layout

```
┌────────────────────────────────────────┐
│  NOVO PRESET                           │  ← MacWindow title bar
├────────────────────────────────────────┤
│  Nome                                  │
│  [_________________________]           │  ← TextField, 24-char limit
│                                        │
│  Dado                                  │
│  [D4] [D6] [D8] [D10] [D12] [D20] [D100]│  ← chip group
│                                        │
│  Quantidade                            │
│  [ − ]  3  [ + ]                       │  ← quantity stepper 1..10
│                                        │
│  [  SALVAR  ]                          │  ← MacButton, disabled when invalid
└────────────────────────────────────────┘
```

Reusa: `MacButton`, `MacWindow`, dice chip do `TypeSelector` (E05), `QuantitySelector` (E05). Reaproveitar widgets de `lib/features/dice/widgets/` no sheet desencoraja duplicação. Verificar exports/visibilidade — se algum é private, mover para `lib/shared/widgets/` é a próxima escolha (não nesta epic; abrir nota se acontecer).

## i18n delta

| Key | pt-BR |
|---|---|
| `presetsSectionBuiltIn` | Jogos |
| `presetsSectionCustom` | Meus presets |
| `presetsAddNew` | + NOVO |
| `presetsSheetTitle` | Novo preset |
| `presetsSheetNameLabel` | Nome |
| `presetsSheetDiceLabel` | Dado |
| `presetsSheetCountLabel` | Quantidade |
| `presetsSheetSave` | Salvar |
| `presetBuiltInLudo` | Ludo |
| `presetBuiltInBancoImobiliario` | Banco Imobiliário |
| `presetBuiltInWar` | War |
| `presetBuiltInYahtzee` | Yahtzee |
| `presetBuiltInDndAtaque` | D&D Ataque |
| `presetBuiltInMagicVida` | Magic Vida |
| `presetBuiltInPercentil` | Percentil |

Total: **15 chaves novas**. Os 7 nomes de jogos têm tradução transparente em algumas línguas (Ludo é Ludo em quase todas) — pt-BR é a fonte da verdade; outros locales reusam o nome quando faz sentido cultural.

## Wiring changes

`PresetsRepository` já está injetado em `lib/app.dart`? Não — só `HistoryRepository` está. Adicionar:

```dart
Provider<PresetsRepository>(create: (_) => InMemoryPresetsRepository()),
```

`main.dart` recebe a versão Hive durante o startup (paralelo ao history); fora do escopo desta epic. Documentar como TODO atrelado ao próximo wiring update (probably E14/E15).

## Out of scope

- Delete e rename de custom presets — API existe em `PresetsRepository.remove/rename`, sem UI no M1
- Reordenação por drag — fora do escopo
- Packs temáticos (Pokémon TCG, Magic, etc.) — listados em `docs/roadmap/06-roadmap-futuro.md` como pós-M1
- Sincronização entre dispositivos — fora do escopo M1
- Goldens — fora do M1
- Confirmação ao salvar duplicata de nome — não validar; o id do preset é único independente do nome

## Risks

- **`StatefulNavigationShell` acesso a partir de `PresetsScreen`**: o shell é fornecido pelo `app_router` ao construir o `AppShell`. `PresetsScreen` é filha do branch e não recebe o shell por construtor. Solução padrão: `StatefulNavigationShell.of(context)`. Confirmar que o `go_router` versão atual expõe esse helper (lib é 14.x); se não, expor via `InheritedWidget` no `AppShell`.
- **Reuso de `TypeSelector` e `QuantitySelector` de E05** no `CreatePresetSheet`: se esses widgets são private ao feature `dice`, esta epic NÃO os move. Em vez disso, duplicar uma versão interna no preset feature (com nota de `Risk` em `progress.md`) e abrir uma issue de extração para `shared/widgets/` em ciclo posterior. Não é decisão deste plano.
- **Cap de 10 custom presets**: se o cap for atingido, o botão "+ NOVO" simplesmente some. O usuário só descobre quando tenta adicionar — risk aceito (sem toast/banner). Mensagem de "atingiu o cap" é YAGNI no M1.
- **Persistência do `PresetsRepository`**: `InMemoryPresetsRepository` é o default no `lib/app.dart` atual (E07 herda essa decisão). Custom presets só ficam persistidos quando E15 fizer o swap para `HivePresetsRepository` no splash boot. Documentar em `progress.md` que essa migração é um item separado.

## References

- [docs/roadmap/08-epics-m1.md](../roadmap/08-epics-m1.md) — E07 line item
- [docs/roadmap/03-stack-tecnico.md](../roadmap/03-stack-tecnico.md) — file layout `lib/features/presets/`
- [lib/core/storage/presets_repository.dart](../../lib/core/storage/presets_repository.dart) — already-implemented API
- [lib/core/storage/models/custom_preset.dart](../../lib/core/storage/models/custom_preset.dart) — model + 24-char limit
- [lib/features/dice/dice_controller.dart](../../lib/features/dice/dice_controller.dart) — adds `applyConfig`
- [lib/shared/widgets/mac_window.dart](../../lib/shared/widgets/mac_window.dart) — card chrome
- [docs/plan/2026-05-26-feat-e05-dice-screen-plan.md](2026-05-26-feat-e05-dice-screen-plan.md) — DiceScreen, TypeSelector, QuantitySelector
