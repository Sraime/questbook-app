import 'api_client.dart';

/// Ce qu'un joueur peut signaler. Chaque valeur correspond à un endroit où du
/// texte écrit par quelqu'un d'autre s'affiche sous ses yeux.
enum ReportableContent {
  user('user'),
  table('table'),
  session('session'),
  investigator('investigator');

  const ReportableContent(this.wireName);

  final String wireName;
}

class ReportApi {
  ReportApi(this._client);

  final ApiClient _client;

  /// L'app ne dit que ce qu'elle vise et ce qu'on lui reproche. Ni l'auteur
  /// du contenu ni la copie de ce qu'il disait ne partent d'ici : le serveur
  /// relit la cible lui-même, faute de quoi un signalement se forgerait.
  ///
  /// Répond `409` quand ce contenu a déjà été signalé par ce compte, et
  /// `404` quand il est hors de sa portée.
  Future<void> report({
    required ReportableContent contentType,
    required String contentId,
    required String reason,
  }) {
    return _client.send(
      (dio) => dio.post<dynamic>(
        '/reports',
        data: {
          'contentType': contentType.wireName,
          'contentId': contentId,
          'reason': reason,
        },
      ),
      parse: (_) {},
    );
  }
}
