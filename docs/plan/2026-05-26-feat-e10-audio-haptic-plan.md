---
title: "feat: e10 audio and haptic"
type: feat
date: 2026-05-26
epic: E10
status: planned
---

# feat: e10 audio and haptic — Standard

## Overview

Entrega a camada de feedback sensorial do 1-Bit Dice — três SFX curtos (`roll`, `stop`, `total`) tocados nos eventos da rolagem, e vibração háptica na ação principal. Ambos com toggles independentes (já persistidos via `AppSettingsPreference.readSoundEnabled` / `readHapticEnabled` da E04), reativos à UI, e respeitando o ciclo de vida do app.

Engine de áudio: **`flutter_soloud` 4.x** (substitui `just_audio` mencionado no roadmap original). O ciclo de vida do app é observado por `AudioController` para parar SFX em voo quando o app sai do foreground. Ambos `AudioController` e `HapticController` são `ChangeNotifier`s expostos via `provider`, espelhando o padrão de [ThemeProvider](../../lib/core/theme/theme_provider.dart).

Esta epic é puramente *core* — zero UI nova. As features de Settings (E11), Dice (E08) e Splash (E06) consumirão os controllers via `context.watch` / `context.read` em epics posteriores. Este plano apenas garante que os controllers existem, estão testados a 100% e estão registrados no `MultiProvider` em `lib/app.dart`.

O brainstorm ([2026-05-26-e10-audio-haptic-brainstorm-doc.md](../brainstorm/2026-05-26-e10-audio-haptic-brainstorm-doc.md)) capturou todas as decisões arquiteturais (engine, padrão `ChangeNotifier`, seam `SoLoudGateway`, ausência de `audio_session`, lifecycle). Este plano transforma essas decisões em um checklist file-by-file com cobertura 100%.

## Problem Statement / Motivation

Hoje o app:

- Não emite **nenhum feedback sensorial** durante a rolagem. O toque no botão "ROLAR" é mudo, e a transição número-final não tem destaque audível.
- Já persiste os flags `soundEnabled` e `hapticEnabled` em [AppSettingsPreference](../../lib/core/storage/app_settings_preference.dart), mas **nada lê ou aplica esses flags** — a UI de Settings (E11) precisará de um controlador vivo para refletir e mutar o estado.
- `progress.md` lista 4.1–4.4 com placeholders ainda usando `just_audio` — desatualizado em relação à decisão do brainstorm.

Sem E10, as features de E08 (Dice) e E11 (Settings) não podem fechar com os requisitos do M1 (3 SFX + 1 háptico + 2 toggles persistentes).

A escolha de `flutter_soloud` sobre `just_audio` evita peso desnecessário: SoLoud é uma engine nativa baseada em miniaudio + SoLoud C++, otimizada para SFX de jogo (latência baixa, sobreposição via `SoundHandle`, `LoadMode.memory` para samples curtos). `just_audio` é orientado a streaming/podcast.

A escolha por `ChangeNotifier`-as-orquestrador (em vez de um `SoundPlayer` plano) centraliza três responsabilidades — engine, persistência, lifecycle — num único ponto, mantendo `SoLoudSoundPlayer` puro (só sabe tocar/parar). Espelha o padrão do `ThemeProvider`, que já é familiar à equipe.

## Proposed Solution

Quatro arquivos de produção em `lib/core/audio/` + `lib/core/haptic/`, com fakes inline para testes. Wiring no `MultiProvider` de [lib/app.dart](../../lib/app.dart) e init temporário em `lib/main.dart` (movido para splash quando E06 entrar).

```
lib/core/
├── audio/
│   ├── sound_player.dart          # abstract interface class + SoundEvent enum
│   ├── soloud_gateway.dart        # seam fino sobre SoLoud.instance (testabilidade)
│   ├── soloud_sound_player.dart   # impl produção, usa SoLoudGateway
│   └── audio_controller.dart      # ChangeNotifier + WidgetsBindingObserver
└── haptic/
    └── haptic_controller.dart     # ChangeNotifier + wrapper HapticFeedback

test/core/
├── audio/
│   ├── sound_player_test.dart           # SoundEvent enum smoke
│   ├── soloud_sound_player_test.dart    # com fake SoLoudGateway
│   └── audio_controller_test.dart       # com fake SoundPlayer
└── haptic/
    └── haptic_controller_test.dart      # com fake HapticPlatform

assets/sounds/
├── roll.mp3    # placeholder (silêncio ou tone curto)
├── stop.mp3    # placeholder
└── total.mp3   # placeholder
```

### Layered responsibility map

| Componente | Responsabilidade | Não responsabiliza-se por |
|---|---|---|
| `SoundEvent` (enum) | Identifica os 3 SFX do roteiro (`roll`, `stop`, `total`); expõe `assetPath` | Estado, tocagem |
| `SoLoudGateway` | Wrapper fino e *typed* sobre os 5–6 métodos de `SoLoud.instance` que usamos (`init`, `deinit`, `loadAsset`, `play`, `stopAll`, `disposeSource`) | Lógica de tocagem; *enabled* flag; lifecycle |
| `SoundPlayer` (interface) | Contrato: `init()`, `play(SoundEvent)`, `stopAll()`, `dispose()` | Persistência; lifecycle |
| `SoLoudSoundPlayer` | Impl prod. Carrega 3 assets em memória uma vez. Mantém mapa `SoundEvent → AudioSource`. `play()` é no-op pre-init | *Enabled* flag (decidido pelo controller) |
| `AudioController` | `ChangeNotifier` orquestrador. Lê `soundEnabled` de `AppSettingsPreference` no construtor (default `true` se `null`). `init()` async (carrega assets via `SoundPlayer`). `play(SoundEvent)` gateia em `_soundEnabled`. `setSoundEnabled(bool)` persiste + `notifyListeners()` + chama `stopAll()` quando desliga. `didChangeAppLifecycleState` para `stopAll()` em `paused`/`inactive`/`hidden` | Tocagem real (delega ao `SoundPlayer`) |
| `HapticController` | `ChangeNotifier` simétrico ao Audio mas mais simples: sem `init` assíncrono, sem lifecycle. Lê `hapticEnabled` no construtor (default `true`). `trigger()` chama `HapticFeedback.mediumImpact` se enabled. `setHapticEnabled(bool)` persiste + notifica | Lifecycle (haptic é instantâneo); persistência (delegada a `AppSettingsPreference`) |

