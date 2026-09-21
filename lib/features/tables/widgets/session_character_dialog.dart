import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/remote_providers.dart';
import '../../../data/remote/api_exception.dart';
import '../../../data/remote/remote_table.dart';
import '../../../design_system/components/qb_button.dart';
import '../../../design_system/components/qb_dialog.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';
import '../../home/providers/character_list_provider.dart';
import '../providers/table_providers.dart';

/// Le choix de l'investigateur avec lequel on vient à une séance.
///
/// Deux moments pour un même geste, distingués par [confirming] :
///
/// - **En confirmant sa venue.** Répondre « Je viens » ouvre ce choix, et
///   c'est le choix qui répond. Rien n'est envoyé tant qu'un investigateur
///   n'est pas désigné : une chaise sans fiche ne sert ni le MJ, qui ne sait
///   pas qui il a en face, ni le joueur, qui ne pourrait pas participer à la
///   séance. Fermer la fenêtre revient à ne pas avoir répondu.
/// - **En cours de route**, pour en changer. La réponse, elle, ne bouge pas.
Future<void> showSessionCharacterDialog(
  BuildContext context, {
  required String tableId,
  required String sessionId,
  required String? currentCharacterId,
  bool confirming = false,
}) {
  return showQBDialog(
    context: context,
    title: confirming ? 'Avec qui viens-tu ?' : 'Ton investigateur',
    builder: (_) => _CharacterPicker(
      tableId: tableId,
      sessionId: sessionId,
      currentCharacterId: currentCharacterId,
      confirming: confirming,
    ),
  );
}

class _CharacterPicker extends ConsumerStatefulWidget {
  const _CharacterPicker({
    required this.tableId,
    required this.sessionId,
    required this.currentCharacterId,
    required this.confirming,
  });

  final String tableId;
  final String sessionId;
  final String? currentCharacterId;
  final bool confirming;

  @override
  ConsumerState<_CharacterPicker> createState() => _CharacterPickerState();
}

class _CharacterPickerState extends ConsumerState<_CharacterPicker> {
  bool _busy = false;
  String? _error;

  Future<void> _choose(String characterId) async {
    setState(() {
      _busy = true;
      _error = null;
    });

    final navigator = Navigator.of(context);
    final api = ref.read(sessionApiProvider);

    try {
      // Un seul appel quand on confirme : venir et dire avec qui sont une même
      // décision, et deux requêtes laisseraient une réponse sans fiche si la
      // seconde échouait.
      await (widget.confirming
          ? api.setAttendance(
              widget.sessionId,
              AttendanceStatus.yes,
              characterId: characterId,
            )
          : api.setAttendanceCharacter(widget.sessionId, characterId));
      refreshTables(ref, tableId: widget.tableId);
      await navigator.maybePop();
    } on ApiException catch (error) {
      setState(() {
        _busy = false;
        // Characters live on the device first and only reach the server on the
        // next synchronisation, so one that has never been uploaded comes back
        // as a 404 here.
        _error = error.isMissing
            ? 'Cet investigateur n’est pas encore sur le serveur. '
                'Synchronise tes investigateurs puis réessaie.'
            : error.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final characters = ref.watch(characterListProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.confirming
              ? 'Choisis-en un et ta place est prise. Tu pourras en changer '
                  'jusqu’à la fin de la séance.'
              : 'Le maître du jeu saura avec qui tu viens.',
          style: QBType.body().copyWith(
            fontSize: QBType.xs,
            color: QBColors.textMuted,
          ),
        ),
        const SizedBox(height: QBSpace.s3),
        ...switch (characters) {
          AsyncData(value: final list) when list.isEmpty => [
              Text(
                'Tu n’as pas encore d’investigateur. Crée-en un depuis '
                'l’onglet Investigateurs, puis reviens ici.',
                style: QBType.body().copyWith(
                  fontSize: QBType.sm,
                  color: QBColors.textBody,
                ),
              ),
            ],
          AsyncData(value: final list) => [
              for (final character in list)
                _CharacterOption(
                  name: character.name,
                  occupation: character.occupation,
                  selected: character.id == widget.currentCharacterId,
                  onTap: _busy ? null : () => _choose(character.id),
                ),
            ],
          AsyncError() => [
              Text(
                'Impossible de lire tes investigateurs.',
                style: QBType.body().copyWith(
                  fontSize: QBType.sm,
                  color: QBColors.textBody,
                ),
              ),
            ],
          _ => [const Center(child: CircularProgressIndicator())],
        },
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
      ],
    );
  }
}

class _CharacterOption extends StatelessWidget {
  const _CharacterOption({
    required this.name,
    required this.occupation,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final String? occupation;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: QBSpace.s2),
      child: QBButton(
        label: occupation == null || occupation!.isEmpty
            ? name
            : '$name · $occupation',
        variant: selected ? QBButtonVariant.primary : QBButtonVariant.secondary,
        size: QBButtonSize.sm,
        expand: true,
        onPressed: onTap,
      ),
    );
  }
}
