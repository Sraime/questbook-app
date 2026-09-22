import 'package:url_launcher/url_launcher.dart';

/// Les pages légales, servies par Caddy sur le domaine public.
///
/// Elles ne sont pas embarquées dans l'app, et c'est délibéré : un texte
/// juridique recopié à deux endroits diverge, et c'est toujours la copie
/// qu'on lit qui a tort. Corriger une clause ne doit pas demander une
/// livraison sur les stores.
///
/// L'adresse ne suit **pas** `QUESTBOOK_API_URL`, contrairement au reste.
/// C'est un choix, et il s'est verifie a l'ecran : un poste de developpement
/// ne fait tourner que l'API Node, et les pages sont servies par Caddy, qui
/// n'y est pas. Les liens repondaient donc `Route not found` en local.
///
/// Les faire pointer ailleurs selon l'etape n'aurait de toute facon aucun
/// sens : ces deux textes engagent NextUs, ils sont les memes pour tout le
/// monde. Il n'existe pas de politique de confidentialite de developpement.
class LegalLinks {
  const LegalLinks._();

  static const String _host = 'https://questbook.nextuscorp.com';

  static Uri get terms => Uri.parse('$_host/conditions-utilisation');
  static Uri get privacy => Uri.parse('$_host/confidentialite');

  /// Ouvre la page dans le navigateur. Rend `false` si rien ne s'est ouvert,
  /// pour que l'appelant le dise plutôt que de laisser croire à un lien mort.
  static Future<bool> open(Uri page) {
    return launchUrl(page, mode: LaunchMode.externalApplication);
  }
}
