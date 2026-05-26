---
date: 2026-05-26
topic: e05-dice-screen
---

# E05 — Tela Principal (Rolar)

> Equivale ao **EPIC 8** no `docs/plan/progress.md` (a numeração do tracker diverge da do roadmap). A partir daqui usamos o nome canônico `E05` para combinar com os outros brainstorms.

## What We're Building

A tela principal do 1-Bit Dice — o coração funcional do MVP. Compõe um seletor de tipo (`DiceType` × 7), um stepper de quantidade clampado em 1..10, uma área de resultado pixel-grid e um botão `ROLAR` full-width. A rolagem usa `Random.secure()` via `rollDice()` (E03), reproduz o SFX `total` (E10), dispara um pulso háptico médio (E10), persiste a última configuração via `LastDiceConfigPreference` (E04), e appenda o `RollResult` no `HistoryRepository` (E04).

A animação real (multi-fase) e o uso completo dos três sons (`roll`/`stop`/`total`) ficam para E12 (Animações dos Dados). Em E05 o `DiceWidget` é um placeholder textual em Silkscreen — mas já estruturado como grid de N slots para que E12 plugue sprite sheets sem refator visual.

## Why This Approach

**O `DiceController` orquestra tudo.** O padrão consistente do projeto (ver `AudioController`, `HapticController`, `ThemeProvider`) é um `ChangeNotifier` por concern que recebe suas dependências via construtor. Aplicar a mesma ideia aqui mantém os widgets puramente declarativos e centraliza o ciclo da rolagem (compute → history → audio → haptic → persist) num único lugar testável. Alternativas consideradas e rejeitadas:

- **Controller só com estado puro, widget orquestra side-effects** — espalha lógica pela árvore de widgets e quebra a simetria com os controllers já existentes.
- **`RollOrchestrator` separado entre controller e deps** — terceira camada gratuita; viola YAGNI.

**Hive fica para E06 (Splash).** O `HiveInit` já existe mas não é bootstrapado em `main.dart`. A documentação do `HiveInit` é explícita: "consumed by the splash screen (E06)". Em vez de antecipar o boot para E05, consumimos `InMemoryHistoryRepository` e `InMemoryLastDiceConfigPreference` (que já existem como test doubles). Quando E06 entrar, o splash troca essas instâncias pelas versões persistentes sem mudar uma linha do `DiceController`. Isso preserva o sequenciamento original do roadmap e mantém E05 fechado em si mesmo.

**Áudio e haptic mínimos em E05.** Os três SFX (`roll`/`stop`/`total`) só fazem sentido com animação multi-fase em E12. Em E05 tocamos só `total` no momento do resultado e disparamos 1 haptic medium no tap. Encadear `roll → stop → total` com delays fixos seria simulação de animação que vai ser descartada — não vale o código temporário.

**Display em grid de slots, não só equação.** Cada `DiceType` rolado vira um "slot" visual independente: número grande Silkscreen em pixel grid (ex: até 3 colunas), com o total destacado abaixo. Renderizar só `RollResult.equation` em texto seria mais simples, mas E12 vai animar cada dado independentemente — começar já com a estrutura de slots evita refator visual quando os sprites entrarem.

**Estado vazio = slots com `?`.** Antes da primeira rolagem, mostramos N slots `?` que reagem em tempo real ao quantity selector. Isso sinaliza intenção ("você vai rolar 5 dados") sem exigir uma string de instrução adicional ("toque ROLAR") nem deixar a área colapsada. Após mudar `type` ou `count`, o resultado anterior é descartado da view e voltamos para slots `?` — a área de resultado representa **a rolagem corrente em fila ou recém-saída**, não um histórico volátil.

## Key Decisions

- **`DiceController` é o único orquestrador.** Construtor recebe `HistoryRepository`, `AudioController`, `HapticController`, `LastDiceConfigPreference`. Expõe `selectedType`, `count`, `lastResult` (nullable) e métodos `setType(DiceType)`, `setCount(int)`, `roll()`. Side-effects do `roll()` em ordem: gera `RollResult` (via `rollDice` + `DateTime.now()`) → notifica → `history.append` → `audio.play(SoundEvent.total)` → `haptic.trigger()` → `lastDiceConfig.write(...)`. **Por quê:** simetria com `AudioController`/`HapticController`, ponto único de teste, widget fica declarativo.

- **Hive bootstrap fica para E06.** Em E05, `lib/app.dart` constrói o `DiceController` com `InMemoryHistoryRepository()` e `InMemoryLastDiceConfigPreference()` expostos via `Provider`. O `main.dart` ainda não chama `HiveInit.init()`. **Por quê:** preserva a documentação de `HiveInit`, mantém E05 autocontido, e quando E06 entrar a troca para as impls persistidas é local.

- **Estado inicial = `LastDiceConfig.read()` ou defaults.** O `DiceController` lê `LastDiceConfigPreference.read()` no construtor. Quando `null` (primeira execução) ou InMemory vazio: `DiceType.d6` + `count: 1`, conforme `docs/roadmap/01-escopo-m1.md`. **Por quê:** alinha com o roadmap; em E06, quando a impl persistida entrar, o restore vira efetivo sem mudança de código.

