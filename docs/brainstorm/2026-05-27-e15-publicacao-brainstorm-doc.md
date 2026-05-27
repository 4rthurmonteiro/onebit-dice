---
date: 2026-05-27
topic: e15-publicacao
---

# E15 — Publicação (Release Prep)

## What We're Building

PR final do M1: bundle IDs definitivos, signing config Android, swap
de `InMemory*` por `Hive*` em `main.dart`, política de privacidade
publicada no GitHub Pages, e builds de release locais verdes (AAB +
IPA). Não inclui upload nas lojas — isso é trabalho humano subsequente
(`15.10`, `15.11`).

Slot **GH-NEXT-4** do
[pipeline master](2026-05-27-m1-completion-pipeline-brainstorm-doc.md).

## Pré-requisitos humanos (atualizados)

Resolvidos **antes** do Ralph atacar E15. Lista atualizada inclui um
item que ficou de fora do master plan:

| Item | Descrição | Estado |
|---|---|---|
| `15.1` | Gerar keystore Android + `key.properties` + backup seguro | bloqueador master |
| `15.7` | Screenshots nas resoluções das lojas | bloqueador master (não bloqueia builds) |
| `15.8` | Records no Play Console + App Store Connect | bloqueador master (não bloqueia builds) |
| `4.4` | Substituir placeholders de áudio (`roll.mp3`, `stop.mp3`, `total.mp3`) por arquivos reais em `assets/sounds/` | **adicionado a esta lista**; sem áudio real a release sai com 100ms de silêncio nos sons |

**Atualização proposta no master plan:** adicionar `4.4` à lista de
bloqueios na seção "Estado atual" do doc-mestre.

## Why This Approach

Cinco decisões de design tomadas nesta sessão:

1. **Bundle ID = `com.am2studio.onebitdice`.** Reverse-DNS com studio
   completo. O gradle atual usa `com.am2.onebitdice` (placeholder) —
   trocar nesta PR. iOS herda via `$(PRODUCT_BUNDLE_IDENTIFIER)` em
   `Info.plist`, set em `.xcconfig`.
2. **Mac com Xcode disponível** → IPA build entra no critério de "M1
   done". `flutter build ipa --release` precisa gerar arquivo limpo.
3. **Privacy policy em GitHub Pages do próprio repo.** Ralph cria o
   Markdown em `docs/legal/privacy-policy.md` + workflow GH Actions
   básico para servir `docs/` como Pages. URL pública estável.
4. **Hive wire-up dentro de E15.** Aproveita que o débito técnico já
   unificou instanciação de repositórios em `main.dart`. Swap de
   `InMemory*` → `Hive*` vira 3 linhas + `Hive.init` antes de `runApp`.
5. **M1 done = builds locais verdes**, sem upload (definição do master
   plan). Upload nas lojas, screenshots em devices, smoke test final
   = trabalho humano fora do escopo.

## Trabalho a ser feito

### 1. Bundle ID Android

**Arquivo:** `android/app/build.gradle.kts`

```kotlin
android {
    namespace = "com.am2studio.onebitdice"       // ← atualizar
    defaultConfig {
        applicationId = "com.am2studio.onebitdice" // ← atualizar
        // ...
    }
}
```

**Arquivo:** `android/app/src/main/AndroidManifest.xml` — sem mudança
(usa `${applicationName}` resolvido pelo gradle).

### 2. Signing config Android

**Arquivo:** `android/key.properties` (gerado pelo humano em `15.1`,
**não commitado** — entra em `.gitignore`).

```properties
storePassword=...
keyPassword=...
keyAlias=upload
storeFile=/absolute/path/to/upload-keystore.jks
```

**Arquivo:** `.gitignore` — confirmar que `**/android/key.properties`
está ignorado.

**Arquivo:** `android/app/build.gradle.kts`

```kotlin
import java.util.Properties
import java.io.FileInputStream

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    // ...
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it as String) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release") // ← era debug
        }
    }
}
```

### 3. Bundle ID iOS

**Arquivo:** `ios/Flutter/Release.xcconfig` (ou
`Debug.xcconfig`/`AppFrameworkInfo.plist` conforme padrão Flutter).

```
PRODUCT_BUNDLE_IDENTIFIER = com.am2studio.onebitdice
```

Verificar `Info.plist` — já usa `$(PRODUCT_BUNDLE_IDENTIFIER)` (não
precisa mudar). Display name `1-Bit Dice` já correto.

iOS min deployment já em **13.0** (`Podfile` + `project.pbxproj`
conferidos). Item `15.4` já satisfeito parcialmente — só falta confirmar
bundle ID.

### 4. Swap InMemory → Hive em `main.dart`

Pré-requisito: débito técnico (item 4) já mergeado, com instanciação
de repositórios concentrada em `main.dart`.

**Arquivo:** `lib/main.dart`

