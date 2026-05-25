import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:onebit_dice/core/storage/models/custom_preset.dart';
import 'package:onebit_dice/core/storage/models/roll_entry.dart';

/// Name of the Hive box that stores the user's roll history.
const String hiveRollHistoryBoxName = 'roll_history';

/// Name of the Hive box that stores custom presets.
const String hiveCustomPresetsBoxName = 'custom_presets';

/// Handle to every Hive box opened by [HiveInit].
///
/// Returned by both [HiveInit.init] (which initializes Flutter's Hive path)
/// and [HiveInit.registerAndOpen] (which assumes Hive is already initialized
/// — used by tests).
class HiveBoxes {
  /// Bundles the [rollHistory] and [customPresets] boxes.
  const HiveBoxes({required this.rollHistory, required this.customPresets});

  /// Box storing every [RollEntry] in insertion order.
  final Box<RollEntry> rollHistory;

  /// Box storing every [CustomPreset], keyed by id.
  final Box<CustomPreset> customPresets;
}

/// Bootstrap entry point for the storage layer.
///
/// Consumed by the splash screen (E06) — `main()` itself stays minimal and
/// does not call into Hive eagerly.
///
/// typeId table (locked by the E04 brainstorm):
///
/// | typeId | Class          |
/// | ------ | -------------- |
/// | `0`    | [RollEntry]    |
/// | `1`    | [CustomPreset] |
///
/// `2..9` are reserved for future storage models.
abstract final class HiveInit {
  /// Initializes Hive's Flutter path provider, registers adapters, and
  /// opens both production boxes.
  static Future<HiveBoxes> init() async {
    await Hive.initFlutter();
    return registerAndOpen();
  }

  /// Registers adapters (idempotently) and opens both production boxes.
  ///
  /// Assumes the caller has already configured Hive's storage directory
  /// (via `Hive.initFlutter` or `Hive.init`). Tests use this overload
  /// directly to avoid the `path_provider` plugin dependency.
  static Future<HiveBoxes> registerAndOpen() async {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(RollEntryAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(CustomPresetAdapter());
    }
    final rollHistory = await Hive.openBox<RollEntry>(hiveRollHistoryBoxName);
    final customPresets = await Hive.openBox<CustomPreset>(
      hiveCustomPresetsBoxName,
    );
    return HiveBoxes(rollHistory: rollHistory, customPresets: customPresets);
  }
}
