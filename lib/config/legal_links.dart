import 'package:url_launcher/url_launcher.dart';

import 'app_config.dart';

/// Les pages légales, servies par Caddy sur le domaine de l'API.
///
/// Elles ne sont pas embarquées dans l'app, et c'est délibéré : un texte
/// juridique recopié à deux endroits diverge, et c'est toujours la copie
/// qu'on lit qui a tort. Corriger une clause ne doit pas demander une
/// livraison sur les stores.
///
/// L'adresse suit `QUESTBOOK_API_URL`, si bien qu'un poste de développement
/// ouvre ses propres pages plutôt que celles du VPS.
class LegalLinks {
  const LegalLinks._();

  static Uri get terms => _page('conditions-utilisation');
  static Uri get privacy => _page('confidentialite');

  static Uri _page(String slug) {
    final base = Uri.parse(AppConfig.apiBaseUrl);
    return base.replace(path: '/$slug', query: null, fragment: null);
  }

  /// Ouvre la page dans le navigateur. Rend `false` si rien ne s'est ouvert,
  /// pour que l'appelant le dise plutôt que de laisser croire à un lien mort.
  static Future<bool> open(Uri page) {
    return launchUrl(page, mode: LaunchMode.externalApplication);
  }
}
