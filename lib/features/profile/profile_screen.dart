import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/remote_providers.dart';
import '../../config/legal_links.dart';
import '../../data/remote/auth_tokens.dart';
import '../../design_system/components/qb_button.dart';
import '../../design_system/components/qb_card.dart';
import '../../design_system/components/qb_icon_button.dart';
import '../../design_system/components/qb_page_background.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/spacing.dart';
import '../../design_system/tokens/typography.dart';
import 'widgets/delete_account_dialog.dart';
import 'widgets/rename_dialog.dart';

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
            if (user case final account?) ...[
              const SizedBox(height: QBSpace.s5),
              _AccountCard(user: account),
            ],
            const SizedBox(height: QBSpace.s5),
            _SyncCard(sync: sync),
            if (user != null) ...[
              const SizedBox(height: QBSpace.s5),
              const _LegalCard(),
              const SizedBox(height: QBSpace.s5),
              const _DeleteAccountCard(),
            ],
          ],
        ),
      ),
    );
  }
}

/// Le compte tel que les autres le voient. Le pseudo est la seule chose qui
/// s'y modifie : l'adresse et la photo appartiennent à Google.
class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    return QBCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Pseudo',
                  style: QBType.body().copyWith(
                    fontSize: QBType.xs,
                    color: QBColors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: QBType.game().copyWith(
                    fontWeight: QBType.weightSemibold,
                    fontSize: 15,
                    color: QBColors.ink900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: QBSpace.s3),
          QBIconButton(
            icon: const Icon(LucideIcons.pencil, size: 16),
            label: 'Changer de pseudo',
            size: 36,
            onPressed: () => showRenameDialog(context, currentName: user.label),
          ),
        ],
      ),
    );
  }
}

/// Les deux textes qu'on a acceptés, à relire quand on veut.
///
/// Ils s'ouvrent dans le navigateur plutôt que dans l'app : ils vivent sur le
/// serveur, et une copie embarquée vieillirait au rythme des livraisons sur
/// les stores. Les stores les veulent joignables depuis le profil, mais ce
/// n'est pas la raison principale — un texte qu'on accepte doit pouvoir se
/// relire après coup.
class _LegalCard extends StatefulWidget {
  const _LegalCard();

  @override
  State<_LegalCard> createState() => _LegalCardState();
}

class _LegalCardState extends State<_LegalCard> {
  String? _error;

  Future<void> _open(Uri page) async {
    if (await LegalLinks.open(page)) return;
    if (!mounted) return;
    setState(() => _error = 'Ouvre cette page dans ton navigateur : $page');
  }

  @override
  Widget build(BuildContext context) {
    return QBCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Ce que tu as accepté',
            style: QBType.game().copyWith(
              fontWeight: QBType.weightSemibold,
              fontSize: 15,
              color: QBColors.ink900,
            ),
          ),
          const SizedBox(height: QBSpace.s3),
          _LegalRow(
            label: 'Conditions d’utilisation',
            onPressed: () => _open(LegalLinks.terms),
            rule: true,
          ),
          _LegalRow(
            label: 'Politique de confidentialité',
            onPressed: () => _open(LegalLinks.privacy),
            rule: false,
          ),
          if (_error case final message?) ...[
            const SizedBox(height: QBSpace.s2),
            Text(
              message,
              style: QBType.body().copyWith(
                fontSize: QBType.xs,
                color: QBColors.semanticDanger,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LegalRow extends StatelessWidget {
  const _LegalRow({
    required this.label,
    required this.onPressed,
    required this.rule,
  });

  final String label;
  final VoidCallback onPressed;
  final bool rule;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: QBSpace.s3),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: rule ? QBColors.borderHairline : Colors.transparent,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: QBType.body().copyWith(
                  fontSize: QBType.sm,
                  color: QBColors.textBody,
                ),
              ),
            ),
            const Icon(
              LucideIcons.externalLink,
              size: 15,
              color: QBColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

/// En bas de l'écran, et pas ailleurs : c'est un geste qu'on vient chercher,
/// jamais un qu'on croise.
class _DeleteAccountCard extends StatelessWidget {
  const _DeleteAccountCard();

  @override
  Widget build(BuildContext context) {
    return QBCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Quitter Questbook',
            style: QBType.game().copyWith(
              fontWeight: QBType.weightSemibold,
              fontSize: 15,
              color: QBColors.ink900,
            ),
          ),
          const SizedBox(height: QBSpace.s2),
          Text(
            'Supprimer ton compte efface tes investigateurs, tes scénarios et '
            'tes achats, ici comme sur le serveur.',
            style: QBType.body().copyWith(
              fontSize: QBType.xs,
              color: QBColors.textMuted,
            ),
          ),
          const SizedBox(height: QBSpace.s3),
          QBButton(
            label: 'Supprimer mon compte',
            variant: QBButtonVariant.danger,
            expand: true,
            onPressed: () => showDeleteAccountDialog(context),
          ),
        ],
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
            'Tes investigateurs remontent tout seuls à la connexion et à chaque '
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
