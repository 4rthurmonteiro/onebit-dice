---
title: "feat: e05 dice screen"
type: feat
date: 2026-05-26
epic: E05
status: planned
---

# feat: e05 dice screen — Standard

> Numbering note: o roadmap (`docs/roadmap/08-epics-m1.md`) chama esta epic de **E05**; `docs/plan/progress.md` numera o mesmo corpo de trabalho como **EPIC 8** (itens 8.1–8.9). Este plano adota o rótulo do roadmap (E05) para casar com o brainstorm, mas as entradas do tracker permanecem em 8.x.

## Overview

Entrega a **tela principal de rolagem** do 1-Bit Dice — o coração funcional do M1. Compõe um `TypeSelector` (chips para os 7 `DiceType`s), um `QuantitySelector` (− / count / +, clampado em `1..10`), uma `DiceWidget` (grid pixel de slots com `?` ou valores), e um botão full-width "ROLAR".

A rolagem usa `Random.secure()` via [`rollDice`](../../lib/shared/utils/random_dice.dart) (E03), toca `SoundEvent.total` via [`AudioController`](../../lib/core/audio/audio_controller.dart) (E10), dispara um pulso médio via [`HapticController`](../../lib/core/haptic/haptic_controller.dart) (E10), persiste a configuração corrente via `LastDiceConfigPreference` (E04), e appenda o `RollResult` no `HistoryRepository` (E04).

A animação multi-fase real e o uso dos três sons (`roll`/`stop`/`total`) ficam para **E12** (Animações dos Dados). Em E05 a `DiceWidget` é um placeholder textual em Silkscreen — mas já estruturado como grid de N slots para que E12 plugue sprite sheets sem refator visual.

Brainstorm de referência: [2026-05-26-e05-dice-screen-brainstorm-doc.md](../brainstorm/2026-05-26-e05-dice-screen-brainstorm-doc.md).

## Problem Statement / Motivation

Hoje o app:

- Mostra apenas o `DesignSystemPreview` ([lib/features/_dev/design_system_preview.dart](../../lib/features/_dev/design_system_preview.dart)) como `home` — um smoke-test do design system marcado para deleção desde a E02.
- Tem **todas as dependências** da rolagem prontas mas nenhuma orquestração: `rollDice()` (E03), `RollResult` (E03), `AudioController` (E10), `HapticController` (E10), `HistoryRepository` + `InMemoryHistoryRepository` (E04), `LastDiceConfigPreference` + `InMemoryLastDiceConfigPreference` (E04), `MacButton`/`MacWindow`/`PixelDivider` (E02), i18n com `actionRoll`/`rollResultTotal` (E13).
- Não persiste seleção de tipo/quantidade entre sessões, mesmo com a infra (`LastDiceConfigPreference`) já existindo.
- Não emite nenhum áudio nem háptico — os controllers existem mas ninguém chama `audio.play(...)` ou `haptic.trigger()`.

Sem E05:
- O M1 não tem **a feature principal** do produto rodando end-to-end.
- E06 (Splash) e E09 (Navegação) não têm uma `home` real para hospedar.
- O `DesignSystemPreview` continua sendo o ponto de entrada — débito visível na primeira vez que alguém roda o app.

A decisão de manter `Hive` desligado em E05 (consumindo `InMemoryHistoryRepository` + `InMemoryLastDiceConfigPreference`) **preserva o sequenciamento original do roadmap**: o bootstrap de Hive é deliberadamente diferido para E06 (Splash), conforme documentado em [hive_init.dart](../../lib/core/storage/hive_init.dart) ("Consumed by the splash screen (E06)"). Em E06 a troca é local — `lib/app.dart` recebe as impls persistentes em vez das in-memory, sem mudar uma linha do `DiceController`.

A decisão de emitir **apenas** `SoundEvent.total` + 1 háptico (em vez dos três sons `roll`/`stop`/`total`) evita simular animação com delays fixos que serão descartados em E12. Esse encadeamento é semântico, não temporal — espera ele em sua fase própria.

## Proposed Solution

Seis arquivos de produção em `lib/features/dice/` + wiring no `MultiProvider` de [lib/app.dart](../../lib/app.dart). Cinco testes (controller + quatro widgets) garantindo cobertura 100% line, conforme política do projeto.

