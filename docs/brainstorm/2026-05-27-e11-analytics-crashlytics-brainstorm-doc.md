---
date: 2026-05-27
topic: e11-analytics-crashlytics
---

# E11 — Analytics & Crash Reporting

## What We're Building

Camada de telemetria do 1-Bit Dice: instrumentação dos 9 eventos
especificados em [docs/roadmap/03-stack-tecnico.md](../roadmap/03-stack-tecnico.md)
via `firebase_analytics` + captura de crashes via `firebase_crashlytics`.

Eventos anônimos (sem PII), sempre ligados, instrumentação inline nos
controllers existentes. Não introduz UI nova nem toggle de privacidade.

**Pré-requisito (humano):** `0.6` Firebase setup
(`flutterfire configure` + `firebase_options.dart` commitado + projeto
criado no Firebase Console com Analytics + Crashlytics habilitados).

## Why This Approach

Cinco decisões de design tomadas nesta sessão:

1. **Instrumentação inline em controllers/repos**, não via observer. Cada
   call site é explícito, grepável e testável. Acompanha o padrão já
   estabelecido por `AudioController`/`HapticController`.
2. **Sempre on, sem toggle de Settings.** Eventos são anônimos por
   design (sem PII, sem advertising_id manual, ATT respeitada nativamente
   no iOS). Política de privacidade publicada no E15 cobre transparência.
   Menos UI, menos i18n, menos teste — YAGNI para um dice roller offline.
3. **Sem No-Op em produção, sem Fake em testes.** A única impl em
   `lib/` é a Firebase. Testes mockam via `mocktail`:
   `class _MockAnalyticsService extends Mock implements AnalyticsService {}`
   declarado inline em cada test (ou consolidado em `test/helpers/`
   apenas se houver reuso). Padrão já estabelecido em outros testes do
   projeto.
   **Exceção de plataforma:** Crashlytics só é inicializado e tem hooks
   conectados quando `defaultTargetPlatform == android || iOS`. Em
   outras plataformas (web, desktop), o bootstrap pula a parte de
   crash reporter inteira — não há fallback, simplesmente não há
   captura. Analytics roda em todas as plataformas suportadas pelo
   `firebase_analytics` (Android/iOS/Web/macOS).
4. **Bridge Firebase excluído do gate de 100% coverage**, junto com
   `main.dart`/`*.g.dart`/`app_localizations*.dart`. Divergência
   consciente do padrão `SoLoudGateway` (que mockou para 100%):
   o bridge Firebase é thin pass-through verificado por console; o custo
   de mockar `FirebaseAnalytics`/`FirebaseCrashlytics` (singletons
   estáticos sem injeção) não compensa.
5. **Crash capture amplo:** `FlutterError.onError` +
   `PlatformDispatcher.instance.onError` + `runZonedGuarded` em
   `main.dart`. Padrão oficial do Firebase, custo marginal.

## Eventos a instrumentar

| # | Evento | Call site | Params |
|---|---|---|---|
| 1 | `app_open` | `main.dart` após `Firebase.initializeApp` (ou primeiro frame do app shell) | — |
| 2 | `roll_dice` | `DiceController.roll()` ao final do método | `dice_type` (d4..d100), `dice_count` (1..10) |
| 3 | `change_palette` | `ThemeProvider.setPalette()` | `palette_name` (id da paleta) |
| 4 | `open_preset` | `DiceController.applyConfig()` quando origem = preset (ou no tap handler do `PresetCard`) | `preset_name` |
| 5 | `save_custom_preset` | `PresetsRepository.add()` (impl InMemory + Hive) | — |
| 6 | `clear_history` | `HistoryRepository.clear()` (impl InMemory + Hive) | — |
| 7 | `change_animation` | `AnimationSettingsController.setStyle()` **e** `setSpeed()` | `style` ou `speed` |
| 8 | `toggle_sound` | `AudioController.toggle()` | `enabled` (bool) |
| 9 | `toggle_haptic` | `HapticController.toggle()` | `enabled` (bool) |

**Decisões de borda:**

- `open_preset` dispara no tap do `PresetCard` (não em `applyConfig`)
  para evitar disparar ao restaurar `LastDiceConfig` no boot.
- `change_animation` dispara em **ambos** setters de
  `AnimationSettingsController` (style + speed são eventos
  independentes). Param identifica qual mudou.
- `roll_dice` dispara mesmo quando vem de `applyConfig` (rolagem é
  rolagem). Os parâmetros separam preset roll de manual roll.

