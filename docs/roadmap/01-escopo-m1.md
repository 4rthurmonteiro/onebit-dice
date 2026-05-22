# 01 — Escopo M1 (MVP)

## Princípio guia
Lançar o mais rápido possível com qualidade visual alta. Cada feature foi decidida pesando ROI (impacto na experiência) vs custo (tempo de desenvolvimento). Quando em dúvida, **cortar**.

## Features incluídas no M1

### 1. Rolagem de 1 a 10 dados simultâneos
- **Decisão**: 10 cobre todos os casos reais (Yahtzee = 5d6, War = 3vs3 = 6d6 com folga, qualquer combate de RPG razoável).
- O concorrente (Lançador de Dados!) faz até 40 — descartado como excesso pro MVP.

### 2. Tipos de dado padrão
- d4, d6, d8, d10, d12, d20, d100
- Cobre 100% dos casos de RPG e tabuleiro.

### 3. Soma total automática
- Após cada rolagem, exibe o total automaticamente.
- Equação grande visível tipo "4 + 6 = 10".

### 4. Histórico completo + botão "Limpar"
- **Decisão final**: salvar TODAS as rolagens (sem limitar a 20 como sugestão inicial).
- Botão "LIMPAR HISTÓRICO" com diálogo de confirmação.
- Cada entrada: data/hora, dados rolados, resultados individuais, soma.

### 5. Toque pra rolar
- Botão grande "ROLAR" na tela principal.
- Shake detection (chacoalhar pra rolar) **NÃO entra no M1** — fica pra M2.

### 6. Som + haptic feedback
- Sons curtos: rolagem, parada, soma.
- Haptic medium ao tocar pra rolar.
- Toggles independentes on/off nas configurações.

### 7. Estética 1-bit + 6 paletas trocáveis
- Mac Classic (default), Mac Beige, Game Boy DMG, Commodore 64, ZX Spectrum, Apple II Green.
- Apple //e Amber como wildcard adicional.
- Troca em tempo real via tela de ajustes.

### 8. Presets de jogos clássicos
| Preset | Configuração |
|---|---|
| Ludo | 1d6 |
| Banco Imobiliário | 2d6 |
| War Ataque | 3d6 |
| War Defesa | 3d6 |
| Yahtzee | 5d6 |
| Catan | 2d6 |
| D&D | 1d20 |
| + Novo (slot custom) | até 10 personalizados |

### 9. Múltiplas animações de rolagem
- Estilos: "Rápida" (queda instantânea), "Tambor" (giro), "Tabuleiro" (rola como dado físico).
- Velocidade ajustável: rápido / médio / longo.
- Configurável na tela de ajustes.

### 10. Salvar configurações customizadas
- Até 10 slots de configuração personalizada (ex: "Minhas 2d6 do Banco" salvo).
- Acessível via tela de Presets.

## Features EXPLICITAMENTE excluídas do M1

| Feature | Motivo da exclusão | Quando entra |
|---|---|---|
| Dados customizados com texto/emoji/imagem | UI complexa de criação | M2 (com IA) |
| Travar dados individuais entre rolagens | Baixa prioridade — útil só pra Yahtzee | M10 |
| Rolagem por shake (chacoalhar) | Mais polimento que MVP | M2 ou M3 |
| 40 dados simultâneos | Caso de uso raro | Nunca (ou M5+ se houver demanda) |
| Dados em 3D real com física | Inviável em Flutter sem dependência pesada | M3+ (via Forge2D) |
| Multiplayer / passar celular entre jogadores | Não é core | M5+ |
| Modo escuro automático | Já é 1-bit, paletas servem | Nunca |
| Login / contas | Não tem necessidade | Nunca |
| Sincronização entre dispositivos | Sem login, sem necessidade | Nunca |

## Comportamento detalhado

### Estado inicial (primeira abertura)
- Splash → Home
- Dado selecionado: d6
- Quantidade: 1
- Paleta default: Mac Classic
- Som: ON
- Haptic: ON
- Velocidade de animação: Médio
- Estilo de animação: Tambor

### Persistência local
- **Configurações** (paleta, som, haptic, animação): `shared_preferences`
- **Histórico de rolagens**: `hive` (escalável pra milhares de entradas)
- **Presets customizados**: `hive`
- **Última configuração de tipo/quantidade**: `shared_preferences`

### Aleatoriedade
- Usar `Random.secure()` do Dart pra garantir distribuição uniforme.
- Importante: jogadores de RPG são paranóicos com isso. Reviews já mencionam.

### Estados de erro
- App é 100% offline e local — praticamente sem possibilidade de erro.
- Crashlytics captura qualquer crash inesperado pra diagnóstico.

### Performance
- Animações em sprite sheet (pré-renderizadas no Blender em 1-bit dithered).
- Target: 60fps em qualquer celular Android dos últimos 5 anos e iPhone 8+.

## Internacionalização
- M1: PT-BR e EN-US (Apple exige inglês como base).
- M2: adicionar ES.
- Strings em arquivo `.arb` (intl Flutter).

## Acessibilidade básica (M1)
- Tap targets mínimo 44pt (Apple HIG).
- Contraste 100% por ser 1-bit puro.
- Suporte a TalkBack (Android) e VoiceOver (iOS) com semantic labels nos botões principais.
