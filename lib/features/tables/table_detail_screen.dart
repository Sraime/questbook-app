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
import '../../design_system/components/qb_icon_button.dart';
import '../../design_system/components/qb_page_background.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/spacing.dart';
import '../../design_system/tokens/typography.dart';
import 'providers/table_providers.dart';
import 'table_formatting.dart';
import 'widgets/invite_player_dialog.dart';
import 'widgets/session_form_dialog.dart';

/// Everything about one table: who is at it, who has been invited, and what is
/// planned. Game-master controls appear only when the server says the viewer
/// is one, so a player never sees a button that would come back a 403.
class TableDetailScreen extends ConsumerWidget {
  const TableDetailScreen({super.key, required this.tableId});

  final String tableId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(tableDetailProvider(tableId));

    return QBPageBackground(
      child: SafeArea(
        bottom: false,
        child: detail.when(
          data: (data) => _Body(detail: data),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _Failure(
            error: error,
            onRetry: () => ref.invalidate(tableDetailProvider(tableId)),
          ),
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.detail});

  final TableDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final table = detail.table;

    return RefreshIndicator(
      onRefresh: () async => refreshTables(ref, tableId: table.id),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 90),
        children: [
          Row(
            children: [
              QBIconButton(
                icon: const Icon(LucideIcons.arrowLeft, size: 18),
                label: 'Retour',
                size: 36,
                onPressed: () => context.go('/tables'),
              ),
              const SizedBox(width: QBSpace.s2),
              Expanded(
                child: Text(
                  table.title,
                  style: QBType.game().copyWith(
                    fontWeight: QBType.weightBold,
                    fontSize: 20,
                    color: QBColors.ink900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: QBSpace.s2),
          Row(
            children: [
              if (table.universeLabel != null)
                QBBadge(label: table.universeLabel!, tone: QBTone.info),
              if (table.universeLabel != null) const SizedBox(width: 6),
              QBBadge(
                label: table.isGameMaster ? 'Tu es MJ' : 'Joueur',
                tone: table.isGameMaster ? QBTone.warning : QBTone.neutral,
              ),
            ],
          ),
          const SizedBox(height: QBSpace.s5),
          _SectionTitle(
            title: 'Sessions',
            action: table.isGameMaster
                ? _SectionAction(
                    label: '+ Proposer',
                    onTap: () => showSessionFormDialog(
                      context,
                      tableId: table.id,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: QBSpace.s3),
          if (detail.upcoming.isEmpty)
            _MutedText(
              table.isGameMaster
                  ? 'Aucune session prévue. Propose une date à tes joueurs.'
                  : 'Aucune session prévue pour l’instant.',
            )
          else
            for (final session in detail.upcoming) ...[
              _SessionCard(session: session, table: table),
              const SizedBox(height: QBSpace.s3),
            ],
          if (detail.past.isNotEmpty) ...[
            const SizedBox(height: QBSpace.s3),
            _SectionTitle(title: 'Sessions passées'),
            const SizedBox(height: QBSpace.s3),
            for (final session in detail.past.take(5)) ...[
              _PastSessionRow(session: session),
              const SizedBox(height: QBSpace.s2),
            ],
          ],
          const SizedBox(height: QBSpace.s6),
          _SectionTitle(
            title: 'Joueurs',
            action: table.isGameMaster
                ? _SectionAction(
                    label: '+ Inviter',
                    onTap: () =>
                        showInvitePlayerDialog(context, tableId: table.id),
                  )
                : null,
          ),
          const SizedBox(height: QBSpace.s3),
          for (final member in table.members) ...[
            _MemberRow(member: member, table: table),
            const SizedBox(height: QBSpace.s2),
          ],
          if (table.pendingInvitations.isNotEmpty) ...[
            const SizedBox(height: QBSpace.s4),
            _SectionTitle(title: 'Invitations en attente'),
            const SizedBox(height: QBSpace.s3),
            for (final invitation in table.pendingInvitations) ...[
              _PendingInvitationRow(invitation: invitation, tableId: table.id),
              const SizedBox(height: QBSpace.s2),
            ],
          ],
          const SizedBox(height: QBSpace.s6),
          _DangerZone(table: table),
        ],
      ),
    );
  }
}

class _SessionCard extends ConsumerStatefulWidget {
  const _SessionCard({required this.session, required this.table});

  final RemoteGameSession session;
  final RemoteGameTable table;

  @override
  ConsumerState<_SessionCard> createState() => _SessionCardState();
}

class _SessionCardState extends ConsumerState<_SessionCard> {
  bool _busy = false;

  Future<void> _answer(AttendanceStatus status) async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await ref
          .read(sessionApiProvider)
          .setAttendance(widget.session.id, status);
      refreshTables(ref, tableId: widget.table.id);
    } on ApiException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel() async {
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

    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(sessionApiProvider).cancel(widget.session.id);
      refreshTables(ref, tableId: widget.table.id);
    } on ApiException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final pending = widget.table.members.length - session.attendances.length;

    return QBCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  session.title,
                  style: QBType.game().copyWith(
                    fontWeight: QBType.weightSemibold,
                    fontSize: 15,
                    color: QBColors.ink900,
                  ),
                ),
              ),
              if (widget.table.isGameMaster) ...[
                QBIconButton(
                  icon: const Icon(LucideIcons.pencil, size: 16),
                  label: 'Modifier la session',
                  size: 32,
                  onPressed: () => showSessionFormDialog(
                    context,
                    tableId: widget.table.id,
                    existing: session,
                  ),
                ),
                QBIconButton(
                  icon: const Icon(LucideIcons.x, size: 16),
                  label: 'Annuler la session',
                  size: 32,
                  onPressed: _cancel,
                ),
              ],
            ],
          ),
          const SizedBox(height: QBSpace.s2),
          _IconLine(
            icon: LucideIcons.calendarDays,
            text: formatSessionDate(session.startsAt),
          ),
          const SizedBox(height: 2),
          _IconLine(icon: LucideIcons.mapPin, text: session.location),
          if (session.description != null && session.description!.isNotEmpty) ...[
            const SizedBox(height: QBSpace.s2),
            Text(
              session.description!,
              style: QBType.body().copyWith(
                fontSize: QBType.sm,
                color: QBColors.textBody,
              ),
            ),
          ],
          const SizedBox(height: QBSpace.s3),
          _AttendanceSummary(session: session, pendingCount: pending),
          const SizedBox(height: QBSpace.s3),
          Row(
            children: [
              Expanded(
                child: QBButton(
                  label: 'Je viens',
                  size: QBButtonSize.sm,
                  expand: true,
                  variant: session.myStatus == AttendanceStatus.yes
                      ? QBButtonVariant.primary
                      : QBButtonVariant.secondary,
                  onPressed:
                      _busy ? null : () => _answer(AttendanceStatus.yes),
                ),
              ),
              const SizedBox(width: QBSpace.s2),
              Expanded(
                child: QBButton(
                  label: 'Je passe',
                  size: QBButtonSize.sm,
                  expand: true,
                  variant: session.myStatus == AttendanceStatus.no
                      ? QBButtonVariant.danger
                      : QBButtonVariant.ghost,
                  onPressed: _busy ? null : () => _answer(AttendanceStatus.no),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Who said what. Members who have not answered are counted separately: not
/// answering is not the same as saying no, and the game master needs to know
/// who to chase.
class _AttendanceSummary extends StatelessWidget {
  const _AttendanceSummary({required this.session, required this.pendingCount});

  final RemoteGameSession session;
  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    final accepted = session.accepted;
    final declined = session.declined;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (accepted.isNotEmpty)
          _MutedText(
            'Présents · ${accepted.map((a) => a.user.label).join(', ')}',
          ),
        if (declined.isNotEmpty)
          _MutedText(
            'Absents · ${declined.map((a) => a.user.label).join(', ')}',
          ),
        if (pendingCount > 0)
          _MutedText(
            pendingCount > 1
                ? '$pendingCount joueurs n’ont pas encore répondu'
                : '1 joueur n’a pas encore répondu',
          ),
      ],
    );
  }
}

class _PastSessionRow extends StatelessWidget {
  const _PastSessionRow({required this.session});

  final RemoteGameSession session;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            session.title,
            style: QBType.body().copyWith(
              fontSize: QBType.sm,
              color: QBColors.textMuted,
              decoration: session.isCancelled ? TextDecoration.lineThrough : null,
            ),
          ),
        ),
        Text(
          session.isCancelled ? 'Annulée' : formatShortDate(session.startsAt),
          style: QBType.body().copyWith(
            fontSize: QBType.xs,
            color: QBColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _MemberRow extends ConsumerWidget {
  const _MemberRow({required this.member, required this.table});

  final RemoteTableMember member;
  final RemoteGameTable table;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The game master is the one member who cannot be removed: the table would
    // be left with nobody able to schedule anything.
    final canRemove = table.isGameMaster && !member.role.isGameMaster;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                member.user.label,
                style: QBType.body().copyWith(
                  fontSize: QBType.sm,
                  color: QBColors.textBody,
                ),
              ),
              if (member.role.isGameMaster)
                Text(
                  'Maître du jeu',
                  style: QBType.body().copyWith(
                    fontSize: QBType.xs,
                    color: QBColors.textMuted,
                  ),
                ),
            ],
          ),
        ),
        if (canRemove)
          QBIconButton(
            icon: const Icon(LucideIcons.userMinus, size: 16),
            label: 'Retirer ${member.user.label}',
            size: 32,
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                await ref
                    .read(tableApiProvider)
                    .removeMember(table.id, member.userId);
                refreshTables(ref, tableId: table.id);
              } on ApiException catch (error) {
                messenger.showSnackBar(SnackBar(content: Text(error.message)));
              }
            },
          ),
      ],
    );
  }
}

