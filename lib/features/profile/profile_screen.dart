import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/remote_providers.dart';
import '../../design_system/components/qb_card.dart';
import '../../design_system/components/qb_page_background.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/spacing.dart';
import '../../design_system/tokens/typography.dart';

/// Where the account answers for itself: who is signed in, and whether this
/// device is actually in step with the server.
///
/// There is no button to force a pass. Synchronisation already runs on sign-in
/// and every time the app comes back to the foreground, so the button only
/// ever offered the illusion of control — and invited the reading that
/// anything not pressed had not been saved.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    final sync = ref.watch(syncControllerProvider);

    return QBPageBackground(
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 24, 18, 90),
          children: [
            Text(
              'Profil',
              style: QBType.game().copyWith(
                fontWeight: QBType.weightBold,
                fontSize: 22,
                color: QBColors.ink900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user == null
                  ? 'Aucun compte connecté.'
                  : 'Connecté avec ${user.email}.',
              style: QBType.body().copyWith(
                fontSize: QBType.sm,
                color: QBColors.textMuted,
              ),
            ),
            const SizedBox(height: QBSpace.s5),
            _SyncCard(sync: sync),
          ],
        ),
      ),
    );
  }
}

class _SyncCard extends ConsumerWidget {
  const _SyncCard({required this.sync});

  final SyncState sync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(connectivityProvider);
    final failed = sync.errorMessage != null;

    return QBCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                online ? LucideIcons.cloud : LucideIcons.cloudOff,
                size: 18,
                color: failed
                    ? QBColors.semanticDanger
                    : online
                        ? QBColors.moss600
                        : QBColors.textMuted,
              ),
              const SizedBox(width: QBSpace.s2),
              Text(
                'Synchronisation',
                style: QBType.game().copyWith(
                  fontWeight: QBType.weightSemibold,
                  fontSize: 15,
                  color: QBColors.ink900,
                ),
              ),
            ],
          ),
          const SizedBox(height: QBSpace.s3),
          Text(
            _status(online: online),
            style: QBType.body().copyWith(
              fontSize: QBType.sm,
              color: failed ? QBColors.semanticDanger : QBColors.textBody,
            ),
          ),
          const SizedBox(height: QBSpace.s2),
          Text(
            'Tes personnages remontent tout seuls à la connexion et à chaque '
            'retour dans l’application.',
            style: QBType.body().copyWith(
              fontSize: QBType.xs,
              color: QBColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  String _status({required bool online}) {
    if (sync.isRunning) return 'En cours…';
    if (sync.errorMessage case final message?) return message;
    if (!online) return 'En attente du réseau.';
    if (sync.lastSyncedAt case final at?) {
      final hour = at.hour.toString().padLeft(2, '0');
      final minute = at.minute.toString().padLeft(2, '0');
      return 'À jour, synchronisé à $hour:$minute.';
    }
    return 'Pas encore de passe de synchronisation.';
  }
}
