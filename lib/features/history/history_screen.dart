import 'dart:async';

import 'package:flutter/material.dart';
import 'package:onebit_dice/core/i18n/l10n_extension.dart';
import 'package:onebit_dice/core/storage/history_repository.dart';
import 'package:onebit_dice/core/storage/models/roll_entry.dart';
import 'package:onebit_dice/core/theme/app_theme.dart';
import 'package:onebit_dice/core/theme/app_typography.dart';
import 'package:onebit_dice/features/history/widgets/clear_history_button.dart';
import 'package:onebit_dice/features/history/widgets/history_entry_tile.dart';
import 'package:onebit_dice/shared/widgets/pixel_divider.dart';
import 'package:provider/provider.dart';

/// History tab — chronological list (newest first) of every persisted roll,
/// with a "CLEAR" action that asks for confirmation before wiping the
/// repository.
///
/// Consumes [HistoryRepository.watch] via [StreamBuilder]; the stream emits
/// the current snapshot on subscription so the empty state is reachable on
/// first frame without an extra pump.
class HistoryScreen extends StatelessWidget {
  /// Creates a [HistoryScreen].
  const HistoryScreen({super.key});

  /// Key tagging the empty-state body.
  @visibleForTesting
  static const Key emptyKey = ValueKey('HistoryScreen.empty');

  /// Key tagging the list when entries are present.
  @visibleForTesting
  static const Key listKey = ValueKey('HistoryScreen.list');

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OneBitColors>()!;
    final repository = context.read<HistoryRepository>();
    return Scaffold(
      backgroundColor: colors.paper,
      appBar: AppBar(title: Text(context.l10n.historyTitle)),
      body: StreamBuilder<List<RollEntry>>(
        stream: repository.watch(),
        initialData: repository.snapshot(),
        builder: (context, snapshot) {
          final entries = snapshot.data ?? const <RollEntry>[];
          if (entries.isEmpty) return _Empty(colors: colors);
          return _List(entries: entries, onClear: repository.clear);
        },
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.colors});

  final OneBitColors colors;

  @override
  Widget build(BuildContext context) {
    return Center(
      key: HistoryScreen.emptyKey,
      child: Text(
        context.l10n.historyEmpty,
        style: AppTypography.body.copyWith(color: colors.ink),
      ),
    );
  }
}

class _List extends StatelessWidget {
  const _List({required this.entries, required this.onClear});

  final List<RollEntry> entries;
  final Future<void> Function() onClear;

  @override
  Widget build(BuildContext context) {
    final reversed = entries.reversed.toList(growable: false);
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            key: HistoryScreen.listKey,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: reversed.length,
            separatorBuilder: (_, _) => const PixelDivider(),
            itemBuilder: (_, index) => HistoryEntryTile(entry: reversed[index]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ClearHistoryButton(onConfirm: () => unawaited(onClear())),
        ),
      ],
    );
  }
}
