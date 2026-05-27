/// Visual style of the dice roll animation.
///
/// AVISO: persistido como `index` em `AppSettingsPreference`. Não reordenar
/// membros sem coordenar uma migração — qualquer alteração na ordem quebra
/// a leitura de valores já persistidos no dispositivo do usuário.
enum AnimationStyle {
  /// Resultado aparece imediatamente, sem animação intermediária.
  fast,

  /// Dado tremula em loop curto antes de revelar o resultado.
  drum,

  /// Animação longa imitando um dado físico rolando na mesa.
  tabletop,
}

/// Velocidade da animação de rolagem.
///
/// AVISO: persistido como `index` em `AppSettingsPreference`. Não reordenar
/// membros sem coordenar uma migração.
enum AnimationSpeed {
  /// Animação curta (menor duração total).
  fast,

  /// Duração intermediária.
  medium,

  /// Animação longa.
  slow,
}