```
lib/features/dice/
├── dice_controller.dart            # ChangeNotifier orquestrador (estado + side effects)
├── dice_screen.dart                # composição visual; home do MaterialApp
└── widgets/
    ├── type_selector.dart          # Wrap de 7 chips DiceType
    ├── quantity_selector.dart      # linha − count + clampada 1..10
    ├── dice_widget.dart            # grid pixel de slots (placeholder textual)
    └── roll_button.dart            # MacButton full-width "ROLAR"

test/features/dice/
├── dice_controller_test.dart
├── dice_screen_test.dart
└── widgets/
    ├── type_selector_test.dart
    ├── quantity_selector_test.dart
    ├── dice_widget_test.dart
    └── roll_button_test.dart

lib/l10n/
└── app_*.arb                       # +2 chaves: diceCountIncreaseLabel, diceCountDecreaseLabel

lib/app.dart                        # MultiProvider: + HistoryRepository, + LastDiceConfigPreference, + DiceController
                                    # home: DiceScreen() (substitui DesignSystemPreview)

lib/features/_dev/                  # remover quando o último consumidor (App) trocar para DiceScreen
```

> **Cleanup**: o `lib/features/_dev/design_system_preview.dart` é declarado descartável desde a E02 ("Slated for deletion in E09"). Como E05 substitui o último consumidor, o arquivo (e a pasta `_dev/`) **devem ser removidos no mesmo PR** — não há valor em manter um smoke-test órfão.

### Layered responsibility map

| Componente | Responsabilidade | Não responsabiliza-se por |
|---|---|---|
| `DiceController` (`ChangeNotifier`) | Único orquestrador. Estado: `selectedType`, `count`, `lastResult` (nullable). Métodos: `setType(DiceType)`, `setCount(int)`, `roll()`. Side effects do `roll()` em ordem fixa: gera `RollResult` → notifica → `history.append` → `audio.play(total)` → `haptic.trigger()` → `lastDiceConfig.write(...)`. `setType`/`setCount` limpam `lastResult` e persistem config. Recebe `Random?` opcional para determinismo em testes. | Renderização; navegação |
| `TypeSelector` (StatelessWidget) | Renderiza um `Wrap` de 7 chips, um por `DiceType.values`. Cada chip é tappable, com selecionado destacado (inverter `ink`/`paper`). Min-hit-target 44pt. Lê `selectedType` e dispara `onChanged(DiceType)`. | Saber o que é "tipo atual" — recebe via parâmetro |
| `QuantitySelector` (StatelessWidget) | Linha `[−] [count] [+]` em Silkscreen grande. `−` desabilitado quando `count == 1`; `+` desabilitado quando `count == 10`. Cada botão expõe Semantics. | Validação fora de `1..10` (clamp é do controller) |
| `DiceWidget` (StatelessWidget) | Renderiza grid pixel (até 3 colunas, até 4 linhas) de N slots. `values == null` → cada slot mostra `?`. `values != null` → cada slot mostra `values[i]`. Total destacado embaixo (Silkscreen 32px) quando `values != null`. Equação textual (`"3 + 5 + 2 = 10"`) só quando `values != null && values.length > 1`. | Lógica de quando atualizar; é puramente visual |
| `RollButton` (StatelessWidget) | Wrapper finíssimo sobre `MacButton(label: l10n.actionRoll, onPressed:, expand: true)`. Existe como entidade nomeada para o `dice_screen_test` ter um alvo estável (`find.byType(RollButton)`). | Ações — recebe `onPressed` via parâmetro |
| `DiceScreen` (StatelessWidget) | Composição: `Scaffold` com `SafeArea`; coluna principal com header título → `DiceWidget` (com border duplo, sem `MacWindow`) → `PixelDivider` → `TypeSelector` → `QuantitySelector` → `RollButton` no rodapé. Lê `DiceController` via `context.watch`; chama `controller.setType` / `setCount` / `roll`. | Side effects da rolagem (delegados ao controller) |

### Sequence: usuário toca "ROLAR"

```
DiceScreen        DiceController      HistoryRepository      AudioController     HapticController     LastDiceConfigPref
     │                  │                     │                     │                    │                     │
     │  roll()          │                     │                     │                    │                     │
     ├─────────────────▶│                     │                     │                    │                     │
     │                  │  rollDice(...)      │                     │                    │                     │
     │                  ├──┐                  │                     │                    │                     │
     │                  │  │                  │                     │                    │                     │
     │                  │◀─┘                  │                     │                    │                     │
     │                  │  _lastResult = R    │                     │                    │                     │
     │                  │  notifyListeners()  │                     │                    │                     │
     │  rebuild (grid)  │                     │                     │                    │                     │
     │◀─────────────────┤                     │                     │                    │                     │
     │                  │  append(R)          │                     │                    │                     │
     │                  ├────────────────────▶│                     │                    │                     │
     │                  │  play(total)        │                     │                    │                     │
     │                  ├────────────────────────────────────────▶│                     │                     │
     │                  │  trigger()          │                     │                    │                     │
     │                  ├──────────────────────────────────────────────────────────────▶│                     │
     │                  │  write(LastDiceConfig(type, count))                                                  │
     │                  ├──────────────────────────────────────────────────────────────────────────────────▶│
```

