import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/remote_providers.dart';
import '../../../data/remote/auth_tokens.dart';
import '../../../data/remote/remote_table.dart';

/// Tables are strictly online: there is no local copy to fall back on, so
/// every provider here reads straight from the API and simply refetches after
/// a change. Watching [authControllerProvider] makes them reload when the
/// account changes and empty out on sign-out.

/// What the Tables tab needs in one go: the tables the user belongs to, and
/// the invitations still waiting for an answer.
class TablesOverview {
  const TablesOverview({required this.tables, required this.invitations});

  final List<RemoteGameTable> tables;
  final List<RemoteTableInvitation> invitations;

  bool get isEmpty => tables.isEmpty && invitations.isEmpty;
}

final tablesOverviewProvider = FutureProvider<TablesOverview>((ref) async {
  final user = ref.watch(authControllerProvider).value;
  if (user == null) {
    return const TablesOverview(tables: [], invitations: []);
  }

  final api = ref.watch(tableApiProvider);
  final results = await Future.wait([
    api.list(),
    api.pendingInvitations(),
  ]);

  return TablesOverview(
    tables: results[0] as List<RemoteGameTable>,
    invitations: results[1] as List<RemoteTableInvitation>,
  );
});

/// A table and its sessions, which the detail screen always shows together.
class TableDetail {
  const TableDetail({required this.table, required this.sessions});

  final RemoteGameTable table;
  final List<RemoteGameSession> sessions;

  /// Scheduled and still ahead of us, soonest first.
  List<RemoteGameSession> get upcoming => sessions
      .where((session) => !session.isCancelled && !session.isPast)
      .toList()
    ..sort((a, b) => a.startsAt.compareTo(b.startsAt));

  /// Everything else, most recent first: past evenings and cancellations.
  List<RemoteGameSession> get past => sessions
      .where((session) => session.isCancelled || session.isPast)
      .toList()
    ..sort((a, b) => b.startsAt.compareTo(a.startsAt));
}

final tableDetailProvider =
    FutureProvider.family<TableDetail, String>((ref, tableId) async {
  final table = await ref.watch(tableApiProvider).get(tableId);
  final sessions = await ref.watch(sessionApiProvider).listForTable(tableId);
  return TableDetail(table: table, sessions: sessions);
});

final notificationsProvider = FutureProvider<RemoteNotificationPage>((ref) async {
  final user = ref.watch(authControllerProvider).value;
  if (user == null) {
    return const RemoteNotificationPage(notifications: [], unreadCount: 0);
  }
  return ref.watch(notificationApiProvider).list();
});

/// Drives the badge on the navigation bar. Falls back to zero rather than an
/// error state: a failed refresh should not make the bar shout.
final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).value?.unreadCount ?? 0;
});

/// True when the tables feature can actually be used. Everything it does
/// needs an account and a reachable server.
final isSignedInProvider = Provider<bool>((ref) {
  final AsyncValue<AuthUser?> auth = ref.watch(authControllerProvider);
  return auth.value != null;
});

/// Refetches the tables tab and any open detail screen after a change.
void refreshTables(WidgetRef ref, {String? tableId}) {
  ref.invalidate(tablesOverviewProvider);
  ref.invalidate(notificationsProvider);
  if (tableId != null) {
    ref.invalidate(tableDetailProvider(tableId));
  }
}
