---
title: "feat: M1 MVP — implementação completa guiada por agents"
type: feat
date: 2026-05-22
---

## ✨ M1 MVP — Implementação Completa Guiada por Agents

## Overview

Este plano cobre o desenvolvimento completo do **1-Bit Dice M1 (MVP)** usando a metodologia de desenvolvimento por AI agents estilo Ralph Wiggum: um loop autônomo onde o agent lê o estado atual, escolhe a próxima tarefa, implementa, testa, commita e atualiza o tracker.

O projeto parte de um scaffold Flutter vazio (`lib/main.dart` com counter app default) e deve chegar a um app publicável em ambas as lojas.

## Metodologia — Ralph Wiggum Loop

O agent executa o mesmo prompt em loop até concluir todas as tarefas:

```
1. Ler progress.md → entender o que está feito
2. Escolher a próxima tarefa de maior prioridade (mais alta na lista com status TODO)
3. Implementar o código
4. Rodar flutter analyze + flutter test (devem passar sem erros)
5. Fazer commit com mensagem convencional
6. Atualizar progress.md (marcar tarefa como DONE)
7. Repetir
```

O agent **nunca pula testes** e **nunca commita com erros de análise**. Cada iteração produz um commit válido e incrementalmente funcional.

### Arquivos de controle

| Arquivo | Propósito |
|---|---|
| `docs/plan/2026-05-22-feat-m1-mvp-agent-driven-implementation-plan.md` | Este arquivo — visão geral e spec detalhada |
| `docs/plan/progress.md` | Tracker de tarefas — lido pelo agent a cada iteração |
| `CLAUDE.md` | Convenções do projeto + instruções do loop para o agent |

---

## Epics do M1

```
EPIC 0  — Infraestrutura & Setup do Agent Loop        ← PRIORIDADE 1
EPIC 1  — Core: Theme & Design System
EPIC 2  — Core: Dice Engine (domínio puro)
EPIC 3  — Core: Storage Layer (Hive + SharedPreferences)
EPIC 4  — Core: Audio & Haptic
EPIC 5  — Core: Analytics & Crash Reporting
EPIC 6  — Feature: Splash Screen
EPIC 7  — Feature: Navegação (AppShell + TabBar)
EPIC 8  — Feature: Home Screen / Rolagem de Dados
EPIC 9  — Feature: Histórico
EPIC 10 — Feature: Presets / Jogos
EPIC 11 — Feature: Ajustes
EPIC 12 — Feature: Internacionalização (PT-BR + EN-US)
EPIC 13 — Feature: Animações de Dados
EPIC 14 — Assets: Ícone + Native Splash
EPIC 15 — Release: Preparação para as Lojas
```

---

## EPIC 0 — Infraestrutura & Setup do Agent Loop

> **Por que vem primeiro**: sem este epic, os agents não têm contexto, convenções, dependências, nem guardrails. Cada task posterior depende disso.

### Features

#### 0.1 — `CLAUDE.md` (convenções + instruções do loop)

O `CLAUDE.md` na raiz do projeto é o "cérebro" do agent. Deve conter:

- Descrição do projeto em 2 parágrafos
- Como rodar o loop: `flutter analyze` → `flutter test` → commit → atualizar `progress.md`
- Convenções de código: nomes de arquivos, estrutura de pastas, state management (`setState` + `ChangeNotifier`)
- Vocabulário proibido na UI (ver `docs/roadmap/02-identidade-visual.md`)
- Regras de paleta: EXATAMENTE 2 cores, zero tons intermediários
- Convenção de commits: Conventional Commits (`feat:`, `fix:`, `chore:`, `test:`)
- Referência ao `docs/roadmap/` para spec detalhada

**Arquivo**: `CLAUDE.md`

#### 0.2 — `pubspec.yaml` completo

Adicionar todas as dependências do M1:

```yaml
dependencies:
  # Persistência
  shared_preferences: ^2.3.0
  hive: ^2.2.3
  hive_flutter: ^1.1.0

  # Firebase
  firebase_core: ^3.0.0
  firebase_crashlytics: ^4.0.0
  firebase_analytics: ^11.0.0

  # UI / assets
  flutter_native_splash: ^2.4.0
  flutter_launcher_icons: ^0.14.0
  just_audio: ^0.9.40
  google_fonts: ^6.2.0

dev_dependencies:
  build_runner: ^2.4.0
  hive_generator: ^2.0.1
  flutter_gen_runner: ^5.0.0   # opcional — gerador de asset references
```

**Arquivo**: `pubspec.yaml`

#### 0.3 — Estrutura de pastas

