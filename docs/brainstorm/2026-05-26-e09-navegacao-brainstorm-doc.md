---
date: 2026-05-26
topic: e09-navegacao
---

# E09 — Navegação (App Shell + Splash)

> Equivale a **EPIC 6** (Splash) + **EPIC 7** (Navegação) no `docs/plan/progress.md`. Tratamos os dois como um único epic E09 ("Navegação") conforme o `docs/roadmap/08-epics-m1.md`, porque ambos compõem o app shell e devem entrar juntos: o splash é a porta de entrada e o tab shell é o que ele substitui.

## What We're Building

O esqueleto navegável do app. Hoje [lib/app.dart:92](../../lib/app.dart#L92) joga `DiceScreen` direto como `home`; E09 substitui isso por:

1. **Splash em dois estágios** — `flutter_native_splash` cobre o cold-start (ícone + bg sólido, ~300–800ms) e elimina o flash branco; quando o Flutter inicializa, uma `SplashScreen` widget desenha wordmark "1-BIT DICE" + tagline + d6 pixel art + microtexto COCU por ~1.5s e navega para o shell.
2. **App shell com 4 abas** — `RetroTabBar` na parte inferior com tabs **ROLAR / HISTÓRICO / JOGOS / AJUSTES**, ícones pixel art 24×24 (d6, ampulheta, estrela, engrenagem) + label VT323 caixa alta. Cada tab preserva seu próprio Navigator (estado da `DiceScreen` sobrevive a trocas de aba).
3. **Stubs por feature** para as 3 telas ainda não implementadas (`HistoryScreen`, `PresetsScreen`, `SettingsScreen`) — cada uma com um centro "EM BREVE", ocupando a estrutura final de pastas para que E06/E07/E08 só substituam o conteúdo.

Assets visuais reais (ícone do app 1024×1024 + sprite final do splash nativo) ficam para **E14**; aqui usamos placeholder gerado a partir do d6 pixel art já existente para que `flutter_native_splash:create` rode.

## Why This Approach

**Navegação via `go_router` + `go_router_builder` + `StatefulShellRoute`.** É o padrão moderno do Flutter para shells com bottom nav: cada branch tem seu próprio Navigator com back-stack independente e estado preservado entre trocas, suporta deep links nativamente e gera APIs type-safe via codegen. Alternativas consideradas e rejeitadas:

- **`IndexedStack` + `setState` manual** — funciona mecanicamente, mas é ad-hoc: sem URLs, sem deep links, sem restoration semantics, e mistura roteamento com state mgmt de UI. Bloqueado por regra de projeto (ver memória `feedback_no_indexed_stack_use_go_router`).
- **`PageView` com swipe entre abas** — UX de tabs paginadas conflita com a expectativa de bottom nav (tap, não swipe) e dificulta animações distintas por aba no futuro.
- **`Navigator.pushReplacementNamed` por tap** — descarta o estado da tela ao trocar de aba; voltar a "ROLAR" depois de visitar "HISTÓRICO" perderia o resultado em tela. Quebra UX esperada de bottom nav.

**Two-stage splash.** Native splash sozinho não consegue mostrar wordmark/tagline/microtexto (são limitados a um drawable centralizado), e Flutter splash sozinho deixa o sistema mostrar um flash do bg padrão (branco no iOS, splash da launcher no Android) antes do Flutter inicializar — quebra a sensação retrô. O two-stage entrega "liga e já está no universo do app". O microtexto COCU no rodapé do splash é, junto com a descrição da loja, o único ponto de contato com o universo Call of Old Chico (ver `docs/roadmap/00-visao-geral.md:12`), então não pode sair.

**Stubs por feature, não placeholder único.** Cada uma das 3 telas pendentes ganha seu arquivo final em `lib/features/<feature>/<feature>_screen.dart` com um widget centralizado "EM BREVE". Mais arquivos agora, mas E06/E07/E08 só trocam o conteúdo sem mover nada, e a estrutura de pastas representa a arquitetura real desde já. Um `PlaceholderScreen(title)` compartilhado seria menos código no curto prazo mas exigiria refator para "tirar o compartilhado de cena" quando cada feature for implementada.

**Tudo localizado via ARB.** Tab labels (`ROLAR`/`HISTÓRICO`/`JOGOS`/`AJUSTES`), tagline (`Dice for every game`), placeholder (`EM BREVE`), e o microtexto COCU entram nos 11 ARBs já existentes em `lib/l10n/`. E13 entregou i18n completa; deixar strings novas hard-coded em PT seria regressão. O microtexto COCU vai como string traduzível mesmo contendo o nome próprio "Call of Old Chico" — tradutores mantêm o nome e adaptam o resto ("parte do universo Call of Old Chico").

**Aba inicial sempre `ROLAR`, sem persistência de seleção de tab.** O roadmap (`docs/roadmap/01-escopo-m1.md:77`) diz "Splash → Home" como estado inicial canônico. Persistir a última tab visitada agregaria pouco valor e adicionaria mais uma chave de SharedPreferences — YAGNI.

## Key Decisions

- **`go_router` + `go_router_builder` + `StatefulShellRoute` para o shell.** Adicionar `go_router` (dep) e `go_router_builder` (dev_dep, + `build_runner` já presente em E04) no `pubspec.yaml`. Definir uma `StatefulShellRoute.indexedStack(...)` com 4 branches (`/dice`, `/history`, `/presets`, `/settings`) e uma rota top-level `/` para o splash. `lib/app.dart` troca `MaterialApp(home: ...)` por `MaterialApp.router(routerConfig: ...)`. **Por quê:** padrão moderno, deep links nativos, per-branch state, type-safe via codegen. Bloqueado contra `IndexedStack` manual por regra de projeto.

- **`AppShell` recebe `StatefulNavigationShell`.** O widget `AppShell` (em `lib/features/shell/app_shell.dart`) é o `builder` da `StatefulShellRoute`. Faz um `Scaffold(body: navigationShell, bottomNavigationBar: RetroTabBar(shell: navigationShell))`. O `RetroTabBar` lê `shell.currentIndex` e chama `shell.goBranch(index, initialLocation: index == shell.currentIndex)` no tap (esse `initialLocation: true` quando re-tap reseta a aba ao topo — comportamento esperado em bottom nav). **Por quê:** API canônica do `StatefulShellRoute`; mantém o shell agnóstico ao conteúdo das tabs.

- **`RetroTabBar` é shared, não feature-internal.** Mora em `lib/shared/widgets/retro_tab_bar.dart` ao lado de `MacButton`, `MacWindow`, `PixelDivider`. **Por quê:** é design system (mesma família estética dos outros widgets shared); reusável em testes/previews.

- **Ícones de tab inline via `CustomPaint` (1-bit pixel grid), não asset SVG.** Os 4 ícones (d6, ampulheta, estrela, engrenagem) são 24×24 em duas cores da paleta ativa. Renderizar via `CustomPainter` que recebe uma matriz `List<List<int>>` (0=paper, 1=ink) mantém perfeita fidelidade pixel-perfect, reage automaticamente à troca de paleta (o painter usa `Theme.of(context).extension<OneBitColors>()`), e não exige toolchain de SVG. Estado ativo: ícone preenchido / inverso de cor conforme `docs/roadmap/02-identidade-visual.md:107`. **Por quê:** consistência com a abordagem dos outros widgets do design system; permite trocar paleta sem reprocessar assets.

- **`SplashScreen` é `StatefulWidget` com `Timer` 1.5s.** Em `lib/features/splash/splash_screen.dart`. `initState` agenda `Timer(Duration(milliseconds: 1500), () => context.go('/dice'))`. `dispose` cancela o timer. Conteúdo: wordmark "1-BIT DICE" (Press Start 2P, double-line), divisor pixel, tagline localizada, d6 pixel art 144×144 (`CustomPaint` reutilizado), e no rodapé "v1.0 · am2 studios" + microtexto COCU. **Por quê:** lifecycle simples; o `Timer` cancelado em dispose evita disparar `go` em widget desmontado se a tela for trocada manualmente em desenvolvimento.

- **Versão no splash lida via `package_info_plus` ou hard-coded?** Inicialmente hard-coded como `"v1.0"` para fechar o epic sem nova dependência. Se a equipe quiser dinâmico depois, plugar `package_info_plus` é trivial. (Decisão de YAGNI explícita.)

- **`flutter_native_splash.yaml` em E09, com placeholder de ícone.** Configurar `color: "#FFFFFF"` + `image: assets/icon/icon.png`. Como `assets/icon/icon.png` real é E14 (humano), gerar um PNG placeholder a partir do d6 pixel art (32×32 → scale 32× para 1024×1024 com nearest-neighbor) e committar. Rodar `dart run flutter_native_splash:create`. **Por quê:** E09 não pode ficar pendurado em E14; placeholder permite gerar a config nativa agora e E14 só troca o PNG.

- **Stubs por feature, sem widget compartilhado.**
  - `lib/features/history/history_screen.dart` — `HistoryScreen` com `Scaffold` + `Center(Text(l10n.commonComingSoon))`
  - `lib/features/presets/presets_screen.dart` — idem
  - `lib/features/settings/settings_screen.dart` — idem
  
  Cada uma com `AppBar` opcional mostrando o título da feature (vindo de l10n). **Por quê:** estrutura de pastas final desde já, E06/E07/E08 só substituem o body.

- **Splash → shell via `context.go('/dice')`, sem animação custom.** Estética 1-bit não casa com fade/slide; hard cut é a transição correta. `go_router` por padrão usa a transição da plataforma, então sobrescrever a rota do splash com `NoTransitionPage` (ou customizar a transition para zero duration). **Por quê:** consistência visual; evita a sensação "moderna" de fade que conflita com o look.

- **Tab inicial sempre `/dice`.** `initialLocation: '/'` (splash) → splash redireciona para `/dice` após 1.5s. Se o usuário matar o app na aba HISTÓRICO, ao reabrir cai em ROLAR. **Por quê:** alinha com `01-escopo-m1.md:77`; YAGNI em persistir tab.

- **Strings novas em ARB (template `app_pt_BR.arb`).** Mínimas:
  - `app_tagline` — "Dice for every game"
  - `nav_tab_dice` — "ROLAR" / "ROLL" / etc
  - `nav_tab_history` — "HISTÓRICO" / "HISTORY" / etc
  - `nav_tab_presets` — "JOGOS" / "GAMES" / etc
  - `nav_tab_settings` — "AJUSTES" / "SETTINGS" / etc
  - `common_coming_soon` — "EM BREVE" / "COMING SOON" / etc
  - `splash_universe_microcopy` — "_part of the call of old chico universe_" (mantendo formatação)
  - `splash_version` — "v1.0 · am2 studios" (ou só "am2 studios" se versão for dinâmica depois)
  
  Replicar nos 10 ARBs traduzidos. **Por quê:** mantém i18n consistente; tradutores podem adaptar microcopy COCU preservando o nome próprio.

- **Remoção de hospedeiro provisório em `lib/app.dart`.** A linha `home: const DiceScreen()` ([lib/app.dart:92](../../lib/app.dart#L92)) sai. `MaterialApp` vira `MaterialApp.router`, recebe `routerConfig`. O `DiceController` continua provido pelo `MultiProvider` no nível raiz — `go_router` não interfere em `Provider`. **Por quê:** ambos coexistem; providers ficam acima da raiz do router para permanecerem visíveis em todas as rotas.

- **Testes obrigatórios** (mantendo 100% line coverage):
  - `test/features/splash/splash_screen_test.dart` — renderiza wordmark/tagline/microtexto/d6; após 1.5s (via `tester.pump(Duration(seconds: 2))`) navega para `/dice`; dispose cancela o timer (pump após dispose não dispara nav).
  - `test/features/shell/app_shell_test.dart` — renderiza `RetroTabBar` com 4 tabs; tap em cada tab muda o `currentIndex` do shell; re-tap na tab ativa não quebra; estado da tab `ROLAR` (resultado da rolagem) sobrevive a uma ida e volta para `HISTÓRICO`.
  - `test/shared/widgets/retro_tab_bar_test.dart` — renderiza 4 ícones + 4 labels; tab ativa fica visualmente inversa; tap dispara callback com índice correto.
  - `test/features/history/history_screen_test.dart` (+ idem presets, settings) — renderiza string `common_coming_soon` localizada.
  - `test/widget_test.dart` — atualizar para refletir `MaterialApp.router`.

## Open Questions

- **Versão do go_router e do go_router_builder a fixar.** Pegar as versões compatíveis com `pubspec.yaml` atual (Flutter 3.x estável). Decidir no /plan com `pub_dev_search` para alinhar com Dart `^3.12.0`.

- **Microtexto COCU: itálico + underscores literais.** O prototype renderiza `_part of the call of old chico universe_` com underscores como decoração textual (não como Markdown). Em Flutter, ou colocamos os underscores literalmente na string traduzida ou aplicamos `fontStyle: italic` programaticamente. Sugestão: deixar a string sem underscores (`part of the call of old chico universe`) e aplicar estilo no widget — facilita tradução. Confirmar no /plan.

- **`flutter_native_splash` dark mode.** Configurar `color_dark` + `image_dark` na yaml? Como a paleta padrão é Mac Classic (preto sobre branco) e a tela está sempre na paleta escolhida (não respeita sistema), a sugestão é ignorar dark mode no native splash — bg branco fixo. Confirmar no /plan se vale o esforço de uma variante dark.

- **Splash deve respeitar a paleta escolhida pelo usuário?** Argumento contra: na primeira execução não há paleta persistida; argumento pró: em execuções subsequentes, splash em paleta-alvo seria coerente. Sugestão MVP: splash sempre em Mac Classic (preto/branco); paleta entra ao montar o shell. Validar no /plan.

- **Reordenar `progress.md`** — os EPICs 6 (Splash) e 7 (Navegação) hoje listados separadamente devem ser fundidos numa nota como foi feito em EPIC 4/E10. Atualizar como parte da PR de E09.

- **`coverage:ignore-file` em rotas geradas (`*.g.dart`) do `go_router_builder`.** Já estão no exclude global de coverage (per `CLAUDE.md`), mas reconfirmar quando rodar `build_runner` que o pacote gera com sufixo `.g.dart`.

- **Atalho "gear" no AppBar da home.** O prototype `03-splash-home.html` mostra um ícone de engrenagem no canto superior direito da home (atalho para Ajustes). Como `AJUSTES` já é uma tab, esse atalho é redundante. Sugestão: descartar o gear-btn do AppBar da home (não está no canon `04-secondary-screens.html`). Confirmar no /plan.
