---
date: 2026-05-25
topic: e03-dice-engine
---

# E03 — Engine de Dados (Dice Engine)

## What We're Building

A camada de domínio pura do 1-Bit Dice: tipos de dado canônicos (d4, d6, d8, d10, d12, d20, d100), função de rolagem com `Random.secure()` e modelo imutável de resultado (`RollResult`). Sem UI, sem I/O, sem estado — apenas lógica determinística (dado um RNG) que será consumida pelo `DiceController` no E08, pelos presets no E10 e persistida pelo `RollEntry` (Hive) no E04.

O objetivo é entregar uma API minimalista, testável e correta, com igualdade por valor para suportar testes de comparação e snapshots de histórico.

## Why This Approach

Três abordagens foram consideradas para cada eixo de design e a escolha priorizou **simplicidade, testabilidade e YAGNI**:

- **RNG**: helper top-level com `Random?` opcional é mais simples que uma classe `DiceRoller` injetada via Provider e ainda permite seed determinístico nos testes — sem custo de DI para uma feature stateless.
- **Igualdade**: `package:equatable` em vez de `==`/`hashCode` manual porque o projeto terá outros modelos imutáveis (`RollEntry`, `CustomPreset`, `Preset`) — adicionar a dep uma vez evita boilerplate repetido em ~5+ classes.
- **Validação**: `assert` em debug em vez de `throw ArgumentError` porque o engine é código interno; o controller é responsável pelos invariantes do usuário (clamp 1–10). `assert` quebra cedo em dev sem custo em release.

## Key Decisions

- **`enum DiceType` com `sides` e `label`** — 7 valores fixos (d4, d6, d8, d10, d12, d20, d100). Sem caso `custom` no M1; o design permite adicionar em M2 sem refatoração.
- **`Random.secure()` como default, injetável via parâmetro opcional** — `rollDie(int sides, {Random? rng})` e `rollDice(int sides, int count, {Random? rng})`. Singleton privado `_defaultRng` no nível do módulo. **Razão**: simples, testável com `Random(seed)`, sem necessidade de classe ou Provider para uma operação stateless.
- **`RollResult` imutável usando `package:equatable`** — campos: `timestamp`, `diceType`, `diceCount`, `values` (List<int>). `total` e `equation` são getters derivados. **Razão**: igualdade por valor habilita comparação em testes e futuros snapshots; `equatable` será reutilizado por `RollEntry`, `CustomPreset` e `Preset` nos próximos epics.
- **Formato do `equation`** — `"5"` para 1 dado, `"3 + 5 + 2 = 10"` para múltiplos. Mantém o que o plano M1 já especificou; consistente com o que o protótipo HTML já mostra.
- **`assert` para inputs inválidos, sem checagem em release** — `assert(sides > 0)` e `assert(count >= 1)`. **Razão**: engine confia no chamador (controller faz clamp); custo zero em prod, falha cedo em dev.
- **Caminho dos arquivos**: `lib/core/models/dice_type.dart`, `lib/core/models/roll_result.dart`, `lib/shared/utils/random_dice.dart`. Já espelha o plano e a estrutura existente.
- **Cobertura de testes**:
  - `test/core/models/dice_type_test.dart` — labels, `sides`, valores do enum.
  - `test/core/models/roll_result_test.dart` — `total`, `equation` (1 dado e múltiplos), igualdade via Equatable.
  - `test/shared/utils/random_dice_test.dart` — range (sempre 1..sides), distribuição uniforme em 10k iterações (nenhum valor >30% para d6), determinismo com `Random(seed)` injetado.

## Open Questions

- **Adicionar `equatable` ao `pubspec.yaml`** já neste epic, ou no E04 quando os modelos Hive entrarem? *Sugestão*: neste epic, porque o `RollResult` é o primeiro modelo imutável e estabelece o padrão.
- **`equation` quando `total == 0`** (cenário impossível na prática se `count >= 1` e `sides >= 1`) — não precisa de tratamento especial.
- **Limite superior de `count`**? O engine não impõe; o controller clampa em 10 (E08). Confirmar que o engine permanece "burro" (sem clamp) — *decidido: sim*.
- **`DateTime.now()` dentro do `RollResult`?** Construtor recebe `timestamp` explicitamente (não usa `now()` default) — isso facilita testes e mantém a classe pura. *Decidido: sim, sempre explícito.*
