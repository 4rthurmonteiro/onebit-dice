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

- [ ] 2.1 `lib/core/models/dice_type.dart` — enum com d4, d6, d8, d10, d12, d20, d100
- [ ] 2.2 `lib/shared/utils/random_dice.dart` — `rollDie()` e `rollDice()` com `Random.secure()`
- [ ] 2.3 `lib/core/models/roll_result.dart` — classe imutável com `total` e `equation`
- [ ] 2.4 `test/core/models/dice_type_test.dart` — testes unitários
- [ ] 2.5 `test/shared/utils/random_dice_test.dart` — distribuição uniforme 10k iterações

---

## EPIC 3 — Core: Storage Layer

- [ ] 3.1 `lib/core/storage/app_prefs.dart` — wrapper SharedPreferences (paleta, som, haptic, animação, último dado)
- [ ] 3.2 `lib/core/storage/models/roll_entry.dart` — `@HiveType` com todos os campos
- [ ] 3.3 `lib/core/storage/models/custom_preset.dart` — `@HiveType` com nome + dado
- [ ] 3.4 `lib/core/storage/hive_init.dart` — `HiveInit.init()` com `initFlutter` + adapters + boxes
- [ ] 3.5 Rodar `dart run build_runner build --delete-conflicting-outputs` (gera `.g.dart`)
- [ ] 3.6 `test/core/storage/app_prefs_test.dart` — mock SharedPreferences
- [ ] 3.7 `test/core/storage/models/roll_entry_test.dart` — testar `total`

---

## EPIC 4 — Core: Audio & Haptic

- [ ] 4.1 `lib/core/audio/sound_player.dart` — wrapper `just_audio` com `playRoll/Stop/Total` + `setEnabled`
- [ ] 4.2 `lib/core/haptic/haptic_controller.dart` — wrapper `HapticFeedback.mediumImpact` + `setEnabled`
- [ ] 4.3 Criar placeholders em `assets/sounds/` (roll.mp3, stop.mp3, total.mp3)
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

- [ ] 12.1 Adicionar `flutter_localizations` + `intl` ao `pubspec.yaml`
- [ ] 12.2 Criar `l10n.yaml`
- [ ] 12.3 Criar `lib/l10n/app_pt.arb` (PT-BR — base) com todas as strings
- [ ] 12.4 Criar `lib/l10n/app_en.arb` (EN-US)
- [ ] 12.5 Rodar gerador de localização
- [ ] 12.6 Substituir todas as strings hardcoded por `context.l10n.*` em todos os features

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
