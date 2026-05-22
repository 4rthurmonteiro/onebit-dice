# 05 — Marketing e ASO

## Princípio
ASO (App Store Optimization) entrega 80% dos downloads orgânicos de utility apps. Marketing pago não vale a pena pra free apps de baixa receita por usuário. Foco em estética como diferencial viral.

## ASO

### Título nas lojas (sugestões)
Precisa ter as keywords de busca + diferencial.

**Opções**:
- `1-Bit Dice — Dados Retrô`
- `1-Bit Dice: Ludo, RPG, Tabuleiro`
- `1-Bit Dice — Dados pra Ludo, RPG`

**Decisão**: testar A/B se possível. Brasileiro pesquisa por "dado", "dados ludo", "dado banco imobiliário", "rolar dados".

### Descrição curta (até 80 chars no Play, 170 no App Store)
**Play (80 chars)**: "Dados em 1-bit retrô. Ludo, Banco Imob., RPG. Grátis, sem ads, offline."

**Apple promotional text (170 chars)**: "Dados em 1-bit retrô. Ludo, Banco Imobiliário, RPG, Yahtzee. 6 paletas (Mac, Game Boy, Apple II). Grátis. Sem anúncios. Offline. Do universo Call of Old Chico."

### Descrição completa (keyword-dense)
Primeiras 2 linhas vendem o app (algoritmo lê). Embaixo, repete keywords pra long-tail:
- ludo
- banco imobiliário
- dados rpg
- D&D
- yahtzee
- catan
- war
- simulador de dados
- pixel art
- retrô
- 1-bit
- offline

### Keywords (Apple, 100 chars)
`dados,dice,ludo,RPG,banco imobiliario,tabuleiro,pixel,retro,1bit,yahtzee,catan,DD`

### Categoria
- **Primária Play**: Ferramentas (mesmo que o concorrente)
- **Secundária**: opcional, "Jogos > Tabuleiro"
- **Apple primária**: Ferramentas (Utilities)
- **Apple secundária**: Estilo de vida ou Jogos > Tabuleiro

### Classificação etária
- **Play (IARC)**: Livre (Everyone)
- **Apple**: 4+

### Screenshots — a bala de prata
Concorrentes têm screenshots GENÉRICOS. Os nossos são poster art com texto sobreposto:

| # | Tela | Overlay text |
|---|---|---|
| 1 | Home com rolagem | "ROLE QUALQUER DADO — até 10 de uma vez" |
| 2 | Ajustes com paletas | "6 PALETAS RETRÔ — Mac, Game Boy, Apple II..." |
| 3 | Presets | "PRESETS PROS SEUS JOGOS — Ludo, Banco Imob., RPG..." |
| 4 | Histórico | "HISTÓRICO INFINITO — cada rolagem salva" |
| 5 | Splash | "GRÁTIS · SEM ADS · OFFLINE — como deveria ser" |

Mockups completos em `docs/prototypes/05-play-store.html` e `06-app-store.html`.

### Ícone
- Crítico pra CTR no scroll. Pixel art real do d6, reconhecível em 48px.
- 5 variações testadas antes de escolher final.

### Feature graphic (Play Store, 1024x500)
- Wordmark Silkscreen gigante + tagline + d6 pixel art enorme + leque de paletas atrás.
- Mockup em `docs/prototypes/05-play-store.html`.

## Canais de lançamento (por prioridade)

### 1. Reddit — onde a vibe pega
- `r/PixelArt` — comunidade gigante de pixel art, vai amar a estética
- `r/boardgames` — público utilitário (Ludo, Banco Imob.)
- `r/rpg` — público RPG (D&D)
- `r/IndieDev` — credibilidade indie
- Formato do post: "I made a 1-bit dice roller, inspired by Obra Dinn" + vídeo curto de 15s mostrando paletas trocando

### 2. Twitter/X com `#pixelart`
- Comunidade ativa, retweetam estética bonita
- Postar vídeo curto + thread sobre o processo
- Marcar comunidades (game devs, pixel art)

### 3. TikTok BR
- Algoritmo brasileiro adora content de board game / RPG
- "Fiz um app pra noite de Banco Imobiliário em família" — vídeo curto mostrando uso real
- Hashtags: #bancoimobiliario #ludo #boardgame #rpg #pixelart

### 4. Grupos de Facebook BR
- "Conexão Boardgame Brasil" (50k+ membros)
- "RPG Brasil" e variações
- Postar com cuidado pra não parecer spam

### 5. Product Hunt
- Lançamento numa quarta-feira (melhor dia)
- Comunidade indie/design vai amar 1-bit
- Pequena chance de virar Product of the Day

### 6. Show HN (Hacker News)
- Opcional. Funciona se enquadrado como "I built a 1-bit dice app in 2 days using Flutter"
- Foco: tech story + side project

### O que NÃO fazer
- ❌ Paid user acquisition (UA) — uneconomic pra free utility
- ❌ Influencer marketing — público é massa, não niche de influencer
- ❌ ASO tools pagos (App Annie, etc) no M1 — só com dados reais
- ❌ Posts em subreddits sem permitir self-promotion

## Conversão pra Call of Old Chico

### Pontos de contato (todos sutis, não invasivos)
1. **Splash**: microtexto rodapé "part of the call of old chico universe" em 6-8px
2. **Tela Sobre**: link discreto pra wishlist Steam / Discord
3. **Descrição da loja**: parágrafo final menciona o universo (1-2 frases)
4. **Easter egg opcional**: a cada N rolagens (ex: 100), splash mostra "saudações de old chico" com link discreto

### Métrica de sucesso
- Cliques no link Call of Old Chico (via Analytics)
- Conversão pra wishlist Steam (via tracking de UTM)
- Membros novos no Discord vindos do app

## Política de privacidade
- Página HTML simples
- Hospedar em: GitHub Pages ou Vercel ou domínio próprio (`1bitdice.com`)
- Conteúdo: nenhum dado pessoal coletado, Analytics anônimo, Crashlytics anônimo, links externos
- URL referenciada nas duas lojas (obrigatório)

## Domínio + handles sociais (reservar logo)
- `1bitdice.com` (ou `.app`, `.io`)
- `@1bitdice` em Twitter, Instagram, TikTok, Reddit