### Sequence: usuário muda `count` (efeito reativo)

```
QuantitySelector    DiceController        LastDiceConfigPref      DiceWidget
       │                  │                       │                    │
       │ setCount(5)      │                       │                    │
       ├─────────────────▶│                       │                    │
       │                  │ clamp(5, 1..10)       │                    │
       │                  │ _count = 5            │                    │
       │                  │ _lastResult = null    │  ← invalida result visual
       │                  │ notifyListeners()     │                    │
       │ rebuild (label)  │                       │                    │
       │◀─────────────────┤                       │                    │
       │                  │ write(...)            │                    │
       │                  ├──────────────────────▶│                    │
       │                  │                       │ rebuild (5× `?`)   │
       │                  │                       │◀──────────────────►│
```

### Wiring em `lib/app.dart`

O `MultiProvider` cresce em duas direções:

1. **Repos** — `Provider<HistoryRepository>` + `Provider<LastDiceConfigPreference>` com `create: (_) => InMemory…()`. Em E06 essas duas linhas trocam para `.value(value: hiveBoxes.…)` sem afetar o `DiceController`.
2. **Controller** — `ChangeNotifierProvider<DiceController>` com `create: (context) => DiceController(history: context.read(), audio: context.read(), haptic: context.read(), lastDiceConfig: context.read())`.

```dart
// lib/app.dart (excerpt — diff vs hoje)
return MultiProvider(
  providers: [
    ChangeNotifierProvider<AudioController>.value(value: audioController),
    ChangeNotifierProvider<HapticController>.value(value: hapticController),
    ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
    ChangeNotifierProvider<LocaleController>(create: (_) => LocaleController()),
    Provider<HistoryRepository>(create: (_) => InMemoryHistoryRepository()),
    Provider<LastDiceConfigPreference>(create: (_) => InMemoryLastDiceConfigPreference()),
    ChangeNotifierProvider<DiceController>(
      create: (context) => DiceController(
        history: context.read<HistoryRepository>(),
        audio: context.read<AudioController>(),
        haptic: context.read<HapticController>(),
        lastDiceConfig: context.read<LastDiceConfigPreference>(),
      ),
    ),
  ],
  child: const _AppView(),
);
```

E em `_AppView`:

```dart
return MaterialApp(
  // ...
  home: const DiceScreen(),  // ← substitui DesignSystemPreview
);
```

## Acceptance Criteria

- [ ] App roda e `DiceScreen` é a tela inicial (sem splash em E05; E06 inserirá a splash antes).
- [ ] Default de primeira execução: `DiceType.d6`, `count: 1`, grid mostra **1 slot `?`**.
- [ ] Trocar de tipo via `TypeSelector`: chip selecionado fica invertido (`ink`/`paper`), grid volta para `?` se já havia resultado, `LastDiceConfigPreference.write(...)` é chamado.
- [ ] Mexer no `QuantitySelector`: `−` desabilitado em `count == 1`; `+` desabilitado em `count == 10`; mudar count limpa o resultado da view e persiste.
- [ ] Tocar "ROLAR": grid passa de `?` para N valores; o total grande aparece; equação só aparece para `count > 1`; `HistoryRepository.append` é chamado uma vez com o `RollResult` correto; `AudioController.play(SoundEvent.total)` é chamado; `HapticController.trigger()` é chamado; `LastDiceConfigPreference.write(...)` é chamado.
- [ ] Fechar e reabrir o app (em E05 com `InMemory*`, isto é, dentro da mesma sessão isolada do teste): o controller construído com a `LastDiceConfigPreference` pré-populada restaura `type` e `count`.
- [ ] `lib/features/_dev/design_system_preview.dart` e `lib/features/_dev/` foram **removidos**; nenhum import órfão.
- [ ] `flutter analyze` exit 0, zero issues.
- [ ] `flutter test --coverage` passa com 100% line coverage (excluindo `lib/main.dart` e `*.g.dart`).
- [ ] Strings novas (`diceCountIncreaseLabel`, `diceCountDecreaseLabel`) presentes nos 10 ARBs.

