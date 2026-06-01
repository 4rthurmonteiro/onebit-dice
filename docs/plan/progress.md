# Progress — 1-Bit Dice M1 MVP

> Este arquivo é o tracker do agent loop. A cada iteração: ler → escolher próximo TODO → implementar → testar → commitar → marcar DONE.
>
> Status: `[ ]` TODO · `[~]` IN PROGRESS · `[x]` DONE · `[!]` BLOCKED: human

---

## EPIC 0 — Infraestrutura & Setup do Agent Loop

- [x] 0.1 `CLAUDE.md` com convenções + instruções do loop
- [x] 0.2 `pubspec.yaml` com todas as dependências do M1
- [x] 0.3 Estrutura de pastas (`lib/core/`, `lib/features/`, `lib/shared/`)
- [x] 0.4 `analysis_options.yaml` com regras `very_good_analysis`
- [x] 0.5 `.github/workflows/ci.yml` (flutter analyze + very_good test)
- [x] 0.6 Firebase setup — projeto `onebit-dice-am2` criado; `flutterfire configure` rodado p/ android+ios; `lib/firebase_options.dart`, `google-services.json`, `GoogleService-Info.plist`, `firebase.json` commitados; plugins Gradle (`com.google.gms.google-services` + `com.google.firebase.crashlytics`) aplicados em `android/settings.gradle.kts` + `android/app/build.gradle.kts`

---

## EPIC 1 — Core: Theme & Design System

- [x] 1.1 `lib/core/theme/palette.dart` — enum `PaletteId` + classe `Palette` com 7 paletas
- [x] 1.2 `lib/core/theme/theme_provider.dart` — `ChangeNotifier` com `current` + `setPalette()`
- [x] 1.3 `lib/core/theme/app_typography.dart` — TextStyles para Silkscreen, VT323, Press Start 2P
- [x] 1.4 Declarar fontes no `pubspec.yaml` + baixar arquivos `.ttf` para `assets/fonts/`
- [x] 1.5 `lib/shared/widgets/mac_button.dart` — borda dupla, sombra offset, estado pressionado
- [x] 1.6 `lib/shared/widgets/mac_window.dart` — title bar listrada + borda dupla
- [x] 1.7 `lib/shared/widgets/pixel_divider.dart` — linha 2px
- [x] 1.8 `lib/app.dart` — MaterialApp com `ChangeNotifierProvider<ThemeProvider>`
- [x] 1.9 `lib/core/theme/app_theme.dart` — `OneBitColors` ThemeExtension + `buildThemeData(palette)`
- [x] 1.10 `lib/core/theme/palette_preference.dart` — interface + `InMemoryPalettePreference`
- [x] 1.11 `lib/features/_dev/design_system_preview.dart` — preview manual (smoke-test)
  - **Removido em E09** quando o app shell real entrou

---

## EPIC 2 — Core: Dice Engine

- [x] 2.1 `lib/core/models/dice_type.dart` — enum com d4, d6, d8, d10, d12, d20, d100
- [x] 2.2 `lib/shared/utils/random_dice.dart` — `rollDie()` e `rollDice()` com `Random.secure()`
- [x] 2.3 `lib/core/models/roll_result.dart` — classe imutável com `total` e `equation`
- [x] 2.4 `test/core/models/dice_type_test.dart` — testes unitários
- [x] 2.5 `test/shared/utils/random_dice_test.dart` — distribuição uniforme 10k iterações

---

## EPIC 3 — Core: Storage Layer

> Nota: o item 3.1 original (um único `app_prefs.dart` agregando tudo) foi
> dividido em quatro interfaces por domínio, conforme decidido no brainstorm
> de E04: `SharedPreferencesPalettePreference`, `AppSettingsPreference`,
> `LastDiceConfigPreference`, mais os repositórios `HistoryRepository` e
> `PresetsRepository`. O id de `CustomPreset` usa
> `microsecondsSinceEpoch + Random.nextInt(1<<16)` em vez de `uuid` para
> evitar dependência adicional para um uso pontual.

