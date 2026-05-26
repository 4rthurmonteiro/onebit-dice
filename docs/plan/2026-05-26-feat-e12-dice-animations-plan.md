---
title: "feat: e12 dice roll animations"
type: feat
date: 2026-05-26
epic: E12
status: planned
---

# feat: e12 dice roll animations — Standard

## Overview

Entrega as três animações de rolagem do `DiceWidget` — **Rápida**, **Tambor**, **Tabuleiro** — em três velocidades configuráveis (Rápido / Médio / Longo). A animação dispara quando o `DiceController.lastResult` muda (via tap em ROLAR ou via preset), consome `AnimationSettingsController.style` + `.speed` (já injetados em E08), e usa o número final como destino.

Não há mudança de domínio. O `RollResult` já carrega `timestamp` + `values` que servem como gatilho da animação. O `DiceWidget` é refatorado para um `DiceAnimator` que escolhe uma das três estratégias com base em `AnimationStyle`. Cada estratégia é um `StatefulWidget` independente, testável isoladamente.

**Sprites ficam para depois.** O item 13.5 de `progress.md` (sprite sheets reais do Blender) é `[!]` bloqueado por intervenção humana. Este plano usa o mesmo renderizador textual atual (`_Slot` com fonte Silkscreen) ciclando valores aleatórios durante a fase de "rolando". Quando os sprites chegarem (epic separada), só o componente de slot muda — as estratégias de animação permanecem.

A escolha de **três `StatefulWidget`s separados** (`FastAnimation`, `DrumAnimation`, `TabletopAnimation`) em vez de um único `Animator` polimórfico é deliberada: cada estilo tem fases e durações distintas; juntar tudo num único `AnimationController` confunde leitura e dobra o esforço de teste. Trade-off aceito: um pouco mais de boilerplate por widget.

## Problem Statement / Motivation

Hoje o app:

- Roda dado e o resultado **aparece instantaneamente** no `DiceWidget`. Não há sensação tátil-visual de "rolagem".
- `AnimationStyle` + `AnimationSpeed` já existem como modelos em [animation_settings.dart](../../lib/core/storage/models/animation_settings.dart), persistidos em `AppSettingsPreference`, e expostos via `AnimationSettingsController` (E08).
- `DiceWidget` ([dice_widget.dart](../../lib/features/dice/widgets/dice_widget.dart)) já renderiza o grid + total + equação. Estrutura pronta para receber a animação.
- `progress.md` lista 13.2 (Rápida), 13.3 (Tambor), 13.4 (Tabuleiro) como TODO + 13.1 (enums) DONE em E04.

Sem E12, M1 fecha funcional mas sensorialmente pobre — uma das diferenças prometidas do app é a sensação retrô "máquina rolando". O default M1 é **Tambor + Médio** (`docs/roadmap/01-escopo-m1.md:80-84`), então o estilo Tambor precisa estar polido o suficiente para ser a primeira impressão.

## Proposed Solution

```
lib/features/dice/widgets/
├── dice_widget.dart                # MODIFY — wrappa o grid num DiceAnimator
├── dice_animator.dart              # NEW — escolhe a strategy baseada em AnimationStyle
└── animations/
    ├── fast_animation.dart         # NEW — AnimatedSwitcher 100ms hard cut
    ├── drum_animation.dart         # NEW — cycle frames + settle
    └── tabletop_animation.dart     # NEW — slide-in + bounce + cycle + settle

test/features/dice/widgets/
├── dice_widget_test.dart           # MODIFY — wrappa com Provider de AnimationSettings
├── dice_animator_test.dart         # NEW — picks correct strategy per style
└── animations/
    ├── fast_animation_test.dart    # NEW
    ├── drum_animation_test.dart    # NEW
    └── tabletop_animation_test.dart # NEW

lib/features/dice/dice_screen.dart  # NO CHANGES — DiceWidget API mantida
```

### Strategy / responsibility map

| Componente | Responsabilidade | Não responsabiliza-se por |
|---|---|---|
| `DiceAnimator` | Lê `AnimationSettingsController.style` via `context.watch`. Recebe `count` + `targetValues` (nullable) + `slotSize`. Roteia para a strategy escolhida via `switch` sobre `AnimationStyle`. Dispara `AnimationController` quando o `targetValues` muda — usa `widget.targetValues` no `didUpdateWidget`. | Renderizar valores reais (delega para a strategy); pegar o estado do Provider direto da preference (controller cuida) |
| `FastAnimation` | `AnimatedSwitcher(duration: 100ms)` que troca o `Grid` com hard cut (sem cross-fade — manter 1-bit). Sem ciclo intermediário; o valor final aparece logo. | Cycling de frames |
| `DrumAnimation` | `AnimationController(duration: speed-dependent)`. Durante a animação, `_Grid` recebe valores aleatórios em cada tick (cycle a ~12fps). Ao terminar, recebe `targetValues`. | Slide; bounce |
| `TabletopAnimation` | `AnimationController` multi-fase: 25% slide-in (translateY from `-slotSize` to 0), 25% bounce (oscilação 4 frames de ±2px), 30% cycle (random como Drum, frame rate dobrado), 20% settle (valor final + breve "thump" — sem áudio, é visual: pulse de scale 0.95→1.0). | Som — `DiceController.roll` já dispara `SoundEvent.total` |