Criar a hierarquia de pastas descrita em `docs/roadmap/03-stack-tecnico.md`:

```
lib/
├── main.dart              ← reescrever (Firebase init + runApp)
├── app.dart               ← MaterialApp + ThemeProvider
├── core/
│   ├── theme/
│   ├── storage/
│   │   └── models/
│   ├── audio/
│   ├── haptic/
│   └── analytics/
├── features/
│   ├── dice/
│   │   └── widgets/
│   ├── history/
│   │   └── widgets/
│   ├── presets/
│   │   └── widgets/
│   ├── settings/
│   │   └── widgets/
│   └── splash/
└── shared/
    ├── widgets/
    └── utils/
```

Criar um `barrel.dart` (ou `index.dart`) em cada pasta de feature para facilitar imports.

**Tarefa**: criar arquivos placeholder `.dart` com comentário `// TODO: implement` em cada leaf.

#### 0.4 — `analysis_options.yaml` reforçado

```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    - always_declare_return_types
    - avoid_print
    - prefer_const_constructors
    - prefer_const_declarations
    - prefer_final_fields
    - require_trailing_commas
    - sort_constructors_first
    - unawaited_futures
```

**Arquivo**: `analysis_options.yaml`

#### 0.5 — GitHub Actions CI

```yaml
# .github/workflows/ci.yml
name: CI
on: [push, pull_request]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: 'stable'
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test
```

**Arquivo**: `.github/workflows/ci.yml`

#### 0.6 — `docs/plan/progress.md` inicializado

O arquivo de tracking com todas as tarefas listadas como `TODO`. Formato:

```markdown
# Progress

## EPIC 0 — Infraestrutura
- [x] 0.1 CLAUDE.md
- [x] 0.2 pubspec.yaml
- [ ] 0.3 Estrutura de pastas
...

## EPIC 1 — Theme
- [ ] 1.1 Palette model
...
```

**Arquivo**: `docs/plan/progress.md`

#### 0.7 — Firebase setup

- Criar projeto Firebase `onebit-dice` no console
- Rodar `flutterfire configure --project=onebit-dice`
- Gera `google-services.json` (Android) e `GoogleService-Info.plist` (iOS)
- Atualizar `android/app/build.gradle` com plugin classpath
- Atualizar `ios/Runner/Info.plist` se necessário

> ⚠️ Esta task requer acesso manual ao Firebase Console — o agent deve sinalizar no `progress.md` quando precisar de intervenção humana.

---

## EPIC 1 — Core: Theme & Design System

### Spec técnica

**Regra de ouro**: cada paleta usa exatamente 2 cores — `ink` (foreground) e `paper` (background). Zero tons intermediários.

#### 1.1 — `lib/core/theme/palette.dart`

```dart
enum PaletteId { macClassic, macBeige, gameBoy, commodore64, zxSpectrum, appleIIGreen, appleIIAmber }

class Palette {
  final PaletteId id;
  final String name;
  final Color ink;    // foreground / texto
  final Color paper;  // background

  // Paletas definidas como constantes estáticas
  static const macClassic = Palette(id: PaletteId.macClassic, name: 'Mac Classic', ink: Color(0xFF000000), paper: Color(0xFFFFFFFF));
  // ... (6 mais)
}
```

#### 1.2 — `lib/core/theme/theme_provider.dart`

```dart
class ThemeProvider extends ChangeNotifier {
  Palette _current = Palette.macClassic;
  Palette get current => _current;

  void setPalette(Palette p) {
    _current = p;
    notifyListeners();
  }
}
```

- Wire no `app.dart` via `ChangeNotifierProvider`
- Persistir seleção via `AppPrefs` (EPIC 3)

#### 1.3 — `lib/core/theme/app_typography.dart`

```dart
class AppTypography {
  static TextStyle wordmark(Color color) => TextStyle(fontFamily: 'Silkscreen', fontSize: 32, color: color, fontFeatures: [FontFeature.disable('liga')]);
  static TextStyle display(Color color) => TextStyle(fontFamily: 'Silkscreen', fontSize: 24, color: color);
  static TextStyle body(Color color) => TextStyle(fontFamily: 'VT323', fontSize: 18, color: color);
  static TextStyle micro(Color color) => TextStyle(fontFamily: 'PressStart2P', fontSize: 10, color: color);
}
```

#### 1.4 — `lib/shared/widgets/mac_button.dart`

- Borda pixel dupla 2px (cor `ink`)
- Sombra offset 2-3px sólida `ink`
- Estado pressionado: sombra desaparece + translation interna 2px
- `GestureDetector` com `onTapDown`/`onTapUp`/`onTapCancel`

