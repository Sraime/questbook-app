import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/effects.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';

/// Leather-bordered modal shell. Ported from components/feedback/Dialog.jsx.
///
/// Use [showQBDialog] rather than constructing this directly — it wraps
/// Flutter's [showDialog] with the correct barrier color and layout.
class QBDialog extends StatelessWidget {
  const QBDialog({
    super.key,
    required this.title,
    required this.child,
    this.onClose,
    this.width = 360,
  });

  final String title;
  final Widget child;
  final VoidCallback? onClose;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Flutter's own Dialog does this; this shell is built from a plain
      // Container, so without it the soft keyboard simply covers the lower
      // fields and taps aimed at them land on the keyboard instead.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Center(
        // Material-dependent descendants (QBSelect's DropdownButton, text
        // field ink effects, etc.) need a Material ancestor — showDialog's
        // route doesn't provide one on its own.
        child: Material(
          type: MaterialType.transparency,
          child: Container(
            width: width,
            padding: const EdgeInsets.all(QBSpace.s6),
            decoration: BoxDecoration(
              color: QBColors.surfaceCard,
              borderRadius: BorderRadius.circular(QBRadius.lg),
              border: Border.all(color: QBColors.leather800, width: 3),
              boxShadow: QBShadows.paperLg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: QBType.game().copyWith(
                          fontWeight: QBType.weightBold,
                          fontSize: QBType.lg,
                          letterSpacing: QBType.lg * 0.02,
                          color: QBColors.ink900,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: onClose ?? () => Navigator.of(context).maybePop(),
                      child: const Text(
                        '×',
                        style: TextStyle(fontSize: 20, color: QBColors.ink500),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: QBSpace.s4),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<T?> showQBDialog<T>({
  required BuildContext context,
  required String title,
  required Widget Function(BuildContext context) builder,
  double width = 360,
}) {
  return showDialog<T>(
    context: context,
    barrierColor: const Color(0x99140C06),
    builder: (context) => QBDialog(
      title: title,
      width: width,
      child: builder(context),
    ),
  );
}