class _PendingInvitationRow extends ConsumerWidget {
  const _PendingInvitationRow({
    required this.invitation,
    required this.tableId,
  });

  final RemoteTableInvitation invitation;
  final String tableId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: Text(
            invitation.email,
            style: QBType.body().copyWith(
              fontSize: QBType.sm,
              color: QBColors.textMuted,
            ),
          ),
        ),
        QBIconButton(
          icon: const Icon(LucideIcons.x, size: 16),
          label: 'Annuler l’invitation',
          size: 32,
          onPressed: () async {
            final messenger = ScaffoldMessenger.of(context);
            try {
              await ref
                  .read(tableApiProvider)
                  .revokeInvitation(tableId, invitation.id);
              refreshTables(ref, tableId: tableId);
            } on ApiException catch (error) {
              messenger.showSnackBar(SnackBar(content: Text(error.message)));
            }
          },
        ),
      ],
    );
  }
}

/// Leaving and disbanding are the same button in two guises: a player walks
/// away, a game master takes the table with them.
class _DangerZone extends ConsumerWidget {
  const _DangerZone({required this.table});

  final RemoteGameTable table;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGm = table.isGameMaster;

    return QBButton(
      label: isGm ? 'Dissoudre la table' : 'Quitter la table',
      variant: QBButtonVariant.danger,
      size: QBButtonSize.sm,
      expand: true,
      onPressed: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(isGm ? 'Dissoudre la table ?' : 'Quitter la table ?'),
            content: Text(
              isGm
                  ? 'La table et toutes ses sessions seront supprimées pour '
                      'tout le monde. C’est définitif.'
                  : 'Tu ne verras plus cette table ni ses sessions.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Non'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(isGm ? 'Dissoudre' : 'Quitter'),
              ),
            ],
          ),
        );

        if (confirmed != true || !context.mounted) return;

        final messenger = ScaffoldMessenger.of(context);
        final router = GoRouter.of(context);

        try {
          final api = ref.read(tableApiProvider);
          if (isGm) {
            await api.delete(table.id);
          } else {
            await api.leave(table.id);
          }
          refreshTables(ref);
          router.go('/tables');
        } on ApiException catch (error) {
          messenger.showSnackBar(SnackBar(content: Text(error.message)));
        }
      },
    );
  }
}