#### 1.5 — `lib/shared/widgets/mac_window.dart`

- Title bar com listras horizontais finas (3-4 linhas de 1px com espaço de 1px)
- Borda dupla pixel ao redor
- `title` String obrigatório, `child` Widget

#### 1.6 — `lib/shared/widgets/pixel_divider.dart`

- `Container` com height 2px, cor `ink` da paleta atual

#### 1.7 — Fontes no pubspec

```yaml
flutter:
  fonts:
    - family: Silkscreen
      fonts:
        - asset: assets/fonts/Silkscreen-Regular.ttf
        - asset: assets/fonts/Silkscreen-Bold.ttf
          weight: 700
    - family: VT323
      fonts:
        - asset: assets/fonts/VT323-Regular.ttf
    - family: PressStart2P
      fonts:
        - asset: assets/fonts/PressStart2P-Regular.ttf
```

> Os arquivos `.ttf` devem ser baixados do Google Fonts e colocados em `assets/fonts/`.

---

## EPIC 2 — Core: Dice Engine

### Spec técnica

Camada de domínio puro — **zero dependências Flutter**, apenas Dart. Testável sem emulador.

#### 2.1 — `lib/shared/utils/random_dice.dart`

```dart
import 'dart:math';

final _rng = Random.secure();

int rollDie(int sides) => _rng.nextInt(sides) + 1;
List<int> rollDice(int sides, int count) => List.generate(count, (_) => rollDie(sides));
```

#### 2.2 — `lib/core/models/dice_type.dart`

```dart
enum DiceType {
  d4(4), d6(6), d8(8), d10(10), d12(12), d20(20), d100(100);

  const DiceType(this.sides);
  final int sides;

  String get label => 'd$sides';
}
```

#### 2.3 — `lib/core/models/roll_result.dart`

```dart
class RollResult {
  final DateTime timestamp;
  final DiceType diceType;
  final int diceCount;
  final List<int> values;

  int get total => values.fold(0, (a, b) => a + b);
  String get equation => values.length == 1 ? '${values.first}' : '${values.join(' + ')} = $total';
}
```

#### 2.4 — Testes unitários

**Arquivo**: `test/core/models/dice_type_test.dart`
**Arquivo**: `test/shared/utils/random_dice_test.dart`

- Verificar que `rollDie(6)` retorna sempre 1–6
- Rodar 10.000 iterações e verificar distribuição razoavelmente uniforme (nenhum valor com >30% dos resultados)
- Verificar `RollResult.total` e `RollResult.equation`

---

## EPIC 3 — Core: Storage Layer

### Spec técnica

#### 3.1 — `lib/core/storage/app_prefs.dart`

```dart
class AppPrefs {
  static const _kPalette = 'palette';
  static const _kSound = 'sound';
  // ...

  static Future<void> setPalette(PaletteId id) async { ... }
  static Future<PaletteId> getPalette() async { ... }
  static Future<void> setSoundEnabled(bool v) async { ... }
  static Future<bool> getSoundEnabled() async { ... }
  // haptic, animStyle, animSpeed, lastDiceType, lastDiceCount
}
```

#### 3.2 — `lib/core/storage/models/roll_entry.dart`

```dart
@HiveType(typeId: 0)
class RollEntry extends HiveObject {
  @HiveField(0) late DateTime timestamp;
  @HiveField(1) late int diceTypeSides;  // int para evitar adapter de enum
  @HiveField(2) late int diceCount;
  @HiveField(3) late List<int> values;

  int get total => values.fold(0, (a, b) => a + b);
}
```

#### 3.3 — `lib/core/storage/models/custom_preset.dart`

```dart
@HiveType(typeId: 1)
class CustomPreset extends HiveObject {
  @HiveField(0) late String name;
  @HiveField(1) late int diceTypeSides;
  @HiveField(2) late int diceCount;
}
```

#### 3.4 — `lib/core/storage/hive_init.dart`

```dart
class HiveInit {
  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(RollEntryAdapter());
    Hive.registerAdapter(CustomPresetAdapter());
    await Hive.openBox<RollEntry>('history');
    await Hive.openBox<CustomPreset>('presets');
  }
}
```

#### 3.5 — Rodar build_runner

```bash
dart run build_runner build --delete-conflicting-outputs
```

Gera `roll_entry.g.dart` e `custom_preset.g.dart`.

#### 3.6 — Testes

**Arquivo**: `test/core/storage/app_prefs_test.dart` — mockar SharedPreferences
**Arquivo**: `test/core/storage/models/roll_entry_test.dart` — testar `total`

---

## EPIC 4 — Core: Audio & Haptic

