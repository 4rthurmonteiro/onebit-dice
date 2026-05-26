---
date: 2026-05-26
topic: e10-audio-haptic
---

# E10 — Áudio & Haptic

## What We're Building

A camada de feedback sensorial do 1-Bit Dice: três SFX curtos (`roll`, `stop`, `total`) tocados nos eventos da rolagem, e vibração háptica na ação principal. Ambos com toggles independentes em Ajustes, persistidos via `AppSettingsPreference` (que já expõe `soundEnabled` e `hapticEnabled`).

A engine de áudio é `flutter_soloud` (não `just_audio`). O ciclo de vida do app é observado pelo `AudioController` para cortar SFX em voo quando o app sai do foreground.

## Why This Approach

**Por que `flutter_soloud`?** Engine nativa baseada em miniaudio + SoLoud C++, voltada a games/SFX. Latência baixa, suporte a sobreposição (cada `play()` retorna um `SoundHandle` independente), `LoadMode.memory` ideal para samples curtos. `just_audio` é orientado a streaming/podcast — pesado para o caso.

**Por que `AudioController` como `ChangeNotifier` (em vez de um `SoundPlayer` plano)?**
A UI de Ajustes precisa reagir ao toggle, e o ciclo de vida (paused/resumed) precisa de um observador vivo no widget tree. Centralizar isso num `ChangeNotifier` orquestrador, espelhando o padrão do `ThemeProvider`, deixa o `SoLoudSoundPlayer` puro (só sabe tocar/parar) e isola a lógica de estado num único lugar.

**Por que escopo mínimo de audio focus (sem `audio_session`)?**
M1 não tem música de fundo nem precisa duckar/pausar para Spotify. Adicionar `audio_session` agora é YAGNI. Aceitamos: no iOS, switch de mute silencia o app; no Android, SFX podem tocar por cima de uma ligação. Trade-off explícito; reavaliar se feedback de usuário cobrar.

## Key Decisions

- **Engine de áudio: `flutter_soloud` 4.x.** Latência baixa, ideal para SFX. Substitui `just_audio` mencionado no roadmap original.
- **Sem `audio_session` no M1.** Trade-off documentado: iOS pode mutar via switch, Android pode sobrepor ligação. YAGNI até reclamação real.
- **`AudioController extends ChangeNotifier`** orquestra: `SoundPlayer` (engine), `AppSettingsPreference` (persistência), `WidgetsBindingObserver` (lifecycle). Espelha o padrão `ThemeProvider`.
- **`HapticController extends ChangeNotifier`**, padrão simétrico ao `AudioController` mas sem lifecycle e sem init assíncrono (haptic é instantâneo, wrapper sobre `HapticFeedback.mediumImpact`).
- **`SoundPlayer` é uma interface (`abstract interface class`).** Implementação produção: `SoLoudSoundPlayer`. Permite fake em testes sem invocar o binário nativo. Mantém o `AudioController` testável sem mocktail acoplado ao SoLoud.
- **Lifecycle: stop-all em `paused`/`inactive`/`hidden`, no-op em `resumed`.** Engine SoLoud permanece inicializado o tempo todo. SFX são one-shot — não há nada para "retomar". Implementado via `WidgetsBindingObserver.didChangeAppLifecycleState`.
- **Init assíncrono via splash (alinhar com Hive).** `AudioController.init()` é exposto e chamado durante a splash screen (E09 — Navegação inclui splash). Para o desenvolvimento de E10, a chamada pode ficar temporariamente em `main.dart` (`WidgetsFlutterBinding.ensureInitialized()` + await + `runApp()`) e migrar quando E09 entrar.
- **Assets em `.mp3` (segue roadmap).** Carregados com `LoadMode.memory, autoDispose: false` — decode acontece uma vez no init, sem custo por play. 3 placeholders em `assets/sounds/` (`roll.mp3`, `stop.mp3`, `total.mp3`). Substituição por arquivos reais permanece bloqueada (humano) conforme task 4.4 do progress.
- **DI no `lib/app.dart` via `MultiProvider`.** Coexistir com `ChangeNotifierProvider<ThemeProvider>`; adicionar `ChangeNotifierProvider<AudioController>` e `ChangeNotifierProvider<HapticController>`.
- **Toggle flow:** Settings UI lê `context.watch<AudioController>().soundEnabled` para exibir. Ao togglar, chama `audioController.setSoundEnabled(value)`, que internamente escreve em `AppSettingsPreference` E aplica no `SoundPlayer`. Mesma simetria para haptic.
- **Hidratação inicial:** `AudioController` lê o flag corrente de `AppSettingsPreference` no construtor (default `true` se `null`). Idem para `HapticController`.
- **Pegadinhas SoLoud:**
  - `play()` é síncrono em 4.x e retorna `SoundHandle`.
  - `autoDispose: false` obrigatório no `loadAsset` (senão o source é descartado após primeiro play).
  - Strip Style do Xcode = "Non-Global Symbols" no archive iOS (configurar quando E15 entrar).
  - Hot restart em dev pode orfanar a thread nativa — defensivo: `deinit()` antes de `init()` se já inicializado.
