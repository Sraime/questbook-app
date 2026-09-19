import 'package:flutter/material.dart';

import '../../../design_system/components/qb_card.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';
import '../../rulebook/content/rulebook_catalog.dart';
import '../../rulebook/content/rulebook_models.dart';
import '../../rulebook/rulebook_blocks.dart';

/// L'aide-mémoire des règles, sans quitter la partie.
///
/// Même contenu que `/regles`, mais déplié : à table, le MJ cherche une valeur
/// pendant qu'un joueur attend, et deux niveaux de navigation lui coûteraient
/// plus que le défilement.
class RulesPanel extends StatefulWidget {
  const RulesPanel({super.key});

  @override
  State<RulesPanel> createState() => _RulesPanelState();
}

class _RulesPanelState extends State<RulesPanel> {
  late String _chapterId = rulebookChapters.first.id;

  @override
  Widget build(BuildContext context) {
    final chapter = rulebookChapterById(_chapterId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            QBSpace.s6,
            QBSpace.s5,
            QBSpace.s6,
            QBSpace.s3,
          ),
          child: Wrap(
            spacing: QBSpace.s2,
            runSpacing: QBSpace.s2,
            children: [
              for (final entry in rulebookChapters)
                _ChapterChip(
                  label: entry.title,
                  selected: entry.id == _chapterId,
                  onTap: () => setState(() => _chapterId = entry.id),
                ),
            ],
          ),
        ),
        Expanded(
          child: chapter == null || !chapter.isReady
              ? _Empty(title: chapter?.title ?? 'Chapitre')
              : ListView(
                  padding: const EdgeInsets.fromLTRB(
                    QBSpace.s6,
                    0,
                    QBSpace.s6,
                    QBSpace.s8,
                  ),
                  children: [
                    for (final section in chapter.sections) ...[
                      _SectionCard(section: section),
                      const SizedBox(height: QBSpace.s4),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _ChapterChip extends StatelessWidget {
  const _ChapterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: QBSpace.s4,
            vertical: QBSpace.s2,
          ),
          decoration: BoxDecoration(
            color: selected ? QBColors.leather700 : QBColors.paper200,
            border: Border.all(color: QBColors.borderStrong, width: 2),
            borderRadius: BorderRadius.circular(QBRadius.full),
          ),
          child: Text(
            label,
            style: QBType.game().copyWith(
              fontWeight: QBType.weightSemibold,
              fontSize: 11,
              letterSpacing: 11 * QBType.trackingWide,
              color: selected ? QBColors.paper50 : QBColors.leather800,
            ),
          ),
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

class _Empty extends StatelessWidget {
  const _Empty({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: QBSpace.s6),
      child: Text(
        '« $title » n’est pas encore rédigé.',
        style: QBType.body().copyWith(
          fontSize: QBType.sm,
          color: QBColors.textMuted,
        ),
      ),
    );
  }
}