- [x] 3.1 Storage por domínio: `palette_preference.dart` (+ impl SharedPreferences), `app_settings_preference.dart`, `last_dice_config_preference.dart`
- [x] 3.2 `lib/core/storage/models/roll_entry.dart` — `@HiveType(typeId: 0)` com todos os campos
- [x] 3.3 `lib/core/storage/models/custom_preset.dart` — `@HiveType(typeId: 1)` com nome + dado
- [x] 3.4 `lib/core/storage/hive_init.dart` — `HiveInit.init()` / `registerAndOpen()` com adapters + boxes
- [x] 3.5 Codegen via `dart run build_runner build` (gera `.g.dart` committados)
- [x] 3.6 Testes de cada preference (mock SharedPreferences) e dos repositórios (Hive em tempDir)
- [x] 3.7 `test/core/storage/models/roll_entry_test.dart` — round-trip `RollResult` ↔ `RollEntry`

---

## EPIC 4 — Core: Audio & Haptic — E10

> Nota: a engine de áudio passou a ser `flutter_soloud` 4.x (substitui o
> `just_audio` originalmente citado no roadmap). Decisão registrada em
> [docs/brainstorm/2026-05-26-e10-audio-haptic-brainstorm-doc.md](../brainstorm/2026-05-26-e10-audio-haptic-brainstorm-doc.md).
> O item 4.1 original (um único `sound_player.dart`) foi dividido em
> `sound_player.dart` (interface + `SoundEvent`), `soloud_gateway.dart`
> (seam sobre `SoLoud.instance`), `soloud_sound_player.dart` (impl),
> e `audio_controller.dart` (`ChangeNotifier` com lifecycle + toggle).

- [x] 4.1 Camada de áudio: `sound_player.dart` (interface + `SoundEvent`), `soloud_gateway.dart` (seam), `soloud_sound_player.dart` (impl `flutter_soloud`), `audio_controller.dart` (`ChangeNotifier` + `WidgetsBindingObserver` + toggle persistido)
- [x] 4.2 `lib/core/haptic/haptic_controller.dart` — `ChangeNotifier` com `HapticTrigger` seam sobre `HapticFeedback.mediumImpact` + toggle persistido
- [x] 4.3 Placeholders em `assets/sounds/` (roll.mp3, stop.mp3, total.mp3) — 100 ms de silêncio
- [x] 4.4 Substituídos por 8 takes `.ogg` reais (grab×2, shake×3, throw×3). `SoundEvent` refatorado para `grab/shake/land` com variantes random; `AudioController.playRollSequence()` toca grab → 120 ms → shake → 500 ms → land.

---

## EPIC 5 — Core: Analytics & Crash Reporting

> Bootstrap entregue junto com **0.6**. Interface `AnalyticsService` +
> `NoOpAnalyticsService` + `FirebaseAnalyticsService` (Analytics +
> Crashlytics injetados via construtor) cobertos por testes. Call sites
> de eventos específicos (dice rolled, palette changed etc.) ficam para
> uma iteração futura — fora do escopo deste bootstrap.

- [x] 5.1 `lib/core/analytics/analytics_service.dart` + `firebase_analytics_service.dart` — interface + `NoOpAnalyticsService` + impl Firebase
- [x] 5.2 `lib/main.dart` — `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` + `FlutterError.onError` → `crashlytics.recordFlutterFatalError` + `PlatformDispatcher.onError` → `crashlytics.recordError(fatal: true)` + `setCrashlyticsCollectionEnabled(!kDebugMode)`. `App` recebe `analyticsService` e expõe via `Provider<AnalyticsService>`.
- [x] 5.3 `test/core/analytics/analytics_service_test.dart` — `NoOpAnalyticsService` smoke + `FirebaseAnalyticsService` forwarding (mocktail mocks de `FirebaseAnalytics` / `FirebaseCrashlytics`)

---

## EPIC 6/7 — Navegação (Splash + App Shell) — E09

> Nota: EPIC 6 (Splash) e EPIC 7 (Navegação) foram fundidos em um único
> entregável (E09), conforme o roadmap (`docs/roadmap/08-epics-m1.md`) e o
> precedente da fusão EPIC 4/E10. O shell usa `go_router` +
> `go_router_builder` + `StatefulShellRoute.indexedStack` (memória do
> projeto: `IndexedStack` manual é proibido). Detalhes:
> [docs/plan/2026-05-26-feat-e09-app-shell-and-splash-plan.md](2026-05-26-feat-e09-app-shell-and-splash-plan.md).

