---
title: "E01 — Setup do Projeto"
date: 2026-05-22
epic: E01
status: brainstorm
---

# E01 — Setup do Projeto

## Contexto

Epic de fundação do 1-Bit Dice. Nenhum outro epic pode avançar sem este estar completo. Cobre cinco áreas: SDK constraints, dependências, estrutura de pastas, linting e CI.

## Decisões tomadas

| Decisão | Escolha | Motivo |
|---|---|---|
| Flutter channel | Stable latest (sem pinagem) | Simplicidade, baixo overhead de manutenção |
| Linting | `very_good_analysis` | Zero config manual, alinhado com toolchain VGV |
| CI jobs | analyze + test + build + coverage | Cobertura completa desde o M1 |
| Estrutura `lib/` | Feature-first | Isolamento por feature, escalável para M2+ |

---

## Features destrinchadas

### F01 — SDK & Platform Constraints

**O que é:** Configurar `pubspec.yaml` com versões de SDK e targets de plataforma.

**Sub-tarefas:**
- Dart SDK: `^3.12.0` no `pubspec.yaml`
- Android `minSdkVersion: 21` (Android 5.0+) em `android/app/build.gradle`
- iOS `IPHONEOS_DEPLOYMENT_TARGET: 13.0` em `ios/Runner.xcodeproj`
- Bundle IDs: `com.am2.onebitdice` (Android + iOS)
- App name: `1-Bit Dice`

**Critério de aceite:** `flutter pub get` sem warnings de SDK incompatível.

---

### F02 — Dependências (pubspec.yaml)

**O que é:** Declarar todas as dependências do M1 agrupadas por categoria.

**Dependências de produção:**

| Grupo | Pacote | Propósito |
|---|---|---|
| Persistência | `shared_preferences ^2.3.0` | Configurações simples |
| Persistência | `hive ^2.2.3` | Histórico e presets |
| Persistência | `hive_flutter ^1.1.0` | Init do Hive no Flutter |
| Firebase | `firebase_core ^3.0.0` | Bootstrap (necessário para Crashlytics + Analytics) |
| Firebase | `firebase_crashlytics ^4.0.0` | Crash reporting em produção |
| Firebase | `firebase_analytics ^11.0.0` | 9 eventos de uso anônimo |
| UI | `flutter_native_splash ^2.4.0` | Splash nativo gerado automaticamente |
| UI | `flutter_launcher_icons ^0.14.0` | Ícones em todas resoluções |
| Áudio | `just_audio ^0.9.40` | Sons de rolagem |
| Fonte | `google_fonts ^6.2.0` | Fontes pixel (Silkscreen, VT323, Press Start 2P) |
| i18n | `flutter_localizations` (SDK) | Base para localização |
| i18n | `intl ^0.19.0` | Formatação e strings localizadas |

**Dev dependencies:**

| Pacote | Propósito |
|---|---|
| `build_runner ^2.4.0` | Geração de código (Hive adapters) |
| `hive_generator ^2.0.1` | Gerador de `TypeAdapter` para Hive |
| `very_good_analysis ^7.0.0` | Linting |

**Sub-tarefas:**
- Atualizar `pubspec.yaml` com todas as dependências acima
- Rodar `flutter pub get` — deve resolver sem conflitos
- Verificar `pubspec.lock` gerado (commitar junto)

**Critério de aceite:** `flutter pub get` limpo, zero conflitos de versão.

---

### F03 — Estrutura de Pastas

**O que é:** Criar a hierarquia de diretórios do projeto com placeholders.

**Estrutura `lib/`:**

```
lib/
├── main.dart              ← reescrever (Firebase init + runApp)
├── app.dart               ← MaterialApp + ThemeProvider (placeholder)
├── core/
│   ├── theme/
│   ├── storage/
│   │   └── models/
│   ├── audio/
│   ├── haptic/
│   ├── models/
│   └── analytics/
├── features/
│   ├── dice/
│   │   └── widgets/
│   ├── history/
│   │   └── widgets/
│   ├── presets/
│   │   └── widgets/
│   ├── settings/
│   │   └── widgets/
│   └── splash/
└── shared/
    ├── widgets/
    └── utils/
```

**Estrutura `test/`** (espelhando `lib/`):

```
test/
├── core/
│   ├── models/
│   ├── storage/
│   └── analytics/
└── features/
    ├── dice/
    ├── history/
    ├── presets/
    └── settings/
```

**Estrutura `assets/`:**