#### 4.1 — `lib/core/audio/sound_player.dart`

```dart
class SoundPlayer {
  bool _enabled = true;

  Future<void> playRoll() async { if (_enabled) ... }
  Future<void> playStop() async { if (_enabled) ... }
  Future<void> playTotal() async { if (_enabled) ... }
  void setEnabled(bool v) => _enabled = v;
}
```

- Usar `just_audio` com `AudioPlayer`
- Assets: `assets/sounds/roll.mp3`, `stop.mp3`, `total.mp3`
- Sons curtos (<500ms cada)

#### 4.2 — `lib/core/haptic/haptic_controller.dart`

```dart
class HapticController {
  bool _enabled = true;

  void onRoll() { if (_enabled) HapticFeedback.mediumImpact(); }
  void setEnabled(bool v) => _enabled = v;
}
```

#### 4.3 — Assets de som

> ⚠️ Intervenção humana: criar/obter os 3 arquivos `.mp3` e colocar em `assets/sounds/`.
> O agent deve criar placeholders (arquivos de 1 byte) para não quebrar o build enquanto os assets reais não chegam.

---

## EPIC 5 — Core: Analytics & Crash Reporting

#### 5.1 — `lib/core/analytics/analytics_service.dart`

```dart
class AnalyticsService {
  final FirebaseAnalytics _analytics;

  Future<void> logRollDice({required DiceType type, required int count}) =>
      _analytics.logEvent(name: 'roll_dice', parameters: {'dice_type': type.label, 'dice_count': count});

  Future<void> logChangePalette(String paletteName) =>
      _analytics.logEvent(name: 'change_palette', parameters: {'palette_name': paletteName});

  // logOpenPreset, logSaveCustomPreset, logClearHistory,
  // logChangeAnimation, logToggleSound, logToggleHaptic
}
```

#### 5.2 — Crashlytics em `main.dart`

```dart
FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
PlatformDispatcher.instance.onError = (error, stack) {
  FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  return true;
};
```

---

## EPIC 6 — Feature: Splash Screen

#### 6.1 — `lib/features/splash/splash_screen.dart`

```
┌─────────────────────────┐
│                         │
│   ████  ██████  ████   │  ← Wordmark "1-BIT DICE" (Silkscreen 32px)
│                         │
│   dados pra todo jogo   │  ← Tagline (VT323 18px)
│                         │
│                         │
│                         │
│  ──────────────────────  │
│  made with ♥ for call   │  ← microtexto (Press Start 2P 8px)
│  of old chico universe  │
└─────────────────────────┘
```

- `initState`: `Future.delayed(1500ms)` → navega para `AppShell`
- Durante inicialização: `HiveInit.init()` + carregar prefs → `ThemeProvider`

#### 6.2 — Native splash

**Arquivo**: `flutter_native_splash.yaml`

```yaml
flutter_native_splash:
  color: "#FFFFFF"
  image: assets/icon/icon.png
  android: true
  ios: true
```

---

## EPIC 7 — Feature: Navegação

#### 7.1 — `lib/app.dart`

```dart
class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (_, theme, __) => MaterialApp(
          theme: ThemeData(scaffoldBackgroundColor: theme.current.paper),
          home: const SplashScreen(),
          // sem router — navegação simples por push/pop
        ),
      ),
    );
  }
}
```

#### 7.2 — `lib/features/shell/app_shell.dart`

```dart
class AppShell extends StatefulWidget { ... }

class _AppShellState extends State<AppShell> {
  int _tab = 0;

  static const _screens = [DiceScreen(), HistoryScreen(), PresetsScreen(), SettingsScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _tab, children: _screens),
      bottomNavigationBar: RetroTabBar(current: _tab, onTap: (i) => setState(() => _tab = i)),
    );
  }
}
```

#### 7.3 — `lib/shared/widgets/retro_tab_bar.dart`

```
┌─────┬─────┬─────┬─────┐  ← divisor 2px preto no topo
│ 🎲  │ 📜  │ ⭐  │ ⚙️  │
│ROLAR│HIST.│JOGOS│AJUST│
└─────┴─────┴─────┴─────┘
```

- Ícone pixel art 24x24 (`Image.asset` com `FilterQuality.none`)
- Label `VT323 12px` em caixa alta
- Tab ativo: cores invertidas (ink ↔ paper)

---

## EPIC 8 — Feature: Home Screen / Rolagem

### Mockup da tela

