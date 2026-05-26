---
date: 2026-05-26
topic: e13-internationalization
---

# E13 — Internacionalização (i18n / l10n)

## What We're Building

Infraestrutura completa de internacionalização para o 1-Bit Dice, suportando **10 idiomas** desde o lançamento: PT-BR (base), EN, ES, FR, DE, IT, JA, ZH (simplificado), KO e RU. O app seguirá o locale do dispositivo por padrão, com **override manual em Ajustes** (a UI propriamente dita será composta em E08, mas a infra de controller + persistência entra agora).

Junto com a infra, este epic já popula um **vocabulário antecipado** (~30-40 chaves) cobrindo nomes dos dados (d4..d100), labels das 4 abas (ROLAR/HISTÓRICO/JOGOS/AJUSTES), botões comuns (ROLAR, LIMPAR, CONFIRMAR, CANCELAR), nomes dos 7 presets clássicos e títulos de seções de Ajustes. As features futuras (E05–E08) nascem usando `context.l10n.*` sem precisar de retrofit. Traduções dos idiomas extras serão **machine translation direto, sem revisão humana** — escolha pragmática consciente do trade-off de qualidade.

## Why This Approach

Considerei três caminhos:

**Standard Flutter l10n (ARB + `gen-l10n`)** ← escolhido

Stack oficial do Flutter: `flutter_localizations` + `intl` + arquivos `.arb` + codegen via `flutter gen-l10n`. Type-safe, sem deps adicionais além das oficiais, alinhado com o que o roadmap já previa (`pubspec` + `l10n.yaml` + `.arb`). Suporta ICU plural nativamente.

- Pros: zero risco, padrão da comunidade, integra com `MaterialApp.localizationsDelegates`, type-safe via codegen
- Cons: precisa rodar codegen (mas o projeto já usa `build_runner` para Hive — fluxo familiar)
- Best when: o app não tem requisitos exóticos de hot-swap de strings ou carregamento remoto

**`slang` package**

Type-safe com APIs mais ergonômicas, suporte a context-based lookup. Adiciona dependência extra; CLAUDE.md exige justificativa para novos pacotes de estado/distribuição, e `slang` substitui efetivamente o stack oficial.

- Pros: API mais agradável, melhor DX para projetos grandes
- Cons: dep extra, divergência do padrão Flutter, over-engineering para um app de ~30-100 strings
- Best when: app grande com muitos contextos e variantes

**`easy_localization` (JSON em runtime)**

Carrega traduções em runtime, sem codegen.

- Pros: sem etapa de geração
- Cons: perde type-safety, strings só falham em runtime, dep extra
- Best when: traduções precisam ser baixadas remotamente

A escolha do **standard Flutter l10n** é a aplicação direta do princípio "prefer boring patterns" da CLAUDE.md: o app é pequeno, o stack oficial cobre 100% das necessidades, e o roadmap já estava nessa direção.

## Key Decisions

- **10 idiomas suportados**: PT-BR, EN, ES, FR, DE, IT, JA, ZH-Hans, KO, RU. **Sem RTL** (AR/HE) no M1 — adicioná-los exigiria auditoria de layout (alinhamentos, ícones direcionais, bordas) que não cabe nesta epic. Rationale: cobre o grosso das lojas Apple/Google ocidentais e asiáticas sem custo de layout.

- **PT-BR é o `template-arb-file`**: o desenvolvedor é falante nativo de PT-BR e escreve as strings primeiro nesse idioma; as outras 9 línguas derivam por MT. EN é o `fallback-locale` quando o sistema do usuário não está na lista de suportados (convenção global). Rationale: separação clara entre "fonte da verdade" (PT) e "rede de segurança" (EN).

- **Tradução automática direta, sem revisão**: idiomas extras são gerados via MT (ChatGPT/DeepL/equivalente) e versionados como estão. Aceita-se imperfeição em troca de cobertura ampla com baixo custo de manutenção. Rationale: o app tem vocabulário pequeno e termos de jogo são tolerantes a tradução literal; revisão humana por 9 idiomas é inviável para um projeto solo.

- **Sigo o sistema + override persistido em Ajustes**: o app usa o locale do dispositivo por padrão. Usuário pode forçar outro idioma em E08 Ajustes. O override é persistido em `SharedPreferences` (mesmo padrão de `PalettePreference`). Rationale: melhor experiência padrão (zero atrito) + flexibilidade para bilíngues.

