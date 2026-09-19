import 'package:drift/drift.dart';

import 'database.dart';

/// Ce qu'une session garde du mode MJ entre deux ouvertures de l'app.
class SessionBoard {
  const SessionBoard({this.tokens = '[]', this.notes = ''});

  /// Pions encodés — voir `features/game_master/models/board_token.dart`.
  /// La couche données n'en connaît que le texte, comme pour [RemoteCache] :
  /// la forme des pions peut changer sans migration.
  final String tokens;
  final String notes;
}

/// Plateau et notes du MJ, rangés par session et par compte.
class SessionBoardDao {
  SessionBoardDao(this._db);

  final AppDatabase _db;

  Future<SessionBoard> read(String accountId, String sessionId) async {
    final row = await (_db.select(_db.sessionBoards)
          ..where((entry) => entry.accountId.equals(accountId))
          ..where((entry) => entry.sessionId.equals(sessionId)))
        .getSingleOrNull();

    if (row == null) return const SessionBoard();
    return SessionBoard(tokens: row.tokens, notes: row.notes);
  }

  Future<void> saveTokens(
    String accountId,
    String sessionId,
    String tokens,
  ) {
    return _upsert(
      accountId,
      sessionId,
      insert: SessionBoardsCompanion.insert(
        sessionId: sessionId,
        accountId: accountId,
        tokens: Value(tokens),
        updatedAt: DateTime.now(),
      ),
      update: SessionBoardsCompanion(
        tokens: Value(tokens),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> saveNotes(String accountId, String sessionId, String notes) {
    return _upsert(
      accountId,
      sessionId,
      insert: SessionBoardsCompanion.insert(
        sessionId: sessionId,
        accountId: accountId,
        notes: Value(notes),
        updatedAt: DateTime.now(),
      ),
      update: SessionBoardsCompanion(
        notes: Value(notes),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Écrit la seule colonne touchée : poser un pion ne doit pas effacer les
  /// notes prises deux minutes plus tôt, et inversement.
  Future<void> _upsert(
    String accountId,
    String sessionId, {
    required SessionBoardsCompanion insert,
    required SessionBoardsCompanion update,
  }) {
    return _db.into(_db.sessionBoards).insert(
          insert,
          onConflict: DoUpdate(
            (_) => update,
            target: [_db.sessionBoards.sessionId, _db.sessionBoards.accountId],
          ),
        );
  }

  Future<void> clear() => _db.delete(_db.sessionBoards).go();
}