### Durations table

Centralizada num único `Map<(AnimationStyle, AnimationSpeed), Duration>` em `dice_animator.dart`:

| Style | Fast | Medium | Slow |
|---|---|---|---|
| Rápida (`fast`) | 100ms | 100ms | 100ms (não escala — é só "instantâneo") |
| Tambor (`drum`) | 400ms | 800ms | 1400ms |
| Tabuleiro (`tabletop`) | 800ms | 1500ms | 2500ms |

Justificativa:
- `fast` ignora `speed` porque "rápido em velocidade lenta" não faz sentido — é o estilo "sem animação" essencialmente.
- `drum`/`tabletop` escalam linearmente. Os valores foram escolhidos para que (a) medium seja visualmente perceptível mas curto, (b) slow não seja chato, (c) fast seja ainda animado para distinguir de `AnimationStyle.fast`.

### Sequence: usuário toca ROLAR (default: Tambor + Médio)

```
RollButton    DiceController    DiceWidget    DiceAnimator    DrumAnimation
    │             │                 │              │               │
    │ tap         │                 │              │               │
    ├────────────▶│                 │              │               │
    │             │ values = rng    │              │               │
    │             │ notifyListeners()              │               │
    │             │                ─▶│ rebuild with new values     │
    │             │                 │ pass to ──▶│ pass to ──────▶│
    │             │                 │              │ didUpdateWidget detects new targetValues
    │             │                 │              │               │ controller.forward(from: 0)
    │             │                 │              │               │ tick every 66ms:
    │             │                 │              │               │   randomize displayedValues
    │             │                 │              │               │ on done: displayedValues = targetValues
    │             │                 │              │               │ setState
```

`DiceController.roll` continua disparando `SoundEvent.total` e `haptic.trigger()` imediatamente — o som/háptico não sincronizam com a animação no M1 (YAGNI: alinhar o "thump" áudio-visual fica para um polimento futuro).

## Acceptance criteria

- [ ] `DiceAnimator` recebe `count`, `targetValues`, e lê `AnimationStyle`/`AnimationSpeed` de `AnimationSettingsController` via `context.watch`
- [ ] `FastAnimation` mostra o valor final em ≤ 100ms sem cycling
- [ ] `DrumAnimation` cicla valores aleatórios durante a duração configurada e termina com `targetValues` correto
- [ ] `TabletopAnimation` executa slide-in + bounce + cycle + settle dentro da duração configurada e termina com `targetValues`
- [ ] Trocar `AnimationStyle` no Settings reflete na próxima rolagem (não interrompe uma animação em andamento — só vale na próxima `widget.targetValues` mudança)
- [ ] Trocar `AnimationSpeed` no Settings ajusta a duração na próxima rolagem
- [ ] `DiceWidget` mantém a API atual (`count`, `values`) — `DiceScreen` não precisa mudar
- [ ] Zero terceira cor, zero gradiente, zero sombra, zero anti-aliasing (todos os efeitos via translate/scale de `_Slot`)
- [ ] 100% line coverage no código novo
- [ ] `flutter analyze` zero issues
- [ ] Out of scope: sprites reais (item 13.5 BLOCKED), animação no splash, animação de transição de aba

## Tasks

- [ ] **T1** Criar pasta `lib/features/dice/widgets/animations/` e mover/extrair `_Slot` + `_Grid` do `DiceWidget` atual para um arquivo reusável (ou expor como `@visibleForTesting`)
- [ ] **T2** `lib/features/dice/widgets/animations/fast_animation.dart` + teste — `AnimatedSwitcher` 100ms, sem cycling. Test: pump 50ms (vê valor antigo), pump 60ms (vê valor novo)
- [ ] **T3** `lib/features/dice/widgets/animations/drum_animation.dart` + teste — `AnimationController` + `Timer.periodic` ou `addListener` cyclando. Test com fake clock: tick fires N vezes (N = duration/frame); valor final = targetValues
- [ ] **T4** `lib/features/dice/widgets/animations/tabletop_animation.dart` + teste — 4 fases, cada uma com `Tween` próprio chained. Test: a cada 25% verificar a posição/scale do `_Slot`
- [ ] **T5** `lib/features/dice/widgets/dice_animator.dart` + teste — `switch` strategy + lookup de duração. Test: troca de style em runtime escolhe strategy nova na próxima rolagem
- [ ] **T6** Modificar `lib/features/dice/widgets/dice_widget.dart` — substitui `_Grid` direto por `DiceAnimator`. Mantém API pública (`count`, `values`)
- [ ] **T7** Atualizar `test/features/dice/widgets/dice_widget_test.dart` — wrappa com `Provider<AnimationSettingsController>` (fake)
- [ ] **T8** Atualizar `progress.md` — marcar EPIC 13 (1–4) como `[x]`; manter 13.5 `[!]` (sprites)
- [ ] **T9** `feedback.sh --all` verde

