import 'api_client.dart';
import 'remote_scenario.dart';

class ScenarioApi {
  ScenarioApi(this._client);

  final ApiClient _client;

  Future<List<RemoteScenarioSummary>> list() async => parseList(await listRaw());

  Future<dynamic> listRaw() {
    return _client.send(
      (dio) => dio.get<dynamic>('/scenarios'),
      parse: (data) => data,
    );
  }

  static List<RemoteScenarioSummary> parseList(Object? data) {
    final scenarios = (data as Map)['scenarios'];
    if (scenarios is! List) return const <RemoteScenarioSummary>[];
    return scenarios
        .whereType<Map>()
        .map((entry) =>
            RemoteScenarioSummary.fromJson(entry.cast<String, dynamic>()))
        .toList(growable: false);
  }

  Future<RemoteScenarioDetail> get(String id) {
    return _client.send(
      (dio) => dio.get<dynamic>('/scenarios/$id'),
      parse: (data) => RemoteScenarioDetail.fromJson(
        (data as Map).cast<String, dynamic>(),
      ),
    );
  }
}
