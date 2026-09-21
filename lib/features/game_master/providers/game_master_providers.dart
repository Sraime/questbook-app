import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../app/remote_providers.dart';
import '../../../config/app_config.dart';
import '../../../data/local/session_board_dao.dart';
import '../../../data/remote/api_exception.dart';
import '../../../data/remote/board_live_client.dart';
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

final boardLiveClientProvider = Provider<BoardLiveClient>(
  (ref) => BoardLiveClient(origin: AppConfig.apiBaseUrl),
);

/// Le plateau d'une session, tel que le MJ le dispose en ce moment.
///
/// Ce que regarde un joueur venu participer. Deux sources pour un seul flux :
///
/// 1. **Un appel HTTP d'abord.** Il donne un plateau à montrer tout de suite,
///    et surtout il rafraîchit le jeton si besoin — la poignée de main d'un
///    socket n'a pas d'intercepteur pour le faire à sa place. Si le canal
///    temps réel est bloqué par un réseau d'entreprise, le joueur voit au
///    moins le plateau de son arrivée.
/// 2. **Le canal ensuite**, qui renvoie le plateau entier puis chaque
///    poussée.
///
/// `autoDispose` : le socket se ferme en quittant le volet. Personne ne
/// regarde un plateau depuis un écran qu'il a fermé.
final liveSessionBoardProvider = StreamProvider.autoDispose
    .family<RemoteSessionBoard, String>((ref, sessionId) async* {
  final api = ref.watch(sessionApiProvider);

  try {
    yield await api.board(sessionId);
  } on ApiException catch (error) {
    // Un refus définitif — pas membre, session disparue — n'a pas à être
    // retenté par le socket juste après.
    if (!error.isRetryable) rethrow;
  }

  yield* ref.watch(boardLiveClientProvider).watch(
        sessionId,
        accessToken: () async =>
            (await ref.read(tokenStoreProvider).read())?.accessToken,
      );
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