```dart
import 'package:hive_flutter/hive_flutter.dart';
import 'package:onebit_dice/core/storage/hive_init.dart';
import 'package:onebit_dice/core/storage/history_repository.dart';
import 'package:onebit_dice/core/storage/presets_repository.dart';
import 'package:onebit_dice/core/storage/last_dice_config_preference.dart';
import 'package:path_provider/path_provider.dart';

Future<void> main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    // ... (crash hooks E11, gated by platform)

    final prefs = await SharedPreferences.getInstance();
    final appSettings = SharedPreferencesAppSettingsPreference(prefs);

    // Hive init — diretório de aplicação + adapters + boxes
    final docs = await getApplicationDocumentsDirectory();
    await HiveInit.init(path: docs.path);
    final historyRepository = await HiveInit.openHistoryRepository();
    final presetsRepository = await HiveInit.openPresetsRepository();

    final lastDiceConfig =
        SharedPreferencesLastDiceConfigPreference(prefs);

    // ... controllers ...

    await analytics.logAppOpen(); // E11

    runApp(App(
      historyRepository: historyRepository,
      presetsRepository: presetsRepository,
      lastDiceConfig: lastDiceConfig,
      // ... controllers ...
      analytics: analytics, // E11
    ));
  }, ...);
}
```

`HiveInit` já existe (`lib/core/storage/hive_init.dart`), mas vai
precisar de helpers `openHistoryRepository()` / `openPresetsRepository()`
se ainda não existirem — confirmar no `/plan` futuro.

`InMemoryHistoryRepository`, `InMemoryPresetsRepository`,
`InMemoryLastDiceConfigPreference` **não são removidas**: continuam
disponíveis para `_buildTestApp()` em testes.

### 5. Privacy Policy

**Arquivo:** `docs/legal/privacy-policy.md` (novo). Conteúdo:

- Nome do app (1-Bit Dice) e studio (AM2 Studio).
- Dados coletados: lista os **9 eventos** do E11 (`app_open`,
  `roll_dice`, `change_palette`, ...) com descrição de cada.
- Reforça: sem PII, sem `userId`, sem advertising_id manual, ATT
  respeitada no iOS.
- Storage local: `shared_preferences` + Hive (histórico + presets),
  todos no device, não sincronizado.
- Crashlytics: stack traces + device info anônimo, só em Android/iOS
  (gate de plataforma do E11).
- Contato: e-mail do studio para data requests.
- Data efetiva + número de versão.

**Workflow:** `.github/workflows/pages.yml` (novo)

```yaml
name: Deploy Pages
on:
  push:
    branches: [main]
    paths: ['docs/**']
permissions:
  pages: write
  id-token: write
jobs:
  deploy:
    runs-on: ubuntu-latest
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    steps:
      - uses: actions/checkout@v4
      - uses: actions/configure-pages@v4
      - uses: actions/upload-pages-artifact@v3
        with:
          path: docs
      - id: deployment
        uses: actions/deploy-pages@v4
```

**Repo settings (humano):** GitHub → Settings → Pages → Source: GitHub
Actions. Único click humano após merge da PR.

**URL final:** `https://4rthurmonteiro.github.io/onebit-dice/legal/privacy-policy.html`
(Pages renderiza .md → .html automaticamente via Jekyll default).

### 6. Builds de release verdes

```bash
# Android
flutter clean
flutter pub get
flutter build appbundle --release
# → build/app/outputs/bundle/release/app-release.aab

# iOS (Mac com Xcode)
flutter build ipa --release
# → build/ios/ipa/onebit_dice.ipa
```

Ambos devem rodar sem erros. AAB é o artefato final do M1; IPA serve
como prova-de-build (upload no App Store Connect é humano).

### 7. Atualizar `progress.md`

Marcar `[x]` em:
- 15.2, 15.3, 15.4, 15.5, 15.6, 15.9

Marcar `[!]` resolvido (com nota humano completou) em:
- 0.6, 14.1, 15.1, 15.7, 15.8, 4.4

Item 15.10 / 15.11 (uploads): permanecem `[ ]` ou viram nota
"out of M1 scope, handed to human".

## Key Decisions

### D1 — `key.properties` fora do repo

Padrão Flutter oficial. Backup do humano é responsabilidade dele
(senha gerenciada externamente). `.gitignore` ganha entrada.

### D2 — Sem ProGuard/R8 custom rules no M1

Configuração default do Flutter para release builds. Se análise
posterior mostrar warnings de shrink, abrir issue para M2 (não bloqueia
release).

### D3 — Privacy policy em Markdown, não HTML

Markdown com Jekyll do GH Pages renderiza automaticamente. Mais fácil
de manter. iOS App Store + Google Play aceitam URL para versão HTML.

### D4 — `lastDiceConfig` permanece em SharedPreferences

Não migra para Hive. Razão: é só uma config simples (1 par
type+count), não justifica box Hive. Já tem impl
`SharedPreferencesLastDiceConfigPreference` lista no E04.

### D5 — Hive boxes inicializadas com `path_provider`

`Hive.initFlutter()` é o atalho, mas precisa de `hive_flutter`. O
projeto já usa apenas `hive`. Solução: `Hive.init(path)` com
`getApplicationDocumentsDirectory()` de `path_provider`. Confirmar
que `path_provider` está no `pubspec.yaml` — se não, adicionar.

