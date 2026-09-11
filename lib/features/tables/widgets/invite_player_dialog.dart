import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/remote_providers.dart';
import '../../../data/remote/api_exception.dart';
import '../../../design_system/components/qb_button.dart';
import '../../../design_system/components/qb_dialog.dart';
import '../../../design_system/components/qb_input.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';
import '../providers/table_providers.dart';

Future<void> showInvitePlayerDialog(
  BuildContext context, {
  required String tableId,
}) {
  return showQBDialog(
    context: context,
    title: 'Inviter un joueur',
    builder: (_) => _InvitePlayerForm(tableId: tableId),
  );
}

class _InvitePlayerForm extends ConsumerStatefulWidget {
  const _InvitePlayerForm({required this.tableId});

  final String tableId;

  @override
  ConsumerState<_InvitePlayerForm> createState() => _InvitePlayerFormState();
}

class _InvitePlayerFormState extends ConsumerState<_InvitePlayerForm> {
  final _controller = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _controller.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Saisis l’adresse Google du joueur.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    final navigator = Navigator.of(context);

    try {
      await ref.read(tableApiProvider).invite(widget.tableId, email: email);
      refreshTables(ref, tableId: widget.tableId);
      await navigator.maybePop();
    } on ApiException catch (error) {
      setState(() {
        _busy = false;
        // Only registered players can be invited, and that refusal arrives as
        // a 404. Saying so plainly is more useful than the raw message.
        _error = error.isMissing
            ? 'Aucun joueur Questbook n’utilise cette adresse. '
                'Demande-lui de se connecter une première fois.'
            : error.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Le joueur doit déjà s’être connecté à Questbook avec ce compte '
          'Google. Il recevra un e-mail avec un lien pour rejoindre la table.',
          style: QBType.body().copyWith(
            fontSize: QBType.xs,
            color: QBColors.textMuted,
          ),
        ),
        const SizedBox(height: QBSpace.s3),
        QBInput(
          label: 'Adresse Google',
          controller: _controller,
          placeholder: 'joueur@gmail.com',
          keyboardType: TextInputType.emailAddress,
          error: _error,
        ),
        const SizedBox(height: QBSpace.s4),
        QBButton(
          label: _busy ? 'Envoi…' : 'Envoyer l’invitation',
          expand: true,
          onPressed: _busy ? null : _submit,
        ),
      ],
    );
  }
}
