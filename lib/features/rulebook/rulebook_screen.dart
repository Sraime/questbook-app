import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../design_system/components/qb_card.dart';
import '../../design_system/components/qb_page_background.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/spacing.dart';
import '../../design_system/tokens/typography.dart';

/// Placeholder, on purpose: the rulebook is a feature of its own and the menu
/// entry ships first. An empty page that says so is more honest than an entry
/// that silently goes nowhere.
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
            const SizedBox(height: QBSpace.s5),
            QBCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    LucideIcons.bookOpen,
                    size: 22,
                    color: QBColors.leather700,
                  ),
                  const SizedBox(height: QBSpace.s3),
                  Text(
                    'Bientôt',
                    style: QBType.game().copyWith(
                      fontWeight: QBType.weightSemibold,
                      fontSize: 15,
                      color: QBColors.ink900,
                    ),
                  ),
                  const SizedBox(height: QBSpace.s2),
                  Text(
                    'Les règles de l’univers — compétences, occupations, jets '
                    'et seuils — se liront ici. En attendant, la fiche de '
                    'personnage reste la référence.',
                    style: QBType.body().copyWith(
                      fontSize: QBType.sm,
                      color: QBColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