## Implementation details

### DiceAnimator strategy switch

```dart
// lib/features/dice/widgets/dice_animator.dart
class DiceAnimator extends StatelessWidget {
  const DiceAnimator({
    required this.count,
    required this.targetValues,
    super.key,
  });

  final int count;
  final List<int>? targetValues;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AnimationSettingsController>();
    final duration = _resolveDuration(settings.style, settings.speed);
    return switch (settings.style) {
      AnimationStyle.fast => FastAnimation(
        count: count,
        targetValues: targetValues,
        duration: duration,
      ),
      AnimationStyle.drum => DrumAnimation(
        count: count,
        targetValues: targetValues,
        duration: duration,
      ),
      AnimationStyle.tabletop => TabletopAnimation(
        count: count,
        targetValues: targetValues,
        duration: duration,
      ),
    };
  }
}

@visibleForTesting
Duration resolveDuration(AnimationStyle style, AnimationSpeed speed) =>
    switch ((style, speed)) {
      (AnimationStyle.fast, _) => const Duration(milliseconds: 100),
      (AnimationStyle.drum, AnimationSpeed.fast) =>
        const Duration(milliseconds: 400),
      (AnimationStyle.drum, AnimationSpeed.medium) =>
        const Duration(milliseconds: 800),
      (AnimationStyle.drum, AnimationSpeed.slow) =>
        const Duration(milliseconds: 1400),
      (AnimationStyle.tabletop, AnimationSpeed.fast) =>
        const Duration(milliseconds: 800),
      (AnimationStyle.tabletop, AnimationSpeed.medium) =>
        const Duration(milliseconds: 1500),
      (AnimationStyle.tabletop, AnimationSpeed.slow) =>
        const Duration(milliseconds: 2500),
    };
```

### DrumAnimation pseudocode

```dart
class DrumAnimation extends StatefulWidget {
  // ... ctor with count, targetValues, duration, diceTypeSides for randomization
}

class _DrumAnimationState extends State<DrumAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<int>? _displayedValues;
  late final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..addListener(_tick)
      ..addStatusListener(_onStatus);
    _displayedValues = widget.targetValues;
  }

  void _tick() {
    if (!_controller.isAnimating) return;
    // Cycle at ~12fps: only update displayedValues every Nth frame.
    if ((_controller.lastElapsedDuration!.inMilliseconds ~/ 80) ==
        _lastTickIndex) return;
    setState(() {
      _displayedValues = List<int>.generate(
        widget.count,
        (_) => _rng.nextInt(_sidesForCurrentDie()) + 1,
      );
    });
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      setState(() => _displayedValues = widget.targetValues);
    }
  }

  @override
  void didUpdateWidget(covariant DrumAnimation old) {
    super.didUpdateWidget(old);
    if (widget.targetValues != null &&
        !listEquals(widget.targetValues, old.targetValues)) {
      _controller
        ..duration = widget.duration
        ..forward(from: 0);
    }
  }

  // ... dispose, build
}
```

**Sides for randomization**: `DrumAnimation` precisa saber o `DiceType.sides` para gerar números válidos no cycling. Duas opções:

- (a) Receber `int sides` como parâmetro — `DiceAnimator` lê de `context.watch<DiceController>().selectedType.sides` e passa adiante.
- (b) Receber `targetValues` apenas e calcular `max(targetValues) + variance` para gerar valores no ciclo — não-determinístico, mais frágil.

Decidir por (a). `DiceAnimator` consome ambos os providers (`AnimationSettings` + `DiceController`).

### TabletopAnimation phases

```dart
// Phase 0..0.25: slide in from translateY(-slotSize) to 0, ease-out
// Phase 0.25..0.50: bounce — sin(t * pi * 4) * 2px on translateY
// Phase 0.50..0.80: cycle (same as DrumAnimation but frame rate 60ms)
// Phase 0.80..1.00: settle — scale 0.92 → 1.05 → 1.0 with linear interp
```

