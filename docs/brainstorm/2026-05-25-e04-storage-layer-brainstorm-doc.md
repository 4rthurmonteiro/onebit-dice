---
date: 2026-05-25
topic: e04-storage-layer
---

# E04 — Storage Layer (Persistência Local)

## What We're Building

Camada de persistência local do 1-Bit Dice MVP: configurações do app (paleta, som, haptic, estilo/velocidade de animação, última configuração de dado/quantidade), histórico completo de rolagens (sem limite) e até 10 presets customizados criados pelo usuário. O app é 100% offline — não há sync, login ou backend.

A camada será consumida pelos EPICs seguintes: histórico (E06), presets (E07), ajustes (E08) e tela principal (E05, que precisa restaurar a última config de dado).

## Why This Approach

O roadmap (`01-escopo-m1.md`) já decidiu o backend técnico: `shared_preferences` pra configs simples e Hive pra dados estruturados (histórico + presets). O brainstorm refinou três pontos que o roadmap deixou em aberto:

1. **Padrão de exposição** — seguir o padrão já estabelecido em E02 (`PalettePreference` interface + `InMemoryPalettePreference`) ao invés de inventar um novo. Isso mantém consistência arquitetural e torna o teste de features triviais (injetar fake in-memory).
2. **Backend Hive** — trocar `hive` 2.x clássico (em modo manutenção desde 2023) por `hive_ce` (community edition, fork ativamente mantido, API idêntica, drop-in replacement). Custo zero hoje, evita dívida técnica em 12-18 meses.
3. **Inicialização** — aproveitar o splash screen (E06, com delay de 1.5s já planejado) como gate de inicialização ao invés de bloquear o `main()`. Splash roda enquanto `HiveInit.init()` resolve; quando completa, monta o app shell já com boxes prontas. Repos nunca lidam com estado "not ready".

## Key Decisions

- **Interfaces por domínio** — uma interface por tipo de dado (`AppSettingsPreference`, `LastDiceConfigPreference`, `HistoryRepository`, `PresetsRepository`), cada uma com impl real (Hive/SharedPrefs) + `InMemory*` para testes. Mantém o padrão de `PalettePreference` já em uso.
- **`hive_ce` em vez de `hive`** — fork mantido, mesma API, mesmos `typeId`s. Future-proof sem custo de migração.
- **`shared_preferences` para configs primitivas** — paleta, toggles de som/haptic, estilo/velocidade de animação, último `DiceType` selecionado, última `count`. Operações síncronas após init.
- **`hive_ce` para coleções tipadas** — `RollEntry` (histórico, append-only) e `CustomPreset` (até 10 slots, CRUD completo).
- **Splash screen como gate de init** — `main()` chama apenas `runApp()`; `SplashScreen` aguarda `Future.wait([HiveInit.init(), SharedPreferences.getInstance(), minDelay(1.5s)])` antes de transicionar pro app shell. Esse encaixe será detalhado em E06.
- **RollEntry com schema completo** — `timestamp`, `diceType`, `count`, `individualResults: List<int>`, `total`. Permite a tela de histórico mostrar "3d6: 4+2+5 = 11" sem parsing de string, e habilita filtros/analytics futuros sem migração.
- **`typeId` allocation** — `RollEntry` = `0`, `CustomPreset` = `1`. Reservar `2-9` pra modelos futuros. `DiceType` é enum simples e será serializado como `index` (int), evitando `typeId` adicional.
- **"Limpar histórico" = hard delete** — `box.clear()` direto, sem soft delete. App não tem undo, não tem sync, e o diálogo de confirmação já cobre o risco de erro.
- **Migração de schema** — usar `@HiveField(N)` desde o dia 1 com numeração contígua; novos campos sempre `nullable` ou com default. Nunca renumerar/remover campos sem release de migração explícita. Documentar no header de cada `@HiveType`.

## Open Questions

- **Path do diretório Hive**: usar `path_provider` + `Hive.initFlutter()` (default em `getApplicationDocumentsDirectory`)? Confirmar no plano.
- **Encriptação at-rest**: roadmap não menciona. Dados não-sensíveis (rolagens de dado), então default = sem criptografia. Confirmar no plano para fechar a decisão.
- **Backup automático Android/iOS**: arquivos em `getApplicationDocumentsDirectory` são incluídos no backup do sistema por padrão. Manter ou excluir? (Provavelmente manter — usuário gostaria de recuperar presets ao trocar de aparelho.)
- **Performance da `HistoryScreen` com 10k+ entradas**: out-of-scope desta camada, mas usar `Hive.openBox` (não-lazy) significa carregar tudo na RAM. Tratar paginação/lazy só se virar problema real.
- **Testes do Hive**: usar `hive_ce` em diretório temporário (`Hive.init(Directory.systemTemp.createTempSync().path)`) ou criar fake `HistoryRepository` em memória? Resposta esperada: ambos — repos de feature usam fake in-memory; a impl Hive tem seus próprios testes de integração com diretório temporário.
