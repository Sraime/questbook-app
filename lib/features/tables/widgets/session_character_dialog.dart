import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/remote_providers.dart';
import '../../../data/remote/api_exception.dart';
import '../../../design_system/components/qb_button.dart';
import '../../../design_system/components/qb_dialog.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';
import '../../home/providers/character_list_provider.dart';
import '../providers/table_providers.dart';

/// Lets a player say who they are playing for one session, change their mind,
/// or take the character back off.
Future<void> showSessionCharacterDialog(
  BuildContext context, {
  required String tableId,
  required String sessionId,
  required String? currentCharacterId,
}) {
  return showQBDialog(
    context: context,
    title: 'Ton personnage',
    builder: (_) => _CharacterPicker(
      tableId: tableId,
      sessionId: sessionId,
      currentCharacterId: currentCharacterId,
    ),
  );
}

class _CharacterPicker extends ConsumerStatefulWidget {
  const _CharacterPicker({
    required this.tableId,
    required this.sessionId,
    required this.currentCharacterId,
  });

  final String tableId;
  final String sessionId;
  final String? currentCharacterId;

  @override
  ConsumerState<_CharacterPicker> createState() => _CharacterPickerState();
}

class _CharacterPickerState extends ConsumerState<_CharacterPicker> {
  bool _busy = false;
  String? _error;

  Future<void> _choose(String? characterId) async {
    setState(() {
      _busy = true;
      _error = null;
    });

    final navigator = Navigator.of(context);

    try {
      await ref
          .read(sessionApiProvider)
          .setAttendanceCharacter(widget.sessionId, characterId);
      refreshTables(ref, tableId: widget.tableId);
      await navigator.maybePop();
    } on ApiException catch (error) {
      setState(() {
        _busy = false;
        // Characters live on the device first and only reach the server on the
        // next synchronisation, so one that has never been uploaded comes back
        // as a 404 here.
        _error = error.isMissing
            ? 'Ce personnage n’est pas encore sur le serveur. '
                'Synchronise tes personnages puis réessaie.'
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
          'Le maître du jeu saura avec qui tu viens. Tu peux en changer '
          'jusqu’à la session.',
          style: QBType.body().copyWith(
            fontSize: QBType.xs,
            color: QBColors.textMuted,
          ),
        ),
        const SizedBox(height: QBSpace.s3),
        ...switch (characters) {
          AsyncData(value: final list) when list.isEmpty => [
              Text(
                'Tu n’as pas encore de personnage. Crée-en un depuis l’onglet '
                'Perso, puis reviens ici.',
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
                'Impossible de lire tes personnages.',
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
        if (widget.currentCharacterId != null) ...[
          const SizedBox(height: QBSpace.s4),
          QBButton(
            label: 'Venir sans personnage',
            variant: QBButtonVariant.ghost,
            size: QBButtonSize.sm,
            expand: true,
            onPressed: _busy ? null : () => _choose(null),
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
