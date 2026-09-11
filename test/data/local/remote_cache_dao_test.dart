import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:questbook/data/local/database.dart';
import 'package:questbook/data/local/remote_cache_dao.dart';

/// The cache is what stands between a player without a network and an error
/// screen, so what matters is that it hands back exactly what went in — and
/// that it refuses to hand it to anybody else.
void main() {
  late AppDatabase db;
  late RemoteCacheDao dao;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = RemoteCacheDao(db);
  });

  tearDown(() => db.close());

  test('gives back the payload it was handed', () async {
    await dao.write(RemoteCacheDao.overviewKey, 'account-1', {
      'tables': [
        {'id': 'table-1', 'title': 'Les Inspecteurs Chavillois'},
      ],
    });

    final cached = await dao.read(RemoteCacheDao.overviewKey, 'account-1');

    expect(cached, isNotNull);
    final tables = (cached!.data as Map)['tables'] as List;
    expect((tables.single as Map)['title'], 'Les Inspecteurs Chavillois');
  });

  test('hides an entry from another account', () async {
    await dao.write(RemoteCacheDao.overviewKey, 'account-1', {'tables': []});

    expect(
      await dao.read(RemoteCacheDao.overviewKey, 'account-2'),
      isNull,
      reason: 'a shared device must not show the previous player their tables',
    );
  });

  test('replaces an entry rather than piling copies up', () async {
    await dao.write(RemoteCacheDao.overviewKey, 'account-1', {'tables': []});
    await dao.write(RemoteCacheDao.overviewKey, 'account-1', {
      'tables': [
        {'id': 'table-1'},
      ],
    });

    final cached = await dao.read(RemoteCacheDao.overviewKey, 'account-1');

    expect(await db.select(db.remoteCache).get(), hasLength(1));
    expect(((cached!.data as Map)['tables'] as List), hasLength(1));
  });

  test('keeps one entry per table detail', () async {
    await dao.write(RemoteCacheDao.detailKey('a'), 'account-1', {'id': 'a'});
    await dao.write(RemoteCacheDao.detailKey('b'), 'account-1', {'id': 'b'});

    final a = await dao.read(RemoteCacheDao.detailKey('a'), 'account-1');
    final b = await dao.read(RemoteCacheDao.detailKey('b'), 'account-1');

    expect((a!.data as Map)['id'], 'a');
    expect((b!.data as Map)['id'], 'b');
  });

  test('empties on sign-out', () async {
    await dao.write(RemoteCacheDao.overviewKey, 'account-1', {'tables': []});
    await dao.clear();

    expect(await dao.read(RemoteCacheDao.overviewKey, 'account-1'), isNull);
  });
}