### Sequence: toggle de som a partir da UI de Settings (futuro E11)

```
SettingsScreen          AudioController             AppSettingsPreference     SoundPlayer
     │                        │                            │                       │
     │ setSoundEnabled(false) │                            │                       │
     ├───────────────────────▶│                            │                       │
     │                        │  writeSoundEnabled(false)  │                       │
     │                        ├───────────────────────────▶│                       │
     │                        │                            │                       │
     │                        │             stopAll()      │                       │
     │                        ├──────────────────────────────────────────────────▶│
     │                        │                            │                       │
     │                        │ notifyListeners()          │                       │
     │                        ├──┐                         │                       │
     │   rebuild (toggle off) │  │                         │                       │
     │◀───────────────────────┘  │                         │                       │
```

### Sequence: SFX durante uma rolagem (futuro E08)

```
DiceController          AudioController             SoundPlayer (impl SoLoud)
     │                        │                            │
     │ play(SoundEvent.roll)  │                            │
     ├───────────────────────▶│                            │
     │                        │  if (_soundEnabled) play() │
     │                        ├───────────────────────────▶│
     │                        │              soloud.play() │
     │                        │                  (handle)  │
     │ play(SoundEvent.stop)  │                            │
     ├───────────────────────▶│                            │
     │                        │  if (_soundEnabled) play() │
     │                        ├───────────────────────────▶│
     │                        │                            │
     │ play(SoundEvent.total) │                            │
     ├───────────────────────▶│                            │
```

Cada `play()` retorna fire-and-forget. Não há await encadeado, não há sequenciamento — o SoLoud aceita sobreposição.

### Lifecycle handling

`AudioController` implementa `WidgetsBindingObserver` e se registra em `WidgetsBinding.instance.addObserver(this)` no `init()`. Comportamento em `didChangeAppLifecycleState`:

| State | Ação |
|---|---|
| `resumed` | no-op (engine permanece inicializada, sources permanecem carregados) |
| `inactive` | `_player.stopAll()` |
| `paused` | `_player.stopAll()` |
| `hidden` | `_player.stopAll()` |
| `detached` | `_player.stopAll()` (defensivo; geralmente seguido de processo morto) |

`dispose()` do controller chama `removeObserver`, `_player.dispose()` e `super.dispose()`.

## Technical Considerations

- **`flutter_soloud` 4.x mudanças relevantes**:
  - `SoLoud.instance.play(source)` retorna `SoundHandle` síncrono. Não precisa await — mas é `async` por contrato (pode retornar erro futuro). Tratar como fire-and-forget (`unawaited(...)`).
  - `loadAsset(path, mode: LoadMode.memory, autoDispose: false)` **é obrigatório `autoDispose: false`** — caso contrário, o source é descartado após o primeiro play, e o segundo play falha. Documentado no doc-comment do `SoLoudSoundPlayer.init()`.
  - `SoLoud` é `interface class` em 4.x — mockável via mocktail diretamente, mas preferimos o seam `SoLoudGateway` para isolar uso (ver decisão abaixo).
  - Hot restart em dev pode orfanar a thread nativa: `init()` do `SoLoudSoundPlayer` chama `_gateway.deinit()` defensivo se `_gateway.isInitialized` é `true`, antes de re-inicializar. Custo: 0 em produção (deinit no-op pós primeiro init).
- **`SoLoudGateway` (decisão default do brainstorm — mantida)**: thin wrapper concreto (não interface) com 5–6 métodos. Em testes, é substituído por uma `_FakeSoLoudGateway` inline. **Por que classe concreta com métodos virtuais e não interface?** Mantém o callsite de produção legível (`_gateway.play(source)` em vez de import de uma interface) e o fake em testes é trivial. Alternativa considerada: mocktail direto em `SoLoud` — descartado para evitar acoplamento de testes ao mocktail e para manter o limite explícito do que usamos da engine.

  Métodos expostos:
  ```dart
  class SoLoudGateway {
    bool get isInitialized => SoLoud.instance.isInitialized;
    Future<void> init() => SoLoud.instance.init();
    Future<void> deinit() async => SoLoud.instance.deinit();
    Future<AudioSource> loadAsset(String path) =>
        SoLoud.instance.loadAsset(path, mode: LoadMode.memory, autoDispose: false);
    Future<SoundHandle> play(AudioSource source) => SoLoud.instance.play(source);
    Future<void> stopAll() => SoLoud.instance.disposeAllSources();
    // NB: disposeAllSources also stops; we keep one verb (`stopAll`) per the SoundPlayer contract.
  }
  ```

  Cobertura: `SoLoudGateway` é trivial passthrough — coberto indiretamente via `soloud_sound_player_test.dart` que injeta o fake. Para satisfazer 100% line coverage, **opção A** (default): excluir `lib/core/audio/soloud_gateway.dart` do `lcov` via `// coverage:ignore-file` no header, tratando-o como código de borda (semelhante a `main.dart`). **Opção B**: integration test que toca a engine de verdade em `setUp` headless — descartada por instabilidade em CI sem áudio device. **Decisão**: A.