- [x] 6/7.1 `lib/features/splash/splash_screen.dart` — wordmark + tagline + microtexto COCU + d6 pixel art + delay 1.5s (cores hard-coded `#000`/`#FFF`)
- [x] 6/7.2 `flutter_native_splash.yaml` — bg `#FFFFFF` + ícone + bloco `android_12`
- [x] 6/7.3 `dart run flutter_native_splash:create` rodado; arquivos nativos commitados
- [x] 6/7.4 `assets/icon/icon.png` 1024×1024 placeholder (d6 derivado do protótipo); E14 substitui
- [x] 6/7.5 `lib/app_router.dart` — `GoRouter` com `SplashRoute` + `MainShellRoute` (4 branches), rotas type-safe via `go_router_builder`, todas com `NoTransitionPage`
- [x] 6/7.6 `lib/features/shell/app_shell.dart` — `Scaffold` + `RetroTabBar` montado pelo `StatefulShellRoute.indexedStack`
- [x] 6/7.7 `lib/shared/widgets/retro_tab_bar.dart` — 4 tabs com `PixelIcon` + label, inversão de cor na ativa, `Semantics(button, selected, label)`
- [x] 6/7.8 `lib/shared/widgets/pixel_icon.dart` — `CustomPaint` que lê `OneBitColors`; suporta `inverted`
- [x] 6/7.9 Stubs `HistoryScreen` / `PresetsScreen` / `SettingsScreen` em `lib/features/*/` (renderizam título localizado + "EM BREVE")
- [x] 6/7.10 `lib/core/app_info.dart` — `kAppVersion`/`kStudioName` (única fonte da versão exibida no splash)
- [x] 6/7.11 `lib/app.dart` — `_AppView` agora é `StatefulWidget`; usa `MaterialApp.router(routerConfig: ...)`; provider stack preservado
- [x] 6/7.12 i18n: 6 chaves novas em 11 ARBs (`appTagline`, `commonComingSoon`, `splashUniverseTagline`, `historyTitle`, `presetsTitle`, `settingsTitle`)
- [x] 6/7.13 Testes 100% cobertura: `app_router_test.dart`, `shell/app_shell_test.dart`, `splash/splash_screen_test.dart`, `history/`/`presets/`/`settings/`, `shared/widgets/retro_tab_bar_test.dart`, `shared/widgets/pixel_icon_test.dart`; `widget_test.dart` atualizado para o fluxo splash → shell

---

## EPIC 8 — Feature: Home Screen / Rolagem

- [x] 8.1 `lib/features/dice/dice_controller.dart` — `ChangeNotifier` com `roll()`, `setType()`, `setCount()`, `applyConfig()`
- [x] 8.2 `lib/features/dice/widgets/type_selector.dart` — 7 chips com `Semantics(button, selected)`
- [x] 8.3 `lib/features/dice/widgets/quantity_selector.dart` — −/count/+ clampado 1–10, com semantics
- [x] 8.4 `lib/features/dice/widgets/dice_widget.dart` + `dice_grid.dart` + `dice_slot.dart` — grid responsivo + animator
- [x] 8.5 `lib/features/dice/widgets/roll_button.dart` — MacButton full-width "ROLAR"
- [x] 8.6 `lib/features/dice/dice_screen.dart` — compõe tudo + result + integração com history/audio/haptic/prefs
- [x] 8.7 `test/features/dice/dice_controller_test.dart`
- [x] 8.8 `test/features/dice/widgets/type_selector_test.dart`
- [x] 8.9 `test/features/dice/widgets/quantity_selector_test.dart` + tests para dice_widget, dice_grid, dice_slot, roll_button, dice_screen

---

## EPIC 8b — Dice Screen Redesign (tap-to-roll / Design C)

