---
date: 2026-05-27
topic: e14-assets-launcher-icons
---

# E14 — Assets Visuais (Launcher Icons + Native Splash refresh)

## What We're Building

Substituição do ícone placeholder por arte final + geração dos
launcher icons (Android adaptive + iOS) + refresh do native splash já
existente. PR roda no slot **GH-NEXT-3** do
[pipeline master](2026-05-27-m1-completion-pipeline-brainstorm-doc.md),
depois do débito técnico.

**Pré-requisito humano (resolvido antes do Ralph atacar):**

- `14.1`: 2 PNGs entregues em `assets/icon/`:
  - `icon.png` (1024×1024, opaco, ícone completo do app — usado para iOS + splash + Android legacy fallback)
  - `icon-foreground.png` (1024×1024, com safe zone de 25% nas bordas, transparência permitida — usado pelo Android adaptive como `foregroundImage`)
- Background do Android adaptive é cor sólida (`#FFFFFF`), não imagem.

## Why This Approach

Três decisões de design tomadas nesta sessão:

1. **Android adaptive completo (foreground + background separados)** —
   conforma com a guideline oficial do Android 8+, suporta animações
   de launcher e parallax. Custo: humano entrega 2 PNGs (não 1).
2. **Splash só claro, sem modo escuro nativo** — coerente com a paleta
   default (carbon: ink `#000` / paper `#FFF`). Manter a config atual
   do splash (`#FFFFFF` + ink preto). Tema escuro do SO não dispara
   variante. Menos config, menos arquivos. Coerente com o splash já
   commitado no E09.
3. **Commitar todos os arquivos gerados** — `mipmap-*/`,
   `AppIcon.appiconset/`, `drawable*/` continuam versionados (padrão
   estabelecido no E09 quando o splash gerado foi commitado). CI não
   precisa rodar tooling. PR fica grande mas reproduzível em qualquer
   máquina.

## Trabalho a ser feito

### 1. Adicionar `flutter_launcher_icons` ao `pubspec.yaml`

Hoje só `flutter_native_splash: ^2.4.7` está presente.

```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1
  flutter_native_splash: ^2.4.7
```

Versão alinhada com o roadmap (`docs/roadmap/03-stack-tecnico.md`).

### 2. Criar `flutter_launcher_icons.yaml`

```yaml
flutter_launcher_icons:
  android: true
  ios: true
  remove_alpha_ios: true
  image_path: "assets/icon/icon.png"

  # Adaptive (Android 8+)
  adaptive_icon_background: "#FFFFFF"
  adaptive_icon_foreground: "assets/icon/icon-foreground.png"

  # Min SDK do projeto define se gera legacy fallback
  min_sdk_android: 21
```

- `remove_alpha_ios: true`: iOS rejeita PNG com canal alpha. O tool
  flatten contra branco. Garante upload limpo na App Store.
