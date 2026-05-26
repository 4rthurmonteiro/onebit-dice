# Progress — 1-Bit Dice M1 MVP

> Este arquivo é o tracker do agent loop. A cada iteração: ler → escolher próximo TODO → implementar → testar → commitar → marcar DONE.
>
> Status: `[ ]` TODO · `[~]` IN PROGRESS · `[x]` DONE · `[!]` BLOCKED: human

---

## EPIC 0 — Infraestrutura & Setup do Agent Loop

- [ ] 0.1 Escrever `CLAUDE.md` com convenções + instruções do loop
- [ ] 0.2 Atualizar `pubspec.yaml` com todas as dependências do M1 + rodar `flutter pub get`
- [ ] 0.3 Criar estrutura de pastas (`lib/core/`, `lib/features/`, `lib/shared/`) com placeholders
- [ ] 0.4 Atualizar `analysis_options.yaml` com regras adicionais
- [ ] 0.5 Criar `.github/workflows/ci.yml` (flutter analyze + flutter test)
- [!] 0.6 Firebase setup — requer conta Firebase + `flutterfire configure` (intervenção humana)

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
  - **Remover em E09** (Navegação) quando o app shell real entrar

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
- [!] 4.4 Substituir placeholders por arquivos `.mp3` reais (intervenção humana — assets de áudio)

---

## EPIC 5 — Core: Analytics & Crash Reporting

- [ ] 5.1 `lib/core/analytics/analytics_service.dart` — todos os 9 eventos do roadmap
- [ ] 5.2 Atualizar `lib/main.dart` — `Firebase.initializeApp` + Crashlytics `FlutterError.onError`
- [ ] 5.3 `test/core/analytics/analytics_service_test.dart` — mock `FirebaseAnalytics`

---

## EPIC 6 — Feature: Splash Screen

- [ ] 6.1 `lib/features/splash/splash_screen.dart` — wordmark + tagline + microtexto + delay 1.5s
- [ ] 6.2 `flutter_native_splash.yaml` — bg branco + ícone
- [ ] 6.3 Rodar `dart run flutter_native_splash:create`

---

## EPIC 7 — Feature: Navegação

- [ ] 7.1 `lib/features/shell/app_shell.dart` — `IndexedStack` + `RetroTabBar`
- [ ] 7.2 `lib/shared/widgets/retro_tab_bar.dart` — 4 tabs pixel art + label VT323
- [ ] 7.3 `test/features/shell/app_shell_test.dart` — troca de tab funciona

---

## EPIC 8 — Feature: Home Screen / Rolagem

- [ ] 8.1 `lib/features/dice/dice_controller.dart` — `ChangeNotifier` com `roll()`, `setType()`, `setCount()`
- [ ] 8.2 `lib/features/dice/widgets/type_selector.dart` — chips para cada DiceType
- [ ] 8.3 `lib/features/dice/widgets/quantity_selector.dart` — − / count / + clampado 1–10
- [ ] 8.4 `lib/features/dice/widgets/dice_widget.dart` — placeholder (número grande Silkscreen)
- [ ] 8.5 `lib/features/dice/widgets/roll_button.dart` — MacButton full-width "ROLAR"
- [ ] 8.6 `lib/features/dice/dice_screen.dart` — compõe todos os widgets + resultado
- [ ] 8.7 `test/features/dice/dice_controller_test.dart`
- [ ] 8.8 `test/features/dice/widgets/type_selector_test.dart`
- [ ] 8.9 `test/features/dice/widgets/quantity_selector_test.dart`

---

## EPIC 9 — Feature: Histórico

- [ ] 9.1 `lib/features/history/widgets/history_entry.dart` — data/hora + dados + resultados + total
- [ ] 9.2 `lib/features/history/history_screen.dart` — `ValueListenableBuilder` do Hive box
- [ ] 9.3 Botão "LIMPAR HISTÓRICO" com `AlertDialog` de confirmação
- [ ] 9.4 `test/features/history/history_screen_test.dart`

---

## EPIC 10 — Feature: Presets / Jogos

- [ ] 10.1 `lib/features/presets/preset_data.dart` — 7 presets estáticos
- [ ] 10.2 `lib/features/presets/widgets/preset_card.dart` — `MacWindow` card com nome + dado
- [ ] 10.3 `lib/features/presets/presets_screen.dart` — seção builtIn + seção custom + "+ NOVO"
- [ ] 10.4 Bottom sheet para criar preset customizado
- [ ] 10.5 `test/features/presets/presets_screen_test.dart`

---

## EPIC 11 — Feature: Ajustes

- [ ] 11.1 `lib/features/settings/widgets/palette_selector.dart` — grid 7 swatches
- [ ] 11.2 `lib/features/settings/widgets/toggle_tile.dart` — checkbox Mac-style □/X
- [ ] 11.3 `lib/features/settings/widgets/animation_settings.dart` — estilo + velocidade
- [ ] 11.4 `lib/features/settings/settings_screen.dart` — compõe tudo
- [ ] 11.5 `test/features/settings/settings_screen_test.dart`

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

- [ ] 13.1 `lib/core/models/animation_style.dart` — enums `AnimationStyle` + `AnimationSpeed`
- [ ] 13.2 Animação "Rápida" — `AnimatedSwitcher` 200ms no `DiceWidget`
- [ ] 13.3 Animação "Tambor" — `AnimationController` ciclando frames (placeholder textual)
- [ ] 13.4 Animação "Tabuleiro" — multi-fase: slide in → bounce → ciclo → resultado
- [!] 13.5 Substituir placeholder por sprite sheets reais (intervenção humana — assets Blender)

---

## EPIC 14 — Assets: Ícone + Native Splash

- [!] 14.1 Criar `assets/icon/icon.png` (1024×1024, d6 pixel art) — intervenção humana
- [ ] 14.2 `flutter_launcher_icons.yaml` — config Android + iOS
- [ ] 14.3 Rodar `dart run flutter_launcher_icons`
- [ ] 14.4 Atualizar `flutter_native_splash.yaml` com ícone real
- [ ] 14.5 Rodar `dart run flutter_native_splash:create`

---

## EPIC 15 — Release Preparation

- [!] 15.1 Gerar keystore Android + configurar `key.properties` + backup (intervenção humana)
- [ ] 15.2 Atualizar `android/app/build.gradle` com signing config
- [ ] 15.3 Atualizar `AndroidManifest.xml` — bundle ID + app name
- [ ] 15.4 Atualizar `ios/Runner/Info.plist` — bundle ID + display name + min iOS 13
- [ ] 15.5 `flutter build appbundle --release` — verificar build sem erros
- [ ] 15.6 `flutter build ipa --release` — verificar build sem erros
- [!] 15.7 Capturar screenshots nas resoluções corretas (intervenção humana — device físico)
- [!] 15.8 Criar app records no Play Console + App Store Connect (intervenção humana)
- [ ] 15.9 Publicar política de privacidade no GitHub Pages
- [ ] 15.10 Upload AAB no Play Console (faixa de testes internos)
- [ ] 15.11 Upload IPA no App Store Connect