## Implementation Plan

A ordem abaixo é a ordem sugerida de execução; cada item mapeia diretamente para uma entrada do checklist em `docs/plan/progress.md` (EPIC 8 — Feature: Home Screen / Rolagem).

### 8.1 — `DiceController` (`lib/features/dice/dice_controller.dart`)

- [ ] Criar `DiceController extends ChangeNotifier`.
- [ ] Construtor: `DiceController({required HistoryRepository history, required AudioController audio, required HapticController haptic, required LastDiceConfigPreference lastDiceConfig, Random? rng})`.
- [ ] No construtor, hidratar estado inicial a partir de `lastDiceConfig.read()`:
  - Se `null` → `_selectedType = DiceType.d6`, `_count = 1` (defaults do roadmap, [01-escopo-m1.md §Estado inicial](../roadmap/01-escopo-m1.md)).
  - Se não-`null` → `_selectedType = config.diceType`, `_count = config.count`.
- [ ] `_lastResult` começa `null` (a hidratação só restaura **configuração**, não resultados).
- [ ] Getters: `selectedType`, `count`, `lastResult`.
- [ ] `setType(DiceType type)`:
  - Se `type == _selectedType` → no-op (sem notify, sem write).
  - Senão: `_selectedType = type`; `_lastResult = null`; `notifyListeners()`; `await lastDiceConfig.write(LastDiceConfig(diceType: type, count: _count))`.
- [ ] `setCount(int value)`:
  - `final clamped = value.clamp(1, 10);`
  - Se `clamped == _count` → no-op.
  - Senão: `_count = clamped`; `_lastResult = null`; `notifyListeners()`; `await lastDiceConfig.write(LastDiceConfig(diceType: _selectedType, count: clamped))`.
- [ ] `roll()`:
  ```dart
  final values = rollDice(_selectedType.sides, _count, rng: _rng);
  _lastResult = RollResult(
    timestamp: DateTime.now(),
    diceType: _selectedType,
    diceCount: _count,
    values: values,
  );
  notifyListeners();
  await history.append(_lastResult!);
  audio.play(SoundEvent.total);
  haptic.trigger();
  await lastDiceConfig.write(LastDiceConfig(diceType: _selectedType, count: _count));
  ```
- [ ] Documentar em dartdoc a ordem dos side-effects e a justificativa (UI > durabilidade).
- [ ] **Não** depender de `BuildContext`, `WidgetsBinding`, ou qualquer construct de UI — controller é Dart puro.

### 8.2 — `TypeSelector` (`lib/features/dice/widgets/type_selector.dart`)

- [ ] `StatelessWidget` com props:
  ```dart
  const TypeSelector({
    required this.selectedType,
    required this.onChanged,
    super.key,
  });
  final DiceType selectedType;
  final ValueChanged<DiceType> onChanged;
  ```
- [ ] Render: `Wrap(spacing: 8, runSpacing: 8, children: [for (final type in DiceType.values) _TypeChip(...)])`.
- [ ] `_TypeChip`:
  - `Semantics(label: type.label, button: true, selected: isSelected, child: GestureDetector(...))`.
  - Container com `border: Border.all(color: colors.ink, width: 2)`; padding interno para garantir `minHeight: 44`, `minWidth: 44` (HIG); `Text(type.label, style: AppTypography.display.copyWith(color: isSelected ? colors.paper : colors.ink, fontSize: 16))`.
  - Selecionado: `color: colors.ink` (fundo inverte); não-selecionado: `color: colors.paper`.
  - `onTap: () => onChanged(type)`.
- [ ] **Não** acessar `Provider` aqui — props-only mantém o widget puramente declarativo e simples de testar.

### 8.3 — `QuantitySelector` (`lib/features/dice/widgets/quantity_selector.dart`)

- [ ] `StatelessWidget` com props:
  ```dart
  const QuantitySelector({
    required this.count,
    required this.onChanged,
    super.key,
  });
  final int count;       // 1..10
  final ValueChanged<int> onChanged;
  ```
- [ ] Layout: `Row(mainAxisAlignment: spaceBetween)` com 3 filhos:
  1. `_StepButton(symbol: '−', enabled: count > 1, onTap: () => onChanged(count - 1), semanticLabel: l10n.diceCountDecreaseLabel)`
  2. `Text('$count', style: AppTypography.display.copyWith(fontSize: 40, color: colors.ink))`
  3. `_StepButton(symbol: '+', enabled: count < 10, onTap: () => onChanged(count + 1), semanticLabel: l10n.diceCountIncreaseLabel)`
