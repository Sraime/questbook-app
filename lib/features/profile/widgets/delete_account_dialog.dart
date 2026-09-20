import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/remote_providers.dart';
import '../../../data/remote/api_exception.dart';
import '../../../design_system/components/qb_button.dart';
import '../../../design_system/components/qb_dialog.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';
import '../../tables/providers/table_providers.dart';

Future<void> showDeleteAccountDialog(BuildContext context) {
  return showQBDialog(
    context: context,
    title: 'Supprimer le compte',
    builder: (_) => const _DeleteAccountForm(),
  );
}

class _DeleteAccountForm extends ConsumerStatefulWidget {
  const _DeleteAccountForm();

  @override
  ConsumerState<_DeleteAccountForm> createState() => _DeleteAccountFormState();
}

class _DeleteAccountFormState extends ConsumerState<_DeleteAccountForm> {
  bool _busy = false;
  String? _error;

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });

    final navigator = Navigator.of(context);

    try {
      await ref.read(authControllerProvider.notifier).deleteAccount();
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
    // Le nombre de tables animées rend l'avertissement concret : « tes tables
    // disparaissent » ne dit rien tant qu'on ne sait pas lesquelles.
    //
    // Tant qu'on l'ignore, le bouton reste inerte. Le mot « définitivement »
    // ne suffit pas si ce qu'on efface n'est pas encore écrit à l'écran, et
    // rien n'empêchait un doigt rapide de confirmer avant que la liste
    // n'arrive.
    final overview = ref.watch(tablesOverviewProvider);
    final counting = overview.isLoading && !overview.hasValue;
    final mastered = overview.value?.tables
            .where((table) => table.isGameMaster)
            .length ??
        0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Tes personnages, tes scénarios et tes achats seront effacés. '
          'C’est définitif : rien ne se restaure ensuite.',
          style: QBType.body().copyWith(
            fontSize: QBType.sm,
            color: QBColors.textBody,
          ),
        ),
        if (counting) ...[
          const SizedBox(height: QBSpace.s3),
          Text(
            'Vérification de tes tables…',
            style: QBType.body().copyWith(
              fontSize: QBType.sm,
              color: QBColors.textMuted,
            ),
          ),
        ] else if (mastered > 0) ...[
          const SizedBox(height: QBSpace.s3),
          Text(
            mastered == 1
                ? 'La table que tu animes sera dissoute, et disparaîtra aussi '
                    'pour ses joueurs.'
                : 'Les $mastered tables que tu animes seront dissoutes, et '
                    'disparaîtront aussi pour leurs joueurs.',
            style: QBType.body().copyWith(
              fontSize: QBType.sm,
              fontWeight: QBType.weightSemibold,
              color: QBColors.semanticDanger,
            ),
          ),
        ],
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
          label: _busy ? 'Suppression…' : 'Supprimer définitivement',
          variant: QBButtonVariant.danger,
          expand: true,
          onPressed: _busy || counting ? null : _submit,
        ),
        const SizedBox(height: QBSpace.s2),
        QBButton(
          label: 'Annuler',
          variant: QBButtonVariant.ghost,
          expand: true,
          onPressed: _busy ? null : () => Navigator.of(context).maybePop(),
        ),
      ],
    );
  }
}
