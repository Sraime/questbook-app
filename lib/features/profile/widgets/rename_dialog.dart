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
import '../../tables/providers/table_providers.dart';

Future<void> showRenameDialog(
  BuildContext context, {
  required String currentName,
}) {
  return showQBDialog(
    context: context,
    title: 'Changer de pseudo',
    builder: (_) => _RenameForm(currentName: currentName),
  );
}

class _RenameForm extends ConsumerStatefulWidget {
  const _RenameForm({required this.currentName});

  final String currentName;

  @override
  ConsumerState<_RenameForm> createState() => _RenameFormState();
}

class _RenameFormState extends ConsumerState<_RenameForm> {
  late final _controller = TextEditingController(text: widget.currentName);
  bool _busy = false;
  String? _error;

  /// La même borne que celle du serveur, pour que le refus arrive avant
  /// l'aller-retour plutôt qu'après.
  static const _maxLength = 60;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _controller.text.trim();

    if (name.isEmpty) {
      setState(() => _error = 'Choisis un pseudo.');
      return;
    }
    if (name.length > _maxLength) {
      setState(() => _error = '$_maxLength caractères au maximum.');
      return;
    }
    if (name == widget.currentName) {
      await Navigator.of(context).maybePop();
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    final navigator = Navigator.of(context);

    try {
      await ref.read(authControllerProvider.notifier).rename(name);
      // Le pseudo voyage avec chaque table : celles déjà en cache portent
      // encore l'ancien, et les autres joueurs le liraient périmé.
      refreshTables(ref);
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
          'C’est sous ce nom que les autres joueurs te voient à leurs tables. '
          'Il ne suit plus le nom de ton compte.',
          style: QBType.body().copyWith(
            fontSize: QBType.xs,
            color: QBColors.textMuted,
          ),
        ),
        const SizedBox(height: QBSpace.s3),
        QBInput(
          label: 'Pseudo',
          controller: _controller,
          placeholder: 'Le Gardien',
          textInputAction: TextInputAction.done,
          error: _error,
        ),
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
