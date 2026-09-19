import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:questbook/data/local/database.dart';
import 'package:questbook/data/local/session_board_dao.dart';

void main() {
  late AppDatabase db;
  late SessionBoardDao dao;

    setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = SessionBoardDao(db);
  });

  tearDown(() => db.close());

  test('a session never opened comes back empty rather than missing', () async {
    final board = await dao.read('account-1', 'session-1');

    expect(board.tokens, '[]');
    expect(board.notes, '');
  });

  test('gives back the board that was left on the table', () async {
    await dao.saveTokens('account-1', 'session-1', '[{"id":"t1"}]');

    expect((await dao.read('account-1', 'session-1')).tokens, '[{"id":"t1"}]');
  });

  test('poser un pion n’efface pas les notes, et inversement', () async {
    await dao.saveNotes('account-1', 'session-1', 'Bonus accordé à Marcus');
    await dao.saveTokens('account-1', 'session-1', '[{"id":"t1"}]');

    final board = await dao.read('account-1', 'session-1');

    expect(board.notes, 'Bonus accordé à Marcus');
    expect(board.tokens, '[{"id":"t1"}]');
  });

  test('keeps each session apart', () async {
    await dao.saveNotes('account-1', 'session-1', 'Chapitre I');
    await dao.saveNotes('account-1', 'session-2', 'Chapitre II');

    expect((await dao.read('account-1', 'session-1')).notes, 'Chapitre I');
    expect((await dao.read('account-1', 'session-2')).notes, 'Chapitre II');
  });

  test('hides another game master’s board on a shared tablet', () async {
    await dao.saveNotes('account-1', 'session-1', 'Le gardien ment');

    expect((await dao.read('account-2', 'session-1')).notes, '');
  });

  test('clears everything on sign-out', () async {
    await dao.saveNotes('account-1', 'session-1', 'Le gardien ment');
    await dao.clear();

    expect((await dao.read('account-1', 'session-1')).notes, '');
  });
}
