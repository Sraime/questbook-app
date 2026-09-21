import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/remote_providers.dart';
import '../../../data/remote/api_exception.dart';
import '../../../data/remote/remote_table.dart';
import '../../../design_system/components/qb_button.dart';
import '../../../design_system/components/qb_toast.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';
import '../../tables/providers/table_providers.dart';
import '../../tables/widgets/session_form.dart';

/// Ce qu'est la session, plutôt que ce qui s'y passe : son titre, sa date, son
/// lieu, le scénario qu'on y joue — et le moyen de l'annuler.
///
/// C'est le volet qui a remplacé les boutons qui encombraient la carte de
/// session : le MJ y arrive d'un doigt sur la carte, et corrige l'heure sans
/// sortir du mode MJ.
class DetailsPanel extends ConsumerWidget {
  const DetailsPanel({
    super.key,
    required this.tableId,
    required this.session,
    required this.onCancelled,
  });

  final String tableId;
  final RemoteGameSession session;

  /// Une session annulée ne s'anime plus : le mode MJ se referme derrière.
  final VoidCallback onCancelled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        QBSpace.s6,
        QBSpace.s5,
        QBSpace.s6,
        QBSpace.s8 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      children: [
        Text(
          'Détails',
          style: QBType.game().copyWith(
            fontWeight: QBType.weightBold,
            fontSize: 16,
            letterSpacing: 16 * QBType.trackingWide,
            color: QBColors.ink900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Déplacer la date ou le lieu prévient les joueurs.',
          style: QBType.body().copyWith(
            fontSize: QBType.xs,
            color: QBColors.textMuted,
          ),
        ),
        const SizedBox(height: QBSpace.s4),
        SessionForm(
          // Recréé quand la session change d'identité : les champs sont
          // remplis une fois pour toutes à la construction.
          key: ValueKey(session.id),
          tableId: tableId,
          existing: session,
          onSaved: () => showQBToast(context, 'Session enregistrée'),
        ),
        const SizedBox(height: QBSpace.s6),
        _CancelSession(
          tableId: tableId,
          session: session,
          onCancelled: onCancelled,
        ),
      ],
    );
  }
}

class _CancelSession extends ConsumerWidget {
  const _CancelSession({
    required this.tableId,
    required this.session,
    required this.onCancelled,
  });

  final String tableId;
  final RemoteGameSession session;
  final VoidCallback onCancelled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (session.isCancelled) {
      return Text(
        'Cette session est annulée.',
        style: QBType.body().copyWith(
          fontSize: QBType.sm,
          color: QBColors.textMuted,
        ),
      );
    }

    return QBButton(
      label: 'Annuler la session',
      variant: QBButtonVariant.danger,
      expand: true,
      onPressed: () => _confirm(context, ref),
    );
  }

  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Annuler la session ?'),
        content: const Text('Les joueurs en seront informés.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Non'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Annuler la session'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(sessionApiProvider).cancel(session.id);
      refreshTables(ref, tableId: tableId);
      onCancelled();
    } on ApiException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    }
  }
}