### D6 — Crashlytics Android setup (plugin gradle)

E11 instala `firebase_crashlytics` mas o plugin gradle do Crashlytics
(`com.google.firebase.crashlytics`) precisa estar em
`android/app/build.gradle.kts` para gerar build IDs corretos. Se E11
não fez (precisa do `flutterfire configure`), E15 confirma e adiciona.

**Conferir em E11 plan**, **adicionar aqui se ausente:**

```kotlin
plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")  // ← garantir
    id("dev.flutter.flutter-gradle-plugin")
}
```

### D7 — `versionCode` / `versionName` permanecem `1.0.0+1`

Default já correto para primeiro release. Sucessivos uploads
incrementam build number — trabalho humano em Play Console / TestFlight.

## Riscos e Mitigações

| Risco | Mitigação |
|---|---|
| `key.properties` commitado por engano | `.gitignore` + revisão antes de push; secrets scanning do GitHub também alerta |
| Bundle ID novo conflita com algum registrado | Humano verifica disponibilidade no Play Console + App Store Connect (`15.8`) **antes** da PR ser aberta |
| `flutter build ipa --release` falha por code signing | Mac requer Apple Developer account + provisioning profile via Xcode; se ausente, IPA fica como `[!]` e M1 fecha só com AAB (regredir D2 do master plan) |
| Hive migrate de schema (futuro) | typeId fixo nos models `roll_entry`/`custom_preset` (E04); migração quando necessário, fora do M1 |
| Política de privacidade desatualizada vs eventos reais | Conteúdo da policy gerado a partir do código E11 (lista canônica de 9 eventos); teste leitura cruzada antes do merge |
| GitHub Pages não habilitado pelo humano após merge | PR descrição inclui "ação humana: ativar Pages em Settings"; URL pública só fica viva após o switch |
| Crashlytics gradle plugin ausente em E11 | D6 explicitamente confirma e fecha o gap aqui |

## Open Questions

- **Q1:** ProGuard/R8 rules — alguma lib (Hive, firebase) precisa de
  `keep` rule? — assumir **não**, dependências documentadas como
  R8-safe. Se build falhar, ajustar reativamente.
- **Q2:** App icon + splash já entregues por E14 antes desta PR? Sim,
  pipeline garante (E14 mergeada antes de E15). Sem ação aqui.
- **Q3:** `Info.plist` precisa de NSUserTrackingUsageDescription? —
  só se quisermos prompt ATT do iOS. Como E11 declarou "não coletar
  advertising_id manual", **deixar de fora**. Se Firebase Analytics
  precisar mesmo assim em release, adicionar string mínima em todos
  os 12 idiomas.
- **Q4:** Build de iOS requer `flutter build ipa --export-method
  development|app-store|ad-hoc|enterprise`? — para verificação local
  basta `development`; para upload real **app-store**. Plan futuro
  decide.

## Critério de aceite (Definition of Done — M1)

Cumulativo de tudo:

- [ ] `flutter analyze` → 0 issues
- [ ] `flutter test --coverage` → 100% line (excl. `main.dart`,
      `*.g.dart`, `app_localizations*.dart`, `firebase_options.dart`,
      `firebase_analytics_service.dart`, `firebase_crash_reporter.dart` se aplicável)
- [ ] `flutter build appbundle --release` → AAB gerado sem erros
- [ ] `flutter build ipa --release` → IPA gerado sem erros
- [ ] `docs/legal/privacy-policy.md` publicado + workflow GH Pages live
- [ ] `progress.md` com todos os `[ ]` viraram `[x]` ou `[!]` documentado
- [ ] Bundle ID `com.am2studio.onebitdice` em Android + iOS
- [ ] `key.properties` listado em `.gitignore`, não commitado
- [ ] Hive em uso para `HistoryRepository` + `PresetsRepository` em
      release (não InMemory)
- [ ] Áudio real (não placeholders de 100ms) em `assets/sounds/`

Quando todos verdes: **M1 DONE**. Human handoff para uploads
(`15.10` / `15.11`), screenshots, store listings.

## Resumo do plano subsequente (`/plan` futuro)

Quando issue `feat: e15 publicação` for criada:

1. Pre-flight: confirmar resolução de `15.1` (key.properties),
   `14.1` (icon final via E14 merged), `4.4` (audio files),
   `0.6` (`firebase_options.dart` via E11 merged).
2. Branch `feat/e15-publicacao` em main rebaseada.
3. Patches Android: bundle ID + signing config.
4. Patches iOS: bundle ID em xcconfig.
5. `lib/main.dart`: Hive init + swap repos. `pubspec.yaml`:
   adicionar `path_provider` se ausente.
6. `docs/legal/privacy-policy.md` (conteúdo do E11 + dados de Hive).
7. `.github/workflows/pages.yml`.
8. Verificações: builds AAB + IPA + runtime smoke (abrir app, rolar,
   confirmar histórico persistido após restart).
9. Atualizar `progress.md`.
10. PR descreve cada item; humano ativa GH Pages + começa uploads
    nas lojas.
