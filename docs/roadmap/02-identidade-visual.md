# 02 — Identidade Visual

## Direção aprovada
Retrô puro de computador antigo: vibe **Macintosh System 1 (1984), Game Boy DMG (1989), Apple II**. ZERO elementos western no app. O universo Call of Old Chico aparece apenas como microtexto discreto no rodapé do splash, sem destaque visual.

## Histórico de iteração
A primeira versão da identidade visual (sépia papel envelhecido + estrela do xerife + revólver + fonte Rye + "Forasteiro"/"Mesa de Jogo" no copy) foi REPROVADA por "western em excesso / cringe". Versão atual descartou completamente esses elementos.

## Paletas

### Mac Classic (default)
- Tinta: `#000000`
- Papel: `#FFFFFF`
- Uso: paleta default do app

### Mac Beige
- Tinta: `#000000`
- Papel: `#C7C7C7`

### Game Boy DMG
- Tinta: `#0F380F`
- Papel: `#9BBC0F`

### Commodore 64
- Tinta: `#352879`
- Papel: `#7869C4`

### ZX Spectrum
- Tinta: `#000000`
- Papel: `#00FF00`

### Apple II Green
- Tinta: `#000000`
- Papel: `#33FF33`

### Apple //e Amber (wildcard)
- Tinta: `#000000`
- Papel: `#FF9933`

**Regra**: cada paleta usa EXATAMENTE 2 cores. Nada de tons intermediários, nada de antialiasing.

## Tipografia (Google Fonts)

| Uso | Fonte | Tamanho típico |
|---|---|---|
| Wordmark "1-BIT DICE" | Silkscreen | 24-96px |
| Display / títulos | Silkscreen | 18-40px |
| Body / UI | VT323 | 14-24px |
| Micro / footer | Press Start 2P | 8-12px |

**CSS / Flutter**:
- `image-rendering: pixelated`
- `-webkit-font-smoothing: none`
- `font-smooth: never`
- Em Flutter: usar `FilterQuality.none` em todas as imagens

## Iconografia

### Permitido
- d6 pixel art em vista frontal (não isométrico)
- d20 hexagonal/icosaedro pixel art
- Engrenagem (config)
- Ampulheta (histórico)
- Estrela genérica de 5 pontas — sem pontos nos vértices (presets)
- Lixeira
- Toggle Mac-style (caixa quadrada com X)
- Setas (4 direções), + e −
- Círculo, ponto, X

### PROIBIDO no app
- Revólver / pistola
- Estrela do xerife (estrela com pontos nos vértices)
- Cacto, caveira, ferradura, chapéu de cowboy, bota, sino de saloon
- Tambor de revólver
- Brasão cruzado

## Componentes

### Botões
- Borda pixel dupla 2px
- Sombra offset 2-3px sólida preta (Mac System 1 style)
- Texto em Silkscreen caixa alta
- Estado pressionado: sombra desaparece + offset interno

### Cards
- Borda pixel simples (NÃO wanted poster, NÃO cantos serrilhados)
- Background da cor secundária da paleta

### Janelas (estilo Mac OS 1)
- Title bar com listras horizontais finas pretas (3-4 listras de 1px com espaçamento de 1px)
- Borda dupla pixel ao redor
- Botão de fechar (quadrado pequeno) no canto

### Divisores
- Linha horizontal preta 1-2px
- Usar entre seções em listas

### Toggle / Checkbox
- Caixa quadrada 20-24px com borda pixel
- Estado on: X dentro
- Estado off: vazio

### Tab bar (rodapé)
- 4 tabs: ROLAR / HISTÓRICO / JOGOS / AJUSTES
- Cada tab: ícone pixel art 24x24 + label VT323 12px caixa alta
- Divisor horizontal 2px no topo da tab bar
- Tab ativo: ícone preenchido / inverso de cor

## Copy (UI em PT-BR)

### Termos canônicos
| Conceito | Termo correto | NÃO usar |
|---|---|---|
| Ação de jogar dado | "Rolar" | "Sacar", "Tirar" |
| Lista de rolagens passadas | "Histórico" | "Histórico do Forasteiro", "Diário" |
| Configurações | "Ajustes" | "Saloon", "Configurações do bandido" |
| Categoria de dado | "Tipo" | "Forma de dado" |
| Número de dados | "Quantidade" | "Quantos dados" |
| Apagar | "Limpar" | "Queimar", "Demolir" |
| Pre-configurações | "Jogos" ou "Presets" | "Jogos do saloon" |
| Sobre o app | "Sobre" | "Sobre o forasteiro" |

### Vocabulário proibido
- Forasteiro, Saque, Saloon, Pistoleiro, Parceiro, Tambor, Mesa de Jogo, Yeehaw, Mestre, Causos

### Wordmark
- "1-BIT DICE" sempre em caixa alta
- Sem hífen no produto final em interfaces (logo pode estilizar com hífen)
- Tagline EN: "Dice for every game"
- Tagline PT: "Dados pra todo jogo"

## Mockups aprovados
Veja `docs/prototypes/`:
- `01-design-system.html` — style guide completo
- `02-app-icon.html` — ícone do app em 6 paletas + zoom + teste de escala
- `03-splash-home.html` — splash + tela principal de rolagem
- `04-secondary-screens.html` — histórico + ajustes + presets
- `05-play-store.html` — listing Google Play
- `06-app-store.html` — listing App Store

## App icon
- Conceito: d6 pixel art em vista frontal, face com 6 pontos arranjados em grid 2x3
- Resolução base: 32x32 pixels escalado pra produção (até 1024x1024)
- Background: cor secundária da paleta (Mac Classic = papel branco)
- Borda pixel dupla
- NÃO usar estrela do xerife, NÃO usar elementos western

## Background da UI
- Cor sólida da paleta (sem textura sépia papel)
- Permitido: pattern de pontos sutil OU scanlines CRT pra textura discreta
- Proibido: textura de "papel envelhecido", "poeira", "granulado de wanted poster"
