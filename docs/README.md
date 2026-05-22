# 1-Bit Dice — Documentação

App mobile (iOS + Android) de rolagem de dados em estética retrô 1-bit. Projeto cobaia pra aprender o fluxo completo de publicação nas lojas, conhecimento reaproveitado depois no projeto principal **Call of Old Chico**.

## Estrutura

```
docs/
├── README.md           — este índice
├── prototypes/         — mockups HTML da identidade visual aprovada
│   ├── 01-design-system.html
│   ├── 02-app-icon.html
│   ├── 03-splash-home.html
│   ├── 04-secondary-screens.html
│   ├── 05-play-store.html
│   └── 06-app-store.html
└── roadmap/            — decisões, escopo e plano
    ├── 00-visao-geral.md
    ├── 01-escopo-m1.md
    ├── 02-identidade-visual.md
    ├── 03-stack-tecnico.md
    ├── 04-monetizacao.md
    ├── 05-marketing-aso.md
    ├── 06-roadmap-futuro.md
    └── 07-publicacao-lojas.md
```

## Decisões-chave (TL;DR)

- **Nome**: 1-Bit Dice
- **Bundle ID**: `com.am2.onebitdice`
- **Stack**: Flutter + Firebase (Crashlytics + Analytics)
- **Sem login, sem coleta de dados pessoais**
- **Armazenamento local** (hive + shared_preferences)
- **Identidade visual**: 1-bit retrô computador antigo (Mac System 1 / Game Boy DMG / Apple II), **zero western no app**
- **Paleta default**: Mac Classic (preto sobre branco) + 5 alternativas retrô
- **Tipografia**: Silkscreen (display) + VT323 (corpo) + Press Start 2P (micro)
- **Monetização M1**: 100% grátis, sem anúncios, sem IAP
- **Monetização M2**: IAP de créditos pra dados customizados via IA
- **Cronograma M1**: 1-2 dias de desenvolvimento
