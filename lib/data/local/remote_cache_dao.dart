import 'dart:convert';

import 'database.dart';

/// Keeps the last successful answer for a handful of API reads, so the tables
/// tab degrades into a readable archive rather than an error screen.
///
/// Entries are scoped to an account and dropped as soon as a different one
/// signs in: a shared device must never show the previous player's tables.
class RemoteCacheDao {
  RemoteCacheDao(this._db);

  final AppDatabase _db;

  static const overviewKey = 'tables.overview';

  static String detailKey(String tableId) => 'tables.detail.$tableId';

  Future<void> write(String key, String accountId, Object payload) {
    return _db.into(_db.remoteCache).insertOnConflictUpdate(
          RemoteCacheCompanion.insert(
            key: key,
            accountId: accountId,
            payload: jsonEncode(payload),
            fetchedAt: DateTime.now(),
          ),
        );
  }

  /// Returns null when nothing was ever stored, or when what was stored
  /// belongs to somebody else.
  Future<CachedPayload?> read(String key, String accountId) async {
    final row = await (_db.select(_db.remoteCache)
          ..where((entry) => entry.key.equals(key))
          ..where((entry) => entry.accountId.equals(accountId)))
        .getSingleOrNull();

    if (row == null) return null;
    return CachedPayload(jsonDecode(row.payload), row.fetchedAt);
  }

  /// Called on sign-out and on account change.
  Future<void> clear() => _db.delete(_db.remoteCache).go();
}

class CachedPayload {
  const CachedPayload(this.data, this.fetchedAt);

  final dynamic data;

  /// When the server last said this. The UI shows it, because a cached table
  /// is only trustworthy to the extent the reader knows how old it is.
  final DateTime fetchedAt;
}
