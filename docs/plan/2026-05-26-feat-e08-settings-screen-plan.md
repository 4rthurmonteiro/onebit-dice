---
title: "feat: e08 settings screen"
type: feat
date: 2026-05-26
epic: E08
status: planned
---

# feat: e08 settings screen — Standard

## Overview

Entrega a tela de **Ajustes** do 1-Bit Dice — cinco seções compostas a partir dos controllers já existentes:

1. **Aparência** — grid de 7 swatches para troca instantânea de paleta (consome `ThemeProvider`).
2. **Feedback** — toggles de Som e Vibração (consomem `AudioController` + `HapticController`).
3. **Animação** — seleção de estilo (Rápida / Tambor / Tabuleiro) e velocidade (Rápido / Médio / Longo); persistência via novo `AnimationSettingsController` (espelha `AudioController`).
4. **Idioma** — seletor com 10 idiomas + "Seguir sistema" (consome `LocaleController`).
5. **Sobre** — versão do app + estúdio (lê `lib/core/app_info.dart`).

Zero código de domínio novo de áudio/háptico/tema/locale — todos já existem desde E10 (áudio+háptico), E02 (tema) e E13 (i18n). A única peça *core* nova é `AnimationSettingsController`, que segue o padrão dos demais (`ChangeNotifier` + leitura/escrita atômica via `AppSettingsPreference`).

Toda a UI respeita a regra de paleta 2 cores (`ink` + `paper`) — nenhum tom intermediário, nenhum sombreado. Swatches usam o `paper` da paleta com borda `ink` de 2px; toggles usam o checkbox Mac-style `□`/`X` puramente desenhado em `CustomPaint` (mesmo padrão de [PixelIcon](../../lib/shared/widgets/pixel_icon.dart)).

## Problem Statement / Motivation

Hoje o app:

- **Não expõe** ao usuário nenhuma das preferências persistidas. Paleta, som, vibração, idioma e animação só seguem o default — `setPalette`, `setSoundEnabled`, `setHapticEnabled`, `setOverride`, e os campos `animationStyle`/`animationSpeed` de [AppSettingsPreference](../../lib/core/storage/app_settings_preference.dart) nunca são chamados a partir da UI.
- Já tem [SettingsScreen stub](../../lib/features/settings/settings_screen.dart) renderizando "EM BREVE" desde E09. A aba Ajustes existe no `RetroTabBar` mas é uma tela vazia.
- Já tem as chaves de l10n para `settingsSectionAppearance`, `settingsSectionFeedback`, `settingsSectionAnimation`, `settingsSectionLanguage`, `settingsSectionAbout` (adicionadas em E13). Faltam só os rótulos terminais (nomes de paleta, labels de toggle, labels de estilo/velocidade, label "Versão").

Sem E08, M1 não fecha: o roadmap exige paleta trocável, toggles funcionais, animação configurável.

A decisão de **incluir o seletor de idioma e a seção Sobre** (além do escopo original do roadmap E08, que listava só paleta/toggles/animação) foi tomada nesta sessão de planejamento: as chaves de l10n já estão lá, o `LocaleController` está pronto desde E13, e a alternativa seria criar uma issue separada — overhead desnecessário para duas seções triviais.

## Proposed Solution

```
lib/features/settings/
├── animation_settings_controller.dart  # NEW — ChangeNotifier (style + speed)
├── settings_screen.dart                # REWRITE — compõe 5 seções
└── widgets/
    ├── settings_section.dart           # NEW — header + child
    ├── palette_selector.dart           # NEW — grid 7 swatches
    ├── toggle_tile.dart                # NEW — Mac-style checkbox tile
    ├── animation_section.dart          # NEW — radios style + speed
    ├── language_picker.dart            # NEW — list of supportedLocales
    └── about_section.dart              # NEW — version + studio

test/features/settings/
├── animation_settings_controller_test.dart
├── settings_screen_test.dart
└── widgets/
    ├── settings_section_test.dart
    ├── palette_selector_test.dart
    ├── toggle_tile_test.dart
    ├── animation_section_test.dart
    ├── language_picker_test.dart
    └── about_section_test.dart

lib/app.dart                            # MODIFY — provide AnimationSettingsController
lib/l10n/app_pt_BR.arb                  # MODIFY — add ~22 new keys
lib/l10n/app_*.arb (10 locales)         # MODIFY — translate new keys
```

