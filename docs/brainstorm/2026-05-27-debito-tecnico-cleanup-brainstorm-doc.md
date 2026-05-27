---
date: 2026-05-27
topic: debito-tecnico-cleanup
---

# Débito Técnico — Cleanup Consolidado

## What We're Building

Uma PR única de refactor que paga 4 dívidas acumuladas nas reviews de PRs
anteriores (E08 e E09 settings, E07 presets). Não muda comportamento;
não toca i18n; não muda nenhum call site além de imports/construtores.

A PR roda no slot **GH-NEXT-2** do
[pipeline master](2026-05-27-m1-completion-pipeline-brainstorm-doc.md),
entre E11 (analytics) e E14 (assets).

## Why This Approach

Quatro decisões de scoping:

1. **PR única, não 4 PRs separadas.** Itens são todos
   cosméticos/movimentação; revisar 4 vezes a mesma natureza de mudança
   é overhead. Manter o pipeline em 4 PRs (não 7).
2. **Antes de E14 e E15.** Os movimentos de arquivo tocam imports em
   testes que E14/E15 não vão tocar; refatorar primeiro evita rebase
   doloroso depois.
3. **Depois de E11.** Analytics instrumenta os mesmos controllers que
   o débito 4 (`lib/app.dart`) toca. Fazer E11 primeiro evita
   conflito de merge na composição do provider tree.
4. **Comportamento congelado.** Nenhum teste deve mudar de
   expectativa; só os caminhos de import e os nomes de arquivo. Se um
   teste precisar mudar lógica para passar, é sinal de regressão e
   deve parar a PR.

## Itens da PR

### Item 1 — Mover `TypeSelector` + `QuantitySelector` para `lib/shared/widgets/`

**De:**
- `lib/features/dice/widgets/type_selector.dart`
- `lib/features/dice/widgets/quantity_selector.dart`

**Para:**
- `lib/shared/widgets/type_selector.dart`
- `lib/shared/widgets/quantity_selector.dart`

**Justificativa:** já são consumidos cross-feature por
`lib/features/presets/widgets/create_preset_sheet.dart`. Hoje o import
atravessa duas features (`presets/` importando de `dice/widgets/`),
quebrando a fronteira de feature slice.

**Consumidores que mudam de import:**
- `lib/features/dice/dice_screen.dart`
- `lib/features/presets/widgets/create_preset_sheet.dart`
- `test/features/dice/widgets/type_selector_test.dart` → move para
  `test/shared/widgets/type_selector_test.dart`
- `test/features/dice/widgets/quantity_selector_test.dart` → move para
  `test/shared/widgets/quantity_selector_test.dart`
- `test/features/presets/widgets/create_preset_sheet_test.dart`

### Item 2 — Mover `AnimationStyle` + `AnimationSpeed` para `lib/core/models/`

**De:** `lib/core/storage/models/animation_settings.dart`

**Para:** `lib/core/models/animation_settings.dart`

**Justificativa:** são enums de domínio (não entidades persistidas via
Hive). Hoje vivem em `lib/core/storage/models/` por acidente da PR
original. Pertencem ao mesmo lugar onde `DiceType` e `RollResult`
moram.

**Consumidores que mudam de import (Dart):**
- `lib/core/storage/app_settings_preference.dart`
- `lib/core/audio/sound_player.dart`
- `lib/features/settings/animation_settings_controller.dart`
- `lib/features/settings/widgets/animation_section.dart`
- `lib/features/dice/widgets/dice_animator.dart` *(arquivo novo do GH-10
  ainda em voo — coordenar timing: aplicar débito **depois** do merge
  do GH-10)*
- `test/core/storage/models/animation_settings_test.dart` → move para
  `test/core/models/animation_settings_test.dart`
- `test/features/settings/animation_settings_controller_test.dart`
- `test/features/settings/widgets/animation_section_test.dart`
- `test/features/dice/widgets/dice_animator_test.dart` *(idem GH-10)*
- `test/core/storage/app_settings_preference_test.dart`

**Não tocar:** ARBs e `app_localizations*.dart` — eles têm os labels
localizados de cada style/speed, mas o **enum** é o que está se
movendo, não os labels.

### Item 3 — Extrair `_NoopCanvas` para `test/helpers/noop_canvas.dart`