- **`SoundEvent` enum**: três valores, `roll`, `stop`, `total`. Cada um expõe `String get assetPath` (`'assets/sounds/roll.mp3'`, etc.). Centraliza a relação evento↔asset num único ponto e evita strings espalhadas.
- **`SoundPlayer.play(SoundEvent)` é síncrono no contrato (`void`), mas internamente chama `unawaited(_gateway.play(source))`**: evita propagar `Future`s vazios pelo call-graph. Erros raros (ex: source não carregado) são logados via `debugPrint` mas não lançam — feedback sensorial nunca deve quebrar a rolagem.
- **Carregamento de assets**: feito uma vez em `SoLoudSoundPlayer.init()`. Sequencial (`await`) para garantir ordem determinística em testes:
  ```dart
  for (final event in SoundEvent.values) {
    _sources[event] = await _gateway.loadAsset(event.assetPath);
  }
  ```
  Custo: ~30–80 ms para 3 MP3 pequenos. Acontece dentro do splash (E06) ou em `main.dart` (este epic) — não bloqueia frame após o app iniciar.
- **Hidratação default**: quando `AppSettingsPreference.readSoundEnabled()` retorna `null` (primeiro launch), o controller assume `true`. Mesma regra para haptic. Documentado em doc-comment.
- **Persistência side-effect**: `setSoundEnabled(value)` (1) atualiza `_soundEnabled`, (2) chama `notifyListeners()`, (3) chama `_player.stopAll()` se `value == false`, (4) faz `await _preference.writeSoundEnabled(value: value)`. Ordem deliberada: UI reage instantaneamente; persistência é assíncrona mas garantida. **Não** aguardar a persistência antes do `notifyListeners()` (UX > durability para um toggle).
- **`HapticController` simétrico**: mesma estrutura, sem `init()` e sem lifecycle. `trigger()` chama `_platform.mediumImpact()` (onde `_platform` é uma interface fina sobre `HapticFeedback` para testabilidade). `setHapticEnabled(value)` persiste + notifica. Sem `stopAll` porque haptic é momentâneo.
- **Testabilidade de `HapticFeedback`**: `HapticFeedback.mediumImpact` é estático e toca o canal `MethodChannel('flutter/platform')`. Duas opções:
  - **Opção A** (escolhida): introduzir interface `HapticPlatform` com método `Future<void> mediumImpact()`. Impl prod (`FlutterHapticPlatform`) delega para `HapticFeedback.mediumImpact()`. Fake em testes registra chamadas. Coverage 100% no controller; `FlutterHapticPlatform` recebe `// coverage:ignore-file` (passthrough).
  - **Opção B**: mockar via `TestDefaultBinaryMessengerBinding.setMockMethodCallHandler` no canal. Mais hermético mas verbose. Descartada.
- **DI/Provider order in `MultiProvider`**: ordem entre `ThemeProvider`, `AudioController`, `HapticController` é irrelevante (nenhum depende do outro). Convenção: ordem alfabética para futuras adições previsíveis.
- **Init em `main.dart` (temporário)**:
  ```dart
  Future<void> main() async {
    WidgetsFlutterBinding.ensureInitialized();
    final prefs = await SharedPreferences.getInstance();
    final appSettings = SharedPreferencesAppSettingsPreference(prefs);
    final audio = AudioController(preference: appSettings);
    await audio.init();
    final haptic = HapticController(preference: appSettings);
    runApp(App(audioController: audio, hapticController: haptic));
  }
  ```
  Passamos os controllers já construídos para `App`, que os instala num `MultiProvider`. Quando E06 (Splash) entrar, o `init()` migra para o splash e `main()` volta a ser uma linha. **Não está no escopo deste epic refatorar para um padrão "create no provider"** — manter explícito facilita a migração futura.
- **`App` signature change**: hoje `App({super.key})` é stateless puro. Vamos receber controllers prontos como params (`required AudioController audioController` / `required HapticController hapticController`) e passá-los para o `MultiProvider`. `ThemeProvider` continua sendo criado dentro do `ChangeNotifierProvider(create: ...)` por enquanto — sem mudança nesse padrão, só adicionamos dois `ChangeNotifierProvider.value` adjacentes para os controllers já construídos (porque eles vivem além do widget tree em testes/main).
- **Coverage policy**:
  - 100% line coverage em `audio_controller.dart`, `haptic_controller.dart`, `soloud_sound_player.dart`, `sound_player.dart` (enum).
  - `// coverage:ignore-file` em `soloud_gateway.dart` (passthrough trivial sobre `SoLoud.instance`) e em uma `FlutterHapticPlatform` se acabar sendo um arquivo separado (provavelmente mora no mesmo arquivo de `HapticController` como segunda classe). **Decisão**: manter `HapticPlatform` no mesmo arquivo, com `// coverage:ignore-start` / `// coverage:ignore-end` envolvendo apenas a impl de produção. Isso evita criar mais um arquivo só para passthrough.
  - `main.dart` continua excluído (já está no quality gate).
- **Não introduz `audio_session`**: já documentado no brainstorm. Trade-offs aceitos: iOS mute switch silencia; Android pode sobrepor ligação. Reavaliar em pós-M1.

## Implementation Tasks

Executar na ordem. Cada step termina com `flutter analyze` (zero issues) + `flutter test --coverage` (100% nos arquivos novos). Commitar entre steps com Conventional Commits.

### Step 0 — Dependency

- [ ] `flutter pub add flutter_soloud` (versão `^4.0.6` ou mais recente compatível com `sdk: ^3.12.0` — confirmar com `flutter pub add --dry-run flutter_soloud`)
- [ ] Verificar `pubspec.lock` regenerado; commit de `pubspec.yaml` + `pubspec.lock`
- [ ] Commit: `chore(e10): add flutter_soloud dependency`

### Step 1 — Placeholder assets

