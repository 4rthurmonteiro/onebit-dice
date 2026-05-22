# 08 — Epics M1

| # | Epic | Descrição |
|---|---|---|
| E01 | Setup do Projeto | Configurar Flutter, dependências, estrutura de pastas, linting, CI |
| E02 | Design System | Paletas 1-bit, tipografia (Silkscreen/VT323/Press Start 2P), widgets base (MacButton, MacWindow, divisores, tab bar) |
| E03 | Engine de Dados | Lógica pura de rolagem — tipos de dado (d4–d100), aleatoriedade com `Random.secure()`, modelo de resultado |
| E04 | Persistência Local | SharedPreferences para configurações, Hive para histórico e presets customizados |
| E05 | Tela Principal (Rolar) | Seletor de tipo, seletor de quantidade, botão ROLAR, exibição do resultado com equação |
| E06 | Histórico | Lista de todas as rolagens passadas, botão limpar com confirmação |
| E07 | Presets / Jogos | 7 presets clássicos (Ludo, War, Yahtzee...) + slots customizados pelo usuário |
| E08 | Ajustes | Troca de paleta, toggles de som/haptic, configuração de animação |
| E09 | Navegação | Shell com 4 abas (ROLAR / HISTÓRICO / JOGOS / AJUSTES) + splash screen |
| E10 | Áudio & Haptic | Sons de rolagem/parada/soma, vibração ao rolar, toggles on/off |
| E11 | Analytics & Crash Reporting | Firebase Analytics (9 eventos) + Crashlytics |
| E12 | Animações dos Dados | 3 estilos (Rápida, Tambor, Tabuleiro) × 3 velocidades |
| E13 | Internacionalização | PT-BR + EN-US via arquivos `.arb` |
| E14 | Assets Visuais | Ícone do app, splash nativo, sprite sheets dos dados, fontes |
| E15 | Publicação nas Lojas | Build de release, keystore Android, signing iOS, assets das lojas, política de privacidade |
