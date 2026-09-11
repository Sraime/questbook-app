import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/remote_providers.dart';
import '../../data/remote/api_exception.dart';
import '../../data/remote/remote_table.dart';
import '../../design_system/components/qb_badge.dart';
import '../../design_system/components/qb_button.dart';
import '../../design_system/components/qb_card.dart';
import '../../design_system/components/qb_dialog.dart';
import '../../design_system/components/qb_icon_button.dart';
import '../../design_system/components/qb_input.dart';
import '../../design_system/components/qb_page_background.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/spacing.dart';
import '../../design_system/tokens/typography.dart';
import 'providers/table_providers.dart';
import 'table_formatting.dart';

/// Screen 1g — Mes tables. A table is shared between players, so unlike
/// characters it lives only on the server: this screen needs an account and a
/// working connection, and says so plainly when it has neither.
class TablesScreen extends ConsumerWidget {
  const TablesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(tablesOverviewProvider);

    return QBPageBackground(
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async => refreshTables(ref),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 24, 18, 90),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Mes tables',
                      style: QBType.game().copyWith(
                        fontWeight: QBType.weightBold,
                        fontSize: 22,
                        color: QBColors.ink900,
                      ),
                    ),
                  ),
                  if (ref.watch(isSignedInProvider)) const _NotificationsBell(),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Tes campagnes en cours, tous univers confondus.',
                style: QBType.body().copyWith(
                  fontSize: QBType.sm,
                  color: QBColors.textMuted,
                ),
              ),
              const SizedBox(height: QBSpace.s5),
              if (!ref.watch(isSignedInProvider))
                const _SignInRequired()
              else
                overview.when(
                  data: (data) => _TablesBody(overview: data),
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, stack) => _LoadFailure(
                    error: error,
                    onRetry: () => refreshTables(ref),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Opens the notification history, with the unread count sitting on the bell
/// the same way it sits on the navigation bar.
class _NotificationsBell extends ConsumerWidget {
  const _NotificationsBell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadNotificationCountProvider);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        QBIconButton(
          icon: const Icon(LucideIcons.bell, size: 18),
          label: 'Notifications',
          size: 38,
          onPressed: () => context.go('/tables/notifications'),
        ),
        if (unread > 0)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: QBColors.wax500,
                borderRadius: BorderRadius.circular(QBRadius.full),
                border: Border.all(color: QBColors.paper50, width: 1.5),
              ),
              child: Text(
                unread > 9 ? '9+' : '$unread',
                style: QBType.game().copyWith(
                  fontWeight: QBType.weightBold,
                  fontSize: 9,
                  height: 1,
                  color: QBColors.paper50,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _TablesBody extends ConsumerWidget {
  const _TablesBody({required this.overview});

  final TablesOverview overview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canWrite = ref.watch(canWriteProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (overview.cachedAt case final fetchedAt?) ...[
          _CachedNotice(fetchedAt: fetchedAt),
          const SizedBox(height: QBSpace.s3),
        ],
        for (final invitation in overview.invitations) ...[
          _InvitationCard(invitation: invitation),
          const SizedBox(height: QBSpace.s3),
        ],
        if (overview.tables.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Aucune table pour l’instant. Crée la tienne et invite tes '
              'joueurs par leur adresse Google.',
              style: QBType.body().copyWith(
                fontSize: QBType.base,
                color: QBColors.textMuted,
              ),
            ),
          )
        else
          for (final table in overview.tables) ...[
            _TableCard(table: table),
            const SizedBox(height: QBSpace.s3),
          ],
        if (canWrite)
          GestureDetector(
            onTap: () => _NewTableDialog.show(context, ref),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                border: Border.all(color: QBColors.borderStrong, width: 3),
                borderRadius: BorderRadius.circular(QBRadius.lg),
              ),
              alignment: Alignment.center,
              child: Text(
                '+ Nouvelle table',
                style: QBType.game().copyWith(
                  fontWeight: QBType.weightSemibold,
                  fontSize: 15,
                  color: QBColors.leather700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _TableCard extends StatelessWidget {
  const _TableCard({required this.table});

  final RemoteGameTable table;

  @override
  Widget build(BuildContext context) {
    final memberCount = table.members.length;

    return GestureDetector(
      onTap: () => context.go('/tables/${table.id}'),
      child: QBCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Badges sit under the title rather than beside it: a universe
            // label is free text, and next to one the title was squeezed hard
            // enough to break mid-word.
            Text(
              table.title,
              style: QBType.game().copyWith(
                fontWeight: QBType.weightSemibold,
                fontSize: 15,
                color: QBColors.ink900,
              ),
            ),
            if (table.universeLabel != null || table.isGameMaster) ...[
              const SizedBox(height: QBSpace.s2),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (table.universeLabel != null)
                    QBBadge(label: table.universeLabel!, tone: QBTone.info),
                  if (table.isGameMaster)
                    const QBBadge(label: 'MJ', tone: QBTone.warning),
                ],
              ),
            ],
            const SizedBox(height: QBSpace.s2),
            Text(
              table.nextSessionAt == null
                  ? 'Aucune session prévue'
                  : 'Prochaine session · ${formatSessionDate(table.nextSessionAt!)}',
              style: QBType.body().copyWith(
                fontSize: QBType.xs,
                color: QBColors.textMuted,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              memberCount > 1
                  ? '$memberCount joueurs'
                  : 'Toi seul pour l’instant',
              style: QBType.body().copyWith(
                fontSize: QBType.xs,
                color: QBColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InvitationCard extends ConsumerStatefulWidget {
  const _InvitationCard({required this.invitation});

  final RemoteTableInvitation invitation;

  @override
  ConsumerState<_InvitationCard> createState() => _InvitationCardState();
}

class _InvitationCardState extends ConsumerState<_InvitationCard> {
  bool _busy = false;

  Future<void> _respond({required bool accept}) async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final api = ref.read(tableApiProvider);

    try {
      if (accept) {
        await api.acceptInvitation(widget.invitation.id);
      } else {
        await api.declineInvitation(widget.invitation.id);
      }
      refreshTables(ref);
    } on ApiException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
      // The invitation may have been revoked in the meantime, so reload
      // either way rather than leaving a card that no longer applies.
      refreshTables(ref);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final invitation = widget.invitation;

    return QBCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const QBBadge(label: 'Invitation', tone: QBTone.success),
          const SizedBox(height: QBSpace.s2),
          Text(
            invitation.tableTitle,
            style: QBType.game().copyWith(
              fontWeight: QBType.weightSemibold,
              fontSize: 15,
              color: QBColors.ink900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Invité par ${invitation.invitedBy.label}',
            style: QBType.body().copyWith(
              fontSize: QBType.xs,
              color: QBColors.textMuted,
            ),
          ),
          if (ref.watch(canWriteProvider)) ...[
            const SizedBox(height: QBSpace.s3),
            Row(
              children: [
                Expanded(
                  child: QBButton(
                    label: 'Rejoindre',
                    size: QBButtonSize.sm,
                    expand: true,
                    onPressed: _busy ? null : () => _respond(accept: true),
                  ),
                ),
                const SizedBox(width: QBSpace.s2),
                Expanded(
                  child: QBButton(
                    label: 'Refuser',
                    variant: QBButtonVariant.ghost,
                    size: QBButtonSize.sm,
                    expand: true,
                    onPressed: _busy ? null : () => _respond(accept: false),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Tables are a shared object: without an account there is nobody to share
/// them with, and nothing to show.
class _SignInRequired extends StatelessWidget {
  const _SignInRequired();

  @override
  Widget build(BuildContext context) {
    return QBCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Connexion requise',
            style: QBType.game().copyWith(
              fontWeight: QBType.weightSemibold,
              fontSize: 15,
              color: QBColors.ink900,
            ),
          ),
          const SizedBox(height: QBSpace.s2),
          Text(
            'Les tables sont partagées avec tes joueurs : il faut un compte '
            'Google pour les rejoindre.',
            style: QBType.body().copyWith(
              fontSize: QBType.sm,
              color: QBColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Says how old the archive is. A table read from the cache looks exactly like
/// a fresh one, and a séance may well have moved since — the reader has to be
/// able to judge for themselves how much to trust it.
class _CachedNotice extends StatelessWidget {
  const _CachedNotice({required this.fetchedAt});

  final DateTime fetchedAt;

  @override
  Widget build(BuildContext context) {
    return Text(
      'Dernière mise à jour ${formatRelative(fetchedAt)}.',
      style: QBType.body().copyWith(
        fontSize: QBType.xs,
        color: QBColors.textMuted,
      ),
    );
  }
}

class _LoadFailure extends StatelessWidget {
  const _LoadFailure({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final message =
        error is ApiException ? (error as ApiException).message : '$error';

    return QBCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            style: QBType.body().copyWith(
              fontSize: QBType.sm,
              color: QBColors.textMuted,
            ),
          ),
          const SizedBox(height: QBSpace.s3),
          QBButton(
            label: 'Réessayer',
            variant: QBButtonVariant.secondary,
            size: QBButtonSize.sm,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

class _NewTableDialog {
  static Future<void> show(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final universeController = TextEditingController();

    return showQBDialog(
      context: context,
      title: 'Nouvelle table',
      builder: (dialogContext) => _NewTableForm(
        titleController: titleController,
        universeController: universeController,
      ),
    );
  }
}

class _NewTableForm extends ConsumerStatefulWidget {
  const _NewTableForm({
    required this.titleController,
    required this.universeController,
  });

  final TextEditingController titleController;
  final TextEditingController universeController;

  @override
  ConsumerState<_NewTableForm> createState() => _NewTableFormState();
}

class _NewTableFormState extends ConsumerState<_NewTableForm> {
  bool _busy = false;
  String? _error;

  Future<void> _submit() async {
    final title = widget.titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Donne un nom à ta table.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    final navigator = Navigator.of(context);
    final universe = widget.universeController.text.trim();

    try {
      await ref.read(tableApiProvider).create(
            title: title,
            universeLabel: universe.isEmpty ? null : universe,
          );
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
        QBInput(
          label: 'Nom de la table',
          controller: widget.titleController,
          error: _error,
        ),
        const SizedBox(height: QBSpace.s3),
        QBInput(
          label: 'Univers',
          controller: widget.universeController,
          placeholder: 'Cthulhu…',
        ),
        const SizedBox(height: QBSpace.s4),
        QBButton(
          label: _busy ? 'Création…' : 'Créer la table',
          variant: QBButtonVariant.primary,
          expand: true,
          onPressed: _busy ? null : _submit,
        ),
      ],
    );
  }
}