```
┌─────────────────────────┐
│ ┌─────────────────────┐ │
│ │■ TIPO DE DADO       │ │  ← MacWindow
│ │  d4  d6  d8  d10   │ │
│ │ d12 d20 d100        │ │
│ └─────────────────────┘ │
│                         │
│ ┌─────────────────────┐ │
│ │■ QUANTIDADE         │ │
│ │     [−]  3  [+]     │ │
│ └─────────────────────┘ │
│                         │
│   ┌──────────────────┐  │
│   │  [dado animado]  │  │  ← sprite animado
│   └──────────────────┘  │
│                         │
│   4   +   6   +   2     │  ← resultados individuais
│        = 12             │  ← soma grande
│                         │
│  ┌────────────────────┐ │
│  │      ROLAR         │ │  ← MacButton grande
│  └────────────────────┘ │
└─────────────────────────┘
```

#### 8.1 — `lib/features/dice/dice_controller.dart`

```dart
class DiceController extends ChangeNotifier {
  DiceType selectedType = DiceType.d6;
  int selectedCount = 1;
  RollResult? lastResult;
  bool isRolling = false;

  void setType(DiceType t) { selectedType = t; notifyListeners(); }
  void setCount(int n) { selectedCount = n.clamp(1, 10); notifyListeners(); }

  Future<void> roll() async {
    isRolling = true;
    notifyListeners();
    // await animation duration
    lastResult = RollResult(
      timestamp: DateTime.now(),
      diceType: selectedType,
      diceCount: selectedCount,
      values: rollDice(selectedType.sides, selectedCount),
    );
    isRolling = false;
    notifyListeners();
    // salvar no Hive, analytics, haptic, sound
  }
}
```

#### 8.2 — Widgets

- **`TypeSelector`**: row horizontal de chips `MacButton` para cada `DiceType`; selecionado usa cores invertidas
- **`QuantitySelector`**: `[−]` `[count]` `[+]` em MacButtons; count clampado 1–10
- **`DiceWidget`**: `AnimatedSwitcher` + sprite sheet (frames do dado); placeholder: número grande na fonte Silkscreen até ter o sprite real
- **`RollButton`**: `MacButton` full-width com label "ROLAR"

#### 8.3 — Testes

**Arquivo**: `test/features/dice/dice_controller_test.dart`
**Arquivo**: `test/features/dice/widgets/type_selector_test.dart`
**Arquivo**: `test/features/dice/widgets/quantity_selector_test.dart`

---

## EPIC 9 — Feature: Histórico

#### 9.1 — `lib/features/history/history_screen.dart`

```dart
ValueListenableBuilder<Box<RollEntry>>(
  valueListenable: Hive.box<RollEntry>('history').listenable(),
  builder: (_, box, __) {
    final entries = box.values.toList().reversed.toList();
    return ListView.builder(...);
  },
)
```

#### 9.2 — `lib/features/history/widgets/history_entry.dart`

```
┌─────────────────────────────┐
│ 22/05/2026  14:32  3d6      │  ← data/hora + configuração
│ 4  +  6  +  2 = 12          │  ← resultados
└─────────────────────────────┘
```

#### 9.3 — Botão "LIMPAR HISTÓRICO"

```dart
showDialog(
  context: context,
  builder: (_) => AlertDialog(
    title: Text('LIMPAR HISTÓRICO'),
    content: Text('Apagar todas as rolagens?'),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: Text('CANCELAR')),
      TextButton(
        onPressed: () {
          Hive.box<RollEntry>('history').clear();
          analyticsService.logClearHistory();
          Navigator.pop(context);
        },
        child: Text('LIMPAR'),
      ),
    ],
  ),
);
```

---

## EPIC 10 — Feature: Presets / Jogos

#### 10.1 — `lib/features/presets/preset_data.dart`

```dart
class Preset {
  final String name;
  final DiceType type;
  final int count;
}

class PresetData {
  static const builtIn = [
    Preset(name: 'Ludo',            type: DiceType.d6,  count: 1),
    Preset(name: 'Banco Imobiliário', type: DiceType.d6, count: 2),
    Preset(name: 'War Ataque',      type: DiceType.d6,  count: 3),
    Preset(name: 'War Defesa',      type: DiceType.d6,  count: 3),
    Preset(name: 'Yahtzee',         type: DiceType.d6,  count: 5),
    Preset(name: 'Catan',           type: DiceType.d6,  count: 2),
    Preset(name: 'D&D',             type: DiceType.d20, count: 1),
  ];
}
```

#### 10.2 — `lib/features/presets/presets_screen.dart`

- Seção "JOGOS CLÁSSICOS": grid de `PresetCard` com os builtIn
- Seção "MEUS PRESETS": grid dos `CustomPreset` do Hive + botão "+ NOVO"
- Toque em preset → aplica no `DiceController` → navega para aba ROLAR
- "+ NOVO": bottom sheet com nome + TypeSelector + QuantitySelector + botão "SALVAR"