- `adaptive_icon_background: "#FFFFFF"`: cor sólida (não imagem) — a
  paleta default do app é carbon (paper #FFF). Coerência visual.
- `min_sdk_android: 21`: emite tanto adaptive (Android 8+) quanto
  legacy (mipmap-*/ic_launcher.png) para versões anteriores.

### 3. Rodar `dart run flutter_launcher_icons`

Gera:
- `android/app/src/main/res/mipmap-{hdpi,mdpi,xhdpi,xxhdpi,xxxhdpi}/ic_launcher.png` (legacy)
- `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml` (adaptive ref)
- `android/app/src/main/res/drawable-{mdpi,...}/ic_launcher_foreground.png`
- `android/app/src/main/res/values/ic_launcher_background.xml` (com `#FFFFFF`)
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/` (todos os tamanhos)
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json`

### 4. Atualizar `flutter_native_splash.yaml` (se necessário)

Provável que **não precise mudar**. O arquivo atual já aponta para
`assets/icon/icon.png`. Quando o humano substitui o placeholder pelo
arquivo final, o splash automaticamente usa o novo. Sem dark mode,
sem alterações.

Conferir após gen do icon:
- `color: "#FFFFFF"` permanece.
- `image: assets/icon/icon.png` permanece.
- Bloco `android_12` permanece com mesmo config.
- Manter `android: true`, `ios: true`, `web: false`.

### 5. Rodar `dart run flutter_native_splash:create`

Regenera:
- `android/app/src/main/res/drawable*/launch_background.xml`
- `android/app/src/main/res/values*/styles.xml` (Android 12 splash icon)
- `ios/Runner/Assets.xcassets/LaunchImage.imageset/`
- `ios/Runner/Base.lproj/LaunchScreen.storyboard`

Os arquivos já existem (E09 rodou pela primeira vez). Esta passagem
substitui com o novo icon.

### 6. Verificação manual

- `flutter clean && flutter pub get`
- `flutter run` em emulador Android → confere se launcher mostra o
  ícone real (não o placeholder) e se o splash mostra o ícone novo.
- `flutter run` em simulador iOS → idem para iOS.
- Conferir em launcher Pixel (circular mask) e Samsung One UI
  (squircle mask) — adaptive deve respeitar o safe zone de 25%.

## Arquivos que mudam na PR

```
pubspec.yaml                                           +1 dev dep
flutter_launcher_icons.yaml                            +novo arquivo
assets/icon/icon.png                                   ← humano substitui
assets/icon/icon-foreground.png                        ← humano cria (novo)

# Gerados pelo flutter_launcher_icons (commitados):
android/app/src/main/res/mipmap-hdpi/ic_launcher.png
android/app/src/main/res/mipmap-mdpi/ic_launcher.png
android/app/src/main/res/mipmap-xhdpi/ic_launcher.png
android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png
android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png
android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml
android/app/src/main/res/drawable-*/ic_launcher_foreground.png
android/app/src/main/res/values/ic_launcher_background.xml
ios/Runner/Assets.xcassets/AppIcon.appiconset/**

# Regenerados pelo flutter_native_splash:create (commitados):
android/app/src/main/res/drawable*/launch_background.xml
android/app/src/main/res/values*/styles.xml
ios/Runner/Assets.xcassets/LaunchImage.imageset/**
ios/Runner/Base.lproj/LaunchScreen.storyboard
```

## Key Decisions

### D1 — Adaptive completo, não legacy-only

Humano entrega 2 PNGs (full icon + foreground). Background é cor
sólida `#FFFFFF`, não imagem (consistente com 1-bit + paleta default).
Custo de assets: 2 PNGs em vez de 1. Ganho: conformidade com
guideline Android, comportamento correto em launchers modernos.

### D2 — Sem variante dark do splash

`carbon` é a paleta default (ink #000 / paper #FFF). O usuário pode
trocar para `screen-glow` (ink #00FF66 / paper #001100) ou outras nas
Settings, mas o splash nativo continua claro — é a primeira impressão
da marca, não respeita preferência do usuário ainda. Pode evoluir
no M2.

### D3 — `remove_alpha_ios: true`

App Store rejeita PNG com canal alpha. O tool achata contra branco
durante geração. Não exige que o humano entregue ícone sem alpha — o
flag cuida disso.

### D4 — Não tocar tests

Nenhum teste cobre arquivos nativos. PR não muda `coverage` nem
adiciona/remove testes. `tools/ralph/feedback.sh` continua passando
sem mudança.

### D5 — Conflito potencial com E15

E15 vai mexer em `android/app/build.gradle` (signing) e
`AndroidManifest.xml` (bundle ID). E14 mexe em `mipmap-*/`. Não há
conflito de arquivo — paths disjuntos.

## Riscos e Mitigações

| Risco | Mitigação |
|---|---|
| Humano entrega só 1 PNG (sem foreground) | Pré-flight: doc lista exatamente os 2 arquivos esperados; Ralph aborta com erro claro se `icon-foreground.png` ausente |
| Ícone final não respeita safe zone de 25% no foreground (recorta partes importantes) | Pré-flight humano; validar em launchers Pixel + Samsung antes do merge |
| Adaptive icon background `#FFFFFF` conflita com paleta escolhida pelo usuário | Por design: splash + launcher = sempre carbon. Settings palette só afeta o app interno |
| `dart run flutter_launcher_icons` falha em CI por falta de Android SDK | Tooling roda **localmente** + commits dos arquivos gerados. CI não roda gen |
| iOS rejeita ícone com alpha residual | `remove_alpha_ios: true` no config |
| `assets/icon/icon-foreground.png` não declarado em `pubspec.yaml` flutter assets | Não precisa — é consumido pelo gerador, não pelo Dart runtime. `pubspec.yaml` assets só lista o que o app carrega em runtime |
| Tamanho do PR (~30 arquivos binários gerados) | Padrão do projeto (E09 já fez); review se concentra em `.yaml` configs |

## Open Questions

- **Q1:** O `icon.png` original (1024×1024) usado pelo splash deve ser o
  ícone completo (com paper #FFF embutido) ou só a "tinta" do d6 sobre
  fundo transparente? — assumir **opaco completo**, porque o splash
  também usa esse arquivo (não há campo separado de splash image).
- **Q2:** Precisa monocromático Android 13+? Android 13 adicionou suporte
  a "themed icons" (monocromático). Não há atributo direto em
  `flutter_launcher_icons` 0.13.x; provavelmente deixar pra M2.
  **Não suportar nesta PR.**
- **Q3:** Branding do `Info.plist` (`CFBundleDisplayName`, etc.) e
  `strings.xml` (`app_name`) — onde isso cai? **Em E15**, junto com
  bundle ID e signing. E14 só mexe em ícone/splash.

## Resumo do plano subsequente (`/plan` futuro)

Quando a issue `feat: e14 launcher icons + splash refresh` for criada:

1. Pre-flight: confirmar que `assets/icon/icon.png` e
   `assets/icon/icon-foreground.png` existem e têm 1024×1024.
2. Adicionar `flutter_launcher_icons: ^0.13.1` em
   `pubspec.yaml/dev_dependencies`.
3. Criar `flutter_launcher_icons.yaml` no root.
4. `flutter pub get`.
5. `dart run flutter_launcher_icons`.
6. `dart run flutter_native_splash:create`.
7. `flutter clean && flutter pub get && flutter run` em Android +
   iOS para validar visualmente.
8. Commit dos arquivos gerados + `pubspec.yaml` + `pubspec.lock` +
   `flutter_launcher_icons.yaml`.
9. PR descreve qual placeholder foi substituído.
