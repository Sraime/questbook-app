import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:questbook/data/local/database.dart';
import 'package:questbook/data/local/downloaded_scenario_dao.dart';
import 'package:questbook/data/remote/remote_scenario.dart';

RemoteScenarioDetail _detail(
  String id, {
  String title = 'Le Phare',
  DateTime? updatedAt,
}) {
  return RemoteScenarioDetail(
    id: id,
    title: title,
    description: 'Brume.',
    minRecommendedPlayers: 2,
    maxRecommendedPlayers: 5,
    averageDurationMinutes: 180,
    context: 'Kerloc\'h.',
    rundownMarkdown: '## Suite',
    npcs: const [],
    clues: const [],
    updatedAt: updatedAt,
  );
}

void main() {
  late AppDatabase db;
  late DownloadedScenarioDao dao;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = DownloadedScenarioDao(db);
  });

  tearDown(() => db.close());

  test('hands back the document that was downloaded', () async {
    await dao.save('account-1', _detail('sc-1'));

    final stored = await dao.read('account-1', 'sc-1');

    expect(stored, isNotNull);
    expect(stored!.title, 'Le Phare');
    expect(stored.rundownMarkdown, '## Suite');
  });

  test('hides another account\'s download', () async {
    await dao.save('account-1', _detail('sc-1'));

    expect(await dao.read('account-2', 'sc-1'), isNull);
    expect(await dao.ids('account-2'), isEmpty);
  });

  test('lists every download of the signed-in account', () async {
    await dao.save('account-1', _detail('sc-1', title: 'A'));
    await dao.save('account-1', _detail('sc-2', title: 'B'));
    await dao.save('account-2', _detail('sc-3', title: 'C'));

    final listed = await dao.list('account-1');

    expect(listed.map((row) => row.id), unorderedEquals(['sc-1', 'sc-2']));
  });

  test('remembers the date the server gave each copy', () async {
    final date = DateTime.utc(2026, 9, 26, 19, 30);
    await dao.save('account-1', _detail('sc-1', updatedAt: date));

    expect(await dao.versions('account-1'), {'sc-1': date});
  });

  // Une copie telechargee avant que la date existe. Elle se lit toujours, et
  // c'est l'ecran qui decide quoi faire de son age inconnu.
  test('admits it does not know the date of an older copy', () async {
    await dao.save('account-1', _detail('sc-1'));

    expect(await dao.versions('account-1'), {'sc-1': null});
  });

  test('clears everything on sign-out', () async {
    await dao.save('account-1', _detail('sc-1'));
    await dao.clear();

    expect(await dao.read('account-1', 'sc-1'), isNull);
  });
}
