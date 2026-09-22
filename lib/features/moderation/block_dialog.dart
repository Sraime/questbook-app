import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/remote_providers.dart';
import '../../data/remote/api_exception.dart';
import '../../data/remote/block_api.dart';
import '../../design_system/components/qb_button.dart';
import '../../design_system/components/qb_dialog.dart';
import '../../design_system/components/qb_toast.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/spacing.dart';
import '../../design_system/tokens/typography.dart';
import '../tables/providers/table_providers.dart';

/// Demande confirmation, puis bloque. Rend ce que le serveur a défait, ou
/// `null` si rien n'a été bloqué — l'appelant s'en sert pour décider s'il
/// reste sur un écran dont il vient de sortir.
///
/// Le blocage n'est pas un signalement qu'on adoucit : il défait le présent,
/// et rien ne le défera. La fenêtre le dit avant, faute de quoi on
/// l'apprendrait en voyant une table disparaître.
Future<BlockOutcome?> showBlockDialog(
  BuildContext context, {
  required String userId,
  required String label,
}) {
  return showQBDialog<BlockOutcome>(
    context: context,
    title: 'Bloquer $label ?',
    width: 440,
    builder: (_) => _BlockForm(userId: userId, label: label),
  );
}

class _BlockForm extends ConsumerStatefulWidget {
  const _BlockForm({required this.userId, required this.label});

  final String userId;
  final String label;

  @override
  ConsumerState<_BlockForm> createState() => _BlockFormState();
}

class _BlockFormState extends ConsumerState<_BlockForm> {
  bool _busy = false;
  String? _error;

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });

    final navigator = Navigator.of(context);

    try {
      final outcome = await ref.read(blockApiProvider).block(widget.userId);
      // Toutes les tables, et pas seulement celle d'où part le geste : le
      // blocage a pu en défaire plusieurs, et l'app ne sait pas lesquelles.
      // Celle qu'on a sous les yeux en fait partie — sans cela, le joueur
      // qu'on vient de retirer resterait affiché dans sa liste.
      refreshTables(ref);
      ref.invalidate(tableDetailProvider);
      navigator.pop(outcome);
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${widget.label} ne pourra plus t’inviter, et les invitations en '
          'attente entre vous disparaissent.',
          style: QBType.body().copyWith(
            fontSize: QBType.sm,
            color: QBColors.textBody,
          ),
        ),
        const SizedBox(height: QBSpace.s3),
        Text(
          'Vos tables communes se défont : tu quittes celles où tu n’es que '
          'joueur, et ${widget.label} est retiré de celles que tu mènes.',
          style: QBType.body().copyWith(
            fontSize: QBType.sm,
            color: QBColors.textBody,
          ),
        ),
        const SizedBox(height: QBSpace.s3),
        // Le seul geste de l'app qu'on ne peut pas reprendre. Le dire en
        // gras, et une ligne à part, parce que c'est ce qu'on regrette de
        // n'avoir pas lu.
        Text(
          'C’est définitif : il n’y a pas de bouton pour débloquer.',
          style: QBType.body().copyWith(
            fontSize: QBType.sm,
            fontWeight: QBType.weightSemibold,
            color: QBColors.textBody,
          ),
        ),
        const SizedBox(height: QBSpace.s3),
        // Ce que les stores demandent de rendre possible, c'est de ne plus
        // croiser quelqu'un. Le sanctionner est un autre geste, et le dire
        // ici évite qu'on bloque en croyant avoir alerté quelqu'un.
        Text(
          'Bloquer ne prévient personne, et ne nous alerte pas. Si le '
          'contenu pose problème, signale-le aussi.',
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
          label: _busy ? 'Blocage…' : 'Bloquer',
          variant: QBButtonVariant.danger,
          expand: true,
          onPressed: _busy ? null : _submit,
        ),
      ],
    );
  }
}

/// Ce que le blocage a défait, en une phrase. Le serveur seul connaissait les
/// tables communes : les taire laisserait chercher pourquoi l'une d'elles a
/// disparu de l'écran d'accueil.
void showBlockOutcomeToast(
  BuildContext context,
  BlockOutcome outcome, {
  required String label,
}) {
  final undone = <String>[
    if (outcome.tablesLeft > 0)
      outcome.tablesLeft == 1
          ? 'tu as quitté votre table commune'
          : 'tu as quitté vos ${outcome.tablesLeft} tables communes',
    if (outcome.playersRemoved > 0)
      outcome.playersRemoved == 1
          ? 'il est sorti de la table que tu mènes'
          : 'il est sorti des ${outcome.playersRemoved} tables que tu mènes',
  ];

  showQBToast(
    context,
    undone.isEmpty
        ? '$label est bloqué.'
        : '$label est bloqué : ${undone.join(', et ')}.',
    tone: QBTone.success,
  );
}
