import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/remote_providers.dart';
import '../../../data/remote/api_exception.dart';
import '../../../data/remote/remote_table.dart';
import '../../../design_system/components/qb_button.dart';
import '../../../design_system/components/qb_dialog.dart';
import '../../../design_system/components/qb_input.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';
import '../providers/game_master_providers.dart';

/// Le formulaire d'un personnage non-joueur : celui qu'on remplit pour en
/// noter un est celui qu'on rouvre pour le corriger.
Future<void> showNpcDialog(
  BuildContext context, {
  required String sessionId,
  RemoteNpc? existing,
}) {
  return showQBDialog(
    context: context,
    // « Nouveau personnage » ne veut plus rien dire maintenant que celui du
    // joueur est un investigateur : la fenêtre dit ce qu'elle crée.
    title: existing == null ? 'Nouveau PNJ' : 'Modifier',
    // Plus large que les autres fenêtres : la description est de la prose, et
    // l'écrire dans une colonne de deux mots empêche de la relire. `QBDialog`
    // ramène cette largeur à celle de l'écran quand il est plus étroit.
    width: 560,
    builder: (_) => _NpcForm(sessionId: sessionId, existing: existing),
  );
}

class _NpcForm extends ConsumerStatefulWidget {
  const _NpcForm({required this.sessionId, this.existing});

  final String sessionId;
  final RemoteNpc? existing;

  @override
  ConsumerState<_NpcForm> createState() => _NpcFormState();
}

class _NpcFormState extends ConsumerState<_NpcForm> {
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _description =
      TextEditingController(text: widget.existing?.description ?? '');

  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Donne-lui un nom.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    final api = ref.read(sessionApiProvider);
    final description = _description.text.trim();
    final existing = widget.existing;
    final navigator = Navigator.of(context);

    try {
      if (existing == null) {
        await api.createNpc(
          widget.sessionId,
          name: name,
          description: description,
        );
      } else {
        await api.updateNpc(
          widget.sessionId,
          existing.id,
          name: name == existing.name ? null : name,
          description:
              description == existing.description ? null : description,
        );
      }

      ref.invalidate(sessionNpcsProvider(widget.sessionId));
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        QBInput(
          label: 'Nom',
          controller: _name,
          placeholder: 'Le rôdeur du seuil',
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: QBSpace.s3),
        QBInput(
          label: 'Description',
          controller: _description,
          placeholder: 'Ce qu’il veut, ce qu’il sait…',
          maxLines: 5,
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
          label: _busy ? 'Enregistrement…' : 'Enregistrer',
          expand: true,
          onPressed: _busy ? null : _submit,
        ),
      ],
    );
  }
}