**Duplicado em 5 arquivos hoje** (confirmado por grep):
- `test/features/settings/widgets/language_picker_test.dart`
- `test/features/settings/widgets/toggle_tile_test.dart`
- `test/features/settings/widgets/palette_selector_test.dart`
- `test/features/settings/widgets/animation_section_test.dart`
- `test/shared/widgets/pixel_icon_test.dart`

**Implementação atual (cópia idêntica nos 5):**

```dart
class _NoopCanvas implements Canvas {
  @override
  void noSuchMethod(Invocation invocation) {}
}
```

**Cleanup:**

```dart
// test/helpers/noop_canvas.dart
import 'package:flutter/rendering.dart';

class NoopCanvas implements Canvas {
  @override
  void noSuchMethod(Invocation invocation) {}
}
```

Cada test passa a importar: `import '../../../helpers/noop_canvas.dart';`
e usar `NoopCanvas()` (sem underscore — agora é público).

### Item 4 — Unificar instanciação de repositórios em `main.dart`

**Hoje (inconsistente):**

- Controllers vêm de `main.dart` via construtor de `App`:
  ```dart
  // main.dart
  final audioController = AudioController(preference: appSettings);
  runApp(App(audioController: audioController, ...));

  // app.dart
  ChangeNotifierProvider<AudioController>.value(value: audioController),
  ```
- Repositórios vêm criados inline dentro do MultiProvider:
  ```dart
  // app.dart
  Provider<HistoryRepository>(create: (_) => InMemoryHistoryRepository()),
  Provider<PresetsRepository>(create: (_) => InMemoryPresetsRepository()),
  Provider<LastDiceConfigPreference>(
    create: (_) => InMemoryLastDiceConfigPreference(),
  ),
  ```

**Cleanup:** mover instanciação de repositórios para `main.dart`,
passar para `App` via construtor, providers viram `.value`. Padrão
consistente.

```dart
// main.dart (depois)
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final appSettings = SharedPreferencesAppSettingsPreference(prefs);

  final audioController = AudioController(preference: appSettings);
  await audioController.init();
  final hapticController = HapticController(preference: appSettings);
  final animationSettingsController =
      AnimationSettingsController(preference: appSettings);

  // Repositórios — InMemory por enquanto; E15 troca por Hive aqui.
  final historyRepository = InMemoryHistoryRepository();
  final presetsRepository = InMemoryPresetsRepository();
  final lastDiceConfig = InMemoryLastDiceConfigPreference();

  runApp(
    App(
      audioController: audioController,
      hapticController: hapticController,
      animationSettingsController: animationSettingsController,
      historyRepository: historyRepository,
      presetsRepository: presetsRepository,
      lastDiceConfig: lastDiceConfig,
    ),
  );
}
```

```dart
// app.dart (depois)
class App extends StatelessWidget {
  const App({
    required this.audioController,
    required this.hapticController,
    required this.animationSettingsController,
    required this.historyRepository,
    required this.presetsRepository,
    required this.lastDiceConfig,
    super.key,
  });

  // ... fields ...

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: audioController),
        ChangeNotifierProvider.value(value: hapticController),
        ChangeNotifierProvider.value(value: animationSettingsController),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleController()),
        Provider<HistoryRepository>.value(value: historyRepository),
        Provider<PresetsRepository>.value(value: presetsRepository),
        Provider<LastDiceConfigPreference>.value(value: lastDiceConfig),
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
  }
}
```

**Justificativa:**

- Consistência de padrão: tudo via construtor.
- Prepara para E15 — quando trocar `InMemory*` por `Hive*`, a
  inicialização é async (`await Hive.openBox(...)`); a única forma
  limpa é instanciar em `main.dart` antes do `runApp`. Hoje o
  `create: (_) => InMemory*()` impede isso.
- `_buildTestApp()` ganha mais 3 parâmetros (já tem precedente:
  recebe os controllers do mesmo jeito).

**`ThemeProvider` e `LocaleController` ficam inline.** Eles não têm
dependência de plataforma/async, e mover para `main.dart` aumentaria
o construtor de `App` sem benefício. Inconsistência consciente.

## Key Decisions

### D1 — Item 4 vs E15: feito agora, não diferido

A movida de repositórios para `main.dart` é estritamente preparatória
para E15 (Hive). Tentamos justificar isso como "fazer junto com E15"
mas seria misturar refactor com novo comportamento na mesma PR — o que
historicamente falhou no projeto (review fica difícil, regressões
escapam). Fazer agora isolado, deixar E15 mecânico (trocar `InMemory*`
por `Hive*` em 3 linhas de `main.dart`).

