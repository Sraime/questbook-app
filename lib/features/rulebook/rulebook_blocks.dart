import 'package:flutter/material.dart';

import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/spacing.dart';
import '../../design_system/tokens/typography.dart';
import 'content/rulebook_models.dart';

/// Renders one content block. Kept next to the screen so a later chapter can
/// reuse the same paragraph / list / table / callout language without
/// inventing a second layout.
class RulebookBlockView extends StatelessWidget {
  const RulebookBlockView({super.key, required this.block});

  final RulebookBlock block;

  @override
  Widget build(BuildContext context) {
    return switch (block) {
      RulebookParagraph(:final text) => Text(
          text,
          style: QBType.body().copyWith(
            fontSize: QBType.sm,
            height: QBType.leadingNormal,
            color: QBColors.textBody,
          ),
        ),
      RulebookBullets(:final items) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(height: QBSpace.s2),
              _BulletRow(text: items[i]),
            ],
          ],
        ),
      RulebookTable(:final headers, :final rows) => _RuleTable(
          headers: headers,
          rows: rows,
        ),
      RulebookCallout(:final text, :final tone) => _Callout(
          text: text,
          tone: tone,
        ),
    };
  }
}

class _BulletRow extends StatelessWidget {
  const _BulletRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: QBColors.leather600,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: QBSpace.s3),
        Expanded(
          child: Text(
            text,
            style: QBType.body().copyWith(
              fontSize: QBType.sm,
              height: QBType.leadingNormal,
              color: QBColors.textBody,
            ),
          ),
        ),
      ],
    );
  }
}

class _RuleTable extends StatelessWidget {
  const _RuleTable({required this.headers, required this.rows});

  final List<String> headers;
  final List<List<String>> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: QBColors.surfaceRaised,
        border: Border.all(color: QBColors.leather700, width: 1.5),
        borderRadius: BorderRadius.circular(QBRadius.md),
      ),
      clipBehavior: Clip.antiAlias,
      child: Table(
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            decoration: const BoxDecoration(color: QBColors.paper200),
            children: [
              for (final header in headers) _Cell(header, header: true),
            ],
          ),
          for (var i = 0; i < rows.length; i++)
            TableRow(
              decoration: BoxDecoration(
                color: i.isOdd ? QBColors.paper100 : QBColors.paper50,
              ),
              children: [
                for (final cell in rows[i]) _Cell(cell),
              ],
            ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell(this.text, {this.header = false});

  final String text;
  final bool header;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Text(
        text,
        style: (header ? QBType.game() : QBType.body()).copyWith(
          fontSize: header ? 11 : QBType.xs,
          fontWeight: header ? QBType.weightSemibold : QBType.weightRegular,
          height: QBType.leadingSnug,
          color: header ? QBColors.ink900 : QBColors.textBody,
        ),
      ),
    );
  }
}

class _Callout extends StatelessWidget {
  const _Callout({required this.text, required this.tone});

  final String text;
  final RulebookCalloutTone tone;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, Color edge) = switch (tone) {
      RulebookCalloutTone.info => (
          QBColors.semanticInfoBg,
          QBColors.arcane700,
          QBColors.arcane500,
        ),
      RulebookCalloutTone.warning => (
          QBColors.semanticWarningBg,
          QBColors.gold700,
          QBColors.gold600,
        ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: edge, width: 1.5),
        borderRadius: BorderRadius.circular(QBRadius.md),
      ),
      child: Text(
        text,
        style: QBType.body().copyWith(
          fontSize: QBType.xs,
          height: QBType.leadingNormal,
          color: fg,
        ),
      ),
    );
  }
}