- [ ] Criar `assets/sounds/roll.mp3`, `assets/sounds/stop.mp3`, `assets/sounds/total.mp3` como placeholders (silêncio de 100 ms ou tone simples gerado offline — qualquer arquivo `.mp3` válido).
  - Substituição por assets reais permanece bloqueada (`[!]` na task 4.4 de `progress.md`) — depende de produção humana.
- [ ] Confirmar que `assets/sounds/` já está declarado no `pubspec.yaml` (sim — linha `- assets/sounds/`).
- [ ] Commit: `chore(e10): add placeholder SFX assets`

### Step 2 — `SoundEvent` + `SoundPlayer` interface

- [ ] Criar [lib/core/audio/sound_player.dart](../../lib/core/audio/sound_player.dart):

  ```dart
  /// Identifica os SFX disponíveis no app e o caminho do asset correspondente.
  ///
  /// AVISO: a ordem dos membros não é persistida (diferente dos enums em
  /// `core/storage/models/animation_settings.dart`), então reordenar é seguro.
  enum SoundEvent {
    roll(assetPath: 'assets/sounds/roll.mp3'),
    stop(assetPath: 'assets/sounds/stop.mp3'),
    total(assetPath: 'assets/sounds/total.mp3');

    const SoundEvent({required this.assetPath});
    final String assetPath;
  }

  /// Contrato mínimo de uma engine de áudio para SFX one-shot.
  ///
  /// Impl de produção: [SoLoudSoundPlayer]. Em testes, use uma fake que
  /// registre chamadas — não há razão para tocar a engine de verdade.
  abstract interface class SoundPlayer {
    /// Inicializa a engine e pré-carrega todos os [SoundEvent.values]. Deve
    /// ser chamado uma vez, antes do primeiro `play`. Subsequentes são no-op.
    Future<void> init();

    /// Toca [event]. Fire-and-forget. No-op se [init] não foi chamado ainda.
    void play(SoundEvent event);

    /// Para qualquer SFX em voo. Idempotente. No-op se [init] não foi chamado.
    Future<void> stopAll();

    /// Libera a engine. Após `dispose`, o player não deve ser usado.
    Future<void> dispose();
  }
  ```

- [ ] Criar [test/core/audio/sound_player_test.dart](../../test/core/audio/sound_player_test.dart) — verifica `SoundEvent.values.length == 3`, cada `assetPath` começa com `'assets/sounds/'` e termina em `'.mp3'`.
- [ ] `flutter analyze` + `flutter test --coverage`
- [ ] Commit: `feat(e10): add SoundEvent enum and SoundPlayer interface`

### Step 3 — `SoLoudGateway`

- [ ] Criar [lib/core/audio/soloud_gateway.dart](../../lib/core/audio/soloud_gateway.dart):
  - Header com `// coverage:ignore-file` (passthrough sobre `SoLoud.instance`)
  - Classe com métodos virtuais (não `final` — para o fake em testes poder estender, caso preferíamos override; mas decisão é usar `_FakeSoLoudGateway` que **implementa o mesmo shape via composição num arquivo de teste**, sem `implements` — então a classe pode ser `final` se conveniente)
  - **Decisão**: classe `final`; testes usam um `_FakeSoLoudGateway` que tem o **mesmo formato** e é injetado via construtor tipado em `SoLoudSoundPlayer` (Dart aceita type-via-duck quando você cria uma `interface` opcional). **Refino**: para evitar ambiguidade e simplificar, transformar `SoLoudGateway` em `abstract interface class` com impl `RealSoLoudGateway` no mesmo arquivo. Mantém `coverage:ignore-file`.

  ```dart
  // coverage:ignore-file
  import 'package:flutter_soloud/flutter_soloud.dart';

  /// Seam thin wrapper sobre `SoLoud.instance`. Existe para permitir uma
  /// fake em testes sem invocar o binário nativo. Não adiciona lógica.
  abstract interface class SoLoudGateway {
    bool get isInitialized;
    Future<void> init();
    Future<void> deinit();
    Future<AudioSource> loadAsset(String path);
    Future<SoundHandle> play(AudioSource source);
    Future<void> stopAll();
  }

  class RealSoLoudGateway implements SoLoudGateway {
    @override
    bool get isInitialized => SoLoud.instance.isInitialized;

    @override
    Future<void> init() => SoLoud.instance.init();

    @override
    Future<void> deinit() async => SoLoud.instance.deinit();

    @override
    Future<AudioSource> loadAsset(String path) => SoLoud.instance.loadAsset(
          path,
          mode: LoadMode.memory,
          assetBundle: rootBundle, // se 4.x exige; checar API ao implementar
        );

    @override
    Future<SoundHandle> play(AudioSource source) => SoLoud.instance.play(source);

    @override
    Future<void> stopAll() => SoLoud.instance.disposeAllSources();
  }
  ```

  **Nota durante implementação**: confirmar a assinatura exata de `loadAsset` em `flutter_soloud` 4.x (parâmetro `autoDispose` vs `assetBundle`); o brainstorm cita `autoDispose: false` como obrigatório. Ajustar antes do primeiro commit.
- [ ] Sem teste correspondente (arquivo está em `coverage:ignore-file`). Documentar essa exceção como comentário no header do arquivo: "Não tem testes unitários — é passthrough sobre `SoLoud.instance`. Coberto indiretamente em integration tests futuros."
- [ ] `flutter analyze` + `flutter test --coverage`
- [ ] Commit: `feat(e10): add SoLoudGateway seam for SoLoud.instance`

### Step 4 — `SoLoudSoundPlayer`

