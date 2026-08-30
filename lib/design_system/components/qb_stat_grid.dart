import 'package:flutter/material.dart';

/// Evenly spaced N-column grid for circular stat widgets ([QBStatDial],
/// creation-screen preview circles, …). Each child is centered in a cell
/// of `availableWidth / columns`, so a full row spans the screen and the
/// leftover items of a short last row stay aligned to the same columns
/// instead of drifting as a separately-centered `Wrap` run.
class QBStatGrid extends StatelessWidget {
  const QBStatGrid({
    super.key,
    required this.children,
    this.columns = 4,
    this.runSpacing = 14,
  });

  final List<Widget> children;
  final int columns;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth = constraints.maxWidth / columns;
        return Wrap(
          alignment: WrapAlignment.center,
          runSpacing: runSpacing,
          children: [
            for (final child in children)
              SizedBox(
                width: cellWidth,
                child: Center(child: child),
              ),
          ],
        );
      },
    );
  }
}