```
assets/
├── fonts/           ← .ttf das fontes pixel
├── sprites/         ← sprite sheets dos dados
└── sounds/          ← roll.mp3, stop.mp3, total.mp3
```

**Sub-tarefas:**
- Criar pastas com arquivos `.gitkeep` nos diretórios sem código ainda
- Declarar `assets/` no `pubspec.yaml` (fonts + sprites + sounds)
- Criar `lib/app.dart` com placeholder `// TODO: implement`

**Critério de aceite:** `flutter analyze` limpo com a estrutura criada.

---

### F04 — Linting (`analysis_options.yaml`)

**O que é:** Substituir o `flutter_lints` default por `very_good_analysis`.

**Conteúdo final:**

```yaml
include: package:very_good_analysis/analysis_options.yaml
```

**Sub-tarefas:**
- Remover `flutter_lints` das dev dependencies
- Adicionar `very_good_analysis ^7.0.0` nas dev dependencies
- Substituir conteúdo de `analysis_options.yaml`
- Rodar `flutter analyze` — corrigir todos os warnings/erros introduzidos

**Critério de aceite:** `flutter analyze` com exit code 0, zero issues.

---

### F05 — CLAUDE.md

**O que é:** Arquivo de convenções do projeto e instruções para o agent loop.

**Conteúdo mínimo:**
- Descrição do projeto (1-Bit Dice, AM2 Studio, propósito do app)
- Stack técnico resumido (Flutter + Firebase + Hive + just_audio)
- Estrutura de pastas (mapa resumido)
- State management: `setState` + `ChangeNotifier` (sem bibliotecas externas no M1)
- Regras de paleta: exatamente 2 cores (`ink` + `paper`), zero tons intermediários
- Convenções de commits: Conventional Commits (`feat:`, `fix:`, `chore:`, `test:`)
- Qualidade: `flutter analyze` + `flutter test` devem passar antes de qualquer commit
- Referências: apontar para `docs/roadmap/` para spec completa, `docs/plan/progress.md` para tracker

**Formato do loop (aberto — definir em iteração futura):**
- Nível de autonomia e instruções de orquestração a definir

**Critério de aceite:** Arquivo presente na raiz com as seções acima.

---

### F06 — CI/CD (`.github/workflows/ci.yml`)

**O que é:** Pipeline GitHub Actions com 4 gates de qualidade.

**Jobs:**

```
push/PR → [flutter analyze] → [flutter test] → [flutter build APK debug] → [coverage report]
```

**Detalhes por gate:**

| Gate | O que faz | Falha se... |
|---|---|---|
| `flutter analyze` | Análise estática | Qualquer warning ou erro de lint |
| `flutter test` | Suite de testes unitários e de widgets | Qualquer teste falhar |
| `flutter build apk --debug` | Compila o APK de debug | Build quebrada |
| Coverage | Gera `lcov.info` + publica no PR summary | N/A (informativo no M1) |

**Configuração:**
- Runner: `ubuntu-latest`
- Flutter: `subosito/flutter-action@v2` com `channel: stable` (sem versão pinada)
- Cache: `pub-cache` via `actions/cache` para acelerar `pub get`
- Coverage: `flutter test --coverage` + `lcov` para gerar relatório

**Sub-tarefas:**
- Criar `.github/workflows/ci.yml`
- Adicionar caching de pub-cache
- Adicionar step de coverage com publicação no PR (GitHub Actions summary)

**Critério de aceite:** Pipeline verde no primeiro push após setup.

---

## Dependências entre features

```
F04 (linting) → deve vir antes de F03 (pastas) para evitar warnings nos placeholders
F02 (deps)    → antes de F03 (pubspec.yaml precisa das deps para declarar assets)
F01 (SDK)     → antes de tudo
F05 (CLAUDE.md) → pode ser feito em qualquer ordem
F06 (CI)      → por último (precisa de tudo funcionando para o pipeline passar)
```

**Ordem recomendada:** F01 → F02 → F04 → F03 → F05 → F06

---

## Critérios de aceite do EPIC

- [ ] `flutter pub get` sem erros
- [ ] `flutter analyze` com zero issues (very_good_analysis)
- [ ] `flutter test` passando
- [ ] Estrutura de pastas criada e declarada no pubspec
- [ ] CLAUDE.md presente na raiz
- [ ] Pipeline CI verde no GitHub Actions

## O que NÃO está em E01

- Firebase setup (→ E11, requer console Firebase + flutterfire configure manual)
- Conteúdo real dos assets (fontes, sprites, sons) → respectivos epics
- Implementação de qualquer feature → E02 em diante