- [ ] Criar [lib/core/audio/soloud_sound_player.dart](../../lib/core/audio/soloud_sound_player.dart):

  ```dart
  import 'dart:async';
  import 'package:flutter/foundation.dart';
  import 'package:flutter_soloud/flutter_soloud.dart';
  import 'package:onebit_dice/core/audio/sound_player.dart';
  import 'package:onebit_dice/core/audio/soloud_gateway.dart';

  /// [SoundPlayer] backed by `flutter_soloud`. Carrega 3 assets em memória
  /// uma única vez no [init]. `play` é fire-and-forget.
  class SoLoudSoundPlayer implements SoundPlayer {
    SoLoudSoundPlayer({SoLoudGateway? gateway})
        : _gateway = gateway ?? RealSoLoudGateway();

    final SoLoudGateway _gateway;
    final Map<SoundEvent, AudioSource> _sources = {};
    bool _initialized = false;

    @override
    Future<void> init() async {
      if (_initialized) return;
      // Defensivo contra hot restart em dev (thread nativa orfã).
      if (_gateway.isInitialized) {
        await _gateway.deinit();
      }
      await _gateway.init();
      for (final event in SoundEvent.values) {
        _sources[event] = await _gateway.loadAsset(event.assetPath);
      }
      _initialized = true;
    }

    @override
    void play(SoundEvent event) {
      if (!_initialized) return;
      final source = _sources[event];
      if (source == null) return;
      unawaited(
        _gateway.play(source).catchError((Object e, StackTrace s) {
          debugPrint('SoLoudSoundPlayer.play($event) failed: $e');
          return SoundHandle.error(); // ou null-equivalente; ajustar à API
        }),
      );
    }

    @override
    Future<void> stopAll() async {
      if (!_initialized) return;
      await _gateway.stopAll();
    }

    @override
    Future<void> dispose() async {
      if (!_initialized) return;
      await _gateway.deinit();
      _sources.clear();
      _initialized = false;
    }
  }
  ```

  **Nota**: o `catchError` precisa retornar um valor compatível com o tipo do `Future<SoundHandle>` — em 4.x checar se há `SoundHandle.error` ou se devemos engolir o erro com `try`/`catch`. O importante: nunca propagar para o caller.
- [ ] Criar [test/core/audio/soloud_sound_player_test.dart](../../test/core/audio/soloud_sound_player_test.dart):
  - `_FakeSoLoudGateway implements SoLoudGateway` inline, registra calls em listas e expõe controles (`isInitializedOverride`, mapas de loaded sources, contagem de `play` por source, contagem de `stopAll`, contagem de `deinit`).
  - Casos:
    - `init` chama `gateway.init` + `loadAsset` por cada `SoundEvent` exatamente uma vez
    - `init` 2x é no-op (segunda chamada não invoca gateway de novo)
    - `init` com `gateway.isInitialized == true` chama `deinit` antes de `init` (defensivo hot-restart)
    - `play` pre-init é no-op
    - `play` pós-init chama `gateway.play` com o source correto
    - `play` quando `gateway.play` falha com erro: erro é engolido (não propaga)
    - `stopAll` pre-init é no-op
    - `stopAll` pós-init chama `gateway.stopAll`
    - `dispose` pre-init é no-op
    - `dispose` pós-init chama `gateway.deinit`, limpa sources, desabilita `play` subsequente
- [ ] `flutter analyze` + `flutter test --coverage`
- [ ] Commit: `feat(e10): add SoLoudSoundPlayer with hot-restart defense`

### Step 5 — `AudioController`

- [ ] Criar [lib/core/audio/audio_controller.dart](../../lib/core/audio/audio_controller.dart):

  ```dart
  import 'package:flutter/foundation.dart';
  import 'package:flutter/widgets.dart';
  import 'package:onebit_dice/core/audio/sound_player.dart';
  import 'package:onebit_dice/core/audio/soloud_sound_player.dart';
  import 'package:onebit_dice/core/storage/app_settings_preference.dart';

  /// Orquestra a engine de áudio com o flag persistido e o ciclo de vida do
  /// app. Distribuído via `ChangeNotifierProvider<AudioController>` em
  /// `lib/app.dart`.
  ///
  /// O flag default é `true` quando [AppSettingsPreference.readSoundEnabled]
  /// retorna `null` (primeiro launch).
  class AudioController extends ChangeNotifier with WidgetsBindingObserver {
    AudioController({
      required AppSettingsPreference preference,
      SoundPlayer? player,
    })  : _preference = preference,
          _player = player ?? SoLoudSoundPlayer(),
          _soundEnabled = preference.readSoundEnabled() ?? true;

    final AppSettingsPreference _preference;
    final SoundPlayer _player;
    bool _soundEnabled;
    bool _initialized = false;

    bool get soundEnabled => _soundEnabled;

    /// Carrega assets e registra observer de lifecycle. Idempotente.
    Future<void> init() async {
      if (_initialized) return;
      await _player.init();
      WidgetsBinding.instance.addObserver(this);
      _initialized = true;
    }

    /// Toca [event] se sound está enabled. No-op caso contrário.
    void play(SoundEvent event) {
      if (!_soundEnabled) return;
      _player.play(event);
    }

    /// Atualiza o flag, persiste em background, e desliga SFX em voo se
    /// `value == false`. Notifica listeners imediatamente.
    Future<void> setSoundEnabled(bool value) async {
      if (_soundEnabled == value) return;
      _soundEnabled = value;
      notifyListeners();
      if (!value) {
        await _player.stopAll();
      }
      await _preference.writeSoundEnabled(value: value);
    }

    @override
    void didChangeAppLifecycleState(AppLifecycleState state) {
      if (state == AppLifecycleState.resumed) return;
      unawaited(_player.stopAll());
    }

    @override
    void dispose() {
      WidgetsBinding.instance.removeObserver(this);
      unawaited(_player.dispose());
      super.dispose();
    }
  }
  ```

