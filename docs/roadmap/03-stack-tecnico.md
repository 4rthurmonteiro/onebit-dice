# 03 — Stack Técnico

## Framework
**Flutter** (Dart) — build único para Android + iOS.

Razões:
- Build dual (Android + iOS) com um único codebase
- Performance nativa pra animações simples e UI 2D
- Renderização pixel-perfect via `FilterQuality.none` em imagens
- Comunidade ativa, libs maduras
- Conhecimento será reusado no Call of Old Chico

## Backend / Cloud

### Firebase (apenas o essencial)
- `firebase_core` — bootstrap
- `firebase_crashlytics` — captura de crashes em produção
- `firebase_analytics` — métricas de uso anônimas
- **SEM autenticação, SEM Firestore, SEM Cloud Functions no M1**

### Eventos de Analytics (M1)
| Evento | Quando dispara |
|---|---|
| `app_open` | Abertura do app |
| `roll_dice` | Qualquer rolagem (params: dice_type, dice_count) |
| `change_palette` | Troca de paleta (param: palette_name) |
| `open_preset` | Toque em preset (param: preset_name) |
| `save_custom_preset` | Salvar preset customizado |
| `clear_history` | Limpar histórico |
| `change_animation` | Trocar estilo/velocidade de animação |
| `toggle_sound` | Liga/desliga som |
| `toggle_haptic` | Liga/desliga haptic |

## Armazenamento local

### `shared_preferences` — configurações simples
- Paleta atual
- Som on/off
- Haptic on/off
- Velocidade de animação
- Estilo de animação
- Última configuração de dado (tipo + quantidade)

### `hive` — dados estruturados
- Histórico completo de rolagens (modelo: timestamp, diceType, diceCount, results[], total)
- Presets customizados pelo usuário (modelo: name, diceType, diceCount)

## Dependências (pubspec.yaml)

### Core
```yaml
flutter:
  sdk: flutter
cupertino_icons: ^1.0.6
```

### Persistência
```yaml
shared_preferences: ^2.2.0
hive: ^2.2.3
hive_flutter: ^1.1.0
```

### Firebase
```yaml
firebase_core: ^2.24.0
firebase_crashlytics: ^3.4.8
firebase_analytics: ^10.7.4
```

### UI / utilidades
```yaml
flutter_native_splash: ^2.3.0  # gera splash automaticamente
flutter_launcher_icons: ^0.13.1  # gera ícones em todas resoluções
just_audio: ^0.9.36  # sons
```

### Animação
```yaml
flame: ^1.10.0  # opcional pra sprites - avaliar se necessário
# OU usar AnimatedBuilder nativo + sprite sheet via Image
```

### State management
- Sem dependência externa no M1. `setState` + `InheritedWidget` ou Provider básico.
- Se complicar: `riverpod` (preferência) ou `provider`.

## Estrutura de pastas

```
lib/
├── main.dart                          — entry point + Firebase init
├── app.dart                           — MaterialApp config + theme
├── core/
│   ├── theme/
│   │   ├── palette.dart               — definição das 6+ paletas
│   │   ├── typography.dart            — fontes Silkscreen, VT323, Press Start 2P
│   │   └── theme_provider.dart        — controla paleta ativa
│   ├── storage/
│   │   ├── prefs.dart                 — wrapper de shared_preferences
│   │   ├── hive_init.dart             — init e adapters
│   │   └── models/
│   │       ├── roll_entry.dart        — modelo de rolagem
│   │       └── custom_preset.dart     — modelo de preset
│   ├── audio/
│   │   └── sound_player.dart          — wrapper de just_audio
│   ├── haptic/
│   │   └── haptic_controller.dart     — wrapper de HapticFeedback
│   └── analytics/
│       └── analytics_service.dart     — wrapper de firebase_analytics
├── features/
│   ├── dice/
│   │   ├── dice_screen.dart           — tela principal de rolagem
│   │   ├── dice_controller.dart       — lógica de rolagem
│   │   ├── widgets/
│   │   │   ├── dice_widget.dart       — dado pixel art animado
│   │   │   ├── type_selector.dart     — seletor d4-d100
│   │   │   ├── quantity_selector.dart — − / + quantidade
│   │   │   └── roll_button.dart       — botão grande ROLAR
│   ├── history/
│   │   ├── history_screen.dart
│   │   └── widgets/
│   │       └── history_entry.dart
│   ├── presets/
│   │   ├── presets_screen.dart
│   │   ├── preset_data.dart           — Ludo, Banco Imob., War, etc
│   │   └── widgets/
│   │       └── preset_card.dart
│   ├── settings/
│   │   ├── settings_screen.dart
│   │   └── widgets/
│   │       ├── palette_selector.dart
│   │       ├── toggle_tile.dart
│   │       └── animation_settings.dart
│   └── splash/
│       └── splash_screen.dart
└── shared/
    ├── widgets/
    │   ├── mac_button.dart            — botão Mac-style com sombra offset
    │   ├── mac_window.dart            — janela Mac com title bar listrada
    │   ├── pixel_divider.dart         — linha horizontal 2px
    │   └── tab_bar.dart               — tab bar inferior 4 abas
    └── utils/
        └── random_dice.dart           — Random.secure() helper
```

## Assets

```
assets/
├── fonts/
│   ├── Silkscreen-Regular.ttf
│   ├── Silkscreen-Bold.ttf
│   ├── VT323-Regular.ttf
│   └── PressStart2P-Regular.ttf
├── sprites/
│   ├── dice_d6_roll.png               — sprite sheet d6 (8x8 frames)
│   ├── dice_d4_roll.png
│   ├── ...
│   └── manifest.json
└── sounds/
    ├── roll.mp3
    ├── stop.mp3
    └── total.mp3
```

## Build e assinatura

### Android
- `flutter build appbundle --release`
- Keystore de produção (gerar antes do primeiro release, guardar com cuidado — perder = recriar app)
- Bundle ID: `com.am2.onebitdice`
- Min SDK: 21 (Android 5.0)
- Target SDK: latest (35+)

### iOS
- `flutter build ipa --release`
- Apple Developer Account ($99/ano)
- Certificado de distribuição + provisioning profile
- Bundle ID: `com.am2.onebitdice`
- Min iOS: 13.0
- Target: latest

## Testes
- M1: testes manuais (smoke test em device físico).
- M2+: adicionar `flutter_test` pra unit + widget tests.

## Notas técnicas

### Aleatoriedade
```dart
import 'dart:math';
final _random = Random.secure();
int rollDie(int sides) => _random.nextInt(sides) + 1;
```

### Renderização pixel-perfect
```dart
Image.asset(
  'assets/sprites/dice_d6_roll.png',
  filterQuality: FilterQuality.none,
)
```

### Fontes pixeladas sem antialiasing
- Garantir `fontFeatures: const [FontFeature.disable('liga')]`
- Forçar baseline grid em múltiplos de 4 ou 8

### Privacidade — declaração nas lojas
- "Nenhum dado pessoal coletado"
- Analytics e Crashlytics: dados anônimos agregados apenas
- Necessário declarar no formulário de segurança de dados (Play) e App Privacy (Apple)
