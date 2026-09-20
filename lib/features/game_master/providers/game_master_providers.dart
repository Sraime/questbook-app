import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../app/remote_providers.dart';
import '../../../data/local/session_board_dao.dart';
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
