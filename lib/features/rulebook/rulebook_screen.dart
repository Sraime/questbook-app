import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../design_system/components/qb_card.dart';
import '../../design_system/components/qb_page_background.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/spacing.dart';
import '../../design_system/tokens/typography.dart';
import 'content/rulebook_catalog.dart';
import 'content/rulebook_models.dart';

/// Table of contents for the 7th-edition keeper reminder.
///
/// A chapter without sections stays on the list, dimmed, until it is written.
class RulebookScreen extends StatelessWidget {
  const RulebookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return QBPageBackground(
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 24, 18, 90),
          children: [
            Text(
              'Livre de règle',
              style: QBType.game().copyWith(
                fontWeight: QBType.weightBold,
                fontSize: 22,
                color: QBColors.ink900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Rappel de l’Appel de Cthulhu, 7e édition — ce qu’on garde '
              'sous la main à l’écran du gardien.',
              style: QBType.body().copyWith(
                fontSize: QBType.sm,
                color: QBColors.textMuted,
              ),
            ),
            const SizedBox(height: QBSpace.s5),
            Text(
              'Sommaire',
              style: QBType.game().copyWith(
                fontWeight: QBType.weightSemibold,
                fontSize: 13,
                color: QBColors.leather700,
              ),
            ),
            const SizedBox(height: QBSpace.s3),
            for (var i = 0; i < rulebookChapters.length; i++) ...[
              if (i > 0) const SizedBox(height: QBSpace.s3),
              _ChapterCard(chapter: rulebookChapters[i], index: i + 1),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChapterCard extends StatelessWidget {
  const _ChapterCard({required this.chapter, required this.index});

  final RulebookChapter chapter;
  final int index;

  @override
  Widget build(BuildContext context) {
    final ready = chapter.isReady;

    return Opacity(
      opacity: ready ? 1 : 0.72,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: ready
              ? () => context.go('/regles/${chapter.id}')
              : null,
          borderRadius: BorderRadius.circular(10),
          child: QBCard(
            padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    index.toString().padLeft(2, '0'),
                    style: QBType.game().copyWith(
                      fontSize: 13,
                      color: QBColors.leather600,
                    ),
                  ),
                ),
                const SizedBox(width: QBSpace.s2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chapter.title,
                        style: QBType.game().copyWith(
                          fontWeight: QBType.weightSemibold,
                          fontSize: 14,
                          color: QBColors.ink900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ready ? chapter.summary : 'Prochainement — ${chapter.summary}',
                        style: QBType.body().copyWith(
                          fontSize: QBType.xs,
                          height: QBType.leadingSnug,
                          color: QBColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: QBSpace.s2),
                Icon(
                  ready ? LucideIcons.chevronRight : LucideIcons.clock,
                  size: 18,
                  color: ready ? QBColors.leather700 : QBColors.ink300,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
