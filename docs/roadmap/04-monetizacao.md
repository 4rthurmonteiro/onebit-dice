# 04 — Monetização

## Princípio
O M1 prioriza **rating alto e tração** sobre receita. Aquisição orgânica nos primeiros 30 dias depende de avaliações 5★. Ads ou paywall logo no lançamento mata isso.

## Estratégia por milestone

### M1 — 100% grátis, sem ads, sem IAP
- Justificativa: estabelecer rating 4.8+ na primeira janela. Reviews positivos viram ASO.
- Custo de oportunidade real é baixo: app novo de utility não gera receita significativa nos primeiros 30 dias mesmo com ads.
- Estatística do concorrente: reviews mais comuns reclamam de "anúncios chatos". Eliminar isso é diferencial.

### M2 — IAP de créditos para IA
- Dados customizados gerados por IA via prompt do usuário (skin, símbolo, cor em 1-bit).
- Modelo: 5-10 gerações grátis para todos os usuários, depois pacotes.
- Sugestão de preços:
  - **R$ 4,90** = 20 gerações
  - **R$ 14,90** = 100 gerações (melhor custo/benefício)
  - **R$ 29,90** = 250 gerações + slot extra de presets
- Cobre custo de IA + margem saudável.
- O app continua "grátis e sem ads" pro Joãozinho casual.
- Modelo consumível (não assinatura).

### M5+ — Possíveis caminhos (decidir conforme tração)
- **"Remove ads"** vitalício R$ 9,90-14,90 — APENAS se em algum momento ads forem adicionados (improvável)
- **Pacote de paletas premium** — paletas exclusivas (NES, Atari Lynx, MSX, etc) por R$ 2,90/pacote ou R$ 9,90 tudo
- **Pacote de presets temáticos** — packs (jogos retrô, jogos de cartas) por R$ 3,90 cada

### O que NÃO fazer (decidido)
- ❌ Subscription mensal — utility apps com subscription têm PR péssimo
- ❌ Paid upfront ($X.99 pra comprar) — mercado morto pra utility apps
- ❌ Ads no M1 — mata rating
- ❌ Features básicas pagas (ex: "trocar paleta é premium") — modelo escroto que gera reviews 1★
- ❌ Dark patterns (pop-ups insistentes, contagens regressivas)

## Doação opcional / tip jar
Botão sutil "Apoiar o desenvolvimento" na tela "Sobre", com link pra:
- Wishlist na Steam do Call of Old Chico
- Discord do projeto principal
- Opção de tip via PIX ou Ko-fi (deixar discreto)

Objetivo: capturar audiência pro projeto grande, não receita direta.

## Métricas chave
| Métrica | Onde medir | Alvo M1 |
|---|---|---|
| Rating Play Store | Play Console | >= 4.7★ |
| Rating App Store | App Store Connect | >= 4.8★ |
| Crash-free users | Crashlytics | >= 99% |
| Retenção D1 | Analytics | >= 40% |
| Retenção D7 | Analytics | >= 20% |
| Rolagens por sessão | Analytics | >= 3 |
