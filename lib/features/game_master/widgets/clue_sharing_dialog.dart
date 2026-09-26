import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/remote_providers.dart';
import '../../../data/remote/api_exception.dart';
import '../../../data/remote/remote_table.dart';
import '../../../design_system/components/qb_button.dart';
import '../../../design_system/components/qb_dialog.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';
import '../providers/game_master_providers.dart';

/// À qui cet indice est ouvert.
///
/// Le MJ coche des noms et valide : l'écran montre l'état d'arrivée, pas une
/// suite d'ajouts. C'est pour cela que décocher quelqu'un lui reprend l'indice
/// sans qu'il faille un second geste nommé autrement.
Future<void> showClueSharingDialog(
  BuildContext context, {
  required String sessionId,
  required RemoteClue clue,
  required List<RemoteTableMember> members,
}) {
  return showQBDialog(
    context: context,
    title: 'Partager',
    builder: (_) => _SharingForm(
      sessionId: sessionId,
      clue: clue,
      members: members,
    ),
  );
}

class _SharingForm extends ConsumerStatefulWidget {
  const _SharingForm({
    required this.sessionId,
    required this.clue,
    required this.members,
  });

  final String sessionId;
  final RemoteClue clue;
  final List<RemoteTableMember> members;

  @override
  ConsumerState<_SharingForm> createState() => _SharingFormState();
}

class _SharingFormState extends ConsumerState<_SharingForm> {
  /// Les joueurs de la table, le MJ exclu : il ne se transmet rien à
  /// lui-même, et sa case n'aurait aucun sens.
  late final List<RemoteTableMember> _players = widget.members
      .where((member) => !member.role.isGameMaster)
      .toList(growable: false);

  /// Restreint à ce que la fenêtre montre.
  ///
  /// Sans ce filtre, un destinataire qui n'est plus joueur — le MJ d'une
  /// table dont les rôles ont changé, par exemple — repart dans la liste
  /// envoyée sans qu'aucune case ne le dise : le MJ voit un seul nom coché,
  /// valide, et l'indice reste ouvert à deux personnes.
  late final Set<String> _chosen = widget.clue.sharedWith
      .where((id) => _players.any((player) => player.userId == id))
      .toSet();

  bool _busy = false;
  String? _error;

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });

    final navigator = Navigator.of(context);

    try {
      await ref.read(sessionApiProvider).shareClue(
            widget.sessionId,
            widget.clue.id,
            userIds: _chosen.toList(growable: false),
          );
      ref.invalidate(sessionCluesProvider(widget.sessionId));
      await navigator.maybePop();
    } on ApiException catch (error) {
      setState(() {
        _busy = false;
        _error = error.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final players = _players;

    if (players.isEmpty) {
      return Text(
        'Personne d’autre à cette table pour l’instant. Invite tes joueurs '
        'depuis l’écran de la table.',
        style: QBType.body().copyWith(
          fontSize: QBType.sm,
          color: QBColors.textMuted,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '« ${widget.clue.title} » — coche qui peut le lire.',
          style: QBType.body().copyWith(
            fontSize: QBType.xs,
            color: QBColors.textMuted,
          ),
        ),
        const SizedBox(height: QBSpace.s3),
        for (final player in players)
          _PlayerRow(
            name: player.user.displayName ?? 'Joueur',
            checked: _chosen.contains(player.userId),
            onChanged: _busy
                ? null
                : (value) => setState(() {
                      if (value) {
                        _chosen.add(player.userId);
                      } else {
                        _chosen.remove(player.userId);
                      }
                    }),
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
        const SizedBox(height: QBSpace.s4),
        QBButton(
          // Le libellé dit l'état d'arrivée, parce que décocher est un geste
          // aussi courant que cocher : « Partager » mentirait à qui vient de
          // tout décocher.
          label: _busy
              ? 'Enregistrement…'
              : _chosen.isEmpty
                  ? 'Ne le montrer à personne'
                  : 'Valider',
          expand: true,
          onPressed: _busy ? null : _submit,
        ),
      ],
    );
  }
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({
    required this.name,
    required this.checked,
    required this.onChanged,
  });

  final String name;
  final bool checked;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: checked,
      label: name,
      child: InkWell(
        onTap: onChanged == null ? null : () => onChanged!(!checked),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: QBSpace.s2),
          child: Row(
            children: [
              Icon(
                checked ? LucideIcons.squareCheck : LucideIcons.square,
                size: 20,
                color: checked ? QBColors.gold700 : QBColors.textMuted,
              ),
              const SizedBox(width: QBSpace.s3),
              Expanded(
                child: Text(
                  name,
                  style: QBType.body().copyWith(
                    fontSize: QBType.sm,
                    color: QBColors.ink900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
