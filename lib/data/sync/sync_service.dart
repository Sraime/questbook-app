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

  /// One chain per character, so two edits a second apart leave in the order
  /// they were made.
  ///
  /// Without it the second `PUT` could land first, and the first would come
  /// back as a stale write carrying the server's version — which the device
  /// would then adopt, on top of a third edit the player may already have
  /// made. Queueing costs a few milliseconds and removes the whole question.
  final _pushChains = <String, Future<void>>{};

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

  /// Sends one aggregate the moment it changes, rather than at the next pass.
  ///
  /// A character is the one thing a player edits while others are waiting on
  /// the answer: the game master reads the sheets from the server, so points
  /// of life lost at the table have to leave the device straight away. The
  /// rest of the pass — the pull, the account bookkeeping — has no reason to
  /// run for a tap on a gauge.
  ///
  /// Best effort by design. The local write has already happened and the row
  /// stays flagged until the server confirms, so a failure here costs a
  /// delay, never an edit: the next full pass takes it.
  Future<void> pushCharacter(String id) {
    final queued =
        (_pushChains[id] ?? Future<void>.value()).then((_) => _pushPending(id));

    // The chain is built on a future that cannot fail, for two reasons: a
    // refused upload must not hold back the next one — which carries the
    // whole sheet anyway, so it says everything the failed one did — and a
    // caller who does not await gets no unhandled error out of the tail.
    final settled = queued.then((_) {}, onError: (_) {});
    _pushChains[id] = settled;
    settled.whenComplete(() {
      // Only if nothing queued behind in the meantime, or the next edit
      // would be chained onto a future nobody holds any more.
      if (identical(_pushChains[id], settled)) _pushChains.remove(id);
    });

    return queued;
  }

  Future<void> _pushPending(String id) async {
    final pending = await _dao.pendingPush(id);
    if (pending == null) return;

    await _pushOne(pending);
  }

  Future<int> _push() async {
    final pending = await _dao.pendingPushes();
    var pushed = 0;

    for (final one in pending) {
      await _pushOne(one);
      pushed++;
    }

    return pushed;
  }

  Future<void> _pushOne(PendingPush pending) async {
    final character = pending.character;

    try {
      await _api.push(character);

      if (character.isDeleted) {
        // The server now holds the tombstone, so the local one is redundant.
        await _dao.purge(character.id);
      } else {
        await _dao.markSynced(character.id, pending.revision);
      }
    } on ApiException catch (error) {
      final winner = error.conflictingCharacter;
      if (error.isStaleWrite && winner != null) {
        // The other device wrote later. Adopting the server version here
        // means the pull below has nothing left to reconcile.
        await _adopt(RemoteCharacter.fromJson(winner));
        return;
      }
      rethrow;
    }
  }

  /// Takes the server's version, unless this device has moved on since.
  ///
  /// The check matters now that a push can be fired by a gesture: the answer
  /// to a tap on a gauge comes back while the player is tapping the next one,
  /// and writing the server's version over an edit it never saw would undo it
  /// in front of them.
  /// Answers whether it took it, so the pull can count what it applied.
  Future<bool> _adopt(RemoteCharacter remote) async {
    final local = await _dao.findRow(remote.id);
    if (local != null &&
        local.needsSync &&
        local.updatedAt.isAfter(remote.updatedAt)) {
      return false;
    }

    await _dao.applyRemote(remote);
    return true;
  }

  Future<int> _pull() async {
    final page = await _api.list(since: await _dao.readCursor());
    var applied = 0;

    for (final remote in page.characters) {
      // A local edit made after the server's version wins and will be pushed
      // on the next pass; overwriting it here would silently lose it.
      if (await _adopt(remote)) applied++;
    }

    await _dao.writeCursor(page.syncedAt);
    return applied;
  }
}
