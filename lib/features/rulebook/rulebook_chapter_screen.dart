import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../design_system/components/qb_card.dart';
import '../../design_system/components/qb_icon_button.dart';
import '../../design_system/components/qb_page_background.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/spacing.dart';
import '../../design_system/tokens/typography.dart';
import 'content/rulebook_catalog.dart';
import 'content/rulebook_models.dart';
import 'rulebook_blocks.dart';

/// One chapter of the rulebook. Unknown or unfinished ids fall back to a
/// short card rather than an empty page.
class RulebookChapterScreen extends StatelessWidget {
  const RulebookChapterScreen({super.key, required this.chapterId});

  final String chapterId;

  @override
  Widget build(BuildContext context) {
    final chapter = rulebookChapterById(chapterId);

    return QBPageBackground(
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 90),
          children: [
            Row(
              children: [
                QBIconButton(
                  icon: const Icon(LucideIcons.arrowLeft, size: 18),
                  label: 'Sommaire',
                  size: 36,
                  onPressed: () => context.go('/regles'),
                ),
                const SizedBox(width: QBSpace.s2),
                Expanded(
                  child: Text(
                    chapter?.title ?? 'Chapitre',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: QBType.game().copyWith(
                      fontWeight: QBType.weightBold,
                      fontSize: 20,
                      color: QBColors.ink900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: QBSpace.s5),
            if (chapter == null || !chapter.isReady)
              const _MissingChapter()
            else
              for (var i = 0; i < chapter.sections.length; i++) ...[
                if (i > 0) const SizedBox(height: QBSpace.s4),
                _SectionCard(section: chapter.sections[i]),
              ],
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.section});

  final RulebookSection section;

  @override
  Widget build(BuildContext context) {
    return QBCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: QBType.game().copyWith(
              fontWeight: QBType.weightSemibold,
              fontSize: 14,
              color: QBColors.ink900,
            ),
          ),
          const SizedBox(height: QBSpace.s4),
          for (var i = 0; i < section.blocks.length; i++) ...[
            if (i > 0) const SizedBox(height: QBSpace.s4),
            RulebookBlockView(block: section.blocks[i]),
          ],
        ],
      ),
    );
  }
}

class _MissingChapter extends StatelessWidget {
  const _MissingChapter();

  @override
  Widget build(BuildContext context) {
    return QBCard(
      padding: const EdgeInsets.all(18),
      child: Text(
        'Ce chapitre n’est pas encore rédigé. Le sommaire indique déjà '
        'sa place ; il arrivera à la prochaine passe.',
        style: QBType.body().copyWith(
          fontSize: QBType.sm,
          color: QBColors.textMuted,
        ),
      ),
    );
  }
}
