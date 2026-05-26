---
title: "feat: e13 internationalization"
type: feat
date: 2026-05-26
epic: E13
status: planned
---

# feat: e13 internationalization — Standard

> Numbering note: the roadmap (`docs/roadmap/08-epics-m1.md`) calls this **E13**. `docs/plan/progress.md` numbers the same body of work as **EPIC 12**. This plan adopts the roadmap label (E13) for the filename to mirror the brainstorm doc, but the task tracker entries in `progress.md` stay at 12.x.

## Overview

Standup of the full i18n / l10n infrastructure for 1-Bit Dice. Ten locales supported from launch — PT-BR (template), EN, ES, FR, DE, IT, JA, ZH-Hans, KO, RU. The app follows the device locale by default; a manual override is persisted via a `LocalePreference` that mirrors the existing [PalettePreference](../../lib/core/theme/palette_preference.dart) pattern.

This epic ships the **controller, the preference seam, the `BuildContext.l10n` extension, the ARB seed (~30–40 keys), and the `MaterialApp` wiring**. The Settings UI that exposes the language picker arrives in E08 — out of scope here. Translations for the 9 non-template locales are produced via a single LLM pass (no human review), reflecting the brainstorm's accepted trade-off.

Brainstorm reference: [2026-05-26-e13-internationalization-brainstorm-doc.md](../brainstorm/2026-05-26-e13-internationalization-brainstorm-doc.md).

## Problem Statement / Motivation

Today the app:

- Has **zero translations**: every user-visible string lives hardcoded in widgets (mostly in `lib/features/_dev/design_system_preview.dart` and shared widgets), making future Store Listings and in-app localization impossible.
- Already commits to 10 launch locales in the roadmap, but no infra exists — no `flutter_localizations` delegate, no `l10n.yaml`, no ARB tree, no `intl` formatter access.
- Has features E05 (Roll), E06 (History), E07 (Presets) and E08 (Settings) **pending implementation**. Writing them against `context.l10n.*` from day one avoids a retrofit pass after the fact.

Without E13:

- Strings in E05–E08 calcify in Portuguese and require a churn-heavy migration later.
- The "Idioma" section of Settings (E08) has no controller to bind to.
- Store readiness (E15) blocks on language coverage.

The decision is therefore to land i18n **before** the four screen-level epics begin.

## Proposed Solution

Add `flutter_localizations` + `intl` to `pubspec.yaml`, create the standard `l10n.yaml` codegen config, write the PT-BR template ARB, machine-translate to 9 other locales, and introduce a small `lib/core/i18n/` package — `LocalePreference` (in-memory + SharedPreferences), `LocaleController` (`ChangeNotifier`), `BuildContext.l10n` extension, and a hardcoded `SupportedLocales` registry exposing native display names.

```
lib/
├── core/
│   └── i18n/
│       ├── locale_preference.dart   # interface + InMemory + SharedPreferences impl
│       ├── locale_controller.dart   # ChangeNotifier; reads override; setOverride/clear
│       ├── supported_locales.dart   # const list of (Locale, nativeName) tuples
│       └── l10n_extension.dart      # BuildContext.l10n → AppLocalizations.of(...)!
└── l10n/
    ├── app_pt.arb                   # template — PT-BR (source of truth)
    ├── app_en.arb                   # fallback locale
    ├── app_es.arb
    ├── app_fr.arb
    ├── app_de.arb
    ├── app_it.arb
    ├── app_ja.arb
    ├── app_zh.arb                   # zh-Hans (simplified)
    ├── app_ko.arb
    └── app_ru.arb

l10n.yaml                            # codegen config (arb-dir, template, output-class)

test/core/i18n/
├── locale_preference_test.dart
├── locale_controller_test.dart
├── supported_locales_test.dart
└── l10n_extension_test.dart         # widget test: forced locale renders right string
```

Generated artifacts (`.dart_tool/flutter_gen/gen_l10n/app_localizations*.dart`) are produced by `flutter gen-l10n` (run automatically on `flutter pub get` because `synthetic-package: true` is the default). They're gitignored.

### Layered responsibility map