### Layered responsibility map

| Componente | Responsabilidade | Não responsabiliza-se por |
|---|---|---|
| `AnimationSettingsController` | `ChangeNotifier`. Lê `animationStyle`/`animationSpeed` do `AppSettingsPreference` no construtor (defaults `AnimationStyle.drum` + `AnimationSpeed.medium` quando `null` — espelha `docs/roadmap/01-escopo-m1.md` linhas 80–84). Expõe `setStyle()` + `setSpeed()` que persistem + notificam. | Renderizar a animação (isso é E12) |
| `SettingsSection` | Renderiza um título de seção (`PixelDivider` ou faixa listrada Mac-style) + o `child`. Reutilizado pelas 5 seções. | Lógica de negócio; consumir providers |
| `PaletteSelector` | Grid 4×2 (7 swatches + 1 célula vazia OU 3×3 com 7+2 vazias) de `PaletteSwatch`. Cada swatch é um botão tappable: borda dupla `ink`, fundo `paper` da paleta target. Swatch ativo ganha glifo `✓` ou inversão de cor. Lê `ThemeProvider.current.id`, chama `setPalette` no tap. | Persistência (`ThemeProvider` cuida); animação |
| `ToggleTile` | Linha com label à esquerda, checkbox Mac-style `□`/`X` à direita (CustomPaint, 2px borda). Recebe `value: bool` + `onChanged: ValueChanged<bool>`. Sem estado interno. | Persistência (callback dispara) |
| `AnimationSection` | Dois grupos: radios de estilo (3 opções) + radios de velocidade (3 opções). Cada radio é um `Row` com glifo `●`/`○` (CustomPaint) + label. Lê `AnimationSettingsController.style`/`.speed`, chama `setStyle`/`setSpeed`. | Renderizar animação |
| `LanguagePicker` | Lista com "Seguir sistema" no topo + os 10 `supportedLocales`. Item ativo recebe glifo `✓`. Lê `LocaleController.override`, chama `setOverride`/`clearOverride`. Display: `nativeName` de `SupportedLocale`. | Carregamento de delegates |
| `AboutSection` | Texto plano com `kStudioName` + `kAppVersion`. Layout: "1-Bit Dice" / "v{kAppVersion}" / "AM2 Studio" (linhas separadas, font Silkscreen). | Pegar dados de pacote em runtime — usa as constantes hard-coded em [app_info.dart](../../lib/core/app_info.dart) |
| `SettingsScreen` | `Scaffold` + `SingleChildScrollView` + `Column` das 5 `SettingsSection`. AppBar com `context.l10n.settingsTitle`. Lê os controllers via `context.watch`. | Lógica de negócio (delega aos controllers) |

### Sequence: usuário toca em um swatch de paleta

```
PaletteSelector       ThemeProvider          PalettePreference         MaterialApp
      │                     │                       │                       │
      │ setPalette(gameBoy) │                       │                       │
      ├────────────────────▶│                       │                       │
      │                     │ _current = ...       │                       │
      │                     │ notifyListeners()    │                       │
      │                     │──────────────────────────────────────────────▶│
      │                     │                       │                       │ rebuild theme
      │                     │ await prefs.write(gameBoy)                    │
      │                     ├──────────────────────▶│                       │
```

UX > durabilidade: o `notifyListeners()` precede o `await preference.write` (mesmo padrão de `AudioController.setSoundEnabled`).

## Acceptance criteria

- [ ] `AnimationSettingsController` lê style/speed no construtor com defaults sensatos; `setStyle`/`setSpeed` são no-op quando valor já é o atual; persistem + notificam quando mudam
- [ ] `SettingsScreen` renderiza 5 seções (Appearance, Feedback, Animation, Language, About) em ordem e usa l10n para títulos e rótulos
- [ ] Tocar em swatch de paleta troca o tema instantaneamente; swatch ativo é visualmente distinto
- [ ] Toggles de Som e Vibração refletem o estado do controller e persistem no tap
- [ ] Radios de estilo de animação e velocidade refletem o controller e persistem no tap
- [ ] Language picker oferece "Seguir sistema" + 10 idiomas; selecionar troca o locale do `MaterialApp` em tempo real
- [ ] Seção Sobre exibe versão e estúdio
- [ ] Zero terceira cor; zero gradiente; zero sombra; zero anti-aliasing
- [ ] 100% line coverage em todo o código novo
- [ ] `flutter analyze` zero issues
- [ ] Testes goldens NÃO são adicionados (fora do escopo de M1)