## Arquitetura

```
lib/core/analytics/
├── analytics_service.dart           — interface + 9 métodos log*
└── firebase_analytics_service.dart  — única impl prod (excluído do coverage)

lib/main.dart                        — runZonedGuarded + Firebase.initializeApp +
                                       FlutterError.onError + PlatformDispatcher.instance.onError
                                       (Crashlytics chamado direto, dentro de gate
                                       `Platform.isAndroid || isIOS`)
                                       (excluído do coverage — já está)

test/**                              — mocks declarados inline via mocktail
                                       (class _MockAnalyticsService extends Mock
                                        implements AnalyticsService {})
```

**Sem interface para crashlytics.** `FirebaseCrashlytics.instance` é
chamado direto em `main.dart` (que já está fora do coverage gate).
Adicionar uma interface `CrashReporter` só faria sentido se algum
controller chamasse `recordError(...)` em código de runtime — não é o
caso, todas as chamadas estão concentradas em `main.dart`. YAGNI.

Não há `NoOpAnalyticsService` em `lib/`. Em plataformas onde
Crashlytics não roda, a inicialização e os hooks simplesmente não
são wired.

## Dependency Injection

`MultiProvider` no `lib/app.dart` recebe `Provider<AnalyticsService>`
(não `ChangeNotifierProvider` — não há estado mutável observável). Não
há provider para Crashlytics: o uso fica todo em `main.dart`.

`lib/main.dart` injeta sempre `FirebaseAnalyticsService`. Não há flavor
debug/release ou variação por modo. Tests injetam um mock de mocktail
(`_MockAnalyticsService`) diretamente em `_buildTestApp()`.

Controllers que precisam de analytics recebem via construtor:

```dart
DiceController({required AnalyticsService analytics, ...});
ThemeProvider({required AnalyticsService analytics, ...});
// etc.
```

Não usar `context.read<AnalyticsService>()` dentro dos controllers
(separação de camadas — controllers não conhecem `BuildContext`).
Wire-up acontece em `lib/app.dart` na construção do provider tree.

## Key Decisions

### D1 — Interface + única impl Firebase + mocktail nos tests

`AnalyticsService` é uma interface pura com uma única impl em `lib/`:
`FirebaseAnalyticsService`. Não existe No-Op em produção nem Fake em
test helpers. Tests mockam diretamente com `mocktail`:

```dart
class _MockAnalyticsService extends Mock implements AnalyticsService {}

// no test:
final analytics = _MockAnalyticsService();
when(() => analytics.logRollDice(diceType: any(named: 'diceType'),
                                 diceCount: any(named: 'diceCount')))
    .thenAnswer((_) async {});
// ... act ...
verify(() => analytics.logRollDice(diceType: DiceType.d20, diceCount: 2))
    .called(1);
```

Padrão simplificado em relação ao `SoundPlayer`/`NoOpSoundPlayer` do
E10 — aqui o No-Op não tem call sites legítimos em runtime, e mocktail
elimina a necessidade de um Fake reusável.

### D2 — Instrumentação inline nos call sites

DiceController:

```dart
Future<void> roll() async {
  final result = _engine.roll(_type, _count);
  _lastResult = result;
  notifyListeners();
  await _analytics.logRollDice(diceType: _type, diceCount: _count);
}
```

PresetsScreen no tap do PresetCard (`open_preset` é UI-driven, não
controller-driven):

```dart
onTap: () async {
  await context.read<AnalyticsService>().logOpenPreset(name: preset.name);
  context.read<DiceController>().applyConfig(preset.toConfig());
  const DiceRoute().go(context);
},
```

### D3 — `app_open` no boot do `main.dart`

Disparado **após** `Firebase.initializeApp` e **antes** de `runApp`.
Evita falsos negativos se o app abrir e crashar antes do primeiro frame.

Não usar `WidgetsBindingObserver.didChangeAppLifecycleState` para evitar
double-firing em retomadas do background (Analytics já tem `session_start`
nativo para esse caso).

### D4 — Bridge Firebase fora do gate de coverage

`tools/ralph/feedback.sh` ganha mais 4 entradas no `--exclude-coverage`:

```bash
--exclude-coverage 'lib/{main.dart,core/analytics/firebase_analytics_service.dart,core/crash/firebase_crash_reporter.dart,firebase_options.dart,**/*.g.dart,l10n/app_localizations*.dart}'
```