- [ ] `_StepButton`: `GestureDetector` envolvendo `Container` (44×44 mínimo, borda 2px ink); `enabled == false` → `onTap: null`. Sem cor cinza, sem opacidade — desabilitado renderiza idêntico ao habilitado mas inerte (estética 1-bit; só o callback muda).
- [ ] Os `_StepButton` usam `Semantics(label: semanticLabel, button: true, enabled: enabled, child: ...)` para TalkBack/VoiceOver.

### 8.4 — `DiceWidget` (`lib/features/dice/widgets/dice_widget.dart`)

- [ ] `StatelessWidget` com props:
  ```dart
  const DiceWidget({
    required this.count,
    required this.values,   // null = empty state ("?"), non-null = result
    super.key,
  });
  final int count;
  final List<int>? values;
  ```
- [ ] Assert defensivo: se `values != null`, `values.length == count`.
- [ ] Layout:
  - Coluna ink-bordered (2px duplo, como `MacButton.face`) — **sem** `MacWindow` (decisão em Open Questions: title-bar listrada adicionaria ruído sobre o grid).
  - Grid de slots: `GridView.count(crossAxisCount: count <= 3 ? count : 3, shrinkWrap: true, ...)` ou um `Wrap` equivalente. Cada slot é um `_Slot(value: int? v)` 64×64 com texto centralizado em Silkscreen 32px.
  - `values == null` → todos os slots exibem `?`. `values != null` → cada slot exibe seu int.
  - Abaixo do grid: divider de 1px ink; total em Silkscreen 40px (`Total: $total` via `l10n.rollResultTotal`); equação em VT323 18px abaixo, só renderizada quando `values != null && values.length > 1`.
- [ ] Defina e exponha em `@visibleForTesting` chaves de localização para o teste alvo:
  - `static const Key gridKey = ValueKey('DiceWidget.grid');`
  - `static const Key totalKey = ValueKey('DiceWidget.total');`
  - `static const Key equationKey = ValueKey('DiceWidget.equation');`

### 8.5 — `RollButton` (`lib/features/dice/widgets/roll_button.dart`)

- [ ] Wrapper finíssimo sobre `MacButton`:
  ```dart
  class RollButton extends StatelessWidget {
    const RollButton({required this.onPressed, super.key});
    final VoidCallback onPressed;

    @override
    Widget build(BuildContext context) {
      return MacButton(
        label: context.l10n.actionRoll,
        onPressed: onPressed,
        expand: true,
      );
    }
  }
  ```
- [ ] Razão de existir como widget separado: o `dice_screen_test` (8.9-equivalente) tem um alvo estável `find.byType(RollButton)` sem depender de `find.text('ROLL')`/`'ROLAR'` (locale-sensitive).

### 8.6 — `DiceScreen` (`lib/features/dice/dice_screen.dart`)

- [ ] `StatelessWidget`. `build`:
  ```dart
  final controller = context.watch<DiceController>();
  final colors = Theme.of(context).extension<OneBitColors>()!;
  return Scaffold(
    backgroundColor: colors.paper,
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(context.l10n.appName.toUpperCase(), style: AppTypography.display.copyWith(color: colors.ink, fontSize: 28)),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: DiceWidget(
                  count: controller.count,
                  values: controller.lastResult?.values,
                ),
              ),
            ),
            const PixelDivider(padding: EdgeInsets.symmetric(vertical: 12)),
            TypeSelector(
              selectedType: controller.selectedType,
              onChanged: controller.setType,
            ),
            const SizedBox(height: 12),
            QuantitySelector(
              count: controller.count,
              onChanged: controller.setCount,
            ),
            const SizedBox(height: 16),
            RollButton(onPressed: controller.roll),
          ],
        ),
      ),
    ),
  );
  ```
- [ ] **Não** `coverage:ignore-file` — cobrir tudo via `dice_screen_test.dart` (decisão em Open Questions).

### 8.6b — Wiring (`lib/app.dart`)