## Tasks

Cada checkbox é um commit lógico. Ralph pode agrupar 2-3 num mesmo commit quando o feedback loop fizer sentido (e.g. widget + teste).

- [ ] **T1** Adicionar 22 novas chaves em `lib/l10n/app_pt_BR.arb` (template) — ver [§ i18n delta](#i18n-delta) abaixo
- [ ] **T2** Traduzir as 22 chaves nos 10 ARBs restantes (en, de, es, fr, it, ja, ko, ru, zh-Hans, pt — pt é fallback que pode apenas reusar o template)
- [ ] **T3** Rodar `flutter gen-l10n` (ou `flutter pub get` que dispara o codegen) e verificar que `lib/l10n/app_localizations*.dart` regeneram sem erro
- [ ] **T4** `lib/features/settings/animation_settings_controller.dart` + teste 100%
- [ ] **T5** Wiring: registrar `ChangeNotifierProvider<AnimationSettingsController>` em `lib/app.dart` (com `Provider<AppSettingsPreference>` se ainda não existir; ver § Wiring)
- [ ] **T6** `lib/features/settings/widgets/settings_section.dart` + teste
- [ ] **T7** `lib/features/settings/widgets/toggle_tile.dart` (CustomPaint do `□`/`X`) + teste — incluir teste de tap callback e teste de render do ícone em estado on/off
- [ ] **T8** `lib/features/settings/widgets/palette_selector.dart` + teste — incluir teste de tap em cada swatch (parametrizado por `PaletteId`) e de marcação visual do ativo
- [ ] **T9** `lib/features/settings/widgets/animation_section.dart` + teste — radios para `AnimationStyle` (3) + `AnimationSpeed` (3); usar `Semantics` com `selected`
- [ ] **T10** `lib/features/settings/widgets/language_picker.dart` + teste — "Seguir sistema" no topo, depois `supportedLocales`; testa `setOverride` para um locale e `clearOverride` para "Seguir sistema"
- [ ] **T11** `lib/features/settings/widgets/about_section.dart` + teste — assert que `kAppVersion` + `kStudioName` aparecem
- [ ] **T12** Reescrever `lib/features/settings/settings_screen.dart` — compõe as 5 seções em `SingleChildScrollView`. Apaga o stub "EM BREVE"
- [ ] **T13** `test/features/settings/settings_screen_test.dart` — testa render das 5 seções + smoke de cada interação (não duplicar testes de widget filho)
- [ ] **T14** Atualizar `progress.md` — marcar EPIC 11 (1–5) como `[x]` e adicionar bloco de notas referenciando este plano
- [ ] **T15** `flutter analyze` zero issues + `very_good test --coverage --min-coverage 100` (`feedback.sh --all`)

## Implementation details

### AnimationSettingsController

```dart
// lib/features/settings/animation_settings_controller.dart
class AnimationSettingsController extends ChangeNotifier {
  AnimationSettingsController({required AppSettingsPreference preference})
    : _preference = preference,
      _style = preference.readAnimationStyle() ?? AnimationStyle.drum,
      _speed = preference.readAnimationSpeed() ?? AnimationSpeed.medium;

  final AppSettingsPreference _preference;
  AnimationStyle _style;
  AnimationSpeed _speed;

  AnimationStyle get style => _style;
  AnimationSpeed get speed => _speed;

  Future<void> setStyle(AnimationStyle value) async {
    if (_style == value) return;
    _style = value;
    notifyListeners();
    await _preference.writeAnimationStyle(value);
  }

  Future<void> setSpeed(AnimationSpeed value) async {
    if (_speed == value) return;
    _speed = value;
    notifyListeners();
    await _preference.writeAnimationSpeed(value);
  }
}
```

Defaults `drum`/`medium` espelham o roadmap M1 (`docs/roadmap/01-escopo-m1.md` linhas 80–84: paleta Mac Classic, som ON, haptic ON, velocidade Médio, estilo Tambor). O usuário pode reduzir para `fast` ou aumentar para `tabletop` via Settings.

### ToggleTile

CustomPaint do checkbox: quadrado de 18×18 com borda 2px `ink`, vazio quando `value == false`, com glifo `X` (duas linhas 2px) quando `true`. Mesmo padrão do `PixelIcon` em [pixel_icon.dart](../../lib/shared/widgets/pixel_icon.dart) — lê `OneBitColors.ink` via `Theme.of(context).extension<OneBitColors>()!`.

Sem `Switch` material — viola a regra de 2 cores (Switch tem trilha cinza intermediária).

### PaletteSelector

Layout: `Wrap` com `runSpacing: 8` e `spacing: 8`, cada swatch é `SizedBox(48, 48)` com borda 2px `ink` + fundo `paper` da paleta target. Swatch ativo tem um glifo `✓` ou inversão (ink/paper trocados).

`Semantics(button: true, selected: isActive, label: palette.name)` em cada swatch.

### LanguagePicker

`Column` com:
1. `LanguageRow(label: context.l10n.settingsLanguageFollowSystem, selected: override == null, onTap: () => controller.clearOverride())`
2. Para cada `entry in supportedLocales`: `LanguageRow(label: entry.nativeName, selected: override == entry.locale, onTap: () => controller.setOverride(entry.locale))`

Glifo `✓` à direita do label quando `selected`. Mesma CustomPaint do checkbox em `ToggleTile`, só que sem o quadrado.

### SettingsScreen

```dart
@override
Widget build(BuildContext context) {
  final colors = Theme.of(context).extension<OneBitColors>()!;
  final l10n = context.l10n;
  return Scaffold(
    backgroundColor: colors.paper,
    appBar: AppBar(title: Text(l10n.settingsTitle)),
    body: SingleChildScrollView(
      child: Column(
        children: [
          SettingsSection(
            title: l10n.settingsSectionAppearance,
            child: const PaletteSelector(),
          ),
          SettingsSection(
            title: l10n.settingsSectionFeedback,
            child: Column(
              children: [
                ToggleTile(
                  label: l10n.settingsToggleSound,
                  value: context.watch<AudioController>().soundEnabled,
                  onChanged: (v) =>
                      context.read<AudioController>().setSoundEnabled(value: v),
                ),
                ToggleTile(
                  label: l10n.settingsToggleHaptic,
                  value: context.watch<HapticController>().hapticEnabled,
                  onChanged: (v) =>
                      context.read<HapticController>().setHapticEnabled(value: v),
                ),
              ],
            ),
          ),
          SettingsSection(
            title: l10n.settingsSectionAnimation,
            child: const AnimationSection(),
          ),
          SettingsSection(
            title: l10n.settingsSectionLanguage,
            child: const LanguagePicker(),
          ),
          SettingsSection(
            title: l10n.settingsSectionAbout,
            child: const AboutSection(),
          ),
        ],
      ),
    ),
  );
}
```

## i18n delta

Adicionar em `lib/l10n/app_pt_BR.arb` (template), e traduzir para os 10 outros ARBs:

| Key | pt-BR |
|---|---|
| `settingsToggleSound` | Som |
| `settingsToggleHaptic` | Vibração |
| `settingsAnimationStyleLabel` | Estilo |
| `settingsAnimationStyleFast` | Rápida |
| `settingsAnimationStyleDrum` | Tambor |
| `settingsAnimationStyleTabletop` | Tabuleiro |
| `settingsAnimationSpeedLabel` | Velocidade |
| `settingsAnimationSpeedFast` | Rápido |
| `settingsAnimationSpeedMedium` | Médio |
| `settingsAnimationSpeedSlow` | Longo |
| `settingsAboutVersion` | Versão |
| `settingsAboutStudio` | AM2 Studio |
| `paletteMacClassic` | Mac Classic |
| `paletteMacBeige` | Mac Beige |
| `paletteGameBoy` | Game Boy DMG |
| `paletteC64` | Commodore 64 |
| `paletteZxSpectrum` | ZX Spectrum |
| `paletteAppleIIGreen` | Apple II Green |
| `paletteAppleIIeAmber` | Apple //e Amber |

Total: **19 chaves novas**. As 3 chaves "estilo" + 3 "velocidade" superam a duplicação com `AnimationStyle.label`/`AnimationSpeed.label` — esses fields hard-coded em pt-BR devem ser removidos no mesmo PR (a UI passa a depender exclusivamente do l10n).

Cada chave segue o padrão dos ARBs existentes:
```json
"settingsToggleSound": "Som",
"@settingsToggleSound": {
  "description": "Toggle label for SFX in Settings"
},
```

## Wiring changes (lib/app.dart)

Hoje `lib/app.dart` não injeta `AppSettingsPreference` no `MultiProvider` — `AudioController` e `HapticController` recebem instâncias criadas em `lib/main.dart`. Para `AnimationSettingsController`, replicar o mesmo padrão: criar em `main.dart`, passar via construtor de `App`.

```dart
// lib/app.dart
class App extends StatelessWidget {
  const App({
    required this.audioController,
    required this.hapticController,
    required this.animationSettingsController,  // NEW
    super.key,
  });

  final AudioController audioController;
  final HapticController hapticController;
  final AnimationSettingsController animationSettingsController;  // NEW

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ... existentes
        ChangeNotifierProvider<AnimationSettingsController>.value(
          value: animationSettingsController,
        ),
      ],
      child: const _AppView(),
    );
  }
}
```

`lib/main.dart` ganha uma linha de construção do controller (igual ao padrão de `AudioController`). `main.dart` é `coverage:ignore-file` então não conta para o gate de cobertura.

## Out of scope

- Animação real dos dados — isso é E12 (`AnimationSettingsController` apenas persiste a preferência; quem consome para renderizar é o DiceWidget em E12).
- Goldens de paleta — fora do M1.
- Toggle "tema escuro" — não existe; toda paleta já é 2-color.
- Botão "resetar para defaults" — não pedido, YAGNI.
- Reordenação/exclusão de paletas — fora do escopo.
- Personalização de cores — viola a regra 2-color.

## Risks

- **AnimationStyle.label / AnimationSpeed.label hard-coded em pt-BR** vs. l10n keys: remover os fields evita drift, mas é uma quebra leve da API pública dessas enums. Mitigação: ambos os enums só são usados em storage (que persiste `.index`) e neste novo `AnimationSection` (que passa a usar l10n). Nenhum outro consumer. Confirmado via `grep -rn "AnimationStyle\\..*label\\|AnimationSpeed\\..*label" lib test`.
- **Paleta names**: similar argumento. Hoje `Palette.name` é usado só em testes e como rótulo no swatch. Decisão deste plano: manter `Palette.name` como fallback para debug/testes mas o `PaletteSelector` lê o nome via l10n. Sem mudança no `Palette`.
- **Reorder de `supportedLocales`**: o `LanguagePicker` reordenará "Seguir sistema" para o topo; mantém o resto na ordem natural de `supportedLocales` (que é pt-BR, en, depois alfabético). Nenhum risco.

## References

- [docs/roadmap/08-epics-m1.md](../roadmap/08-epics-m1.md) — E08 line item
- [docs/roadmap/03-stack-tecnico.md](../roadmap/03-stack-tecnico.md) — file layout for `lib/features/settings/`
- [lib/core/theme/theme_provider.dart](../../lib/core/theme/theme_provider.dart) — pattern reference for the controller
- [lib/core/audio/audio_controller.dart](../../lib/core/audio/audio_controller.dart) — pattern reference for setX persistence ordering
- [lib/core/storage/app_settings_preference.dart](../../lib/core/storage/app_settings_preference.dart) — storage backing animation style/speed
- [lib/core/storage/models/animation_settings.dart](../../lib/core/storage/models/animation_settings.dart) — `AnimationStyle` / `AnimationSpeed` enums
- [docs/plan/2026-05-26-feat-e10-audio-haptic-plan.md](2026-05-26-feat-e10-audio-haptic-plan.md) — closest sibling plan
- [docs/plan/2026-05-26-feat-e13-internationalization-plan.md](2026-05-26-feat-e13-internationalization-plan.md) — LocaleController consumed by the language picker
