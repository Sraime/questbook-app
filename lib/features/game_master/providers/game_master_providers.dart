import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../app/remote_providers.dart';
import '../../../data/local/session_board_dao.dart';
import '../../../data/remote/api_exception.dart';
import '../../../data/remote/remote_table.dart';

final sessionBoardDaoProvider = Provider<SessionBoardDao>(
  (ref) => SessionBoardDao(ref.watch(appDatabaseProvider)),
);

/// Les personnages non-joueurs d'une session.
///
/// Rien n'en est gardé sur l'appareil, contrairement au plateau et aux notes :
/// ils vivent sur le serveur pour suivre le MJ d'un appareil à l'autre. Sans
/// réseau, le volet le dit plutôt que de faire semblant.
final sessionNpcsProvider =
    FutureProvider.family<List<RemoteNpc>, String>((ref, sessionId) {
  return ref.watch(sessionApiProvider).listNpcs(sessionId);
});

/// Remonte le plateau au serveur, pour les joueurs qui le regardent.
///
/// Rend `true` si le serveur a pris la poussée. Un échec n'est pas une panne :
/// **l'appareil du MJ garde la vérité**, il a déjà écrit en local, et une
/// soirée dans une cave sans réseau doit continuer de marcher. L'appelant note
/// qu'il reste quelque chose à pousser et réessaie quand le réseau revient.
Future<bool> pushSessionBoard(
  WidgetRef ref, {
  required String sessionId,
  required String tokens,
  String? mapId,
}) async {
  // Sans compte, personne à qui montrer le plateau : l'app tourne hors ligne.
  if (ref.read(authControllerProvider).value == null) return false;

  try {
    await ref
        .read(sessionApiProvider)
        .pushBoard(sessionId, tokens: tokens, mapId: mapId);
    return true;
  } on ApiException {
    return false;
  }
}