| Component | Responsibility | Does NOT own |
|---|---|---|
| `app_pt.arb` (template) | Source of truth for **every** key, ICU metadata (`@key` descriptors, placeholder types) | Translations to other locales |
| `app_<locale>.arb` (9 files) | Localized strings; same key set as template; no `@` metadata block | New keys (template only) |
| `l10n.yaml` | Tells `flutter gen-l10n` where to look and what to generate (`AppLocalizations` class, `app_pt.arb` as template, `en` as fallback) | Runtime behaviour |
| `LocalePreference` | Persists the user override as a BCP-47 language tag (e.g. `pt-BR`, `zh-Hans`) or `null` meaning "follow system" | Locale resolution |
| `SharedPreferencesLocalePreference` | `read()` parses tag → `Locale`; rejects unknown tags as `null` (graceful degradation) | Validation of "is this locale supported?" (controller's job) |
| `SupportedLocale` + `supportedLocales` (top-level const) | Hardcoded list of `SupportedLocale(locale, nativeName)` for the 10 launch locales, ordered: PT-BR (default), EN (global fallback), then alphabetical | Persistence; UI; lookup helpers (deferred to E08 if needed) |
| `LocaleController` | `ChangeNotifier`. Owns `override` (`Locale?`). Reads from preference in constructor. `setOverride(Locale)` validates against `supportedLocales` (private `_isSupported` helper), persists, notifies. `clearOverride()` persists `null` + notifies | Resolved locale (Flutter does the system-fallback) |
| `BuildContext.l10n` extension | `AppLocalizations.of(this)!` — non-null after delegates are registered | Anything else |

### Locale resolution flow

```
        ┌─────────────────────────┐
        │ MaterialApp build       │
        └────────────┬────────────┘
                     │
       context.watch<LocaleController>()
                     │
                     ▼
        ┌─────────────────────────┐
        │ controller.override     │
        └────────────┬────────────┘
                     │
        ┌────────────┴────────────┐
        │                         │
        ▼                         ▼
   Locale? != null            override == null
        │                         │
        ▼                         ▼
locale = override         locale = null
                          → Flutter falls back to system,
                            then to fallback-locale (EN)
                            via supportedLocales order
```

`MaterialApp.locale` is set to `controller.override`. When `null`, Flutter's `localeListResolutionCallback` (default behaviour) walks `supportedLocales` against the system list and picks the first match; if nothing matches, the **first entry** of `supportedLocales` is used. We order `supportedLocales` as `[pt-BR, en, ...]` so:

- Brazilian users (PT-BR system) get PT-BR.
- Generic English users get EN.
- Users on an unsupported language get **PT-BR** (not EN) because PT-BR is index 0.

Brainstorm explicitly flags this — to make EN the global fallback we set `MaterialApp.localeResolutionCallback` to force EN when nothing in `supportedLocales` matches the system locale. That callback is the **only** custom resolution logic.

### Sequence: user toggles language in Settings (future E08)

```
SettingsScreen        LocaleController         LocalePreference         MaterialApp
     │                       │                        │                       │
     │  setOverride(Locale)  │                        │                       │
     ├──────────────────────▶│                        │                       │
     │                       │  write('zh-Hans')      │                       │
     │                       ├───────────────────────▶│                       │
     │                       │                        │                       │
     │                       │  notifyListeners()     │                       │
     │                       ├──┐                     │                       │
     │                       │  │                     │                       │
     │  rebuild              │  │   context.watch picks up override           │
     │◀──────────────────────┘  └─────────────────────────────────────────────┤
     │                       │                        │                       │
     │                       │                        │  MaterialApp.locale = │
     │                       │                        │      zh-Hans          │
     │                       │                        │                       │
     │                       │                        │  delegates re-resolve │
     │                       │                        │  AppLocalizations     │
```

## Implementation Plan

The order below is the suggested execution order; each numbered item maps directly to a checklist entry in `docs/plan/progress.md`.

### 12.1 — Dependencies + codegen scaffolding

- [ ] Add to `pubspec.yaml > dependencies`:
  ```yaml
  flutter_localizations:
    sdk: flutter
  intl: any   # let flutter_localizations pin the exact compatible version
  ```
  Rationale: brainstorm Q5 — declaring `intl: any` lets the Flutter SDK resolve the transitively-required version without us hard-pinning. Verify after `flutter pub deps` that the resolved version is recent (≥ `0.20.x` for current stable Flutter).
- [ ] Add to `pubspec.yaml > flutter`:
  ```yaml
  generate: true
  ```
- [ ] Create `l10n.yaml` at the project root:
  ```yaml
  arb-dir: lib/l10n
  template-arb-file: app_pt.arb
  output-localization-file: app_localizations.dart
  output-class: AppLocalizations
  preferred-supported-locales:
    - pt-BR
    - en
  synthetic-package: true
  ```
- [ ] Run `flutter pub get` and `flutter gen-l10n`; confirm `.dart_tool/flutter_gen/gen_l10n/app_localizations.dart` is produced.
- [ ] Verify `.gitignore` already covers `.dart_tool/` (it should, from project init); no new ignore lines needed.

### 12.2 — Author template `app_pt.arb`

- [ ] Create `lib/l10n/app_pt.arb` with `@@locale: "pt_BR"` and **all** initial keys (template doc below). Keep all `@key` metadata blocks here; they're omitted from translated files.

Initial key inventory (~29 keys) — names use `lowerCamelCase`, prefixed by domain. Dice notation (`d4`…`d100`) is rendered as literals at the widget layer — same string across all 10 locales, no value in ARBing it.

```jsonc
{
  "@@locale": "pt_BR",

  // ─── App & generic actions ───
  "appName": "1-Bit Dice",
  "@appName": { "description": "App name — kept untranslated across locales" },

  "actionRoll": "ROLAR",
  "actionClear": "LIMPAR",
  "actionConfirm": "CONFIRMAR",
  "actionCancel": "CANCELAR",
  "actionClose": "FECHAR",

  // ─── Tabs (E09 shell) ───
  "tabRoll": "ROLAR",
  "tabHistory": "HISTÓRICO",
  "tabPresets": "JOGOS",
  "tabSettings": "AJUSTES",

  // ─── Roll screen messaging ───
  "rollingNDice": "{count, plural, one{Rolando 1 dado} other{Rolando {count} dados}}",
  "@rollingNDice": {
    "placeholders": { "count": { "type": "int" } }
  },
  "rollResultTotal": "Total: {total}",
  "@rollResultTotal": {
    "placeholders": { "total": { "type": "int" } }
  },

  // ─── History ───
  "historyEmpty": "Nenhuma rolagem ainda.",
  "historyClearConfirmTitle": "Limpar histórico?",
  "historyClearConfirmBody": "Isso apaga todas as rolagens registradas.",

  // ─── Presets (classic games — names kept original) ───
  "presetsSectionClassic": "Jogos Clássicos",
  "presetsSectionCustom": "Personalizados",
  "presetLudo": "Ludo",
  "presetWar": "War",
  "presetYahtzee": "Yahtzee",
  "presetCraps": "Craps",
  "presetBunco": "Bunco",
  "presetFarkle": "Farkle",
  "presetLiarsDice": "Liar's Dice",

  // ─── Settings sections ───
  "settingsSectionAppearance": "Aparência",
  "settingsSectionFeedback": "Feedback",
  "settingsSectionAnimation": "Animação",
  "settingsSectionLanguage": "Idioma",
  "settingsSectionAbout": "Sobre",

  "settingsLanguageFollowSystem": "Seguir sistema"
}
```

Brainstorm decisions baked into the template:
- **Game preset names are untranslated** (Q2 resolved): Ludo, War, Yahtzee, Craps, Bunco, Farkle, Liar's Dice stay verbatim across all locales. Translators must preserve them.
- **`appName` is untranslated**: marketing identity.
- **ICU plural** appears in `rollingNDice` to validate the codegen + extension flow end-to-end.

### 12.3 — Machine-translate to the other 9 locales

- [ ] For each locale in `[en, es, fr, de, it, ja, zh, ko, ru]`, produce `lib/l10n/app_<locale>.arb` via a single LLM prompt (recommended: one Claude/ChatGPT pass per locale, **input = the PT-BR ARB content**, **output = the locale ARB content**). Prompt template (copy verbatim):

  ```
  You will translate a Flutter ARB localization file from Brazilian Portuguese to <TARGET LANGUAGE / LOCALE>.

  Hard rules:
  1. Preserve every JSON key exactly as in the source.
  2. Drop every "@<key>" metadata block — those stay only in the template file.
  3. Replace "@@locale" with the target BCP-47 tag (e.g. "en", "es", "fr", "de", "it", "ja", "zh_Hans", "ko", "ru").
  4. Keep ICU placeholders, plural syntax, and brace structure intact: e.g. {count, plural, one{...} other{...}}, {total}.
  5. Do NOT translate the following — copy verbatim:
     - "1-Bit Dice" (appName)
     - "d4", "d6", "d8", "d10", "d12", "d20", "d100"
     - Game names: "Ludo", "War", "Yahtzee", "Craps", "Bunco", "Farkle", "Liar's Dice"
  6. Keep the same UPPERCASE/lowercase style for action verbs (UPPERCASE on roll/clear/confirm/cancel/close).
  7. Output the resulting JSON only — no commentary, no markdown fence.
  ```

- [ ] After generating each file, **eyeball-verify**:
  - `@@locale` matches the filename suffix.
  - All keys from `app_pt.arb` are present (excluding `@key` metadata blocks).
  - ICU placeholder syntax is intact for `rollingNDice` and `rollResultTotal`.
  - Game preset values are still in their original form.
- [ ] Run `flutter gen-l10n` and confirm no warnings about missing keys or malformed ICU.

### 12.4 — `lib/core/i18n/supported_locales.dart`

- [ ] Create a small immutable value type `SupportedLocale` and a top-level `const` list. A named class beats anonymous records here: the public surface is documented per-field and survives renames / additions cleanly. No static-only "namespace class" — that pattern trips `very_good_analysis`'s preference against utility classes; a top-level `const` is idiomatic Dart.

  Pseudo-Dart sketch:

  ```dart
  import 'package:flutter/widgets.dart';

  /// Pairs a supported [Locale] with its display name in that locale's own
  /// script ("native name") — for use in the E08 language picker.
  @immutable
  class SupportedLocale {
    const SupportedLocale({required this.locale, required this.nativeName});
    final Locale locale;
    final String nativeName;
  }

  /// All locales supported at M1 launch.
  ///
  /// Order matters for Flutter's fallback resolution:
  ///   index 0 — pt-BR (codebase default, source of truth)
  ///   index 1 — en    (global fallback, forced by localeResolutionCallback
  ///                    when the device locale matches nothing supported)
  /// Remaining entries are alphabetical by language code.
  const List<SupportedLocale> supportedLocales = [
    SupportedLocale(locale: Locale('pt', 'BR'), nativeName: 'Português (Brasil)'),
    SupportedLocale(locale: Locale('en'),       nativeName: 'English'),
    SupportedLocale(locale: Locale('de'),       nativeName: 'Deutsch'),
    SupportedLocale(locale: Locale('es'),       nativeName: 'Español'),
    SupportedLocale(locale: Locale('fr'),       nativeName: 'Français'),
    SupportedLocale(locale: Locale('it'),       nativeName: 'Italiano'),
    SupportedLocale(locale: Locale('ja'),       nativeName: '日本語'),
    SupportedLocale(locale: Locale('ko'),       nativeName: '한국어'),
    SupportedLocale(locale: Locale('ru'),       nativeName: 'Русский'),
    SupportedLocale(
      locale: Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
      nativeName: '中文（简体）',
    ),
  ];
  ```

- [ ] No `find()` helper, no `localesList` getter. Consumers needing a `List<Locale>` build it inline at the call site (only `app.dart`); the controller's "is this supported?" check is a private one-liner over `supportedLocales.any(...)`. YAGNI — E08 will introduce richer lookups if it actually needs them.

### 12.5 — `lib/core/i18n/locale_preference.dart`

- [ ] Mirror the [PalettePreference](../../lib/core/theme/palette_preference.dart) structure:
  - `abstract interface class LocalePreference { Locale? read(); Future<void> write(Locale? value); }`
  - `InMemoryLocalePreference` (default for tests / pre-init).
  - `SharedPreferencesLocalePreference(SharedPreferences prefs)`:
    - Stores `Locale.toLanguageTag()` under key `'locale_override'`.
    - `write(null)` removes the key.
    - `read()` parses via `Locale.fromSubtags` after splitting the BCP-47 tag.
    - Unknown / malformed tags return `null` (graceful, no throw).
- [ ] Document that `LocalePreference` does **not** validate against `SupportedLocales` — that's the controller's job. The preference is a dumb persistence seam.

### 12.6 — `lib/core/i18n/locale_controller.dart`

- [ ] `LocaleController extends ChangeNotifier` with the constructor signature `LocaleController({LocalePreference? preference})`:
  - Defaults `_preference` to `InMemoryLocalePreference()`.
  - In the constructor body, reads `preference?.read()` and assigns it to `_override` directly. The `SharedPreferencesLocalePreference.read()` layer already returns `null` for malformed/unparsable tags, so the only edge case left would be a *well-formed but no-longer-supported* locale — that case has no trigger in M1 (the 10-locale list is fixed) and a doc-comment + a defensive guard inside `setOverride` is enough.
- [ ] Public API:
  - `Locale? get override;`
  - `Future<void> setOverride(Locale locale)` — validates via a private `_isSupported(locale)` helper (a one-liner over `supportedLocales.any(...)`). If not supported, throws `ArgumentError` (caller bug; UI should only surface supported locales). If supported and differs from `_override`, updates field, notifies, persists.
  - `Future<void> clearOverride()` — no-op if already null; otherwise nulls, notifies, persists `null`.
- [ ] Add doc-comments matching the [ThemeProvider](../../lib/core/theme/theme_provider.dart) style.

### 12.7 — `lib/core/i18n/l10n_extension.dart`

- [ ] Single-file extension. Replace the forced unwrap with an explicit `?? throw StateError(...)` — same runtime contract, clearer failure message, no `!` for `very_good_analysis` to nag about:

  ```dart
  import 'package:flutter/widgets.dart';
  import 'package:flutter_gen/gen_l10n/app_localizations.dart';

  /// Shorthand for `AppLocalizations.of(context)` with a clear failure mode.
  ///
  /// `AppLocalizations.of` only returns null when the `AppLocalizations`
  /// delegate is missing from the surrounding `MaterialApp` — a wiring bug,
  /// not a runtime condition. Surface that as a descriptive `StateError`
  /// rather than a generic null-check failure.
  extension L10nX on BuildContext {
    AppLocalizations get l10n =>
        AppLocalizations.of(this) ??
        (throw StateError(
          'AppLocalizations missing from context. Did you forget to add '
          'AppLocalizations.localizationsDelegates to MaterialApp?',
        ));
  }
  ```

- [ ] Wiring is asserted end-to-end by the widget test in 12.9, which boots a real `MaterialApp` with the real delegates and reads `context.l10n` — if anyone removes the delegates in the future the test fails loudly.

### 12.8 — Wire `lib/app.dart`

- [ ] Convert the root from a single `ChangeNotifierProvider` to a `MultiProvider` exposing both `ThemeProvider` and `LocaleController`:

  ```dart
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
      ChangeNotifierProvider<LocaleController>(create: (_) => LocaleController()),
    ],
    child: const _AppView(),
  );
  ```

- [ ] In `_AppView.build`, watch the `LocaleController` and feed `MaterialApp`. Build `supportedLocales` inline from the const list — no separate getter needed. Use `onGenerateTitle` so the app-switcher / accessibility title reads from the ARB (`appName` is already in the template):

  ```dart
  final locale = context.watch<LocaleController>().override;
  return MaterialApp(
    onGenerateTitle: (context) => context.l10n.appName,
    theme: buildThemeData(palette),
    locale: locale,
    supportedLocales: [for (final l in supportedLocales) l.locale],
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    localeResolutionCallback: (deviceLocale, supported) {
      if (deviceLocale == null) return const Locale('en');
      return supported.firstWhere(
        (l) => l.languageCode == deviceLocale.languageCode &&
               (l.countryCode == null ||
                l.countryCode == deviceLocale.countryCode),
        orElse: () => const Locale('en'),
      );
    },
    home: const DesignSystemPreview(),
  );
  ```

- [ ] Update `main.dart` later (E04 already moved storage init out; for E13 we can wire a `SharedPreferencesLocalePreference` once we touch `main.dart`. Out of scope here — the in-memory default is correct until E08 lands).

### 12.9 — Tests

Cover everything in `lib/core/i18n/` to 100% line coverage (CLAUDE.md gate). Mirror the patterns in `test/core/theme/palette_preference_test.dart` and `test/core/theme/theme_provider_test.dart`.

- [ ] `test/core/i18n/locale_preference_test.dart`
  - `InMemoryLocalePreference`: `read()` is null initially; round-trip preserves value across all 10 supported tags; `write(null)` clears.
  - `SharedPreferencesLocalePreference`:
    - `setUp` → `SharedPreferences.setMockInitialValues({})`.
    - `read()` null when empty.
    - Round-trip for each of the 10 supported tags (parametrized loop is fine — keeps the file readable).
    - `write(null)` removes the key (`prefs.containsKey` is false after).
    - Malformed stored tag (`{'locale_override': 'not-a-tag-!!!'}`) → `read()` returns `null`, no throw.
- [ ] `test/core/i18n/locale_controller_test.dart`
  - Defaults: `override` is null when preference is empty.
  - Constructor reads valid persisted override.
  - `setOverride(supported)` updates `override`, notifies exactly once, writes to preference.
  - `setOverride(same)` is a no-op (no notify, no write).
  - `setOverride(unsupported)` throws `ArgumentError`, **and** leaves `override` unchanged, **and** does not write to preference.
  - `clearOverride()` from non-null: writes `null`, notifies exactly once.
  - `clearOverride()` from null: no-op (no notify, no write).
  - Use an inline `_RecordingPreference` that mirrors `theme_provider_test.dart:6-20`. Assert the recorded `writes` list explicitly (sequence + values) — same idiom as `palette_preference_test.dart:47`.
- [ ] `test/core/i18n/supported_locales_test.dart`
  - Exactly 10 entries.
  - PT-BR is index 0, EN is index 1.
  - All `nativeName` values non-empty.
  - `zh-Hans` entry has both `languageCode == 'zh'` and `scriptCode == 'Hans'`.
  - `SupportedLocale` is `@immutable` and equates by `locale` + `nativeName` (or document that we rely on identity — pick one and lock it in via the test).
- [ ] `test/core/i18n/l10n_extension_test.dart`
  - Widget test using `pumpWidget` of a `MaterialApp` with `LocaleController` provider + `localizationsDelegates: AppLocalizations.localizationsDelegates`.
  - Force `locale: const Locale('en')`, find a `Text` with `context.l10n.actionRoll` → expect `"ROLL"` (or the actual EN translation).
  - Force `locale: const Locale('pt', 'BR')`, repump, expect `"ROLAR"`.
  - Negative path: pump a `MaterialApp` **without** `AppLocalizations.localizationsDelegates`, read `context.l10n`, expect a `StateError` (covers the `?? throw` branch of the extension and locks the failure message contract).
  - This trio simultaneously verifies: codegen produced output, delegates are wired, override drives `MaterialApp.locale`, and the extension's happy and unhappy paths both work.
- [ ] `test/app_test.dart` — **new or extended** (whichever already exists for `ThemeProvider`):
  - Pump `App`, assert `MaterialApp` has the expected `supportedLocales` length (10) and `localizationsDelegates` includes `AppLocalizations.delegate`.
  - Directly exercise the `localeResolutionCallback` branches by constructing the closure inputs:
    - `(deviceLocale: null, supported: ...)` → returns `Locale('en')`.
    - `(deviceLocale: Locale('pt', 'BR'), supported: ...)` → returns the matching PT-BR locale.
    - `(deviceLocale: Locale('zh', 'CN'), supported: ...)` → returns the `zh-Hans` entry (language match, country differs, callback accepts).
    - `(deviceLocale: Locale('ar'), supported: ...)` → returns `Locale('en')` (no match → EN fallback).
  - This is the test that guards the **100% line coverage gate** on `lib/app.dart`'s new logic. The simplest path is to extract the callback into a top-level (or library-private) function in `app.dart` so it's directly testable; otherwise drive it via `find(MaterialApp).widget.localeResolutionCallback!(...)`.

### 12.10 — Progress tracker entries

- [ ] Update `docs/plan/progress.md > EPIC 12` to reflect the actual checklist below (replacing the abbreviated 12.1–12.6 entries):

  ```
  - [ ] 12.1 Adicionar flutter_localizations + intl + generate:true + l10n.yaml
  - [ ] 12.2 Criar lib/l10n/app_pt.arb (template) com ~29 chaves
  - [ ] 12.3 Gerar 9 ARBs traduzidos (en, es, fr, de, it, ja, zh, ko, ru) via MT
  - [ ] 12.4 lib/core/i18n/supported_locales.dart (SupportedLocale class + const list)
  - [ ] 12.5 lib/core/i18n/locale_preference.dart (interface + InMemory + SharedPreferences)
  - [ ] 12.6 lib/core/i18n/locale_controller.dart (ChangeNotifier)
  - [ ] 12.7 lib/core/i18n/l10n_extension.dart (BuildContext.l10n)
  - [ ] 12.8 Wire MultiProvider + MaterialApp.locale/delegates/resolutionCallback em lib/app.dart
  - [ ] 12.9 Testes (4 arquivos em test/core/i18n/ + test/app_test.dart) — 100% cobertura
  ```

  Drop the old "12.6 Substituir todas as strings hardcoded por `context.l10n.*` em todos os features" — that work happens organically inside E05–E08, not as a one-shot pass. (Brainstorm: design_system_preview is excluded — slated for removal in E09.)

## Acceptance Criteria

- [ ] `flutter analyze` exits 0 with zero issues.
- [ ] `flutter test --coverage` passes with 100% line coverage for all new files in `lib/core/i18n/`.
- [ ] `flutter gen-l10n` runs cleanly (no warnings about missing keys, malformed ICU, or unrecognized locales).
- [ ] All 10 ARB files exist with the same key set as the PT-BR template (minus `@` metadata blocks).
- [ ] App launches on a simulator with no locale override → renders PT-BR (system: pt-BR) and EN (system: en-US).
- [ ] Forcing a Brazilian Portuguese device to a Korean override (manually in a unit/widget test) re-renders text in Korean.
- [ ] Game preset names render identically across all 10 locales ("Ludo", "Yahtzee", "Liar's Dice" — unchanged).
- [ ] `appName` ("1-Bit Dice") renders identically across all 10 locales.
- [ ] `LocaleController.setOverride` rejects unsupported locales with an `ArgumentError`.
- [ ] `SharedPreferencesLocalePreference.read()` returns `null` (does not throw) when the stored tag is malformed.
- [ ] No new strings remain hardcoded **inside the files this epic creates**. (Hardcoded strings in pre-existing features will be migrated as those features are reimplemented in E05–E08.)

## Dependencies & Risks

### Hard dependencies

- **E04 storage layer** — already shipped. `SharedPreferences` is in the dep tree and reused as-is.
- **Flutter stable channel with `flutter_localizations` SDK** — confirmed by environment constraint `sdk: ^3.12.0` in `pubspec.yaml`.

### Risks

- **MT quality drift.** Single-prompt LLM translations can hallucinate, mistranslate game-domain terms, or drop placeholders. **Mitigation**: prompt enforces verbatim copy of game names + ICU placeholders, plus a manual eyeball pass per locale before commit. Acceptable per brainstorm decision — no human review beyond syntactic correctness.
- **`flutter gen-l10n` synthetic-package quirks in tests.** Some CI setups need `flutter gen-l10n` explicitly before `flutter test`. **Mitigation**: rely on Flutter's auto-run on `flutter pub get`; if CI fails, add an explicit `flutter gen-l10n` step.
- **`Locale.fromSubtags` parsing of stored language tags.** Persisted tags like `zh-Hans` use a hyphen-separated format that needs careful splitting to feed `scriptCode` (not just `countryCode`). **Mitigation**: the preference module parses defensively and returns `null` on any unrecognized shape. The controller's `SupportedLocales.find` then filters out non-matches.
- **`intl` version conflict.** Declaring `intl: any` defers to `flutter_localizations`. If a future direct use of `intl` (e.g. `NumberFormat`) needs a tighter constraint, we bump it then. **Mitigation**: after `flutter pub deps`, **replace `any` with the resolved caret constraint (`^x.y.z`)** before opening the PR — VGV convention prefers concrete bounds. The resolved version goes into the PR description for traceability.
- **Forgetting to add the `localizationsDelegates`.** Without them, `AppLocalizations.of(context)` returns `null` and the `?? throw StateError` in the extension fires. **Mitigation**: `l10n_extension_test.dart` has both a happy-path and a negative-path test — the negative one explicitly omits the delegates and asserts the `StateError`. Regressions are caught.

## Out of Scope (deferred to later epics)

- **Settings UI for language selection** — E08.
- **Translating strings currently inside `lib/features/_dev/design_system_preview.dart`** — that file is slated for removal in E09 per CLAUDE.md folder note; translating it is discarded work.
- **Migrating strings inside `lib/shared/widgets/*`** — most of those widgets currently render no user-visible copy; any future-visible copy will be added through `context.l10n` natively.
- **RTL locales (AR/HE)** — explicitly out of M1; would require a layout audit.
- **Per-locale number/date formatting** — `intl` is in the tree, but no E13 feature consumes `NumberFormat` yet. Wiring lives where consumers appear (likely E05 for dice totals).
- **Localized app title** (`MaterialApp.onGenerateTitle`) — cosmetic; left for E15 store-prep when localized store listings are wired.
- **Remote / OTA translation updates** — `easy_localization` style. Not needed; app vocabulary is small.

## Files Touched / Created

### Created

- `lib/l10n/app_pt.arb` (template, ~36 keys + metadata blocks)
- `lib/l10n/app_en.arb`
- `lib/l10n/app_es.arb`
- `lib/l10n/app_fr.arb`
- `lib/l10n/app_de.arb`
- `lib/l10n/app_it.arb`
- `lib/l10n/app_ja.arb`
- `lib/l10n/app_zh.arb`
- `lib/l10n/app_ko.arb`
- `lib/l10n/app_ru.arb`
- `l10n.yaml`
- `lib/core/i18n/supported_locales.dart`
- `lib/core/i18n/locale_preference.dart`
- `lib/core/i18n/locale_controller.dart`
- `lib/core/i18n/l10n_extension.dart`
- `test/core/i18n/locale_preference_test.dart`
- `test/core/i18n/locale_controller_test.dart`
- `test/core/i18n/supported_locales_test.dart`
- `test/core/i18n/l10n_extension_test.dart`

### Modified

- `pubspec.yaml` — add `flutter_localizations`, `intl` (pinned to the resolved caret version after `flutter pub deps`), `generate: true`.
- `lib/app.dart` — convert root provider to `MultiProvider`; wire `MaterialApp.locale`, `supportedLocales`, `localizationsDelegates`, `localeResolutionCallback`, `onGenerateTitle`. Extract the resolution callback to a library-private function for direct testability.
- `test/app_test.dart` — new or extended to cover `localeResolutionCallback` branches (`null` device locale, exact match, language-match-different-country, no-match → EN).
- `docs/plan/progress.md` — rewrite EPIC 12 checklist per 12.10.

### Unchanged (explicitly)

- `lib/main.dart` — `SharedPreferences.getInstance()` wiring for `LocalePreference` lands when Settings (E08) needs it; until then the in-memory default is fine.
- `lib/features/_dev/design_system_preview.dart` — slated for removal in E09; not translated.

## References

- Brainstorm: [docs/brainstorm/2026-05-26-e13-internationalization-brainstorm-doc.md](../brainstorm/2026-05-26-e13-internationalization-brainstorm-doc.md)
- Pattern to mirror — Palette preference: [lib/core/theme/palette_preference.dart](../../lib/core/theme/palette_preference.dart)
- Pattern to mirror — Theme provider: [lib/core/theme/theme_provider.dart](../../lib/core/theme/theme_provider.dart)
- Pattern to mirror — Theme preference tests: [test/core/theme/palette_preference_test.dart](../../test/core/theme/palette_preference_test.dart) and [test/core/theme/theme_provider_test.dart](../../test/core/theme/theme_provider_test.dart)
- Roadmap epic table: [docs/roadmap/08-epics-m1.md](../roadmap/08-epics-m1.md) — row E13.
- CLAUDE.md state-management constraint: "setState + ChangeNotifier + provider (DI only). No Bloc, no Riverpod."
- Flutter docs (well-established, no fetch needed): `flutter_localizations`, `flutter gen-l10n`, `intl` `NumberFormat`.
