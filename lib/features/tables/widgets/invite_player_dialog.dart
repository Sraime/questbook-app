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
        Text(
          'S’il n’a pas encore Questbook, il recevra un e-mail pour installer '
          'l’app et rejoindre la table avec cette adresse Google.',
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
