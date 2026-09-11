import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../app/remote_providers.dart';
import '../../../data/local/remote_cache_dao.dart';
import '../../../data/remote/api_exception.dart';
import '../../../data/remote/auth_tokens.dart';
import '../../../data/remote/remote_character.dart';
import '../../../data/remote/remote_table.dart';
import '../../../data/remote/session_api.dart';
import '../../../data/remote/table_api.dart';

final remoteCacheProvider = Provider<RemoteCacheDao>(
  (ref) => RemoteCacheDao(ref.watch(appDatabaseProvider)),
);

/// Tables live on the server: they are shared with other players, so the
/// device is never their source of truth. What it does keep is a copy of the
/// last answer, so losing the network turns the tab into a dated archive
/// rather than an error screen. Watching [authControllerProvider] makes these
/// reload when the account changes and empty out on sign-out.

/// What the Tables tab needs in one go: the tables the user belongs to, and
/// the invitations still waiting for an answer.
class TablesOverview {
  const TablesOverview({
    required this.tables,
    required this.invitations,
    this.cachedAt,
  });

  final List<RemoteGameTable> tables;
  final List<RemoteTableInvitation> invitations;

  /// Set when this came from the local copy rather than the server, and says
  /// how old it is. Null means fresh.
  final DateTime? cachedAt;

  bool get isEmpty => tables.isEmpty && invitations.isEmpty;
}

final tablesOverviewProvider = FutureProvider<TablesOverview>((ref) async {
  final user = ref.watch(authControllerProvider).value;
  if (user == null) {
    return const TablesOverview(tables: [], invitations: []);
  }

  final api = ref.watch(tableApiProvider);
  final cache = ref.watch(remoteCacheProvider);

  try {
    final results = await Future.wait([
      api.listRaw(),
      api.pendingInvitationsRaw(),
    ]);

    await cache.write(
      RemoteCacheDao.overviewKey,
      user.id,
      {'tables': results[0], 'invitations': results[1]},
    );

    return TablesOverview(
      tables: TableApi.parseTables(results[0]),
      invitations: TableApi.parseInvitations(results[1]),
    );
  } on ApiException catch (error) {
    // Only a missing network falls back. A refusal from the server is real
    // news about the account, and showing yesterday's tables would hide it.
    if (!error.isRetryable) rethrow;

    final cached = await cache.read(RemoteCacheDao.overviewKey, user.id);
    if (cached == null) rethrow;

    final payload = (cached.data as Map).cast<String, dynamic>();
    return TablesOverview(
      tables: TableApi.parseTables(payload['tables']),
      invitations: TableApi.parseInvitations(payload['invitations']),
      cachedAt: cached.fetchedAt,
    );
  }
});

/// A table and its sessions, which the detail screen always shows together.
class TableDetail {
  const TableDetail({
    required this.table,
    required this.sessions,
    this.cachedAt,
  });

  final RemoteGameTable table;
  final List<RemoteGameSession> sessions;

  /// See [TablesOverview.cachedAt].
  final DateTime? cachedAt;

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

/// Disposed with the detail screen, so opening a table always fetches it
/// again. A table changes under the user's feet — the game master moves a
/// session, someone answers — and a cached copy from an earlier visit would
/// show none of it.
final tableDetailProvider =
    FutureProvider.autoDispose.family<TableDetail, String>((ref, tableId) async {
  final user = ref.watch(authControllerProvider).value;
  final cache = ref.watch(remoteCacheProvider);
  final key = RemoteCacheDao.detailKey(tableId);

  try {
    final table = await ref.watch(tableApiProvider).getRaw(tableId);
    final sessions =
        await ref.watch(sessionApiProvider).listForTableRaw(tableId);

    if (user != null) {
      await cache.write(key, user.id, {'table': table, 'sessions': sessions});
    }

    return TableDetail(
      table: TableApi.parseTable(table),
      sessions: SessionApi.parseSessions(sessions),
    );
  } on ApiException catch (error) {
    if (!error.isRetryable || user == null) rethrow;

    final cached = await cache.read(key, user.id);
    if (cached == null) rethrow;

    final payload = (cached.data as Map).cast<String, dynamic>();
    return TableDetail(
      table: TableApi.parseTable(payload['table']),
      sessions: SessionApi.parseSessions(payload['sessions']),
      cachedAt: cached.fetchedAt,
    );
  }
});

/// Another player's sheet, readable only because they registered it for a
/// session this user is also at. Fetched on demand and dropped when the sheet
/// closes: it is someone else's data, and it is theirs to change.
final attendeeCharacterProvider = FutureProvider.autoDispose
    .family<RemoteCharacter, AttendeeCharacterRef>((ref, key) {
  return ref
      .watch(sessionApiProvider)
      .attendeeCharacter(key.sessionId, key.userId);
});

class AttendeeCharacterRef {
  const AttendeeCharacterRef({required this.sessionId, required this.userId});

  final String sessionId;
  final String userId;

  @override
  bool operator ==(Object other) =>
      other is AttendeeCharacterRef &&
      other.sessionId == sessionId &&
      other.userId == userId;

  @override
  int get hashCode => Object.hash(sessionId, userId);
}

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