---

## EPIC 11 — Feature: Ajustes

#### 11.1 — Layout

```
┌─────────────────────────────┐
│ ■ PALETAS                   │
│  ○ Mac Classic  ○ Mac Beige │
│  ○ Game Boy     ○ C64       │
│  ○ ZX Spectrum  ○ Apple II  │
│  ○ Apple //e                │
│─────────────────────────────│
│ ■ SOM                       │
│  [X] Som ligado             │
│─────────────────────────────│
│ ■ VIBRAÇÃO                  │
│  [X] Vibrar ao rolar        │
│─────────────────────────────│
│ ■ ANIMAÇÃO                  │
│  Estilo: Rápida / Tambor /  │
│          Tabuleiro          │
│  Velocidade: Rápido / Médio │
│             / Longo         │
└─────────────────────────────┘
```

#### 11.2 — `ToggleTile`

```dart
class ToggleTile extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  // caixa quadrada 24x24 com borda pixel
  // estado on: "X" dentro (Silkscreen)
  // estado off: vazio
}
```

#### 11.3 — `PaletteSelector`

- Grid de 2 colunas com `PaletteSwatch` para cada paleta
- Toque → `ThemeProvider.setPalette()` → reativa toda a UI + analytics

---

## EPIC 12 — Feature: Internacionalização

#### 12.1 — Setup

```yaml
# l10n.yaml
arb-dir: lib/l10n
template-arb-file: app_pt.arb
output-localization-file: app_localizations.dart
```

```yaml
# pubspec.yaml (adicionar)
dependencies:
  flutter_localizations:
    sdk: flutter
  intl: ^0.19.0
```

#### 12.2 — `lib/l10n/app_pt.arb` (PT-BR — base)

```json
{
  "@@locale": "pt",
  "tabRoll": "ROLAR",
  "tabHistory": "HISTÓRICO",
  "tabGames": "JOGOS",
  "tabSettings": "AJUSTES",
  "rollButton": "ROLAR",
  "clearHistory": "LIMPAR HISTÓRICO",
  "clearHistoryConfirm": "Apagar todas as rolagens?",
  "cancel": "CANCELAR",
  "clear": "LIMPAR",
  "diceType": "TIPO DE DADO",
  "diceCount": "QUANTIDADE",
  "palettes": "PALETAS",
  "sound": "SOM",
  "haptic": "VIBRAÇÃO",
  "animation": "ANIMAÇÃO",
  "tagline": "Dados pra todo jogo"
}
```

#### 12.3 — `lib/l10n/app_en.arb` (EN-US)

Mesmas chaves em inglês.

#### 12.4 — Uso

```dart
// BuildContext extension gerado automaticamente
context.l10n.rollButton  // → "ROLAR" ou "ROLL"
```

---

## EPIC 13 — Feature: Animações de Dados

### Spec técnica

#### 13.1 — Modelos

```dart
enum AnimationStyle { rapida, tambor, tabuleiro }
enum AnimationSpeed { rapido, medio, longo }

extension AnimationSpeedDuration on AnimationSpeed {
  Duration get duration => switch(this) {
    AnimationSpeed.rapido => const Duration(milliseconds: 400),
    AnimationSpeed.medio  => const Duration(milliseconds: 800),
    AnimationSpeed.longo  => const Duration(milliseconds: 1500),
  };
}
```

#### 13.2 — Rápida

`AnimatedSwitcher` com `FadeTransition` de 200ms. Mostra placeholder → resultado final.

#### 13.3 — Tambor

`AnimationController` ciclando através de 8 frames do sprite sheet. Frames "embaralhados" com números aleatórios. Para no resultado correto no último frame.

```dart
// Sprite sheet: imagem horizontal 8 frames de 32x32px cada
// Usar Rect para clipar o frame correto
final frameRect = Rect.fromLTWH(frame * 32.0, 0, 32.0, 32.0);
```

#### 13.4 — Tabuleiro

Multi-fase:
1. Dado entra voando de cima (400ms) — `SlideTransition`
2. Bounce (200ms) — `ScaleTransition` 1.0 → 1.2 → 1.0
3. Frame cycling rápido decrementando (600ms)
4. Para no resultado

#### 13.5 — Notas sobre sprites

> ⚠️ Intervenção humana: os sprite sheets de animação devem ser criados no Blender em 1-bit dithered e colocados em `assets/sprites/`.
> Enquanto não existem, usar um `AnimatedBuilder` com um `Text` mostrando um número aleatório a cada frame — visualmente aproximado.

