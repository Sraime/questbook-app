import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/remote_providers.dart';
import '../../data/remote/api_exception.dart';
import '../../data/remote/remote_table.dart';
import '../../design_system/components/qb_card.dart';
import '../../design_system/components/qb_icon_button.dart';
import '../../design_system/components/qb_page_background.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/spacing.dart';
import '../../design_system/tokens/typography.dart';
import 'providers/table_providers.dart';
import 'table_formatting.dart';

/// The history behind the push notifications. It is written server-side inside
/// the same transaction as the change that caused it, so it stays complete
/// even when a push never arrives.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = ref.watch(notificationsProvider);

    return QBPageBackground(
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(notificationsProvider),
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
                      'Notifications',
                      // Without this the game font breaks the word in two
                      // when the action beside it takes the width.
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: QBType.game().copyWith(
                        fontWeight: QBType.weightBold,
                        fontSize: 20,
                        color: QBColors.ink900,
                      ),
                    ),
                  ),
                  if ((page.value?.unreadCount ?? 0) > 0)
                    GestureDetector(
                      onTap: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          await ref.read(notificationApiProvider).markAllRead();
                          ref.invalidate(notificationsProvider);
                        } on ApiException catch (error) {
                          messenger.showSnackBar(
                            SnackBar(content: Text(error.message)),
                          );
                        }
                      },
                      child: Text(
                        'Tout lire',
                        style: QBType.game().copyWith(
                          fontWeight: QBType.weightSemibold,
                          fontSize: QBType.sm,
                          color: QBColors.leather700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: QBSpace.s5),
              page.when(
                data: (data) => data.notifications.isEmpty
                    ? Text(
                        'Rien à signaler. Les invitations, les sessions et les '
                        'réponses de tes joueurs apparaîtront ici.',
                        style: QBType.body().copyWith(
                          fontSize: QBType.sm,
                          color: QBColors.textMuted,
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final notification in data.notifications) ...[
                            _NotificationCard(notification: notification),
                            const SizedBox(height: QBSpace.s2),
                          ],
                        ],
                      ),
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, stack) => Text(
                  error is ApiException ? error.message : '$error',
                  style: QBType.body().copyWith(
                    fontSize: QBType.sm,
                    color: QBColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationCard extends ConsumerWidget {
  const _NotificationCard({required this.notification});

  final RemoteNotification notification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () async {
        final router = GoRouter.of(context);
        final tableId = notification.tableId;

        if (notification.isUnread) {
          // Reading it is the point of tapping it; a failure here is not worth
          // interrupting the navigation for.
          try {
            await ref
                .read(notificationApiProvider)
                .markRead([notification.id]);
            ref.invalidate(notificationsProvider);
          } on ApiException {
            // Ignored on purpose: the badge will catch up on the next refresh.
          }
        }

        // Every notification is about a table, and a session is always shown
        // inside its table, so one destination covers all five kinds.
        if (tableId != null) router.go('/tables/$tableId');
      },
      child: QBCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 3, right: 10),
              child: Icon(
                _iconFor(notification.type),
                size: 15,
                color: notification.isUnread
                    ? QBColors.wax500
                    : QBColors.textMuted,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    notification.title,
                    style: QBType.game().copyWith(
                      fontWeight: notification.isUnread
                          ? QBType.weightBold
                          : QBType.weightSemibold,
                      fontSize: QBType.sm,
                      color: QBColors.ink900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notification.body,
                    style: QBType.body().copyWith(
                      fontSize: QBType.xs,
                      color: QBColors.textBody,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatRelative(notification.createdAt),
                    style: QBType.body().copyWith(
                      fontSize: QBType.xs,
                      color: QBColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String type) => switch (type) {
        'table_invitation' => LucideIcons.mail,
        'invitation_accepted' => LucideIcons.userPlus,
        'session_created' => LucideIcons.calendarPlus,
        'session_updated' => LucideIcons.calendarClock,
        'session_cancelled' => LucideIcons.calendarX,
        'attendance_changed' => LucideIcons.check,
        'attendance_character_changed' => LucideIcons.userRound,
        'game_master_transferred' => LucideIcons.crown,
        _ => LucideIcons.messageSquare,
      };
}