- [ ] Criar [test/core/audio/audio_controller_test.dart](../../test/core/audio/audio_controller_test.dart):
  - `_FakeSoundPlayer implements SoundPlayer` registra calls (init, play list, stopAll count, dispose count).
  - Reutilizar `InMemoryAppSettingsPreference` (já existe em [lib/core/storage/app_settings_preference.dart](../../lib/core/storage/app_settings_preference.dart)) como impl de teste — sem precisar de novo fake.
  - Casos:
    - **Hidratação**: `preference.readSoundEnabled() == null` → `controller.soundEnabled == true`
    - **Hidratação**: `preference.readSoundEnabled() == false` → `controller.soundEnabled == false`
    - **Hidratação**: `preference.readSoundEnabled() == true` → `controller.soundEnabled == true`
    - `init` chama `player.init` e registra observer (smoke: chamar `init()` 2x não duplica)
    - `play` quando `soundEnabled == true` delega ao player
    - `play` quando `soundEnabled == false` é no-op (player não recebe call)
    - `setSoundEnabled(true→false)` notifica 1×, chama `stopAll`, persiste `false`
    - `setSoundEnabled(false→true)` notifica 1×, **não** chama `stopAll`, persiste `true`
    - `setSoundEnabled` com valor igual ao atual é no-op (sem notify, sem stopAll, sem write)
    - `didChangeAppLifecycleState(paused)` chama `stopAll`
    - `didChangeAppLifecycleState(inactive)` chama `stopAll`
    - `didChangeAppLifecycleState(hidden)` chama `stopAll`
    - `didChangeAppLifecycleState(detached)` chama `stopAll`
    - `didChangeAppLifecycleState(resumed)` é no-op (não chama `stopAll`)
    - `dispose` chama `player.dispose` e remove observer (verificar via `WidgetsBinding.instance.observers` pré/pós)
  - Usar `TestWidgetsFlutterBinding.ensureInitialized()` no top-level do main de testes para que `WidgetsBinding.instance.addObserver` funcione.
- [ ] `flutter analyze` + `flutter test --coverage`
- [ ] Commit: `feat(e10): add AudioController with lifecycle and toggle`

### Step 6 — `HapticController` + `HapticPlatform`

- [ ] Criar [lib/core/haptic/haptic_controller.dart](../../lib/core/haptic/haptic_controller.dart):

  ```dart
  import 'package:flutter/foundation.dart';
  import 'package:flutter/services.dart';
  import 'package:onebit_dice/core/storage/app_settings_preference.dart';

  /// Plataforma de haptic — seam fino sobre `HapticFeedback` para testes.
  abstract interface class HapticPlatform {
    Future<void> mediumImpact();
  }

  // coverage:ignore-start
  class FlutterHapticPlatform implements HapticPlatform {
    @override
    Future<void> mediumImpact() => HapticFeedback.mediumImpact();
  }
  // coverage:ignore-end

  /// Orquestra o flag persistido de haptic e o trigger da vibração.
  ///
  /// Padrão simétrico ao [AudioController], mas sem lifecycle e sem init
  /// assíncrono (haptic é instantâneo). Default `true` quando
  /// [AppSettingsPreference.readHapticEnabled] retorna `null`.
  class HapticController extends ChangeNotifier {
    HapticController({
      required AppSettingsPreference preference,
      HapticPlatform? platform,
    })  : _preference = preference,
          _platform = platform ?? FlutterHapticPlatform(),
          _hapticEnabled = preference.readHapticEnabled() ?? true;

    final AppSettingsPreference _preference;
    final HapticPlatform _platform;
    bool _hapticEnabled;

    bool get hapticEnabled => _hapticEnabled;

    /// Dispara um pulso de mediumImpact se haptic está enabled.
    void trigger() {
      if (!_hapticEnabled) return;
      unawaited(_platform.mediumImpact());
    }

    Future<void> setHapticEnabled(bool value) async {
      if (_hapticEnabled == value) return;
      _hapticEnabled = value;
      notifyListeners();
      await _preference.writeHapticEnabled(value: value);
    }
  }
  ```

- [ ] Criar [test/core/haptic/haptic_controller_test.dart](../../test/core/haptic/haptic_controller_test.dart):
  - `_FakeHapticPlatform implements HapticPlatform` — registra calls a `mediumImpact`.
  - Casos:
    - **Hidratação**: `null` → `true`, `false` → `false`, `true` → `true`
    - `trigger` quando enabled → `platform.mediumImpact` chamado 1×
    - `trigger` quando disabled → no-op
    - `setHapticEnabled(true→false)` notifica 1×, persiste
    - `setHapticEnabled(false→true)` notifica 1×, persiste
    - `setHapticEnabled` com valor igual é no-op (sem notify, sem write)
- [ ] `flutter analyze` + `flutter test --coverage`
- [ ] Commit: `feat(e10): add HapticController with toggle`

### Step 7 — Wiring no `app.dart` e `main.dart`

- [ ] Modificar [lib/main.dart](../../lib/main.dart) para construir as deps antes de `runApp`:

  ```dart
  import 'package:flutter/widgets.dart';
  import 'package:onebit_dice/app.dart';
  import 'package:onebit_dice/core/audio/audio_controller.dart';
  import 'package:onebit_dice/core/haptic/haptic_controller.dart';
  import 'package:onebit_dice/core/storage/app_settings_preference.dart';
  import 'package:shared_preferences/shared_preferences.dart';

  Future<void> main() async {
    WidgetsFlutterBinding.ensureInitialized();
    final prefs = await SharedPreferences.getInstance();
    final appSettings = SharedPreferencesAppSettingsPreference(prefs);
    final audioController = AudioController(preference: appSettings);
    await audioController.init();
    final hapticController = HapticController(preference: appSettings);
    runApp(
      App(
        audioController: audioController,
        hapticController: hapticController,
      ),
    );
  }
  ```

  - `main.dart` continua excluído de coverage (entry point).
  - Quando E06 entrar, o `audioController.init()` migra para o splash.
