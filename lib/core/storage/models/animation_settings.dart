/// Visual style of the dice roll animation.
///
/// AVISO: persistido como `index` em `AppSettingsPreference`. Não reordenar
/// membros sem coordenar uma migração — qualquer alteração na ordem quebra
/// a leitura de valores já persistidos no dispositivo do usuário.
enum AnimationStyle {
  /// Resultado aparece imediatamente, sem animação intermediária.
  fast(label: 'Rápida'),

  /// Dado tremula em loop curto antes de revelar o resultado.
  drum(label: 'Tambor'),

  /// Animação longa imitando um dado físico rolando na mesa.
  tabletop(label: 'Tabuleiro');

  const AnimationStyle({required this.label});

  /// Rótulo em pt-BR exibido na UI de configurações.
  final String label;
}

/// Velocidade da animação de rolagem.
///
/// AVISO: persistido como `index` em `AppSettingsPreference`. Não reordenar
/// membros sem coordenar uma migração.
enum AnimationSpeed {
  /// Animação curta (menor duração total).
  fast(label: 'Rápido'),

  /// Duração intermediária.
  medium(label: 'Médio'),

  /// Animação longa.
  slow(label: 'Longo');

  const AnimationSpeed({required this.label});

  /// Rótulo em pt-BR exibido na UI de configurações.
  final String label;
}
