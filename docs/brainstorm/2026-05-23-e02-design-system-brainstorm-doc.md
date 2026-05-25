---
title: "E02 — Design System"
date: 2026-05-23
epic: E02
status: brainstorm
---

# E02 — Design System

## Contexto

Epic de fundação visual do 1-Bit Dice. Tudo que vier depois (Home, Histórico, Presets, Ajustes) consome este sistema. O roadmap (`docs/roadmap/02-identidade-visual.md`) já fixou as **escolhas estéticas** (paletas, fontes, formas dos componentes). O brainstorm foca em **como traduzir essas decisões para Flutter** dentro das restrições do CLAUDE.md.

## O que estamos construindo

A camada de tema + os widgets base reutilizáveis pelo resto do app:

- **Paletas**: enum `PaletteId` cobrindo as 7 paletas de [02-identidade-visual.md](../roadmap/02-identidade-visual.md#paletas) — cada uma exatamente 2 cores (`ink` + `paper`), zero tons intermediários.
- **ThemeProvider**: `ChangeNotifier` com `current` (paleta ativa) + `setPalette(PaletteId)`, distribuído via `ChangeNotifierProvider` do `package:provider`.
- **Tipografia**: TextStyles em Silkscreen, VT323 e Press Start 2P (fontes locais já presentes em `assets/fonts/` e declaradas em `pubspec.yaml`).
- **Widgets base**: `MacButton`, `MacWindow`, `PixelDivider` — pixel-perfect, sem antialiasing, sem sombras suaves.
- **Wiring**: `lib/app.dart` envolve `MaterialApp` num `ChangeNotifierProvider<ThemeProvider>` + reconstrói `ThemeData` a cada troca de paleta via `context.watch`.

## Decisões tomadas

| # | Decisão | Escolha | Motivo |
|---|---|---|---|
| D1 | Distribuição do ThemeProvider | `ChangeNotifierProvider<ThemeProvider>` do `package:provider`, lido por consumers via `context.watch<ThemeProvider>()` / `context.read<ThemeProvider>()` | CLAUDE.md atualizado pra permitir `provider` como mecanismo de DI dos `ChangeNotifier`s do M1. Evita reinventar `InheritedNotifier` boilerplate; padrão idiomático Flutter; será reutilizado pelos próximos controllers (DiceController, SettingsController) |
| D2 | Integração com `ThemeData` | `ColorScheme` construído via construtor explícito (todos os slots = ink ou paper) + `ThemeExtension<OneBitColors>` com `{ink, paper}` | `ColorScheme.fromSeed` foi descartado: deriva uma paleta tonal completa, violando a regra estrita 1-bit. O construtor explícito força a gente a mapear cada slot conscientemente. A extension dá um canal limpo pros widgets custom lerem `ink`/`paper` sem ambiguidade semântica |
| D3 | Persistência da paleta | Adiada para E04 via interface `PalettePreference` | E02 fica focado no design system; sem `shared_preferences` dep. Implementação default é `InMemoryPalettePreference`. E04 troca por `SharedPrefsPalettePreference` sem refactor do ThemeProvider |
| D4 | Title bar do `MacWindow` | `CustomPaint` desenhando linhas horizontais 1px ink / 1px paper | Pixel-perfect em qualquer DPR, sem risco de smear de gradiente, ~30 LOC, repinta só quando paleta muda |
| D5 | Origem das fontes | Locais (`assets/fonts/*.ttf`), já declaradas em `pubspec.yaml` | Removida menção a `google_fonts` do plano técnico — offline-first, build determinístico |
| D6 | Estado pressionado do `MacButton` | `StatefulWidget` + `GestureDetector` (`onTapDown`/`onTapUp`/`onTapCancel`) trocando offset da sombra e posição do conteúdo | Sem InkWell (deixaria ripple Material) e sem AnimatedContainer (não queremos easing — é instantâneo, 1-bit) |
| D7 | Cobertura de testes | Widget tests para os 3 widgets base × paletas representativas (Mac Classic + Game Boy + ZX Spectrum) + unit tests para `ThemeProvider`. `_DesignSystemPreview` é marcado com `// coverage:ignore-file` (smoke-test manual) | CLAUDE.md exige 100% line coverage; goldens ficam fora do M1 pra evitar fragilidade — entram em E12+ quando o layout estabilizar |
| D8 | `MacButton` em E02 | Sem estado disabled (`onPressed` é não-nulo) | Nenhum consumer de E02 precisa de disabled (preview é descartável). Adiar a decisão de como representar disabled em 1-bit (hachura? oclusão?) pra quando o primeiro feature realmente precisar |

---

## Features destrinchadas

### F01 — Palette + PaletteId

**Arquivo:** `lib/core/theme/palette.dart`

```dart
enum PaletteId { macClassic, macBeige, gameBoy, c64, zxSpectrum, appleIIGreen, appleIIeAmber }

@immutable
class Palette {
  const Palette({required this.id, required this.name, required this.ink, required this.paper});
  final PaletteId id;
  final String name;
  final Color ink;
  final Color paper;

  static const Map<PaletteId, Palette> all = { /* 7 entries com hex de 02-identidade-visual.md */ };
  static Palette of(PaletteId id) => all[id]!;
}
```

**Critério de aceite:**
- `Palette.all` tem exatamente 7 entradas.
- Cada `Palette` tem exatamente 2 `Color` (ink + paper) — não há campo intermediário.
- Hex codes batem com os de `docs/roadmap/02-identidade-visual.md`.

---

### F02 — ThemeProvider

**Arquivos:**
- `lib/core/theme/theme_provider.dart` — `ChangeNotifier` com `current`, `setPalette(PaletteId)`.
- `lib/core/theme/palette_preference.dart` — interface `PalettePreference` + implementação `InMemoryPalettePreference` (default).

```dart
abstract class PalettePreference {
  PaletteId? read();
  Future<void> write(PaletteId id);
}

class ThemeProvider extends ChangeNotifier {
  ThemeProvider({PalettePreference? preference})
    : _preference = preference ?? InMemoryPalettePreference(),
      _current = Palette.of(preference?.read() ?? PaletteId.macClassic);

  final PalettePreference _preference;
  Palette _current;
  Palette get current => _current;

  Future<void> setPalette(PaletteId id) async {
    if (_current.id == id) return;
    _current = Palette.of(id);
    notifyListeners();
    await _preference.write(id);
  }
}
```

Distribuição: ver F08 (`ChangeNotifierProvider<ThemeProvider>` no root).

**Critério de aceite:**
- `setPalette` notifica listeners e chama `preference.write`.
- Construtor lê paleta inicial da preference (fallback `macClassic`).
- Consumers leem via `context.watch<ThemeProvider>()` e re-buildam na troca.

---

### F03 — Tipografia

**Arquivo:** `lib/core/theme/app_typography.dart`

```dart
class AppTypography {
  static const _noLiga = [FontFeature.disable('liga')];

  static const TextStyle display = TextStyle(fontFamily: 'Silkscreen',   fontSize: 24, fontFeatures: _noLiga);
  static const TextStyle body    = TextStyle(fontFamily: 'VT323',        fontSize: 18, fontFeatures: _noLiga);
  static const TextStyle micro   = TextStyle(fontFamily: 'PressStart2P', fontSize: 10, fontFeatures: _noLiga);
}
```

`TextTheme` é construído a partir desses tokens dentro de `buildThemeData(palette)`. Cor padrão sempre `palette.ink`.

> Tamanhos especiais (ex: wordmark 48px no splash) são responsabilidade do consumer — usar `AppTypography.display.copyWith(fontSize: 48)` no feature respectivo (E06). E02 só expõe os 3 estilos canônicos compartilhados.

**Critério de aceite:**
- 3 TextStyles canônicos (`display`, `body`, `micro`) cobrem os usos compartilhados do app.
- `FontFeature.disable('liga')` aplicado nos três pra evitar ligaturas no pixel art.
- Sem antialiasing extra: o engine cuida via `TextPainter` quando a fonte é bitmap-only.

---

### F04 — Theming integration

**Arquivo:** `lib/core/theme/app_theme.dart`

```dart
class OneBitColors extends ThemeExtension<OneBitColors> {
  const OneBitColors({required this.ink, required this.paper});
  final Color ink;
  final Color paper;

  @override OneBitColors copyWith({Color? ink, Color? paper}) => OneBitColors(ink: ink ?? this.ink, paper: paper ?? this.paper);
  @override OneBitColors lerp(ThemeExtension<OneBitColors>? other, double t) => this; // sem interpolação — é 1-bit
}

ThemeData buildThemeData(Palette p) => ThemeData(
  brightness: p.paper.computeLuminance() > 0.5 ? Brightness.light : Brightness.dark,
  scaffoldBackgroundColor: p.paper,
  colorScheme: ColorScheme(
    brightness: /* mesma lógica */,
    surface: p.paper, onSurface: p.ink,
    primary: p.ink, onPrimary: p.paper,
    secondary: p.ink, onSecondary: p.paper,
    error: p.ink, onError: p.paper,
  ),
  textTheme: /* derivado de AppTypography com color = p.ink */,
  extensions: const [OneBitColors(ink: ..., paper: ...)],
  splashFactory: NoSplash.splashFactory,
  highlightColor: Colors.transparent,
);
```

> ⚠ Risco de implementação: o construtor `ColorScheme(...)` exige **todos** os slots nomeados (`surface`, `onSurface`, `primary`, `onPrimary`, `secondary`, `onSecondary`, `error`, `onError`, `outline`, `outlineVariant`, `inverseSurface`, etc.). Cada um precisa ser `ink` ou `paper` — sem defaults Material vazando.

**Critério de aceite:**
- `Theme.of(context).extension<OneBitColors>()` nunca retorna null.
- Sem ripple, sem highlight Material em nenhum lugar do app.
- Todo slot obrigatório do `ColorScheme` mapeado pra `ink` ou `paper` (verificável por inspeção do código).

---

### F05 — MacButton

**Arquivo:** `lib/shared/widgets/mac_button.dart`

```dart
class MacButton extends StatefulWidget {
  const MacButton({super.key, required this.label, required this.onPressed, this.expand = false});
  final String label;
  final VoidCallback onPressed; // não-nulo em E02 (sem disabled)
  final bool expand;
  // ...
}
```

Visual:
- Borda dupla pixel 2px em `ink`.
- Sombra offset 3px sólida `ink` (sem blur).
- Background `paper`.
- Label em `AppTypography.display`, caixa alta, cor `ink`.
- **Estado pressionado**: sombra some + conteúdo desloca +3px (X e Y) — visual de "afundou".

Implementação: `GestureDetector` + `setState` num `bool _pressed`. Sombra desenhada como `Positioned` + `Container(color: ink)` deslocado.

**Critério de aceite:**
- Toques rápidos disparam `onPressed` exatamente uma vez.
- Estado pressionado é visualmente instantâneo (sem easing).
- Lê `ink`/`paper` exclusivamente de `Theme.of(context).extension<OneBitColors>()` — nenhum `Color` hardcoded no arquivo.

---

### F06 — MacWindow

**Arquivo:** `lib/shared/widgets/mac_window.dart`

```dart
class MacWindow extends StatelessWidget {
  const MacWindow({super.key, this.title, required this.child, this.onClose});
  final String? title;
  final Widget child;
  final VoidCallback? onClose;
}
```

Visual:
- Borda dupla pixel ao redor (`ink`).
- Title bar com **CustomPainter** desenhando linhas 1px ink / 1px paper.
- Title (se fornecido): label centralizado em `Silkscreen` com background `paper` num retângulo "recortando" as listras.
- Botão de fechar (opcional): quadradinho 12×12 com X dentro, alinhado à esquerda da title bar.
- Conteúdo: `child` com padding 8px em background `paper`.

**Critério de aceite:**
- Title bar nunca quebra em telas estreitas (overflow controlado).
- Linhas se mantêm pixel-perfeitas em DPR 1×, 2× e 3×.
- `onClose == null` esconde o botão de fechar.

---

### F07 — PixelDivider

**Arquivo:** `lib/shared/widgets/pixel_divider.dart`

```dart
class PixelDivider extends StatelessWidget {
  const PixelDivider({super.key, this.thickness = 2, this.padding = EdgeInsets.zero});
  final double thickness;
  final EdgeInsets padding;
  // build: Padding -> Container(height: thickness, color: ink)
}
```

**Critério de aceite:**
- `thickness` default = 2 (sem decimais).
- Cor sempre vinda de `OneBitColors.ink`.

---

### F08 — App wiring

**Arquivo:** `lib/app.dart`

> Dependência nova: adicionar `provider: ^6.1.0` em `pubspec.yaml` (`flutter pub add provider`).

```dart
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ThemeProvider>(
      create: (_) => ThemeProvider(),
      child: const _AppView(),
    );
  }
}

class _AppView extends StatelessWidget {
  const _AppView();

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeProvider>().current;
    return MaterialApp(
      title: '1-Bit Dice',
      theme: buildThemeData(palette),
      home: const _DesignSystemPreview(),
    );
  }
}
```

`_DesignSystemPreview` é uma tela manual de smoke-test: mostra `MacButton`, `MacWindow`, `PixelDivider` e uma faixa com as 7 paletas tocáveis para validar troca em runtime via `context.read<ThemeProvider>().setPalette(...)`. Não é tela de produção — vai ser substituída em E05/E09. Arquivo marcado com `// coverage:ignore-file` (smoke-test manual, não entra na suite automatizada).

**Critério de aceite:**
- `flutter run` mostra a preview funcionando.
- Tap num chip de paleta troca a paleta em tempo real (sem flash de cor).
- `Theme.of(context).extension<OneBitColors>()` retorna a paleta nova após a troca.

---

## Ordem de implementação

F01 → F03 → F04 → F02 → F05 → F07 → F06 → F08.

(F05/F06/F07 consomem `OneBitColors` via `Theme.of(context).extension<...>()` — todos dependem de F04.)

---

## O que NÃO está em E02

- Persistência da paleta selecionada — vai para **E04 (Storage)** via `SharedPrefsPalettePreference`.
- Tab bar inferior (`RetroTabBar`) e shell de navegação — vão para **E09 (Navegação)** porque dependem de ícones pixel art ainda inexistentes.
- Toggle/Checkbox Mac-style — vão para **E08 (Ajustes)** onde realmente são usados.
- Localização das strings da preview — strings em PT-BR direto no código (preview é descartável); i18n entra em **E12**.
- Sprite sheets dos dados — **E12/E14** (animação + assets).
- Golden tests — fora do M1 (fragilidade vs. ganho).

---

## Open Questions

- **Wordmark "1-BIT DICE" no splash**: a fonte Silkscreen em 48px+ pixela bem em qualquer densidade? Validar manualmente no device em E06 (Splash) antes de gravar como decisão.
- **Listras da title bar em paletas low-contrast** (Apple //e Amber, Commodore 64): 1px/1px pode ficar visualmente "pesado" demais. Se aparecer feio na preview, considerar 1px ink / 2px paper como variante.

---

## Critérios de aceite do EPIC

- [ ] `lib/core/theme/` contém `palette.dart`, `theme_provider.dart`, `palette_preference.dart`, `app_typography.dart`, `app_theme.dart`.
- [ ] `lib/shared/widgets/` contém `mac_button.dart`, `mac_window.dart`, `pixel_divider.dart`.
- [ ] `pubspec.yaml` declara `provider: ^6.1.0`.
- [ ] `lib/app.dart` aplica o tema reativo via `ChangeNotifierProvider<ThemeProvider>` + `context.watch`.
- [ ] Preview manual (`flutter run`) permite trocar entre as 7 paletas em runtime.
- [ ] `flutter analyze` com zero issues.
- [ ] `flutter test --coverage` com 100% line coverage em todos os arquivos novos (`_DesignSystemPreview` marcado com `// coverage:ignore-file`).
