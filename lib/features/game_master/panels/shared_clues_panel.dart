import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../data/remote/api_exception.dart';
import '../../../data/remote/remote_table.dart';
import '../../../design_system/components/qb_card.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';
import '../providers/game_master_providers.dart';
import '../widgets/clue_reader_dialog.dart';

/// Ce que le MJ a transmis au joueur qui regarde, et rien d'autre.
///
/// Ni le nombre d'indices qu'il ne voit pas, ni leur titre, ni le moindre
/// signe qu'il en existe : ce que le MJ garde ne se devine pas. C'est la
/// raison d'etre de cette liste separee de celle du MJ — le serveur ne rend
/// ici que les indices ouverts, sans compteur ni destinataires.
///
/// La liste se recharge a l'ouverture du volet, pas en direct. Autour d'une
/// table, le MJ dit a voix haute qu'il vient de transmettre quelque chose.
class SharedCluesPanel extends ConsumerWidget {
  const SharedCluesPanel({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clues = ref.watch(myCluesProvider(sessionId));

    return ListView(
      padding: const EdgeInsets.all(QBSpace.s4),
      children: [
        Text(
          'Indices',
          style: QBType.game().copyWith(
            fontWeight: QBType.weightBold,
            fontSize: 16,
            letterSpacing: 16 * QBType.trackingWide,
            color: QBColors.ink900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Ce que tu as trouvé en chemin, et que le MJ t’a laissé lire.',
          style: QBType.body().copyWith(
            fontSize: QBType.xs,
            color: QBColors.textMuted,
          ),
        ),
        switch (clues) {
          // Le cas courant en debut de partie, et celui qu'on verra le plus
          // souvent. Il dit qu'il n'y a rien, sans laisser entendre qu'il y a
          // quelque chose ailleurs.
          AsyncData(value: final list) when list.isEmpty => Padding(
              padding: const EdgeInsets.only(top: QBSpace.s3),
              child: Text(
                'Rien pour l’instant.',
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
                  _SharedClueCard(clue: clue),
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

/// Un indice recu : son titre dans la liste, son texte dans une fenetre.
///
/// La meme carte que chez le MJ, moins le badge et les gestes. Une liste de
/// titres se parcourt du regard, et un joueur qui en a ramasse cinq cherche
/// celui d'avant-hier.
class _SharedClueCard extends StatelessWidget {
  const _SharedClueCard({required this.clue});

  final RemoteSharedClue clue;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Lire ${clue.title}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => showClueReaderDialog(
          context,
          title: clue.title,
          contentMarkdown: clue.contentMarkdown,
        ),
        behavior: HitTestBehavior.opaque,
        child: QBCard(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
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
              const Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: QBColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