### D2 — `DiceController` continua sendo criado dentro do MultiProvider

Razão: ele precisa de `context.read` para resolver suas dependências
(`HistoryRepository`, `AudioController`, etc.). Movê-lo para
`main.dart` exigiria duplicar a resolução, ou rotear via parâmetros
posicionais — mais ruído que ganho. Mantém-se como
`ChangeNotifierProvider<DiceController>(create: (context) => ...)`.

### D3 — `_NoopCanvas` vira `NoopCanvas` (público)

Hoje tem `_` por convenção de file-private. Ao mover para helper
compartilhado precisa ser público. Renomeação trivial.

### D4 — Pasta `test/helpers/` é novidade

Não existe ainda no projeto. Criação dela é parte desta PR. Não
adicionar `.gitkeep` — `noop_canvas.dart` é arquivo suficiente para
manter a pasta versionada.

### D5 — Sem mudanças em ARBs, sem rebuild de localizations

Nenhum dos 4 itens toca strings localizadas. `tools/ralph/feedback.sh`
não precisa de regen de l10n.

### D6 — Conflito potencial com GH-10 (E12) em voo

`AnimationStyle`/`AnimationSpeed` são lidas por
`lib/features/dice/widgets/dice_animator.dart` — arquivo novo que
GH-10 está introduzindo. Ordem operacional:

1. Aguardar merge de GH-10.
2. Rebasear esta branch em main.
3. Aplicar Item 2 (já incluindo os novos imports do dice_animator).
4. Aplicar os outros 3 itens em qualquer ordem.

## Riscos e Mitigações

| Risco | Mitigação |
|---|---|
| Imports quebrados após mover arquivo | `flutter analyze` é o gate; PR não passa com import quebrado |
| Teste antes localizado em `dice/widgets/` falha ao mover para `shared/widgets/` por causa de path relativo | Imports relativos (`../../`) viram absolutos (`package:onebit_dice/...`) durante o move |
| Coverage cai em algum arquivo movido (path muda no LCOV) | `lcov` reporta por caminho final; coverage deve preservar 100% se nenhuma linha mudou |
| `_buildTestApp()` em ~10 arquivos de teste precisa de update simultâneo | Refactor mecânico; CI pega qualquer esquecimento |
| Conflito de merge com PR de E11 (que também toca `lib/app.dart`) | E11 entra **antes**; débito rebaseia em main pós-E11; chance de conflito real é zero porque E11 *adiciona* provider, débito *converte* provider sem mover o slot |

## Open Questions

- **Q1:** Onde colocar `app_settings_preference.dart`? Hoje vive em
  `lib/core/storage/` mas é consumido por `AudioController`,
  `HapticController`, `AnimationSettingsController`. Não é parte do
  débito atual, mas vale registrar para uma futura limpeza. **Não
  mover nesta PR.**
- **Q2:** A pasta `lib/features/dice/widgets/` ainda terá conteúdo
  legítimo após o move (`dice_widget.dart`, `roll_button.dart`,
  `dice_animator.dart`, `animations/`). OK manter.
- **Q3:** Renomear arquivo movido para refletir compartilhamento? Ex.
  `shared/widgets/type_selector.dart` está bom, ou
  `shared/widgets/dice_type_selector.dart` é mais claro? **Assumir
  manter nome** — historicamente menos churn em diff/blame.

## Resumo do plano subsequente (`/plan` futuro)

Quando a issue `chore: m1 cleanup` for criada (depois do merge de E11):

1. Pre-flight: confirmar GH-10 (E12) já merged em main.
2. Criar branch `chore/m1-cleanup` em main.
3. **Item 2 primeiro** (mover AnimationStyle/AnimationSpeed) —
   maior fan-out, mais visível em PR review.
4. **Item 1** (mover TypeSelector/QuantitySelector).
5. **Item 3** (extrair NoopCanvas).
6. **Item 4** (unificar repos em main.dart) — toca `lib/app.dart` e
   `lib/main.dart`; risco maior, fica por último para validar isolado.
7. Após cada item: `flutter analyze` + `flutter test --coverage`,
   commits separados na branch (depois squash no merge).
8. PR única, descrição lista os 4 itens; review se concentra em
   diffs de import + provider conversion.