Tudo num único `AnimationController` com `Tween<double>` para cada fase composto via `Interval(begin, end, curve: ...)`.

Translate sem anti-aliasing: usar `Transform.translate(offset: Offset(0, dy.roundToDouble()))` para snap-to-pixel.

Scale: `Transform.scale(scale: s)` — Flutter `Transform.scale` usa `MatrixUtils` que pode anti-aliasing dependendo do filterQuality. Forçar `FilterQuality.none` se necessário (sprites futuros precisam disso). M1 com texto: aceitar leve fuzziness na fase settle — risk documentado.

### FastAnimation

```dart
class FastAnimation extends StatelessWidget {
  // ...
  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,  // 100ms
      switchInCurve: Curves.linear,
      switchOutCurve: Curves.linear,
      transitionBuilder: (child, anim) => child,  // hard cut, sem fade
      child: Grid(
        key: ValueKey(_keyOf(targetValues)),  // novo key dispara troca
        count: count,
        values: targetValues,
      ),
    );
  }
}
```

`transitionBuilder` retornando o `child` cru elimina a transição visual mas mantém a key-based swap — o tempo de 100ms vira tempo "morto" entre `setState` e exibição. Aceitável para o estilo "sem animação".

## Wiring changes

Nenhuma. `AnimationSettingsController` já é provido em E08; `DiceController` já é provido. `DiceAnimator` apenas consome os dois via `context.watch`.

## i18n delta

Nenhuma. Os labels de estilo/velocidade vivem no Settings (E08); E12 não adiciona texto novo na UI.

## Out of scope

- Sprite sheets reais — item 13.5 `[!]` BLOCKED por intervenção humana (assets Blender)
- Animação no splash screen — fora de E12 (E09 já fechou splash)
- Animação de transição entre abas — fora de E12 (E09 usa `NoTransitionPage`)
- Sincronização áudio-visual do "thump" — YAGNI no M1
- Suporte a `MediaQuery.disableAnimations` (reduced motion) — risk documentado, não implementar
- Customização de durações pelo usuário (slider) — fora de escopo (3 níveis fixos)
- Animação por slot individual (cada dado anima independente) — YAGNI; whole-grid é suficiente para a sensação alvo

## Risks

- **Frame rate / jank em devices baixos**: `setState` a 12fps no `DrumAnimation` pode causar jank em Android antigo. Mitigação: usar `RepaintBoundary` ao redor do `_Grid` na strategy; medir via `flutter run --profile` quando devices reais estiverem disponíveis. M1: aceitar e iterar pós-launch.
- **Pixel-snap do `Transform.translate`**: `dy.roundToDouble()` garante alinhamento; sem isso, anti-aliasing aparece nas bordas do `_Slot`. Importante para a regra 1-bit estrita.
- **Race entre `setStyle` e animação em andamento**: usuário troca o estilo enquanto uma rolagem está animando. Solução: `DiceAnimator` lê `style` no `build` mas só re-cria a strategy filha quando `targetValues` muda; animação em curso completa com o estilo antigo. Verificar com teste.
- **`AnimatedSwitcher` mantém o widget filho 200ms a mais** (fade default). Com `transitionBuilder` custom (hard cut), o filho é trocado imediatamente — o "duration: 100ms" vira só o atraso de unmount. Aceitável.
- **Substituição futura por sprite sheets**: hoje cada `_Slot` é `Container + Text`. Quando sprites entrarem, vira `Image.asset(spriteFor(side, frame))`. O `frame` precisa ser exposto pela strategy — assinar isso explicitamente: `DrumAnimation` e `TabletopAnimation` mantêm um `_frameIndex` int que será passado adiante quando o `_Slot` aceitar sprites. Não implementar agora.

## References

- [docs/roadmap/01-escopo-m1.md](../roadmap/01-escopo-m1.md) — defaults M1 (Tambor + Médio), feature 9
- [docs/roadmap/03-stack-tecnico.md](../roadmap/03-stack-tecnico.md) — `flame` opcional (não usar no M1), sprite sheets futuros
- [lib/core/storage/models/animation_settings.dart](../../lib/core/storage/models/animation_settings.dart) — enums já existentes
- [docs/plan/2026-05-26-feat-e08-settings-screen-plan.md](2026-05-26-feat-e08-settings-screen-plan.md) — `AnimationSettingsController` (consumido por E12)
- [lib/features/dice/widgets/dice_widget.dart](../../lib/features/dice/widgets/dice_widget.dart) — current placeholder grid
- [lib/features/dice/dice_controller.dart](../../lib/features/dice/dice_controller.dart) — emits `RollResult` (the animation trigger)