- **Cobertura 100%:** atingida testando `AudioController` e `HapticController` com fakes (`_FakeSoundPlayer implements SoundPlayer`) — segue o padrão de `_RecordingPreference` nos testes existentes. `SoLoudSoundPlayer` em si requer um seam fino: as 4-5 chamadas a `SoLoud.instance` ficam atrás de uma interface interna `SoLoudGateway` (ou são testadas indiretamente em integration tests). **Decisão default:** introduzir um `SoLoudGateway` mínimo para preservar 100% de cobertura unitária. Reavaliar se for excesso de mock para pouco código.

## Estrutura proposta

```
lib/core/
├── audio/
│   ├── sound_player.dart            # abstract interface SoundPlayer
│   ├── soloud_sound_player.dart     # impl produção
│   ├── soloud_gateway.dart          # seam fino sobre SoLoud.instance
│   └── audio_controller.dart        # ChangeNotifier + lifecycle
└── haptic/
    └── haptic_controller.dart       # ChangeNotifier simples

test/core/
├── audio/
│   ├── audio_controller_test.dart
│   └── soloud_sound_player_test.dart
└── haptic/
    └── haptic_controller_test.dart

assets/sounds/
├── roll.mp3    # placeholder
├── stop.mp3    # placeholder
└── total.mp3   # placeholder
```

## Tasks (substituem 4.1–4.4 do progress.md)

1. Adicionar `flutter_soloud: ^4.0.6` ao `pubspec.yaml`; `flutter pub get`.
2. Criar `lib/core/audio/sound_player.dart` (interface) + `lib/core/audio/soloud_gateway.dart` (seam) + `lib/core/audio/soloud_sound_player.dart` (impl).
3. Criar `lib/core/audio/audio_controller.dart` (`ChangeNotifier` + `WidgetsBindingObserver`).
4. Criar `lib/core/haptic/haptic_controller.dart` (`ChangeNotifier` wrappando `HapticFeedback.mediumImpact`).
5. Criar placeholders `assets/sounds/roll.mp3`, `stop.mp3`, `total.mp3` (silêncio ou tones temporários).
6. Wirear `MultiProvider` em `lib/app.dart` com os dois novos controllers + ajustar `main.dart` para `init()` temporário (movido para splash em E09).
7. Testes: `audio_controller_test.dart`, `haptic_controller_test.dart`, `soloud_sound_player_test.dart` — todos com fakes inline. 100% cobertura.
8. Atualizar `progress.md`: substituir referências a `just_audio` por `flutter_soloud`; expandir tasks conforme acima.

## Open Questions

- **Volume default e haptic intensity:** assumir `1.0` no SoLoud e `HapticFeedback.mediumImpact` por enquanto. Ajustes pode expor controle fino em iteração futura — fora do escopo de E10.
- **SoLoudGateway vs mocktail direto:** o seam interno é a opção que escolhi para preservar 100% cobertura limpa; se a equipe achar overkill, alternativa é mocktail em `SoLoud` (que é `interface class` em 4.x) — decidir no `/plan-technical-review`.
- **Behaviour em hot restart (dev only):** chamar `deinit()` defensivo antes de `init()` resolve, mas precisa ser testado manualmente — flag para QA da E10.
- **Substituição dos `.mp3` reais (task 4.4):** permanece bloqueada (`[!]`) — depende de produção dos assets de áudio.
