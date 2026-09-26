import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../data/remote/api_exception.dart';
import '../../../data/remote/remote_table.dart';
import '../../../design_system/components/qb_button.dart';
import '../../../design_system/components/qb_card.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';
import '../../scenarios/scenario_detail_screen.dart';
import '../providers/game_master_providers.dart';
import '../widgets/clue_dialog.dart';
import '../widgets/clue_sharing_dialog.dart';

/// Ce que le MJ prépare pour le faire passer de l'autre côté de l'écran.
///
/// L'inverse du volet PNJ : ceux-là, ses joueurs ne les verront jamais ; les
/// indices, c'est lui qui décide quand et à qui. D'où la seule chose que
/// chaque carte doit dire sans qu'on la déplie — qui l'a déjà lu.
class CluesPanel extends ConsumerWidget {
  const CluesPanel({
    super.key,
    required this.sessionId,
    required this.members,
    required this.compact,
  });

  final String sessionId;

  /// Les joueurs de la table, le MJ exclu : ce sont les cases à cocher du
  /// partage, et il ne se transmet rien à lui-même.
  final List<RemoteTableMember> members;

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clues = ref.watch(sessionCluesProvider(sessionId));

    return ListView(
      padding: const EdgeInsets.all(QBSpace.s4),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Indices',
                style: QBType.game().copyWith(
                  fontWeight: QBType.weightBold,
                  fontSize: 16,
                  letterSpacing: 16 * QBType.trackingWide,
                  color: QBColors.ink900,
                ),
              ),
            ),
            QBButton(
              label: compact ? '+ Composer' : '+ Composer un indice',
              size: QBButtonSize.sm,
              onPressed: () => showClueDialog(context, sessionId: sessionId),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          'Lettres, plans, pages arrachées. Un indice n’est à personne tant '
          'que tu ne l’as pas transmis.',
          style: QBType.body().copyWith(
            fontSize: QBType.xs,
            color: QBColors.textMuted,
          ),
        ),
        switch (clues) {
          AsyncData(value: final list) when list.isEmpty => Padding(
              padding: const EdgeInsets.only(top: QBSpace.s3),
              child: Text(
                'Rien pour l’instant. Compose ce que tes joueurs trouveront '
                'en chemin.',
                style: QBType.body().copyWith(
                  fontSize: QBType.sm,
                  color: QBColors.textMuted,
                ),
              ),
            ),
          AsyncData(value: final list) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final clue in list) ...[
                  const SizedBox(height: QBSpace.s3),
                  _ClueCard(
                    sessionId: sessionId,
                    clue: clue,
                    members: members,
                  ),
                ],
              ],
            ),
          AsyncError(error: final error) => Padding(
              padding: const EdgeInsets.only(top: QBSpace.s3),
              child: Text(
                error is ApiException
                    ? error.message
                    : 'Impossible de charger les indices.',
                style: QBType.body().copyWith(
                  fontSize: QBType.sm,
                  color: QBColors.semanticDanger,
                ),
              ),
            ),
          _ => const Padding(
              padding: EdgeInsets.all(QBSpace.s4),
              child: Center(child: CircularProgressIndicator()),
            ),
        },
      ],
    );
  }
}

/// Un indice, replié sur son titre et sur qui l'a lu.
///
/// Le contenu se déplie sur place plutôt que dans un écran : le MJ vérifie ce
/// qu'il s'apprête à transmettre, souvent juste avant de le transmettre, et un
/// aller-retour lui ferait perdre la liste de vue.
class _ClueCard extends ConsumerStatefulWidget {
  const _ClueCard({
    required this.sessionId,
    required this.clue,
    required this.members,
  });

  final String sessionId;
  final RemoteClue clue;
  final List<RemoteTableMember> members;

  @override
  ConsumerState<_ClueCard> createState() => _ClueCardState();
}

class _ClueCardState extends ConsumerState<_ClueCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final clue = widget.clue;
    final shared = clue.sharedWith.length;

    return QBCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            label: _open ? 'Replier ${clue.title}' : 'Déplier ${clue.title}',
            child: GestureDetector(
              onTap: () => setState(() => _open = !_open),
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      clue.title,
                      style: QBType.game().copyWith(
                        fontWeight: QBType.weightSemibold,
                        fontSize: 15,
                        color: QBColors.ink900,
                      ),
                    ),
                  ),
                  _SharedBadge(count: shared),
                  const SizedBox(width: QBSpace.s2),
                  Icon(
                    _open ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                    size: 18,
                    color: QBColors.textMuted,
                  ),
                ],
              ),
            ),
          ),
          if (_open) ...[
            const SizedBox(height: QBSpace.s3),
            // Le rendu, pas la source : c'est ce que le joueur va lire, et
            // c'est donc ce que le MJ doit relire avant de l'envoyer.
            ScenarioMarkdown(clue.contentMarkdown),
            const SizedBox(height: QBSpace.s4),
            Row(
              children: [
                QBButton(
                  label: 'Transmettre',
                  size: QBButtonSize.sm,
                  onPressed: () => showClueSharingDialog(
                    context,
                    sessionId: widget.sessionId,
                    clue: clue,
                    members: widget.members,
                  ),
                ),
                const SizedBox(width: QBSpace.s2),
                if (clue.isEditable)
                  QBButton(
                    label: 'Modifier',
                    size: QBButtonSize.sm,
                    variant: QBButtonVariant.ghost,
                    onPressed: () => showClueDialog(
                      context,
                      sessionId: widget.sessionId,
                      existing: clue,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Combien de joueurs l'ont déjà lu. Le seul état qui compte au premier coup
/// d'oeil, et celui qu'on regrette de ne pas voir quand on cherche ce qu'on a
/// déjà lâché.
class _SharedBadge extends StatelessWidget {
  const _SharedBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    if (count == 0) {
      return Text(
        'Non transmis',
        style: QBType.body().copyWith(
          fontSize: QBType.xs,
          color: QBColors.textMuted,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(LucideIcons.eye, size: 14, color: QBColors.gold700),
        const SizedBox(width: 4),
        Text(
          count == 1 ? '1 joueur' : '$count joueurs',
          style: QBType.body().copyWith(
            fontSize: QBType.xs,
            color: QBColors.gold700,
          ),
        ),
      ],
    );
  }
}