- **`LocalePreference` em `lib/core/i18n/` segue o padrão de `PalettePreference`**: interface + `InMemoryLocalePreference` + `SharedPreferencesLocalePreference`. Persiste `Locale.toLanguageTag()` (ex: `pt-BR`, `zh-Hans`) ou `null` para "seguir sistema". Rationale: simetria com o que já existe em `lib/core/theme/palette_preference.dart`.

- **`LocaleController` (`ChangeNotifier`) exposto via `Provider`**: análogo a `ThemeProvider`. Tem `current` (resolved locale), `override` (locale forçado ou null), `setOverride()`, `clearOverride()`. Wired no `app.dart` ao lado do `ThemeProvider`. Rationale: state management consistente com o resto do app (CLAUDE.md: setState + ChangeNotifier + provider).

- **Extension `BuildContext.l10n`**: helper em `lib/core/i18n/l10n_extension.dart` retornando `AppLocalizations.of(context)!` (não-nulo após delegates registrados). Rationale: ergonomia — `context.l10n.rollButton` é mais limpo que `AppLocalizations.of(context)!.rollButton`.

- **ICU plural + `package:intl` para números**: strings com contagem (ex: "rolando N dados") usam sintaxe ICU nos `.arb`. Formatação numérica (totais grandes? não aplicável agora, mas barato deixar pronto) via `NumberFormat.decimalPattern(locale)`. Rationale: padrão, robusto, sem hacks condicionais em Dart.

- **Vocabulário antecipado de ~30-40 chaves**: nomes dos dados (`diceD4`..`diceD100`), labels das abas (`tabRoll`/`tabHistory`/`tabPresets`/`tabSettings`), botões (`actionRoll`/`actionClear`/`actionConfirm`/`actionCancel`), nomes dos 7 presets, títulos de seções de Ajustes. Rationale: features futuras (E05–E08) consomem `context.l10n` direto, sem refator.

- **Strings de `lib/features/_dev/design_system_preview.dart` não são internacionalizadas**: o arquivo é placeholder marcado para remoção em E09. Internacionalizá-lo é trabalho descartado. Rationale: YAGNI ruthless.

- **UI de seleção de locale fica em E08 Ajustes**: o controller + preference + plumbing entram em E13; a UI propriamente dita (lista de idiomas com nomes nativos) é composta quando E08 chegar. Rationale: separar infra de apresentação evita criar mock screens de descarte.

- **Testes**: `LocalePreference` (round-trip de cada idioma + valor inválido), `LocaleController` (notifica listeners, persiste, restaura override no init, clear funciona), um widget test wireando `MaterialApp` com locale forçado e verificando que `context.l10n.actionRoll` re-renderiza ao trocar locale. Sem teste de "tradução está correta" — confiamos no MT. Cobertura visa o gate de 100% de linhas sem teatro.

## Open Questions

- **Estratégia de geração das traduções MT**: usar ChatGPT/Claude com prompt único contendo o `.arb` de PT-BR? DeepL/Google Translate por chave? Decidir no plano. Recomendação preliminar: um único prompt LLM com o `.arb` completo e instrução de preservar placeholders ICU e nomes próprios ("1-Bit Dice", "AM2 Studio", nomes de jogos como "Ludo"/"War"/"Yahtzee" — mantidos no original).

- **Nomes de jogos nos presets são traduzíveis?** "Ludo" varia: PT/ES "Ludo", EN "Parcheesi/Sorry!", DE "Mensch ärgere Dich nicht". Manter no original (Ludo, War, Yahtzee, Craps, Bunco, Farkle, Liar's Dice) simplifica e respeita marcas — decidir no plano.

- **Como expor a lista de idiomas suportados no `LocaleController`?** Usar `AppLocalizations.supportedLocales` gerado, ou hardcodar um array com nomes nativos para exibição em Ajustes? Recomendação: hardcodar `({Locale locale, String nativeName})` na própria camada i18n para evitar acoplar a UI ao gen.

- **Ordem do `supportedLocales` no `MaterialApp`** afeta o fallback do Flutter quando o locale do sistema não bate exatamente — confirmar no plano que PT-BR/EN ficam no topo na ordem certa.

- **Quando o usuário troca de idioma em runtime via override**, todos os widgets re-renderizam? Sim, contanto que `LocaleController` notifique e `app.dart` use `context.watch<LocaleController>()` para alimentar `MaterialApp.locale`. Validar no widget test.

- **Versão exata de `intl`** a usar — `flutter_localizations` pina uma versão específica; precisamos alinhar ou aceitar a versão transitiva sem declarar `intl` direto? Decidir no plano após `flutter pub deps`.
