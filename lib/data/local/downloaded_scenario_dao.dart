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

  /// La date de chaque copie gardée, telle que le serveur l'avait donnée.
  ///
  /// C'est la date **du document**, pas celle du téléchargement : la seconde
  /// vient de l'horloge de l'appareil, qui peut dériver de plusieurs minutes
  /// et ferait alors croire à une copie plus récente que l'original. Comparer
  /// deux dates émises par le serveur ne ment pas.
  ///
  /// Nulle pour un scénario téléchargé avant que la date existe.
  Future<Map<String, DateTime?>> versions(String accountId) async {
    final rows = await (_db.select(_db.downloadedScenarios)
          ..where((entry) => entry.accountId.equals(accountId)))
        .get();

    return {
      for (final row in rows)
        row.scenarioId: parseScenarioDate(
          (jsonDecode(row.payload) as Map)['updatedAt'],
        ),
    };
  }

  Future<void> clear() => _db.delete(_db.downloadedScenarios).go();
}
