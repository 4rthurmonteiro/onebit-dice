# 06 — Roadmap Futuro

## M2 — Dados IA (após M1 estável)
Estimativa: 1 semana

### Features
- Dados customizados via IA generativa
- Usuário escreve prompt ("dragão verde com asas", "café fumegante")
- IA gera sprite 32x32 em 1-bit dithered automaticamente
- Salvar no inventário de dados customizados (até 50 slots)
- IAP de créditos:
  - 5-10 gerações grátis pra todos
  - Pacotes pagos (R$ 4,90 / 14,90 / 29,90)
- Rolagem por shake (chacoalhar pra rolar) — sai do M1

### Stack adicional
- Firebase Genkit OU Vertex AI
- Gemini Imagen 3 Fast (~$0.02/imagem) pra imagem
- Cloud Function pra pós-processamento (dithering Floyd-Steinberg garantindo 1-bit real)
- App Check + rate limit
- Firebase In-App Purchases (IAP)

### Riscos
- Aprovação da Apple: política de IA generativa exige filtros de safety + botão de "reportar conteúdo"
- Custos de IA: monitorar de perto, ajustar preços se necessário

## M3 — Polimento e física
Estimativa: 1 semana

### Features
- Física 3D real de dados (Forge2D / Box2D em Dart)
- Dados batendo em parede / chacoalhando
- Modo "mesa de jogo" com tabuleiro virtual
- Modo escuro adaptativo (overlay nas paletas pra noite)
- Sincronização em nuvem opcional (Firestore) com login Google/Apple

### Riscos
- Forge2D adiciona MB ao APK
- Sync na nuvem aumenta complexidade significativamente — avaliar se vale o ROI

## M5 — Expansão por demanda

### Possíveis features (priorizar com dados reais de uso)
- Multiplayer local (passar celular)
- Modo escrava: usar telefone como dado físico (NFC + dois dispositivos)
- Pacote de paletas premium (R$ 2,90/pacote)
- Pacote de presets temáticos (Pokémon TCG, Magic, jogos brasileiros)
- Widgets de tela inicial (rolar sem abrir o app)
- Apple Watch / Wear OS companion app
- Modo iPad / tablet otimizado

## M10 — Long tail
Estimativa: backlog longo prazo

### Features de menor prioridade
- Travar dados individuais entre rolagens (modo Yahtzee)
- Salvar e compartilhar rolagens com amigos (link curto)
- Modo "Random Picker" usando dados (sorteio temático)
- Estatísticas do histórico (qual número saiu mais)
- Modo competitivo: dois jogadores rolam simultaneamente
- Integração com VRChat / Discord Activities

## Critério de priorização
Cada feature acima precisa passar nestes filtros antes de virar prioridade:

1. **Métrica suporta?** Olhar Analytics: quantos % dos usuários ativos usariam isso?
2. **Reviews pedem?** Se 5+ reviews pedem a feature, sobe prioridade
3. **Esforço cabe em 1 sprint?** Se demora >1 semana, quebrar
4. **Risco loja?** Não introduzir nada que ameace aprovação

## O que NUNCA entra no roadmap
- Account system / login obrigatório
- Coleta de dados pessoais
- Anúncios invasivos (banner permanente)
- Subscription mensal
- Paid upfront
- Compartilhamento social compulsório
- Push notifications de marketing