---

## EPIC 14 — Assets: Ícone + Native Splash

#### 14.1 — Ícone do app

Spec: d6 pixel art vista frontal, face com 6 pontos em grid 2x3, borda pixel dupla.
- Resolução base: 32x32 escalado para 1024x1024
- Background: branco (`#FFFFFF` paleta Mac Classic)

> ⚠️ Intervenção humana: criar o arquivo `assets/icon/icon.png` (1024x1024 PNG).

#### 14.2 — `flutter_launcher_icons.yaml`

```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icon/icon.png"
  min_sdk_android: 21
  web:
    generate: false
```

Rodar: `dart run flutter_launcher_icons`

#### 14.3 — Native splash

```yaml
flutter_native_splash:
  color: "#FFFFFF"
  image: assets/icon/icon.png
  android_12:
    color: "#FFFFFF"
    image: assets/icon/icon.png
```

Rodar: `dart run flutter_native_splash:create`

---

## EPIC 15 — Release Preparation

### Android

#### 15.1 — Keystore

```bash
keytool -genkey -v -keystore android/app/keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias onebitdice
```

> ⚠️ Fazer backup do keystore em 3 lugares. Perder = não conseguir atualizar o app nunca mais.

**Arquivo**: `android/key.properties` (NÃO commitar — adicionar ao `.gitignore`)

```properties
storePassword=<senha>
keyPassword=<senha>
keyAlias=onebitdice
storeFile=../app/keystore.jks
```

Atualizar `android/app/build.gradle` com signing config.

#### 15.2 — Atualizar `AndroidManifest.xml`

```xml
<manifest package="com.am2.onebitdice">
<application android:label="1-Bit Dice">
<!-- Sem permissões além do básico — app totalmente offline -->
```

#### 15.3 — Build Android

```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### iOS

#### 15.4 — `ios/Runner/Info.plist`

```xml
<key>CFBundleIdentifier</key> <string>com.am2.onebitdice</string>
<key>CFBundleDisplayName</key> <string>1-Bit Dice</string>
<key>MinimumOSVersion</key> <string>13.0</string>
```

#### 15.5 — Build iOS

```bash
flutter build ipa --release
# Upload via Transporter.app
```

### Assets das lojas

#### 15.6 — Screenshots

| Plataforma | Resolução | Quantidade |
|---|---|---|
| iPhone 6.7" | 1290×2796 | 3–10 |
| Android phone | 1080×1920 | 2–8 |
| Feature graphic (Play) | 1024×500 | 1 |

> ⚠️ Intervenção humana: capturar screenshots com o app funcional em simulador/device.

#### 15.7 — Política de privacidade

Deploy em GitHub Pages (`docs/` branch ou repositório separado):

```markdown
# Privacy Policy — 1-Bit Dice

1-Bit Dice does not collect any personal data.
Analytics data is anonymous and aggregated.
Crash reports contain no personally identifiable information.
```

URL: `https://am2-studio.github.io/onebit-dice/privacy`

#### 15.8 — Reserva de nomes nas lojas

> ⚠️ Intervenção humana:
> - Play Console: criar app record `com.am2.onebitdice` "1-Bit Dice"
> - App Store Connect: criar app record com Bundle ID `com.am2.onebitdice`

---

## Acceptance Criteria

### Functional Requirements

- [ ] App abre em iOS 13+ e Android 5.0+ sem crash
- [ ] Rolar dados: 1–10 dados de qualquer tipo (d4 a d100)
- [ ] Resultado exibe valores individuais + soma com equação
- [ ] Histórico salva todas as rolagens (persiste entre sessões)
- [ ] Histórico pode ser limpo com confirmação
- [ ] 7 presets clássicos funcionam e aplicam configuração na tela ROLAR
- [ ] Até 10 presets customizados podem ser criados/editados/deletados
- [ ] 7 paletas trocam em tempo real e persistem entre sessões
- [ ] Som e haptic têm toggles independentes que persistem
- [ ] 3 estilos de animação funcionam
- [ ] 3 velocidades de animação funcionam
- [ ] UI em PT-BR e EN-US (baseado no locale do device)

### Non-Functional Requirements

- [ ] `flutter analyze` retorna 0 issues
- [ ] `flutter test` passa 100% dos testes
- [ ] 60fps em animações (verificar com Flutter DevTools)
- [ ] Renderização pixel-perfect: todas imagens com `FilterQuality.none`
- [ ] Fontes sem antialiasing: `FontFeature.disable('liga')`
- [ ] Aleatoriedade via `Random.secure()` (nunca `Random()`)
- [ ] App totalmente offline — zero requests de rede no fluxo principal
- [ ] Sem coleta de dados pessoais (declaração nas lojas)