- [ ] Modificar [lib/app.dart](../../lib/app.dart) para receber os controllers e instalá-los num `MultiProvider`:

  ```dart
  import 'package:flutter/material.dart';
  import 'package:onebit_dice/core/audio/audio_controller.dart';
  import 'package:onebit_dice/core/haptic/haptic_controller.dart';
  import 'package:onebit_dice/core/theme/app_theme.dart';
  import 'package:onebit_dice/core/theme/theme_provider.dart';
  import 'package:onebit_dice/features/_dev/design_system_preview.dart';
  import 'package:provider/provider.dart';

  class App extends StatelessWidget {
    const App({
      required this.audioController,
      required this.hapticController,
      super.key,
    });

    final AudioController audioController;
    final HapticController hapticController;

    @override
    Widget build(BuildContext context) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<AudioController>.value(value: audioController),
          ChangeNotifierProvider<HapticController>.value(value: hapticController),
          ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
        ],
        child: const _AppView(),
      );
    }
  }
  ```

  - `_AppView` permanece inalterado (já usa `context.watch<ThemeProvider>()`).
- [ ] **Não é necessário** atualizar `test/widget_test.dart` se ele só verifica que o `App` instancia. Verificar o conteúdo de [test/widget_test.dart](../../test/widget_test.dart) antes do commit. Se quebrar, fornecer fakes inline (`InMemoryAppSettingsPreference` + um `_FakeSoundPlayer` + `_FakeHapticPlatform`) e atualizar o teste para passar controllers de teste:
  ```dart
  final settings = InMemoryAppSettingsPreference();
  final audio = AudioController(preference: settings, player: _FakeSoundPlayer());
  final haptic = HapticController(preference: settings, platform: _FakeHapticPlatform());
  await tester.pumpWidget(App(audioController: audio, hapticController: haptic));
  ```
- [ ] `flutter analyze` + `flutter test --coverage`
- [ ] Commit: `feat(e10): wire AudioController and HapticController into App`

### Step 8 — Wrap-up

- [ ] Atualizar [docs/plan/progress.md](progress.md):
  - Substituir o texto de 4.1: `lib/core/audio/sound_player.dart — wrapper just_audio com playRoll/Stop/Total + setEnabled` por entrada que reflita o split em `sound_player.dart` (interface), `soloud_gateway.dart`, `soloud_sound_player.dart`, e `audio_controller.dart`.
  - Substituir 4.2: `lib/core/haptic/haptic_controller.dart — wrapper HapticFeedback.mediumImpact + setEnabled` por descrição que cite `ChangeNotifier` + `HapticPlatform` seam.
  - Marcar 4.1, 4.2, 4.3 como `[x]`.
  - Manter 4.4 como `[!]` (substituição por `.mp3` reais — humano).
  - Atualizar o nome do epic se necessário (de "Audio & Haptic" para "Audio & Haptic — E10").
  - Acrescentar nota: "Engine de áudio: `flutter_soloud` 4.x (substitui `just_audio` mencionado no roadmap original). Decisão registrada em `docs/brainstorm/2026-05-26-e10-audio-haptic-brainstorm-doc.md`."
- [ ] Rodar `flutter analyze` + `flutter test --coverage` aggregate; confirmar 100% line coverage nos arquivos novos.
- [ ] Commit: `chore(e10): mark audio/haptic tasks complete in progress.md`
- [ ] Abrir PR contra `main` titulado `feat: e10 audio and haptic`.

## Acceptance Criteria

- [ ] `flutter_soloud ^4.x` declarado em [pubspec.yaml](../../pubspec.yaml) e `pubspec.lock` regenerado.
- [ ] Existem `assets/sounds/roll.mp3`, `assets/sounds/stop.mp3`, `assets/sounds/total.mp3` como placeholders válidos.
- [ ] `SoundEvent` enum em [lib/core/audio/sound_player.dart](../../lib/core/audio/sound_player.dart) tem exatamente 3 valores com `assetPath` correto.
- [ ] `SoundPlayer` é `abstract interface class` com `init`/`play`/`stopAll`/`dispose`.
- [ ] `SoLoudGateway` é `abstract interface class` em [lib/core/audio/soloud_gateway.dart](../../lib/core/audio/soloud_gateway.dart), com `RealSoLoudGateway` impl. Arquivo marcado `// coverage:ignore-file`.
- [ ] `SoLoudSoundPlayer` em [lib/core/audio/soloud_sound_player.dart](../../lib/core/audio/soloud_sound_player.dart) implementa `SoundPlayer`, é defensivo contra hot restart (calls `deinit` se `gateway.isInitialized`), carrega assets uma vez, `play` é fire-and-forget.
- [ ] `AudioController extends ChangeNotifier with WidgetsBindingObserver` em [lib/core/audio/audio_controller.dart](../../lib/core/audio/audio_controller.dart):
  - Hidrata `_soundEnabled` de `AppSettingsPreference`, default `true`.
  - `play(SoundEvent)` é gated em `_soundEnabled`.
  - `setSoundEnabled` persiste, chama `stopAll` quando desliga, notifica imediatamente.
  - `didChangeAppLifecycleState` chama `stopAll` em todos os estados exceto `resumed`.
  - `dispose` remove observer e dispose o player.
