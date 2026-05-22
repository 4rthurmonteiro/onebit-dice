# docs/assets

Material visual, sonoro e de marketing do **1-Bit Dice**.

> Nota: estes são os assets de **documentação e produção**. Os assets que vão pro app Flutter ficam em `lib/assets/` (ou `assets/` na raiz do projeto Flutter), copiados daqui quando finalizados.

## Estrutura

```
assets/
├── images/
│   ├── icon/                   — app icon nas várias resoluções (PNG)
│   ├── splash/                 — splash screen variações
│   ├── screenshots/            — screenshots reais do app rodando
│   └── ui-references/          — referências de UI (paletas em uso, mockups)
│
├── sprites/
│   └── dice/                   — sprite sheets dos dados (export Blender 1-bit)
│
├── fonts/                      — Silkscreen, VT323, Press Start 2P (.ttf)
│
├── sfx/                        — sound effects (roll, stop, total)
│
├── music/                      — música ambiente (M2+ talvez, M1 não tem)
│
└── marketing/
    ├── play-store/
    │   ├── feature-graphic/    — 1024x500 PNG
    │   └── screenshots/        — 1080x1920 com overlays
    ├── app-store/
    │   ├── screenshots/        — 1290x2796 iPhone 6.7"
    │   └── app-preview/        — vídeo 15-30s (.mp4)
    ├── social/
    │   ├── twitter/            — 1200x675, 1080x1080
    │   ├── instagram/          — 1080x1080, 1080x1920 stories
    │   └── tiktok/             — vídeos verticais
    └── press-kit/              — logo em vários formatos, screenshots, descrição
```

## Convenções de nome de arquivo

- **Ícones**: `icon_{paleta}_{tamanho}.png` (ex: `icon_mac-classic_1024.png`)
- **Screenshots reais**: `screenshot_{tela}_{paleta}_{plataforma}.png` (ex: `screenshot_home_mac-classic_android.png`)
- **Sprite sheets**: `dice_{tipo}_{paleta}.png` (ex: `dice_d6_mac-classic.png`)
- **Sons**: snake_case minúsculo (`roll.mp3`, `stop.mp3`, `total.mp3`)
- **Marketing screenshots**: `{loja}_screenshot_{numero}_{lang}.png` (ex: `play_screenshot_01_pt.png`)

## Formatos preferidos

| Tipo | Formato | Notas |
|---|---|---|
| Ícone do app | PNG sem compressão | Sem antialiasing |
| Sprite sheets | PNG indexed (2 cores) | filterQuality: none no Flutter |
| Screenshots | PNG | 1:1 pixel-perfect |
| Sons | MP3 ou OGG | curtos (<2s pros efeitos) |
| Música | OGG (menor que MP3) | loop pra ambiente |
| Marketing | PNG ou JPG | JPG só pra fotos, PNG pra pixel art |
| Vídeo | MP4 H.264 | 15-30s, max 30MB |

## Estado atual (M1)

- [ ] App icon exportado nas resoluções iOS/Android
- [ ] Sprite sheets dos dados (Blender → PNG)
- [ ] Splash screen export
- [ ] Sound effects gravados/escolhidos
- [ ] Screenshots reais do app (depois de codar)
- [ ] Feature graphic Play Store final
- [ ] Screenshots formatados pra cada loja
- [ ] Vídeo preview Apple (opcional M1)

## Fontes (downloads)

Antes de subir os `.ttf` aqui, baixar de:
- **Silkscreen**: https://fonts.google.com/specimen/Silkscreen
- **VT323**: https://fonts.google.com/specimen/VT323
- **Press Start 2P**: https://fonts.google.com/specimen/Press+Start+2P

Todas Open Font License — uso comercial liberado.
