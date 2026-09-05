import '../remote/api_exception.dart';
import '../remote/character_api.dart';
import '../remote/remote_character.dart';
import 'character_sync_dao.dart';

/// Outcome of one synchronisation pass, for the UI to report.
class SyncReport {
  const SyncReport({this.pushed = 0, this.pulled = 0, this.error});

  final int pushed;
  final int pulled;
  final ApiException? error;

  bool get isSuccess => error == null;
}

/// Keeps the local Drift database and the API in step.
///
/// Drift stays the source of truth for the UI — every screen still reads the
/// same streams, online or not. This service only mirrors those rows to the
/// server and brings back what other devices changed.
///
/// Conflicts are resolved last-write-wins on the character as a whole, which
/// is the same rule the API applies, so both sides always agree on the winner.
class SyncService {
  SyncService(this._api, this._dao);

  final CharacterApi _api;
  final CharacterSyncDao _dao;

  Future<void>? _inFlight;

  /// Runs a full push-then-pull pass.
  ///
  /// Push comes first so that a character created offline exists on the server
  /// before the pull could otherwise mistake it for something to delete.
  ///
  /// Concurrent calls (app resume + manual pull, say) share the same pass
  /// rather than racing each other on the same rows.
  Future<SyncReport> synchronize({required String accountId}) async {
    if (_inFlight != null) {
      await _inFlight;
      return const SyncReport();
    }

    final completer = _run(accountId);
    _inFlight = completer;
    try {
      return await completer;
    } finally {
      _inFlight = null;
    }
  }

  Future<SyncReport> _run(String accountId) async {
    final previousAccount = await _dao.readAccountId();
    if (previousAccount == null) {
      // First sign-in on this device: whatever was created offline belongs to
      // the account that just signed in, and is uploaded as-is.
      await _dao.writeAccountId(accountId);
    } else if (previousAccount != accountId) {
      await _dao.resetForNewAccount(accountId);
    }

    try {
      final pushed = await _push();
      final pulled = await _pull();
      return SyncReport(pushed: pushed, pulled: pulled);
    } on ApiException catch (error) {
      return SyncReport(error: error);
    }
  }

  Future<int> _push() async {
    final pending = await _dao.pendingPushes();
    var pushed = 0;

    for (final character in pending) {
      try {
        await _api.push(character);

        if (character.isDeleted) {
          // The server now holds the tombstone, so the local one is redundant.
          await _dao.purge(character.id);
        } else {
          await _dao.markSynced(character.id, character.updatedAt);
        }
        pushed++;
      } on ApiException catch (error) {
        final winner = error.conflictingCharacter;
        if (error.isStaleWrite && winner != null) {
          // The other device wrote later. Adopting the server version here
          // means the pull below has nothing left to reconcile.
          await _dao.applyRemote(RemoteCharacter.fromJson(winner));
          continue;
        }
        rethrow;
      }
    }

    return pushed;
  }

  Future<int> _pull() async {
    final page = await _api.list(since: await _dao.readCursor());
    var applied = 0;

    for (final remote in page.characters) {
      final local = await _dao.findRow(remote.id);

      // A local edit made after the server's version wins and will be pushed
      // on the next pass; overwriting it here would silently lose it.
      if (local != null &&
          local.needsSync &&
          local.updatedAt.isAfter(remote.updatedAt)) {
        continue;
      }

      await _dao.applyRemote(remote);
      applied++;
    }

    await _dao.writeCursor(page.syncedAt);
    return applied;
  }
}