- [ ] Adicionar dois `Provider`s para os repos `InMemory*` (constructor `Provider<T>(create:)` em vez de `.value` para alinhar com `ThemeProvider`/`LocaleController`).
- [ ] Adicionar `ChangeNotifierProvider<DiceController>` que injeta os 4 deps via `context.read<>()`.
- [ ] Trocar `home: const DesignSystemPreview()` → `home: const DiceScreen()` em `_AppView.build`.
- [ ] Remover o import de `package:onebit_dice/features/_dev/design_system_preview.dart`.

### 8.6c — Cleanup do `DesignSystemPreview`

- [ ] `git rm lib/features/_dev/design_system_preview.dart`.
- [ ] Remover a pasta vazia `lib/features/_dev/` (o `feedback_no_underscore_prefixed_folders` memory já desaconselhava o nome — esta é a remoção definitiva).
- [ ] `grep -r "DesignSystemPreview" lib/ test/` deve retornar 0 hits.

### 8.6d — i18n: 2 chaves novas

Brainstorm "Open Q3" decide entrar com semantic labels já agora (em vez de aguardar E11). Adições mínimas — apenas os botões `+` e `−` precisam, porque os chips `D4..D100` já são auto-descritivos pelo próprio label.

- [ ] **Em `lib/l10n/app_pt.arb` (template)**, adicionar:
  ```jsonc
  "diceCountIncreaseLabel": "Aumentar quantidade de dados",
  "@diceCountIncreaseLabel": {
    "description": "Semantic label for the + button in the dice quantity stepper"
  },
  "diceCountDecreaseLabel": "Diminuir quantidade de dados",
  "@diceCountDecreaseLabel": {
    "description": "Semantic label for the − button in the dice quantity stepper"
  }
  ```
- [ ] Adicionar as **duas chaves** (sem o bloco `@`, conforme convenção da E13) aos outros 9 ARBs: `en, es, fr, de, it, ja, zh_Hans, ko, ru`. Tradução via mesmo prompt LLM usado em E13. Sugestões iniciais (revisão humana opcional, alinhado à política da E13):
  - en: `Increase dice count` / `Decrease dice count`
  - es: `Aumentar cantidad de dados` / `Disminuir cantidad de dados`
  - fr: `Augmenter le nombre de dés` / `Diminuer le nombre de dés`
  - de: `Würfelanzahl erhöhen` / `Würfelanzahl verringern`
  - it: `Aumenta numero di dadi` / `Diminuisci numero di dadi`
  - ja: `サイコロを増やす` / `サイコロを減らす`
  - zh: `增加骰子数量` / `减少骰子数量`
  - ko: `주사위 개수 늘리기` / `주사위 개수 줄이기`
  - ru: `Увеличить количество кубиков` / `Уменьшить количество кубиков`
- [ ] Rodar `flutter gen-l10n` para regenerar os `app_localizations*.dart` committados.

### 8.7 — `dice_controller_test.dart`

Doubles inline (mesma estrutura dos `_RecordingAppSettings` de [haptic_controller_test.dart](../../test/core/haptic/haptic_controller_test.dart)):

```dart
class _FakeHistoryRepository implements HistoryRepository { /* records append calls */ }
class _FakeAudioController extends ChangeNotifier implements AudioController { /* records play */ }
class _FakeHapticController extends ChangeNotifier implements HapticController { /* records trigger */ }
class _FakeLastDicePref implements LastDiceConfigPreference { /* records writes */ }
```

Casos:

- [ ] `defaults to d6 / count 1 when LastDiceConfigPreference is empty`.
- [ ] `hydrates from LastDiceConfigPreference when present` (d20 / count 5).
- [ ] `setType to same value is a no-op (no notify, no write, lastResult preserved)`.
- [ ] `setType to a different value clears lastResult, notifies, persists`.
- [ ] `setCount clamps below 1 to 1` (`setCount(0)` → `count == 1`).
- [ ] `setCount clamps above 10 to 10` (`setCount(11)` → `count == 10`).
- [ ] `setCount to same value is a no-op` (após clamp).
- [ ] `setCount different value clears lastResult, notifies, persists`.
- [ ] `roll() with injected Random is deterministic` — `Random(42)` → valores esperados conhecidos.
- [ ] `roll() invokes deps in order: history.append, audio.play(total), haptic.trigger, lastDiceConfig.write` — verificar via um `events: <String>[]` compartilhado, replicando o padrão de [haptic_controller_test.dart](../../test/core/haptic/haptic_controller_test.dart#L91).
- [ ] `roll() does not play roll or stop` — só `total` registrado.
- [ ] `roll() sets lastResult with correct diceCount, diceType, values, and a sensible timestamp`.

### 8.8 — `type_selector_test.dart`

- [ ] `renders 7 chips, one per DiceType.values, in order`.
- [ ] `the chip matching selectedType is rendered inverted` (assertion via `ColoredBox` ou `Container.decoration.color` comparado a `colors.ink`).
- [ ] `tapping a non-selected chip invokes onChanged with that DiceType`.
- [ ] `tapping the already-selected chip still invokes onChanged` (validação visual fica no controller — widget é burro).
- [ ] `each chip has Semantics(label: type.label, button: true)`.

### 8.9 — `quantity_selector_test.dart`

- [ ] `renders count in Silkscreen` (verificar `find.text('1')` etc).
- [ ] `− is disabled when count == 1` — `onChanged` não dispara em tap.
- [ ] `+ is disabled when count == 10` — `onChanged` não dispara em tap.
- [ ] `+ calls onChanged(count + 1)` em estados intermediários.
- [ ] `− calls onChanged(count - 1)` em estados intermediários.
- [ ] `+ has Semantics(label: l10n.diceCountIncreaseLabel)`; `−` idem `diceCountDecreaseLabel`.

### 8.10 — `dice_widget_test.dart` (não listado em `progress.md` mas necessário p/ cobertura)

- [ ] `values == null → renders count slots, each showing "?"`.
- [ ] `values != null → renders one slot per value, each showing the integer`.
- [ ] `values != null && length > 1 → renders the equation`.
- [ ] `values != null && length == 1 → does NOT render the equation` (find.byKey(DiceWidget.equationKey) → nothing).
- [ ] `values != null → renders total (sum)`.
- [ ] `asserts when values.length != count`.

### 8.11 — `roll_button_test.dart`

- [ ] `renders a MacButton with label = l10n.actionRoll`.
- [ ] `tap forwards to onPressed`.

### 8.12 — `dice_screen_test.dart` (integração com Provider)

Builder helper:

```dart
Widget _harness({
  required HistoryRepository history,
  required AudioController audio,
  required HapticController haptic,
  required LastDiceConfigPreference lastDicePref,
  Random? rng,
}) {
  return MaterialApp(
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: MultiProvider(
      providers: [
        Provider<HistoryRepository>.value(value: history),
        ChangeNotifierProvider<AudioController>.value(value: audio),
        ChangeNotifierProvider<HapticController>.value(value: haptic),
        Provider<LastDiceConfigPreference>.value(value: lastDicePref),
        ChangeNotifierProvider<DiceController>(
          create: (ctx) => DiceController(
            history: ctx.read(), audio: ctx.read(),
            haptic: ctx.read(), lastDiceConfig: ctx.read(),
            rng: rng,
          ),
        ),
      ],
      child: const DiceScreen(),
    ),
  );
}
```

Casos:

- [ ] `initial: shows 1 "?" slot, d6 chip selected, count == 1, no total shown`.
- [ ] `tap on D20 chip: d20 is now visually selected, slot still "?" (no result yet), pref.write called`.
- [ ] `tap +: count → 2, two "?" slots, pref.write called`.
- [ ] `tap ROLL: grid updates to N integers, total shown, audio.play(SoundEvent.total) called once, haptic.trigger() called once, history.append called once with expected RollResult, pref.write called`.
- [ ] `after ROLL, tap +: result is discarded, grid back to N+1 "?"; history is unchanged`.
- [ ] `restores last config: pre-populated InMemoryLastDiceConfigPreference with (d12, 4) → screen opens with D12 selected and count == 4 and 4 "?" slots`.

### 8.13 — `progress.md` upkeep

- [ ] Marcar `[x]` em **EPIC 8** itens 8.1–8.6, 8.7–8.9, e adicionar (se necessário) entradas para 8.10–8.12 que cobrem `dice_widget_test`, `roll_button_test` e `dice_screen_test`. Atualizar o cabeçalho da seção com a nota de mapeamento E05 ↔ EPIC 8.
- [ ] Adicionar `[x] EPIC 1 — Theme & Design System → 1.11` continua DONE mas anotar "removed in E05 PR".

## Risks & Considerations

### Riscos técnicos

1. **`DiceController.roll()` é parcialmente async (`await history.append` e `await lastDiceConfig.write`).** Se um tap acontecer durante a await, o segundo `roll()` reentra antes do primeiro completar. O brainstorm não menciona reentrância; em E05 a write é o(1µs) em memória então o risco é praticamente zero. Mitigação preventiva: documentar (dartdoc) que `roll()` não é reentrante; um futuro debounce no botão (E12) protege contra duplo-tap. **Não** adicionar lock agora — YAGNI.
2. **`notifyListeners()` vem antes de `await history.append`.** Intencional: queremos UI snappy. Se `append` lançar, o resultado já apareceu na tela e o histórico fica fora-de-sync. Em E05 a `InMemoryHistoryRepository` não lança; em E06 a Hive box pode (raríssimo, disk full). Mitigação: deixar a exceção propagar (Crashlytics em E05 vai mais tarde via E06+); revisitar quando `HiveHistoryRepository` entrar em produção.
3. **`Wrap` de 7 chips em iPhone SE 1ª geração (320pt).** Com 44pt min-hit-target + padding, ~3 chips/linha → 2 linhas + 1 sobrando. Aceitável visualmente; se ficar feio na fase de implementação, fallback é `SingleChildScrollView(scrollDirection: Axis.horizontal)`. Não fixar agora.
4. **`MacWindow` em torno do `DiceWidget`** — brainstorm marca como decisão visual. Plano resolve por **não** envelopar (title-bar listrada compete visualmente com os slots). Se A/B no simulador discordar, troca é local.

### Riscos de produto

1. **Estado vazio com `?` ao mudar `count` pode confundir o usuário** ("perdi minha rolagem"). Mitigação: o histórico (E07) continua íntegro — mostrar uma toast "moved to history" seria churn fora de escopo. Aceitar.
2. **Sem animação em E05, o tap "ROLAR" parece instantâneo demais** — feedback do `total` SFX + haptic carrega esse peso até E12 entrar. Aceitar como degradação temporária.

### Dependências

| Origem | Item | Status |
|---|---|---|
| E02 | `MacButton`, `MacWindow`, `PixelDivider`, `AppTypography`, `OneBitColors` | DONE |
| E03 | `DiceType`, `RollResult`, `rollDice` | DONE |
| E04 | `HistoryRepository` + `InMemoryHistoryRepository`, `LastDiceConfigPreference` + `InMemoryLastDiceConfigPreference` | DONE |
| E10 | `AudioController` (com `play(SoundEvent.total)`), `HapticController` (com `trigger()`) | DONE |
| E13 | `BuildContext.l10n` extension, `actionRoll`, `rollResultTotal`, `appName`, 10-locale ARB tree | DONE (em PR) |

Nenhuma dependência externa nova entra em E05. `package:provider` já está em uso.

## Open Questions — resolvidas neste plano

| # | Pergunta do brainstorm | Resolução |
|---|---|---|
| 1 | Tap-target em chips de tipo com 7 dados em telas estreitas | `Wrap` com `min 44pt hit-target`. Fallback para scroll horizontal é **não-decidido** até implementação visual; deixar como found-in-impl, não bloqueante. |
| 2 | `MacWindow` envolve `DiceWidget`? | **Não.** Borda dupla simples; sem title-bar listrada sobre o grid. |
| 3 | Semantic labels entram em E05 ou E11? | **E05.** Mas mínimo: só `+` / `−` precisam de chaves novas; os chips usam o próprio `DiceType.label`. Total novo de chaves i18n: **2**. |
| 4 | Equação textual sempre / só se `count > 1` / nunca? | **Só se `count > 1`.** Para 1 dado, o slot já é o resultado. |
| 5 | `coverage:ignore-file` em `dice_screen.dart`? | **Não.** Cobrir via `dice_screen_test.dart`. |

## Out of Scope

- Animação multi-fase com `roll`/`stop` SFX → **E12**.
- Sprites pixel-art reais (substituem o placeholder textual do `DiceWidget`) → **E12**.
- Tela de Histórico (consumir `HistoryRepository.watch`) → **E07**.
- Bottom-tab shell (a `DiceScreen` ainda é `home` direta) → **E09**.
- Trocar `InMemory*` por impls Hive-backed → **E06** (Splash).
- Settings UI que toca `AudioController.setSoundEnabled` / `HapticController.setHapticEnabled` → **E11**.

## Success Metrics

- `flutter analyze` exit 0, zero issues.
- `flutter test --coverage` passa com **100% line coverage**.
- Smoke manual em simulador iOS + Android Studio emulator: tap "ROLAR" toca SFX, vibra, mostra resultado; ler `LastDiceConfigPreference` (in-memory) entre cold-restarts simulados confirma restore.
- PR diff ≤ ~600 linhas adicionadas em produção (sem contar `app_localizations*.dart` gerados).
