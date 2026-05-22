# 07 — Publicação nas Lojas

## Pré-requisitos

### Google Play
- [ ] Conta Google Play Console ($25 one-time)
- [ ] Política de privacidade hospedada (URL pública)
- [ ] Keystore de produção gerado e armazenado com segurança
- [ ] AAB de release assinado e testado

### Apple App Store
- [ ] Apple Developer Account ($99/ano)
- [ ] Certificado de distribuição + provisioning profile
- [ ] Acesso ao Xcode pra archive (Mac obrigatório)
- [ ] IPA de release assinado e testado

## Reserva de nome (fazer ANTES de codar muito)
1. Criar app record no Play Console:
   - Nome: "1-Bit Dice"
   - Package: `com.am2.onebitdice`
2. Criar app record no App Store Connect:
   - Nome: "1-Bit Dice"
   - Bundle ID: `com.am2.onebitdice`
   - Sku: `onebit_dice_001`

Reservar nome cedo evita descobrir tarde que já está tomado.

## Assets obrigatórios

### Google Play Store
| Asset | Spec |
|---|---|
| Ícone do app | 512x512 PNG, alpha channel |
| Feature graphic | 1024x500 PNG, sem alpha |
| Phone screenshots | 2-8 imagens, 1080x1920 (ou similar 16:9) |
| 7" tablet screenshots (opcional) | 1024x600 |
| 10" tablet screenshots (opcional) | 1920x1200 |
| Vídeo promocional (opcional) | YouTube link |

### Apple App Store
| Asset | Spec |
|---|---|
| Ícone do app | 1024x1024 PNG, sem alpha, sem cantos arredondados |
| iPhone 6.7" screenshots | 1290x2796, 3-10 imagens |
| iPhone 6.5" screenshots | 1242x2688 OU usar 6.7" também |
| iPhone 5.5" (opcional legacy) | 1242x2208 |
| iPad screenshots (opcional) | 2048x2732 |
| App Preview Video (opcional) | 15-30s, formato Apple |

## Listagem (textos)

### Google Play
- **Título**: até 30 chars
- **Descrição curta**: até 80 chars
- **Descrição completa**: até 4000 chars

### Apple App Store
- **Nome do app**: até 30 chars
- **Subtítulo**: até 30 chars (KEY pra ASO Apple)
- **Promotional text**: até 170 chars (editável sem nova submissão)
- **Descrição**: até 4000 chars
- **Keywords**: até 100 chars (NÃO repetir nome do app — desperdício)
- **What's New**: até 4000 chars (release notes)

## Formulários nas lojas

### Google Play Console
- [ ] Classificação etária IARC (questionário)
- [ ] Formulário de segurança de dados (privacy)
- [ ] Categoria do app: Ferramentas
- [ ] Tags (até 5)
- [ ] Países de distribuição (todos por padrão)
- [ ] Preço: Grátis
- [ ] Contém anúncios: NÃO
- [ ] Compras no app: NÃO (no M1)
- [ ] Tem login obrigatório: NÃO

### App Store Connect
- [ ] Idade: 4+
- [ ] Categoria primária: Ferramentas
- [ ] Categoria secundária (opcional): Jogos > Tabuleiro
- [ ] Direitos de uso de conteúdo (questionário)
- [ ] Informações de privacidade (App Privacy):
  - Nenhum dado coletado
- [ ] Sandbox de teste preenchido com Test Account opcional
- [ ] Trade representative info (preenchido em Tax info — Apple exige)

## Fluxo de submissão

### Google Play (passo a passo)
1. `flutter build appbundle --release` — gera AAB
2. Upload no Play Console → Faixa de Testes Internos
3. Adicionar testers (email do dev)
4. Verificar funcionamento via link de teste interno
5. Promover pra Closed Testing → Open Testing (opcional)
6. Promover pra Produção
7. Aguardar review (geralmente 1-7 dias na primeira submissão)

### Apple App Store (passo a passo)
1. Configurar Signing & Capabilities no Xcode
2. `flutter build ipa --release` — gera IPA
3. Upload via Transporter (recomendado) ou Xcode → App Store Connect
4. Esperar processamento do build (15-30 min)
5. Selecionar build em App Store Connect → Preparar pra submissão
6. Preencher metadados + screenshots
7. Submeter pra App Review
8. Aguardar review (geralmente 24-48h, mas pode levar dias)

## Erros comuns que atrasam aprovação

### Google Play
- Política de privacidade inválida ou inacessível
- Formulário de segurança de dados incompleto
- Permissões declaradas em uso real (se declarou microfone, precisa usar)
- Tamanho de feature graphic errado

### Apple
- **Guideline 4.2 (Minimum Functionality)**: app "muito simples". Mitigar com descrição completa vendendo features.
- **Guideline 5.1.1 (Privacy)**: declarar corretamente que não coleta dados
- Screenshots não correspondem à versão final do app
- Bundle ID divergente entre Xcode e App Store Connect
- Esquecer de submeter "App Privacy" antes de submeter o build
- Builds antigos em desuso bloqueando submissão

## Pós-aprovação — primeiras 48h
- [ ] Verificar Crashlytics 100% online
- [ ] Verificar Analytics recebendo eventos
- [ ] Compartilhar nas comunidades (Reddit, Twitter, FB groups)
- [ ] Pedir avaliação pros primeiros usuários conhecidos (família, amigos do projeto principal)
- [ ] Monitorar reviews diariamente, responder profissionalmente
- [ ] Hotfix (se necessário) numa nova versão patch

## Quanto custa publicar
| Item | Custo |
|---|---|
| Google Play Console | $25 one-time |
| Apple Developer Program | $99/ano |
| Domínio (`1bitdice.com`) | ~R$ 50/ano |
| Hosting privacy policy (GitHub Pages) | Grátis |
| Firebase free tier | Grátis (até bater limites) |
| **TOTAL primeiro ano** | ~R$ 700 |

## Backup e segurança
- [ ] Keystore Android: backup em 3 lugares (drive, cofre físico, password manager)
- [ ] Senha do keystore: NÃO perder NUNCA. Perder = não conseguir mais atualizar o app.
- [ ] Certificados Apple: revogáveis e re-emitíveis, menos crítico
- [ ] Conta Google Play Console: 2FA obrigatório
- [ ] Apple Developer Account: 2FA obrigatório
