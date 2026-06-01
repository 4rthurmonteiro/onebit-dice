---
date: 2026-05-30
topic: dice-screen-c-redesign
---

# Redesign da DiceScreen — Design C (tap-to-roll)

## What We're Building

Inverter a hierarquia da tela **Rolar** (`DiceScreen`). Hoje a tela empilha 7
botões de tipo em largura cheia e empurra o botão **ROLAR** para baixo da dobra.
No **Design C**, o canvas do dado vira o **herói** e o **próprio botão de rolar**:
tocar em qualquer ponto da área do dado dispara `controller.roll()` (com a
animação atual — tabletop/fast/drum — preservada). Não existe mais botão grande
"ROLAR".

Os controles encolhem para uma **barra fina** acima da tab bar, em uma linha: um
**campo de tipo** `D20 ▾` (que abre um **bottom sheet**, Variante A — lista
vertical dos 7 tipos) à esquerda, e o **stepper de quantidade** `− N +`
(clamp 1–10) à direita. O resultado continua sendo renderizado pelo `DiceWidget`
existente (faces + `TOTAL` + equação), centralizado no canvas herói.

## Why This Approach

Foram consideradas três frentes de decisão; em todas privilegiamos **preservar o
que já funciona** (animações, `DiceWidget`, controller) e mexer no **layout** e
na **forma de escolher o tipo**, em vez de reescrever a renderização:

- **Canvas-como-botão** (escolhido) em vez de manter um CTA dedicado: elimina o
  problema da dobra, dá ao dado o protagonismo do Design C e reduz a distância
  de toque (Fitts) — a maior área da tela é o alvo.
- **Bottom sheet (Variante A — lista)** em vez dos 7 chips na tela: a lista
  vertical é a solução mais fiel ao 1-bit (só bordas e inversão), tem alvo de
  toque ≥44px por item e libera a tela principal para o herói. A própria nota de
  design do arquivo 03 recomenda a Variante A para o M1.
- **Reaproveitar `DiceWidget`** em vez de reescrever o bloco de resultado:
  preserva as três animações e a cobertura de testes existente; o efeito "herói"
  vem de centralizá-lo num canvas grande e tocável.

## Key Decisions

- **Tap-to-roll:** a área do dado é um `GestureDetector`
  (`HitTestBehavior.opaque`) com `Semantics(button: true, label: "Rolar dados")`;
  o tap chama `controller.roll()`. Remove-se `RollButton`
  (`roll_button.dart` + teste deletados).
- **Scrim do sheet — hachura 1-bit fiel:** barrier customizado com hachura
  xadrez 4×4 (preto/branco), reproduzindo o "dimming" do mockup sem usar cinza
  nem alpha. Não usar o scrim translúcido padrão. Implementado via
  `showGeneralDialog`/`showModalBottomSheet` com `barrierColor: transparent` +
  overlay `CustomPaint` hachurado (ou um `ModalRoute` customizado).
- **Resultado — manter `DiceWidget` atual:** faces + `TOTAL` + equação dentro da
  moldura existente; preserva animações e testes. O herói é o canvas ao redor.
- **Dica de toque — só até a 1ª rolagem:** `▸ TOQUE PARA ROLAR ◂` visível no
  canvas até o primeiro roll da sessão, depois some permanentemente. Requer uma
  flag de sessão `hasRolled` no `DiceController` (não basta `lastResult == null`,
  pois trocar tipo/quantidade limpa `lastResult` e faria a dica reaparecer).
- **Lista do sheet — completa (fiel ao arquivo 03):** cada item tem badge pixel
  da forma + label (`D20`) + sublabel `N LADOS`; o tipo atual é invertido
  (ink/paper) + checkmark pixel. Título `ESCOLHER DADO`, drag handle pixel,
  fecha por tap-fora / arrastar pra baixo / ✕.
- **Campo de tipo:** `type_selector.dart` deixa de ser os 7 chips e vira o campo
  compacto `{label} ▾` (≥44px, `Semantics` button com value = tipo atual) que
  abre o sheet. A lista dos 7 tipos migra para o novo widget do sheet.
- **Stepper compacto:** `quantity_selector.dart` passa de full-width
  (`spaceBetween`) para um grupo justo `− N +` (`mainAxisSize.min`), mantendo
  botões 44×44, clamp 1–10 e os `Semantics` existentes.
- **i18n:** novas chaves em todos os 12 locales (template `app_pt_BR.arb`):
  `rollTapHint`, `rollCanvasLabel`, `diceTypeSheetTitle`, `diceTypeFieldLabel`,
  `diceTypeSidesLabel` (`{count}`). Rodar `flutter gen-l10n`.
- **Restrições mantidas:** paleta estrita 2 cores (ink/paper), sem gradiente/
  sombra/tom intermediário; state com `setState`/`ChangeNotifier`/`provider`;
  acessibilidade com `Semantics` no canvas, campo de tipo e stepper; alvos ≥44px.
- **Quality gates:** `flutter analyze` 0 issues + `flutter test --coverage`
  verde com 100% de cobertura de linha (testes novos/atualizados para a tela, o
  sheet, o campo de tipo e o stepper).

## Open Questions

- **Badges das formas no sheet:** os glifos do mockup (`▲ ■ ◆ ◇ ⬠ ⬟ %`) podem não
  renderizar nas fontes pixel (Silkscreen/PressStart2P). Avaliar no plano: mapear
  cada `DiceType` para um badge confiável ou desenhar via `CustomPaint`/SVG.
- **Pixel-art da hachura do scrim:** definir no plano se via `CustomPainter`
  (tile 4×4) repintado ou um `DecoratedBox` com `ImageShader`/asset — manter
  perfeitamente "pixelado" sem anti-aliasing.
- **`hasRolled` e troca de tipo:** confirmado que a dica não reaparece ao trocar
  tipo/quantidade após a 1ª rolagem (flag de sessão, não derivada de
  `lastResult`). Reset apenas em nova sessão.