### Quality Gates por Epic

- [ ] EPIC 0: `flutter pub get` sem erros + CI verde
- [ ] EPIC 1: `flutter run` mostra design system básico com paleta Mac Classic
- [ ] EPIC 2: testes de distribuição aleatória passam
- [ ] EPIC 3: dados persistem após hot restart
- [ ] EPIC 8: botão ROLAR produz resultado correto em todos os tipos de dado
- [ ] EPIC 14: ícone aparece corretamente no launcher iOS e Android
- [ ] EPIC 15: build de release produz AAB e IPA sem erros

---

## Dependências e Ordem de Implementação

```
EPIC 0 (infra)
    ↓
EPIC 1 (theme) ←── EPIC 3 (storage) para persistir paleta
    ↓
EPIC 2 (dice engine)
    ↓
EPIC 3 (storage)
    ↓
EPIC 4 (audio)  EPIC 5 (analytics)     ← paralelo
    ↓                 ↓
EPIC 6 (splash)
    ↓
EPIC 7 (navegação)
    ↓
EPIC 8 (home)  EPIC 9 (histórico)  EPIC 10 (presets)  EPIC 11 (settings)  ← paralelo
    ↓
EPIC 12 (i18n) ← substitui strings em todos os features
    ↓
EPIC 13 (animações)
    ↓
EPIC 14 (icon/splash)
    ↓
EPIC 15 (release)
```

### Intervenções humanas necessárias (agent deve pausar e sinalizar)

| Tarefa | Epic | Por quê |
|---|---|---|
| Firebase Console setup | EPIC 0.7 | Requer conta + UI web |
| Criar arquivos `.mp3` de som | EPIC 4.3 | Assets de áudio |
| Criar sprite sheets `.png` | EPIC 13.5 | Assets visuais (Blender) |
| Criar `icon.png` 1024×1024 | EPIC 14.1 | Asset visual |
| Keystore Android (backup!) | EPIC 15.1 | Decisão de segurança |
| Capturar screenshots | EPIC 15.6 | Requer device físico |
| Criar app records nas lojas | EPIC 15.8 | Requer contas de developer |

O agent deve registrar no `progress.md` com tag `[BLOCKED: human]` ao encontrar essas tarefas.

---

## Risk Analysis

| Risco | Probabilidade | Impacto | Mitigação |
|---|---|---|---|
| Sprite sheets não prontos bloqueiam EPIC 13 | Alta | Médio | Usar placeholder de texto até assets chegarem |
| Firebase configuração incorreta no iOS | Média | Alto | Testar `firebase_core` no início do EPIC 5 |
| Apple rejeitar por "Minimum Functionality" | Média | Alto | Garantir descrição detalhada na loja + histórico como diferencial |
| Perda do keystore Android | Baixa | Crítico | Backup em 3 lugares antes de primeiro build |
| `just_audio` bugs em iOS | Baixa | Médio | Testar em device iOS real antes do EPIC 15 |

---

## Future Considerations (pós-M1)

- **M2**: Dados customizados via IA (Gemini Imagen 3) + IAP de créditos + shake-to-roll
- **M3**: Física 3D (Forge2D) + modo mesa de jogo + sync Firestore opcional
- **M5+**: Multiplayer local, widgets, Apple Watch

A arquitetura M1 foi desenhada para suportar M2 sem refatoração: `DiceType` pode ter um caso `custom` com asset dinâmico, e `DiceController` pode ser estendido.

---

## References

### Internal
- Visão geral: [docs/roadmap/00-visao-geral.md](../roadmap/00-visao-geral.md)
- Escopo M1: [docs/roadmap/01-escopo-m1.md](../roadmap/01-escopo-m1.md)
- Identidade visual: [docs/roadmap/02-identidade-visual.md](../roadmap/02-identidade-visual.md)
- Stack técnico: [docs/roadmap/03-stack-tecnico.md](../roadmap/03-stack-tecnico.md)
- Publicação lojas: [docs/roadmap/07-publicacao-lojas.md](../roadmap/07-publicacao-lojas.md)

### External
- [Ralph Wiggum — AI Coding Loop](https://www.aihero.dev/tips-for-ai-coding-with-ralph-wiggum)
- [Flutter docs](https://docs.flutter.dev)
- [Hive Flutter docs](https://docs.hivedb.dev)
- [FlutterFire docs](https://firebase.flutter.dev)
- [Conventional Commits](https://www.conventionalcommits.org)
