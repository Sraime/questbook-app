import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/remote_providers.dart';
import '../../../config/app_config.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';

/// Compact account and synchronisation strip for the top of the character
/// list: who is signed in, whether the last sync worked, and a way to sign in
/// or out.
class AccountBar extends ConsumerWidget {
  const AccountBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // A build without an OAuth client id can never sign in, so the strip would
    // only be a dead end.
    if (!AppConfig.isRemoteEnabled) return const SizedBox.shrink();

    final auth = ref.watch(authControllerProvider);
    final sync = ref.watch(syncControllerProvider);
    final user = auth.value;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: QBColors.surfaceSunken,
        borderRadius: BorderRadius.circular(QBRadius.md),
        border: Border.all(color: QBColors.borderHairline),
      ),
      child: Row(
        children: [
          Icon(
            user == null ? LucideIcons.cloudOff : LucideIcons.cloud,
            size: 18,
            color: user == null ? QBColors.textMuted : QBColors.moss600,
          ),
          const SizedBox(width: QBSpace.s2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user == null ? 'Hors ligne' : user.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: QBType.game().copyWith(
                    fontWeight: QBType.weightSemibold,
                    fontSize: 13,
                    color: QBColors.ink900,
                  ),
                ),
                Text(
                  _statusLabel(user == null, sync),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: QBType.body().copyWith(
                    fontSize: QBType.xs,
                    color: sync.errorMessage != null
                        ? QBColors.semanticDanger
                        : QBColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (user != null)
            IconButton(
              tooltip: 'Synchroniser',
              onPressed: sync.isRunning
                  ? null
                  : () => ref.read(syncControllerProvider.notifier).synchronize(),
              icon: sync.isRunning
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(LucideIcons.refreshCw, size: 18),
            ),
          IconButton(
            tooltip: user == null ? 'Se connecter' : 'Se déconnecter',
            onPressed: () => _toggleSession(ref, isSignedIn: user != null),
            icon: Icon(
              user == null ? LucideIcons.logIn : LucideIcons.logOut,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(bool signedOut, SyncState sync) {
    if (signedOut) return 'Personnages enregistrés sur cet appareil';
    if (sync.isRunning) return 'Synchronisation…';
    if (sync.errorMessage case final message?) return message;
    if (sync.lastSyncedAt case final at?) {
      final time =
          '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}';
      return 'Synchronisé à $time';
    }
    return 'Synchronisation en attente';
  }

  Future<void> _toggleSession(WidgetRef ref, {required bool isSignedIn}) async {
    final controller = ref.read(authControllerProvider.notifier);
    if (isSignedIn) {
      await controller.signOut();
    } else {
      await controller.signIn();
    }
  }
}
