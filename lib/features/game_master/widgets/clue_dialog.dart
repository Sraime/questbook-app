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

/// Le formulaire d'un indice : celui qu'on remplit pour en ajouter un est
/// celui qu'on rouvre pour le corriger.
///
/// Il ne sait qu'enregistrer. Les gestes qui portent sur l'indice lui-même —
/// le partager, le supprimer — se prennent depuis sa lecture : ouvrir une
/// correction pour ne rien corriger n'avait pas de sens.
Future<void> showClueDialog(
  BuildContext context, {
  required String sessionId,
  RemoteClue? existing,
}) {
  return showQBDialog(
    context: context,
    title: existing == null ? 'Nouvel indice' : 'Modifier',
    // Même largeur que la fenêtre d'un PNJ, et pour la même raison : ce qu'on
    // écrit ici est de la prose, et une colonne de deux mots empêche de la
    // relire.
    width: 560,
    builder: (_) => _ClueForm(sessionId: sessionId, existing: existing),
  );
}

class _ClueForm extends ConsumerStatefulWidget {
  const _ClueForm({required this.sessionId, this.existing});

  final String sessionId;
  final RemoteClue? existing;

  @override
  ConsumerState<_ClueForm> createState() => _ClueFormState();
}

class _ClueFormState extends ConsumerState<_ClueForm> {
  late final _title = TextEditingController(text: widget.existing?.title ?? '');
  late final _content =
      TextEditingController(text: widget.existing?.contentMarkdown ?? '');

  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Donne-lui un titre.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    final api = ref.read(sessionApiProvider);
    final content = _content.text.trim();
    final existing = widget.existing;
    final navigator = Navigator.of(context);

    try {
      if (existing == null) {
        await api.createClue(
          widget.sessionId,
          title: title,
          contentMarkdown: content,
        );
      } else {
        // Seul ce qui a bougé part au serveur — et quand rien n'a bougé, il
        // ne reste rien à envoyer. Un patch vide n'est pas une requête que le
        // serveur peut honorer, et il a raison de la refuser : c'est ici
        // qu'on doit voir que le geste était vide, pas là-bas.
        final newTitle = title == existing.title ? null : title;
        final newContent =
            content == existing.contentMarkdown ? null : content;

        if (newTitle != null || newContent != null) {
          await api.updateClue(
            widget.sessionId,
            existing.id,
            title: newTitle,
            contentMarkdown: newContent,
          );
        }
      }

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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        QBInput(
          label: 'Titre',
          controller: _title,
          placeholder: 'La lettre de Corbitt',
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: QBSpace.s3),
        QBInput(
          label: 'Contenu',
          controller: _content,
          placeholder: 'Ce que tes joueurs vont lire…',
          maxLines: 8,
        ),
        const SizedBox(height: QBSpace.s2),
        Text(
          'Le markdown est interprété : ## pour un titre, ** pour du gras, '
          '> pour une citation.',
          style: QBType.body().copyWith(
            fontSize: QBType.xs,
            color: QBColors.textMuted,
          ),
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