// --- Small shared pieces ---

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.action});

  final String title;
  final _SectionAction? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: QBType.game().copyWith(
              fontWeight: QBType.weightSemibold,
              fontSize: 15,
              color: QBColors.ink900,
            ),
          ),
        ),
        if (action != null)
          GestureDetector(
            onTap: action!.onTap,
            child: Text(
              action!.label,
              style: QBType.game().copyWith(
                fontWeight: QBType.weightSemibold,
                fontSize: QBType.sm,
                color: QBColors.leather700,
              ),
            ),
          ),
      ],
    );
  }
}

class _SectionAction {
  const _SectionAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;
}

class _IconLine extends StatelessWidget {
  const _IconLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: QBColors.textMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: QBType.body().copyWith(
              fontSize: QBType.xs,
              color: QBColors.textMuted,
            ),
          ),
        ),
      ],
    );
  }
}

class _MutedText extends StatelessWidget {
  const _MutedText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        text,
        style: QBType.body().copyWith(
          fontSize: QBType.xs,
          color: QBColors.textMuted,
        ),
      ),
    );
  }
}

class _Failure extends StatelessWidget {
  const _Failure({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final api = error is ApiException ? error as ApiException : null;
    final message = api == null
        ? '$error'
        : api.isMissing
            ? 'Cette table n’existe plus, ou tu n’en fais plus partie.'
            : api.message;

    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: QBType.body().copyWith(
              fontSize: QBType.sm,
              color: QBColors.textMuted,
            ),
          ),
          const SizedBox(height: QBSpace.s4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              QBButton(
                label: 'Retour',
                variant: QBButtonVariant.ghost,
                size: QBButtonSize.sm,
                onPressed: () => context.go('/tables'),
              ),
              const SizedBox(width: QBSpace.s2),
              QBButton(
                label: 'Réessayer',
                variant: QBButtonVariant.secondary,
                size: QBButtonSize.sm,
                onPressed: onRetry,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
