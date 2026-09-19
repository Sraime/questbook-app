import 'dart:convert';

import 'database.dart';
import '../remote/remote_scenario.dart';

/// Keeps the full document of scenarios the user chose to download, scoped to
/// the signed-in account so a shared device never shows the previous player's
/// adventures.
class DownloadedScenarioDao {
  DownloadedScenarioDao(this._db);

  final AppDatabase _db;

  Future<void> save(String accountId, RemoteScenarioDetail scenario) {
    return _db.into(_db.downloadedScenarios).insertOnConflictUpdate(
          DownloadedScenariosCompanion.insert(
            scenarioId: scenario.id,
            accountId: accountId,
            payload: jsonEncode(scenario.toJson()),
            downloadedAt: DateTime.now(),
          ),
        );
  }

  Future<RemoteScenarioDetail?> read(String accountId, String scenarioId) async {
    final row = await (_db.select(_db.downloadedScenarios)
          ..where((entry) => entry.accountId.equals(accountId))
          ..where((entry) => entry.scenarioId.equals(scenarioId)))
        .getSingleOrNull();

    if (row == null) return null;
    return RemoteScenarioDetail.fromJson(
      (jsonDecode(row.payload) as Map).cast<String, dynamic>(),
    );
  }

  Future<List<RemoteScenarioDetail>> list(String accountId) async {
    final rows = await (_db.select(_db.downloadedScenarios)
          ..where((entry) => entry.accountId.equals(accountId)))
        .get();

    return [
      for (final row in rows)
        RemoteScenarioDetail.fromJson(
          (jsonDecode(row.payload) as Map).cast<String, dynamic>(),
        ),
    ];
  }

  Future<Set<String>> ids(String accountId) async {
    final rows = await (_db.select(_db.downloadedScenarios)
          ..where((entry) => entry.accountId.equals(accountId)))
        .get();
    return {for (final row in rows) row.scenarioId};
  }

  Future<void> clear() => _db.delete(_db.downloadedScenarios).go();
}