- [ ] `HapticController extends ChangeNotifier` em [lib/core/haptic/haptic_controller.dart](../../lib/core/haptic/haptic_controller.dart) com `HapticPlatform` interface + `FlutterHapticPlatform` impl no mesmo arquivo (impl marcada `// coverage:ignore-start/end`).
- [ ] [lib/app.dart](../../lib/app.dart) instala os 3 controllers num `MultiProvider`. [lib/main.dart](../../lib/main.dart) constrói e inicializa antes de `runApp`.
- [ ] `flutter analyze` exits 0 sob `very_good_analysis`.
- [ ] `flutter test --coverage` exibe 100% line coverage em `sound_player.dart`, `soloud_sound_player.dart`, `audio_controller.dart`, `haptic_controller.dart`. `soloud_gateway.dart` e a impl `FlutterHapticPlatform` estão fora da contagem via `coverage:ignore`.
- [ ] [test/widget_test.dart](../../test/widget_test.dart) continua passando (ajustado se necessário).
- [ ] `progress.md` reflete o split do epic, com 4.1–4.3 `[x]` e 4.4 `[!]`.

## Success Metrics

- **Quality gate**: `flutter analyze` zero issues; `flutter test --coverage` 100% line coverage nos arquivos novos (exceto os com `coverage:ignore`).
- **Downstream readiness**:
  - E08 (Dice) pode injetar `AudioController` e `HapticController` via `context.read` e chamar `audio.play(SoundEvent.roll)` / `haptic.trigger()` no fluxo de rolagem sem mudanças adicionais aqui.
  - E11 (Settings) pode ler `context.watch<AudioController>().soundEnabled` e chamar `setSoundEnabled` direto na UI de toggle. Idem para haptic.
  - E06 (Splash) pode chamar `audioController.init()` no `initState` com um `FutureBuilder`, removendo o `await` de `main.dart`.
- **Roundtrip de estado**: setar `soundEnabled = false`, recriar o controller com a mesma `AppSettingsPreference` instance, e ler `soundEnabled == false` (verificado em teste de hidratação).
- **Resiliência**: chamar `play`, `stopAll` ou `dispose` antes de `init` é no-op (não throws).
- **Lifecycle correctness**: enviar `paused` enquanto SFX está tocando para o `stopAll` em ≤1 frame (verificado em teste com fake).

## Dependencies and Risks

- **Nova runtime dep**: `flutter_soloud ^4.0.6`. Engine nativa (C++); contém binários para iOS, Android, macOS, Linux, Windows. Tamanho do artefato de release Android cresce ~1–2 MB (aceitável). Verificar build iOS/Android funciona após `flutter pub get` — se algum platform-specific setup for necessário (config Podfile, NDK), endereçar dentro do Step 0.
- **Risco: API de `flutter_soloud` 4.x diferente do que o brainstorm assume**: especificamente `loadAsset` (parâmetros `autoDispose`, `mode`, `assetBundle`) e `play` (retorno `SoundHandle` ou `Future<SoundHandle>`). Mitigação: validar a assinatura exata ao implementar Step 3 e Step 4 — ajustar `SoLoudGateway` e `SoLoudSoundPlayer` antes do commit. O contrato de `SoundPlayer` permanece estável.
- **Risco: hot restart deixa thread nativa orfã em dev**: Mitigado por `deinit` defensivo no `init`. Não afeta release.
- **Risco: `WidgetsBindingObserver` em testes**: precisa de `TestWidgetsFlutterBinding.ensureInitialized()` no `setUpAll`. Se esquecido, `addObserver` no `controller.init()` lança ou no-op. Documentado nos testes.
- **Risco: assets `.mp3` placeholders triviais (silêncio) podem ser rejeitados pelo decoder**: gerar com um tone-generator de 100 ms ou usar um arquivo conhecido válido. Validar tocando manualmente no simulador antes do commit do Step 1.
- **Risco: testes que chamam `audio.init()` levantam o gateway real**: mitigado por injeção (`AudioController(player: _FakeSoundPlayer())`). Toda chamada de teste passa um fake — o `SoLoudSoundPlayer` só é instanciado em produção via `main.dart`.
- **Risco: ordem do `MultiProvider` na refatoração de `app.dart`**: o `_AppView` lê `ThemeProvider` via `context.watch` — confirmar que `ThemeProvider` ainda está acessível após o `MultiProvider` wrapping. Como ele continua como um `ChangeNotifierProvider` no mesmo nível, deve funcionar; verificar via `flutter test` do widget test.
- **Risco: `audio_session` ausente** (já documentado no brainstorm): iOS mute switch silencia o app; Android pode tocar SFX por cima de uma ligação. Reavaliar pós-M1 se receber feedback de usuário.
- **Sem dependência de Firebase/external API/backend**: epic é 100% local.

## Out of Scope

- **UI de Settings consumindo os controllers**: o `palette_selector` + `toggle_tile` de Settings (E11) é onde os toggles ganham UI.
- **UI de Dice tocando SFX/haptic**: o `DiceController` (E08) é quem decide *quando* tocar cada SFX e o trigger de haptic (provavelmente no `roll()` → `play(SoundEvent.roll)`, no resultado → `play(SoundEvent.stop)` e `play(SoundEvent.total)`).
- **Init via splash**: hoje fica em `main.dart`. Migração para `SplashScreen.initState` é responsabilidade de E06.
- **`audio_session` / audio focus / ducking**: descartado em M1. Reavaliar pós-launch.
- **Volume control e haptic intensity**: assumimos `1.0` no SoLoud (padrão) e `HapticFeedback.mediumImpact` fixo. Controle fino fica para iteração futura, fora de M1.
- **Substituir placeholders `.mp3` por assets reais**: bloqueado por produção de áudio (humano) — task 4.4 permanece `[!]`.
- **Strip Style do Xcode = "Non-Global Symbols" no archive iOS**: necessário para shipping em iOS (SoLoud requisito), mas configurado em E15 (release prep).
- **Integration tests com SoLoud real**: descartado em CI (sem áudio device). Pode entrar como manual QA em E15.
- **Acessibilidade do toggle de haptic** (ex: respeitar "Reduce Motion" do iOS): fora do escopo deste epic.
- **Analytics dos eventos de áudio/haptic** (ex: tracking de toggle on/off): se entrar, vem em E05 (analytics).
