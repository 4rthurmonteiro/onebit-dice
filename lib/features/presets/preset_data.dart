import 'package:flutter/widgets.dart';
import 'package:onebit_dice/core/i18n/l10n_extension.dart';
import 'package:onebit_dice/core/models/dice_type.dart';
import 'package:onebit_dice/l10n/app_localizations.dart';

/// One of the 7 built-in dice configurations exposed by the Presets screen.
///
/// Each entry pre-applies a `(diceType, diceCount)` pair to the
/// `DiceController` when the user taps its card. Names are looked up from
/// [AppLocalizations] at render time via [localizedName].
@immutable
class BuiltInPreset {
  /// Creates a [BuiltInPreset].
  const BuiltInPreset({
    required this.id,
    required this.diceType,
    required this.diceCount,
    required this.nameLookup,
  });

  /// Stable identifier — kebab-case, used as a test fixture handle.
  final String id;

  /// Die type pre-applied when the user taps this card.
  final DiceType diceType;

  /// Number of dice (1..10) pre-applied when the user taps this card.
  final int diceCount;

  /// Resolves the localized user-visible name from an [AppLocalizations].
  final String Function(AppLocalizations l10n) nameLookup;

  /// Resolves [nameLookup] from [context].
  String localizedName(BuildContext context) => nameLookup(context.l10n);

  /// Notation in the form `NxDM` (e.g. `1xD6`, `2xD20`).
  String get notation => '$diceCount${diceType.label}';
}

/// The canonical seven built-in presets shown in the "Games" section.
const List<BuiltInPreset> builtInPresets = [
  BuiltInPreset(
    id: 'ludo',
    diceType: DiceType.d6,
    diceCount: 1,
    nameLookup: _ludo,
  ),
  BuiltInPreset(
    id: 'banco-imobiliario',
    diceType: DiceType.d6,
    diceCount: 2,
    nameLookup: _bancoImobiliario,
  ),
  BuiltInPreset(
    id: 'war',
    diceType: DiceType.d6,
    diceCount: 3,
    nameLookup: _war,
  ),
  BuiltInPreset(
    id: 'yahtzee',
    diceType: DiceType.d6,
    diceCount: 5,
    nameLookup: _yahtzee,
  ),
  BuiltInPreset(
    id: 'dnd-ataque',
    diceType: DiceType.d20,
    diceCount: 1,
    nameLookup: _dndAtaque,
  ),
  BuiltInPreset(
    id: 'magic-vida',
    diceType: DiceType.d20,
    diceCount: 1,
    nameLookup: _magicVida,
  ),
  BuiltInPreset(
    id: 'percentil',
    diceType: DiceType.d100,
    diceCount: 1,
    nameLookup: _percentil,
  ),
];

String _ludo(AppLocalizations l10n) => l10n.presetBuiltInLudo;
String _bancoImobiliario(AppLocalizations l10n) =>
    l10n.presetBuiltInBancoImobiliario;
String _war(AppLocalizations l10n) => l10n.presetBuiltInWar;
String _yahtzee(AppLocalizations l10n) => l10n.presetBuiltInYahtzee;
String _dndAtaque(AppLocalizations l10n) => l10n.presetBuiltInDndAtaque;
String _magicVida(AppLocalizations l10n) => l10n.presetBuiltInMagicVida;
String _percentil(AppLocalizations l10n) => l10n.presetBuiltInPercentil;
