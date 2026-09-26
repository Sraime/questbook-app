import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/remote_providers.dart';
import '../../../data/remote/api_exception.dart';
import '../../../data/remote/remote_table.dart';
import '../../../design_system/components/qb_button.dart';
import '../../../design_system/components/qb_card.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';
import '../providers/game_master_providers.dart';
import '../widgets/clue_dialog.dart';
import '../widgets/clue_reader_dialog.dart';
import '../widgets/clue_sharing_dialog.dart';

/// Ce que le MJ prépare pour le faire passer de l'autre côté de l'écran.
///
/// L'inverse du volet PNJ : ceux-là, ses joueurs ne les verront jamais ; les
/// indices, c'est lui qui décide quand et à qui.
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
              label: compact ? '+ Ajouter' : '+ Ajouter un indice',
              size: QBButtonSize.sm,
              onPressed: () => showClueDialog(context, sessionId: sessionId),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          'Lettres, plans, pages arrachées. Un indice n’est à personne tant '
          'que tu ne l’as pas partagé.',
          style: QBType.body().copyWith(
            fontSize: QBType.xs,
            color: QBColors.textMuted,
          ),
        ),
        switch (clues) {
          AsyncData(value: final list) when list.isEmpty => Padding(
              padding: const EdgeInsets.only(top: QBSpace.s3),
              child: Text(
                'Rien pour l’instant. Ajoute ce que tes joueurs trouveront '
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

/// Un indice dans la liste : son titre, et rien d'autre.
///
/// Le contenu s'ouvre dans une fenêtre, avec les gestes qui le concernent. La
/// liste reste ainsi parcourable du regard — un MJ qui en a préparé huit
/// cherche celui qu'il s'apprête à donner, pas une colonne de prose.
///
/// À qui il est ouvert se lit dans la fenêtre de partage, cases cochées : un
/// compteur sur la carte ne nommait personne et occupait la ligne.
class _ClueCard extends StatelessWidget {
  const _ClueCard({
    required this.sessionId,
    required this.clue,
    required this.members,
  });

  final String sessionId;
  final RemoteClue clue;
  final List<RemoteTableMember> members;

  void _open(BuildContext context) {
    showClueReaderDialog(
      context,
      title: clue.title,
      contentMarkdown: clue.contentMarkdown,
      actions: _ClueActions(
        sessionId: sessionId,
        clue: clue,
        members: members,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Lire ${clue.title}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => _open(context),
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

/// Tout ce qu'on peut faire d'un indice, au bas de sa lecture.
///
/// Les trois gestes au même endroit, parce qu'on les prend au même moment :
/// on relit l'indice, et on décide alors de le donner, de le reprendre ou de
/// s'en débarrasser. La suppression vivait au fond du formulaire de
/// modification, ce qui demandait d'ouvrir une correction pour ne rien
/// corriger.
///
/// Partager et modifier **remplacent** cette fenêtre plutôt que de s'empiler
/// dessus : deux fenêtres l'une sur l'autre sur un téléphone ne laissent plus
/// voir ni l'une ni l'autre. Supprimer, lui, se règle sur place.
class _ClueActions extends ConsumerStatefulWidget {
  const _ClueActions({
    required this.sessionId,
    required this.clue,
    required this.members,
  });

  final String sessionId;
  final RemoteClue clue;
  final List<RemoteTableMember> members;

  @override
  ConsumerState<_ClueActions> createState() => _ClueActionsState();
}

class _ClueActionsState extends ConsumerState<_ClueActions> {
  bool _busy = false;
  bool _confirmingDelete = false;
  String? _error;

  /// En deux temps, comme partout ailleurs dans l'app : supprimer un indice
  /// efface aussi ce que des joueurs avaient déjà sous les yeux.
  Future<void> _delete() async {
    if (!_confirmingDelete) {
      setState(() => _confirmingDelete = true);
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    final navigator = Navigator.of(context);

    try {
      await ref
          .read(sessionApiProvider)
          .deleteClue(widget.sessionId, widget.clue.id);
      ref.invalidate(sessionCluesProvider(widget.sessionId));
      await navigator.maybePop();
    } on ApiException catch (error) {
      setState(() {
        _busy = false;
        _confirmingDelete = false;
        _error = error.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final clue = widget.clue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            QBButton(
              label: 'Partager',
              size: QBButtonSize.sm,
              onPressed: _busy
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      showClueSharingDialog(
                        context,
                        sessionId: widget.sessionId,
                        clue: clue,
                        members: widget.members,
                      );
                    },
            ),
            if (clue.isEditable) ...[
              const SizedBox(width: QBSpace.s2),
              QBButton(
                label: 'Modifier',
                size: QBButtonSize.sm,
                variant: QBButtonVariant.ghost,
                onPressed: _busy
                    ? null
                    : () {
                        Navigator.of(context).pop();
                        showClueDialog(
                          context,
                          sessionId: widget.sessionId,
                          existing: clue,
                        );
                      },
              ),
            ],
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: QBSpace.s3),
          Text(
            _error!,
            style: QBType.body().copyWith(
              fontSize: QBType.xs,
              color: QBColors.semanticDanger,
            ),
          ),
        ],
        const SizedBox(height: QBSpace.s2),
        Center(
          child: TextButton(
            onPressed: _busy ? null : _delete,
            child: Text(
              _confirmingDelete
                  ? 'Confirmer : personne ne le lira plus'
                  : 'Supprimer cet indice',
              style: QBType.body().copyWith(
                fontSize: QBType.xs,
                color: QBColors.semanticDanger,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