- [x] 8b.1 `dice_controller.dart` — flag `hasRolled` (session, in-memory) + guarda de reentrância `isRolling` (early-return + `finally`)
- [x] 8b.2 `dice_screen.dart` — canvas herói tap-to-roll (`Semantics(button)`, ignora tap enquanto `isRolling`) + hint `▸ TOQUE PARA ROLAR ◂` até a 1ª rolagem + barra fina (campo + stepper); `RollButton` removido
- [x] 8b.3 `widgets/type_selector.dart` — repurposed: campo compacto `{label} ▾` que abre `DiceTypeSheet` (caret pintado via `PixelIcon`)
- [x] 8b.4 `widgets/quantity_selector.dart` — layout compacto (`mainAxisSize.min`, fonte 24)
- [x] 8b.5 `widgets/dice_type_sheet.dart` — bottom sheet (7 tipos, linha invertida + checkmark) com barreira hachurada 1-bit via `_DiceTypeSheetRoute` (corte seco, sem alpha); dismiss por ✕/scrim/arrastar/back
- [x] 8b.6 `widgets/dice_type_badge.dart` — silhuetas 8×8 por `DiceType` via `PixelIcon`
- [x] 8b.7 `shared/widgets/hatch_painter.dart` — xadrez 1-bit ink/paper (sem cinza/alpha)
- [x] 8b.8 `create_preset_sheet.dart` — adota o mesmo campo + sheet (UX consistente)
- [x] 8b.9 i18n: 5 chaves novas em 12 locales (`rollTapHint`, `rollCanvasLabel`, `diceTypeSheetTitle`, `diceTypeFieldLabel`, `diceTypeSidesLabel` plural)
- [x] 8b.10 `roll_button.dart` + teste removidos
- [x] 8b.11 Testes 100% cobertura: controller (`hasRolled`/`isRolling`), screen (tap-to-roll, reentrância, sheet), `type_selector`, `dice_type_sheet`, `dice_type_badge`, `hatch_painter`, `create_preset_sheet`

---

## EPIC 9 — Feature: Histórico

- [x] 9.1 `lib/features/history/widgets/history_entry_tile.dart` — data/hora + notação + valores + total (com placeholder p/ entry corrompido)
- [x] 9.2 `lib/features/history/history_screen.dart` — `StreamBuilder` sobre `HistoryRepository.watch()`, empty state + lista reversa (newest-first)
- [x] 9.3 `lib/features/history/widgets/clear_history_button.dart` — botão "LIMPAR" + `AlertDialog` 1-bit de confirmação
- [x] 9.4 `test/features/history/` — testes para `history_screen`, `history_entry_tile`, `clear_history_button` (100% line coverage)

---

## EPIC 10 — Feature: Presets / Jogos

- [x] 10.1 `lib/features/presets/preset_data.dart` — 7 presets builtIn (Ludo, Banco, War, Yahtzee, D&D Ataque, Magic Vida, Percentil)
- [x] 10.2 `lib/features/presets/widgets/preset_card.dart` — card com label + notação + semantics
- [x] 10.3 `lib/features/presets/presets_screen.dart` — `preset_section.dart` builtIn + custom + `add_preset_button.dart`
- [x] 10.4 `lib/features/presets/widgets/create_preset_sheet.dart` — bottom sheet com TextField (24 chars max, trim) + save habilitado condicional
- [x] 10.5 Tests para presets_screen, preset_card, preset_section, add_preset_button, create_preset_sheet, preset_data

---

## EPIC 11 — Feature: Ajustes

- [x] 11.1 `lib/features/settings/widgets/palette_selector.dart` — grid 7 swatches com `PaletteSwatchPainter`
- [x] 11.2 `lib/features/settings/widgets/toggle_tile.dart` — checkbox Mac-style □/X com `CheckboxPainter`
- [x] 11.3 `lib/features/settings/widgets/animation_section.dart` — radios de estilo + velocidade (3×3) com `RadioPainter`
- [x] 11.4 `lib/features/settings/settings_screen.dart` — compõe 5 sections (palette, sound/haptic, animation, language, about)
- [x] 11.5 Tests para settings_screen, about_section, animation_section, language_picker, palette_selector, toggle_tile

---

## EPIC 12 — Feature: Internacionalização

> Nota: a engine `synthetic-package` foi removida no Flutter 3.44, então a
> codegen escreve em `lib/l10n/app_localizations*.dart` (excluído do gate de
> cobertura, como `**/*.g.dart`). Decisão registrada na PR de E13.