Justificativa registrada neste doc: bridge é pass-through; verificação é
manual via console Firebase (eventos aparecem em 24h em DebugView).
Custo de mockar singletons estáticos > valor do teste.

### D5 — Crashes: 3 hooks em `main.dart`, gated por plataforma

```dart
void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    final isMobile = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
         defaultTargetPlatform == TargetPlatform.iOS);

    if (isMobile) {
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    }

    // ... resto do bootstrap (analytics.logAppOpen, etc.)
    runApp(const App());
  }, (error, stack) {
    final isMobile = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
         defaultTargetPlatform == TargetPlatform.iOS);
    if (isMobile) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    }
  });
}
```

Em plataformas não-mobile (web, desktop, testes Dart VM):
- Nenhum hook de crash reporter é registrado;
- Erros escapam para o handler default do Flutter (console);
- `App()` não recebe `CrashReporter` via Provider (nenhum call site
  depende dele em runtime).

Debug build em mobile: `FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false)`
para não poluir o dashboard durante desenvolvimento.

### D6 — Sem PII, sem advertising_id manual

Não coletar `userId`, não setar `setUserProperty` para identificadores
pessoais. ATT prompt no iOS é nativo do `firebase_analytics` 10.x —
manter como vem (sem custom ATT framework).

## Riscos e Mitigações

| Risco | Mitigação |
|---|---|
| `flutterfire configure` não rodado → Firebase init falha em release | Pre-flight humano (decisão D1 do master plan); doc de E15 verifica `firebase_options.dart` antes de buildar |
| Crashlytics em testes (causa logs ruidosos) | `NoOpCrashReporter` em test environment via `flavor` de provider em `_buildTestApp()` |
| Analytics em widget tests (chamadas reais) | Mesmo pattern: `FakeAnalyticsService` injetado em todos os tests via `_buildTestApp()` (já é o padrão do projeto) |
| Eventos duplicados de `roll_dice` (animação dispara 2x?) | Instrumentar **uma vez** em `DiceController.roll()`, não em widget callbacks de animação |
| Drift entre o spec dos 9 eventos e o que está no código | Constantes em `analytics_service.dart` (event names), testes verificam que cada call site passa o nome esperado |
| `change_animation` disparar 2x se UI muda style e speed juntos | Não muda — são setters separados em `AnimationSettingsController`. Cada setter dispara seu próprio evento |

## Open Questions

- **Q1:** `app_open` no `main.dart` é suficiente, ou também queremos
  `screen_view` por aba (4 abas)? — não está no spec dos 9 eventos.
  Assumir **não** até stakeholder pedir.
- **Q2:** Crashlytics em **debug** builds: enviar (para validar o
  pipeline) ou desligar? — assumir **desligar** com
  `setCrashlyticsCollectionEnabled(false)`; reativar manualmente quando
  precisar testar o dashboard.
- **Q3:** Eventos de presets built-in disparam `open_preset` com o **id**
  do preset (`yahtzee`, `ludo`, ...) ou com o **label localizado**
  (`Yahtzee`, `Ludo`, ...)? — assumir **id** (estável entre locales,
  agrupável no dashboard).
- **Q4:** Crashlytics aceita `customKey`s — instrumentar paleta atual /
  locale como custom keys para correlacionar crashes? — fora do
  escopo M1. Registrar como follow-up para M2.

## Resumo do plano subsequente (`/plan` futuro)

Quando a issue `feat: e11 analytics & crash reporting` for criada e
`flutterfire configure` rodado:

1. `pubspec.yaml` — `firebase_core ^2.24.0`, `firebase_analytics ^10.7.4`,
   `firebase_crashlytics ^3.4.8` (versões já listadas no roadmap).
2. `lib/core/analytics/` (2 arquivos: interface + Firebase impl).
3. Wire em `lib/main.dart` (3 hooks de crash gated por plataforma + log
   de `app_open`).
4. Wire em `lib/app.dart` (`MultiProvider` recebe analytics + crash).
5. Atualizar 7 controllers/repos para receber `AnalyticsService` no
   construtor + disparar evento.
6. 1 alteração de UI: `PresetCard` tap handler.
7. Atualizar `tools/ralph/feedback.sh` (exclude-coverage).
8. Tests: mocks `_MockAnalyticsService extends Mock implements
   AnalyticsService` declarados inline + atualização de todos os
   `_buildTestApp()` que instanciam controllers.
9. Verificação manual: rodar app, executar fluxo de cada evento,
   confirmar no Firebase DebugView.
