import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../app/remote_providers.dart';
import '../../../data/local/downloaded_scenario_dao.dart';
import '../../../data/local/remote_cache_dao.dart';
import '../../../data/remote/api_exception.dart';
import '../../../data/remote/remote_scenario.dart';
import '../../../data/remote/scenario_api.dart';

final downloadedScenarioDaoProvider = Provider<DownloadedScenarioDao>(
  (ref) => DownloadedScenarioDao(ref.watch(appDatabaseProvider)),
);

class ScenariosOverview {
  const ScenariosOverview({
    required this.scenarios,
    required this.downloadedIds,
    this.downloadedVersions = const {},
    this.cachedAt,
  });

  final List<RemoteScenarioSummary> scenarios;
  final Set<String> downloadedIds;

  /// La date que portait chaque copie gardée, par identifiant.
  final Map<String, DateTime?> downloadedVersions;

  final DateTime? cachedAt;

  bool isDownloaded(String id) => downloadedIds.contains(id);

  /// Vrai quand le serveur a corrigé l'aventure depuis qu'elle a été
  /// téléchargée.
  ///
  /// Trois refus avant le verdict. Ce qui n'est pas téléchargé n'a rien à
  /// remettre à jour. Une liste qui vient du cache ne peut rien apprendre de
  /// neuf, et c'est ce qui tient lieu de test de connexion : on ne peut pas
  /// savoir qu'une version plus récente existe sans avoir joint le serveur.
  /// Et un serveur qui ne date pas ses aventures ne permet aucune
  /// comparaison.
  ///
  /// Reste le cas d'une copie sans date, téléchargée avant que le mécanisme
  /// existe : impossible de prouver qu'elle est à jour, donc on propose. Un
  /// tapotement, et elle portera enfin la sienne.
  bool isOutdated(RemoteScenarioSummary scenario) {
    if (!isDownloaded(scenario.id)) return false;
    if (cachedAt != null) return false;

    final onServer = scenario.updatedAt;
    if (onServer == null) return false;

    final onDevice = downloadedVersions[scenario.id];
    if (onDevice == null) return true;

    return onServer.isAfter(onDevice);
  }
}

final scenariosOverviewProvider = FutureProvider<ScenariosOverview>((ref) async {
  final user = ref.watch(authControllerProvider).value;
  if (user == null) {
    return const ScenariosOverview(scenarios: [], downloadedIds: {});
  }

  final api = ref.watch(scenarioApiProvider);
  final cache = RemoteCacheDao(ref.watch(appDatabaseProvider));
  final downloads = ref.watch(downloadedScenarioDaoProvider);
  final versions = await downloads.versions(user.id);
  final downloadedIds = versions.keys.toSet();

  try {
    final raw = await api.listRaw();
    await cache.write(RemoteCacheDao.scenariosOverviewKey, user.id, raw);
    return ScenariosOverview(
      scenarios: ScenarioApi.parseList(raw),
      downloadedIds: downloadedIds,
      downloadedVersions: versions,
    );
  } on ApiException catch (error) {
    if (!error.isRetryable) rethrow;
    final cached =
        await cache.read(RemoteCacheDao.scenariosOverviewKey, user.id);
    if (cached == null) rethrow;
    return ScenariosOverview(
      scenarios: ScenarioApi.parseList(cached.data),
      downloadedIds: downloadedIds,
      downloadedVersions: versions,
      cachedAt: cached.fetchedAt,
    );
  }
});

final downloadedScenarioProvider =
    FutureProvider.family<RemoteScenarioDetail?, String>((ref, id) async {
  final user = ref.watch(authControllerProvider).value;
  if (user == null) return null;
  return ref.watch(downloadedScenarioDaoProvider).read(user.id, id);
});

final downloadedScenariosProvider =
    FutureProvider<List<RemoteScenarioDetail>>((ref) async {
  final user = ref.watch(authControllerProvider).value;
  if (user == null) return const [];
  return ref.watch(downloadedScenarioDaoProvider).list(user.id);
});

Future<void> refreshScenarios(WidgetRef ref) async {
  ref.invalidate(scenariosOverviewProvider);
  ref.invalidate(downloadedScenariosProvider);
  await ref.read(scenariosOverviewProvider.future);
}

Future<void> downloadScenario(WidgetRef ref, String id) async {
  final user = ref.read(authControllerProvider).value;
  if (user == null) return;
  final detail = await ref.read(scenarioApiProvider).get(id);
  await ref.read(downloadedScenarioDaoProvider).save(user.id, detail);
  ref.invalidate(scenariosOverviewProvider);
  ref.invalidate(downloadedScenariosProvider);
  ref.invalidate(downloadedScenarioProvider(id));
}