- **Persiste `LastDiceConfig` em toda mutação (não só no `roll`).** `setType` e `setCount` chamam `lastDiceConfig.write(...)` antes de notificar. **Por quê:** o usuário pode fechar o app sem rolar (browsing o seletor) — esperaríamos que a próxima abertura traga essa seleção. SharedPreferences é barato; over-writing é trivial.

- **Em E05 só toca `SoundEvent.total` e dispara 1 haptic.** No `roll()`. Os sons `roll` e `stop` ficam reservados para E12 (Animações). **Por quê:** sem fases de animação, esses sons não têm gatilho semântico; emitir todos os três no mesmo instante seria ruído.

- **Display = grid de slots Silkscreen + total destacado.** `DiceWidget` recebe `List<int>? values` (null = estado vazio "?") e renderiza um grid pixel com até 3 colunas (até 4 linhas para 10 dados). Total embaixo, em fonte maior. Equação textual completa (`"3 + 5 + 2 = 10"`) aparece como linha secundária quando `values.length > 1`. **Por quê:** cada slot é candidato natural a sprite sheet em E12; preserva a hierarquia visual entre "valor individual" e "total".

- **Estado vazio = `?` reativo ao count.** Antes de qualquer rolagem (ou após mudar type/count), o grid mostra N slots `?`. **Por quê:** comunica a "rolagem em fila" sem precisar de string de instrução localizada.

- **Mudar type ou count limpa `lastResult` da view.** Internamente: `setType` / `setCount` setam `_lastResult = null` antes de notificar. **Por quê:** sinaliza que o número exibido refere-se à configuração atual; depois de mexer no seletor, o que estava no grid não bate mais. Histórico no Hive não é afetado.

- **`DiceScreen` vira o `home` em `lib/app.dart`, substituindo `DesignSystemPreview`.** O preview cumpriu seu papel (smoke-test do design system) e está marcado para remoção quando o shell real entrar. Em E05, o shell ainda não existe (E09 = Navegação no roadmap), então a `DiceScreen` é hospedada direto como `home` do `MaterialApp`. Quando E09 entrar, ela vira a tab "ROLAR" do shell. **Por quê:** evita manter dois caminhos de entrada no app; o `DesignSystemPreview` já é compromisso temporário.

- **Layout proposto:** `Scaffold` com `SafeArea`; coluna principal contém — top: título "1-BIT DICE" (display); área de resultado (`DiceWidget` em `MacWindow` opcional para o pixel border); `PixelDivider`; `TypeSelector` (Wrap horizontal de chips); `QuantitySelector` (linha − count +); `RollButton` (`MacButton` full-width "ROLAR") fixo no rodapé com `SafeArea` bottom. Detalhes finos (paddings, qual elemento vai dentro de `MacWindow`) ficam para o /plan.

- **Strings que entram na i18n:** as adições são mínimas — `dice_roll_button_label` ("ROLAR" / "ROLL"), e (se decidirmos exibir) `dice_total_label` ("Total" / "Total"). Os labels dos `DiceType` (`D4`, `D6`, …) são locale-agnostic. **Por quê:** mantém o churn de chaves baixo enquanto a i18n ainda está em PR.

- **Testes obrigatórios** (mantendo 100% line coverage):
  - `dice_controller_test.dart` — defaults, restore via `LastDiceConfigPreference`, clamp de `setCount` em 1..10, `roll()` chama todas as deps na ordem correta, `setType`/`setCount` limpam `lastResult` e persistem config, `roll()` com `Random` injetado para determinismo.
  - `type_selector_test.dart` — renderiza 7 chips, chip selecionado destaca, tap chama callback.
  - `quantity_selector_test.dart` — `−` desabilitado em `count == 1`, `+` desabilitado em `count == 10`, callback dispara corretamente.
  - `dice_screen_test.dart` — integração: tap em `ROLAR` muda a view para o grid de valores, `HistoryRepository.append` foi chamado, `AudioController.play(total)` foi chamado, `HapticController.trigger()` foi chamado, e mudar `count` volta para `?`.

## Open Questions

- **Tap targets ≥ 44pt nos chips de tipo:** com 7 tipos em `Wrap`, em telas estreitas (e.g. iPhone SE 1ª gen) podem espremer demais. Decidir no /plan se a estratégia é "scroll horizontal" ou "grid 2 linhas" — a princípio `Wrap` cobre o caso.
- **`MacWindow` envolve o `DiceWidget`?** Cosméticamente combinaria, mas adiciona uma title bar listrada por cima do grid. Decisão visual para a fase de implementação (provavelmente um `A/B` rápido no simulador).
- **Semantic labels para TalkBack/VoiceOver:** o roadmap pede acessibilidade básica. Cada chip de tipo e o botão `ROLAR` precisam de `Semantics` explícito. As chaves de l10n correspondentes (`dice_type_d6_semantic`, etc.) entram em E05 ou aguardam E11 (Ajustes)? Sugere-se que entrem agora junto com as outras strings.
- **Equação textual abaixo do total:** mostrar `"3 + 5 + 2 = 10"` sempre, só para `count > 1`, ou nunca (deixar só os slots + total falarem)? Recomendo "só para `count > 1`" — para 1 dado, o slot já é o resultado.
- **`coverage:ignore-file` em `dice_screen.dart`?** A composição vai ter linhas de layout puro que talvez não compensem testar. Decidir no /plan; preferência inicial: cobrir tudo via `dice_screen_test.dart`.
