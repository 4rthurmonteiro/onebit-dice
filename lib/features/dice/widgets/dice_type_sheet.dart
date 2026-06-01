import 'package:flutter/material.dart';
import 'package:onebit_dice/core/i18n/l10n_extension.dart';
import 'package:onebit_dice/core/models/dice_type.dart';
import 'package:onebit_dice/core/theme/app_theme.dart';
import 'package:onebit_dice/core/theme/app_typography.dart';
import 'package:onebit_dice/features/dice/widgets/dice_type_badge.dart';
import 'package:onebit_dice/shared/widgets/hatch_painter.dart';
import 'package:onebit_dice/shared/widgets/mac_window.dart';
import 'package:onebit_dice/shared/widgets/pixel_icon.dart';

/// Bottom sheet listing the seven [DiceType]s for selection.
///
/// Presented over a 1-bit checkerboard [HatchPainter] barrier instead of the
/// default translucent grey scrim — owning the barrier lets us honor the
/// strict 2-color palette (no grey, no alpha). Dismisses via the ✕, a tap on
/// the hatch, a downward drag on the handle, or the Android back button, all
/// resolving the [show] future to `null`. Tapping a row resolves it to that
/// [DiceType].
class DiceTypeSheet extends StatelessWidget {
  /// Creates a [DiceTypeSheet] highlighting [selected].
  const DiceTypeSheet({
    required this.selected,
    required this.onPicked,
    required this.onDismiss,
    super.key,
  });

  /// The currently active type, rendered inverted with a checkmark.
  final DiceType selected;

  /// Invoked with the tapped [DiceType].
  final ValueChanged<DiceType> onPicked;

  /// Invoked when the sheet is dismissed without a selection.
  final VoidCallback onDismiss;

  /// Key tagging the sheet panel.
  @visibleForTesting
  static const Key sheetKey = ValueKey('DiceTypeSheet.sheet');

  /// Key tagging the hatch barrier behind the sheet.
  @visibleForTesting
  static const Key barrierKey = ValueKey('DiceTypeSheet.barrier');

  /// Key tagging the drag handle above the panel.
  @visibleForTesting
  static const Key dragHandleKey = ValueKey('DiceTypeSheet.dragHandle');

  /// Pixel checkmark drawn on the selected row, rendered through [PixelIcon]
  /// (inverted so it shows in paper over the row's ink fill).
  static const List<List<int>> _checkmark = [
    [0, 0, 0, 0, 0, 0, 0, 1],
    [0, 0, 0, 0, 0, 0, 1, 1],
    [0, 0, 0, 0, 0, 1, 1, 0],
    [1, 0, 0, 0, 1, 1, 0, 0],
    [1, 1, 0, 1, 1, 0, 0, 0],
    [0, 1, 1, 1, 0, 0, 0, 0],
    [0, 0, 1, 1, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0],
  ];

  /// Pushes the sheet and resolves to the picked [DiceType], or `null` when
  /// dismissed. [selected] marks the row to invert + check.
  static Future<DiceType?> show(
    BuildContext context, {
    required DiceType selected,
  }) {
    return Navigator.of(
      context,
    ).push<DiceType>(_DiceTypeSheetRoute(selected: selected));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DragHandle(onDismiss: onDismiss),
            KeyedSubtree(
              key: sheetKey,
              child: MacWindow(
                title: l10n.diceTypeSheetTitle,
                onClose: onDismiss,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final type in DiceType.values)
                      _DiceTypeRow(
                        type: type,
                        selected: type == selected,
                        onTap: () => onPicked(type),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single tappable dice-type row: badge + label + `N sides` sublabel.
/// Inverted (ink fill, paper text) with a pixel checkmark when [selected].
class _DiceTypeRow extends StatelessWidget {
  const _DiceTypeRow({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final DiceType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OneBitColors>()!;
    final l10n = context.l10n;
    final fg = selected ? colors.paper : colors.ink;
    return Semantics(
      button: true,
      selected: selected,
      label: type.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          color: selected ? colors.ink : colors.paper,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              DiceTypeBadge(type: type, inverted: selected),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type.label,
                      style: AppTypography.display.copyWith(
                        color: fg,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      l10n.diceTypeSidesLabel(type.sides),
                      style: AppTypography.body.copyWith(
                        color: fg,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                const ExcludeSemantics(
                  child: PixelIcon(
                    matrix: DiceTypeSheet._checkmark,
                    size: 20,
                    inverted: true,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pixel drag handle that pops the sheet once a downward drag passes a small
/// threshold — the bottom-sheet "swipe to dismiss" affordance, hand-wired
/// because the custom route owns its own barrier.
class _DragHandle extends StatefulWidget {
  const _DragHandle({required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  State<_DragHandle> createState() => _DragHandleState();
}

class _DragHandleState extends State<_DragHandle> {
  static const double _threshold = 24;
  double _dragged = 0;
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OneBitColors>()!;
    return GestureDetector(
      key: DiceTypeSheet.dragHandleKey,
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: (details) {
        if (_dismissed) return;
        _dragged += details.delta.dy;
        if (_dragged > _threshold) {
          _dismissed = true;
          widget.onDismiss();
        }
      },
      onVerticalDragEnd: (_) => _dragged = 0,
      child: Container(
        width: double.infinity,
        height: 24,
        color: colors.paper,
        alignment: Alignment.center,
        child: Container(width: 32, height: 4, color: colors.ink),
      ),
    );
  }
}

/// Custom [PopupRoute] hosting the [HatchPainter] barrier and the bottom-
/// aligned [DiceTypeSheet]. Appears with a hard cut (zero transition) so no
/// alpha fade is ever needed — a fade would violate the 2-color rule.
class _DiceTypeSheetRoute extends PopupRoute<DiceType> {
  _DiceTypeSheetRoute({required this.selected});

  final DiceType selected;

  // We paint our own opaque hatch barrier, so suppress the framework's.
  @override
  Color? get barrierColor => null;

  // Dismissal is wired manually via the hatch GestureDetector below.
  @override
  bool get barrierDismissible => false;

  @override
  String? get barrierLabel => null;

  @override
  Duration get transitionDuration => Duration.zero;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final colors = Theme.of(context).extension<OneBitColors>()!;
    final l10n = context.l10n;
    void dismiss() => Navigator.of(context).pop();
    return Stack(
      children: [
        Positioned.fill(
          child: Semantics(
            button: true,
            label: l10n.actionClose,
            child: GestureDetector(
              key: DiceTypeSheet.barrierKey,
              behavior: HitTestBehavior.opaque,
              onTap: dismiss,
              child: CustomPaint(
                painter: HatchPainter(ink: colors.ink, paper: colors.paper),
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: DiceTypeSheet(
            selected: selected,
            onPicked: (type) => Navigator.of(context).pop(type),
            onDismiss: dismiss,
          ),
        ),
      ],
    );
  }
}