- [x] 12.1 Adicionar `flutter_localizations` + `intl` + `generate: true` + `l10n.yaml`
- [x] 12.2 Criar `lib/l10n/app_pt_BR.arb` (template) com ~29 chaves
- [x] 12.3 Gerar 9 ARBs traduzidos (en, es, fr, de, it, ja, zh, ko, ru) + bases `app_pt.arb` / `app_zh.arb` via MT
- [x] 12.4 `lib/core/i18n/supported_locales.dart` (`SupportedLocale` class + const list)
- [x] 12.5 `lib/core/i18n/locale_preference.dart` (interface + `InMemory` + `SharedPreferences`)
- [x] 12.6 `lib/core/i18n/locale_controller.dart` (`ChangeNotifier`)
- [x] 12.7 `lib/core/i18n/l10n_extension.dart` (`BuildContext.l10n`)
- [x] 12.8 Wire `MultiProvider` + `MaterialApp.locale/delegates/resolutionCallback` em `lib/app.dart`
- [x] 12.9 Testes (4 arquivos em `test/core/i18n/` + `test/widget_test.dart`) — 100% cobertura

---

## EPIC 13 — Feature: Animações de Dados

- [x] 13.1 `lib/core/models/animation_style.dart` — enums `AnimationStyle` + `AnimationSpeed`
- [x] 13.2 Animação "Rápida" — `AnimatedSwitcher` 100ms hard cut em `FastAnimation`
- [x] 13.3 Animação "Tambor" — `AnimationController` ciclando frames (placeholder textual)
- [x] 13.4 Animação "Tabuleiro" — multi-fase: slide in → bounce → ciclo → settle
- [!] 13.5 Substituir placeholder por sprite sheets reais (intervenção humana — assets Blender)

---

## EPIC 14 — Assets: Ícone + Native Splash

- [x] 14.1 `assets/icon/icon.png` + `assets/icon/icon-foreground.png` (1024×1024, d6 face 1, direção A do critique em [docs/design/icon-review/](../design/icon-review/))
- [x] 14.2 `flutter_launcher_icons.yaml` + `flutter_launcher_icons: ^0.13.1` em dev_dependencies
- [x] 14.3 `dart run flutter_launcher_icons` — mipmaps Android (legacy + adaptive) + `AppIcon.appiconset` + `colors.xml` gerados
- [x] 14.4 `flutter_native_splash.yaml` inalterado (já apontava para `assets/icon/icon.png`)
- [x] 14.5 `dart run flutter_native_splash:create` — splash regenerado com ícone novo

---

## EPIC 15 — Release Preparation

- [!] 15.1 Gerar keystore Android + configurar `key.properties` + backup (intervenção humana)
- [ ] 15.2 Atualizar `android/app/build.gradle` com signing config
- [x] 15.3 Bundle ID `com.am2.onebitdice` + `android:label="1-Bit Dice"` (configurado no `build.gradle.kts` namespace/applicationId + AndroidManifest)
- [x] 15.4 iOS `PRODUCT_BUNDLE_IDENTIFIER = com.am2.onebitdice`, `CFBundleDisplayName/Name = "1-Bit Dice"`, `IPHONEOS_DEPLOYMENT_TARGET = 13.0` + Podfile `platform :ios, '13.0'`
- [ ] 15.5 `flutter build appbundle --release` — verificar build sem erros
- [ ] 15.6 `flutter build ipa --release` — verificar build sem erros
- [!] 15.7 Capturar screenshots nas resoluções corretas (intervenção humana — device físico)
- [!] 15.8 Criar app records no Play Console + App Store Connect (intervenção humana)
- [x] 15.9 Política de privacidade redigida em PT-BR + EN ([docs/privacy/index.html](../privacy/index.html) + [en.html](../privacy/en.html)) — falta habilitar GH Pages no GitHub: Settings → Pages → Source: `main` / `/docs`. URL final: `https://4rthurmonteiro.github.io/onebit-dice/privacy/`
- [ ] 15.10 Upload AAB no Play Console (faixa de testes internos)
- [ ] 15.11 Upload IPA no App Store Connect
