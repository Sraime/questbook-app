import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/io.dart';

import 'remote_table.dart';

/// Le canal est tombé et l'app retente. Portée jusqu'à l'écran plutôt que
/// ravalée : un joueur a le droit de savoir que ce qu'il regarde ne bouge
/// plus.
class BoardInterrupted implements Exception {
  const BoardInterrupted();

  @override
  String toString() => 'BoardInterrupted';
}

/// Le plateau d'une session, tel qu'il bouge sous les doigts du MJ.
///
/// Un canal temps réel plutôt qu'une interrogation périodique : un pion qu'on
/// voit bouger trois secondes après le MJ donne l'impression de regarder un
/// enregistrement, et une table qui joue ne supporte pas ce décalage.
///
/// Le serveur envoie le plateau entier à la connexion, puis un message par
/// poussée. Chacun porte l'état complet — le plateau est un état, pas un flux
/// d'événements — si bien qu'un message manqué n'a pas à être rattrapé : le
/// suivant porte tout ce qu'il portait.
class BoardLiveClient {
  BoardLiveClient({required this.origin});

  /// La racine de l'API, telle que la configuration la donne. Le schéma se
  /// traduit ici plutôt que d'être configuré deux fois : `https` devient
  /// `wss`, et une URL de développement en clair reste en clair.
  final String origin;

  static const _reconnectDelay = Duration(seconds: 2);

  /// Écoute le plateau jusqu'à ce que l'appelant se détourne.
  ///
  /// Se reconnecte tant qu'on l'écoute : un joueur qui traverse un couloir
  /// perd le réseau quelques secondes, et une partie ne s'interrompt pas pour
  /// autant. À chaque reconnexion le serveur renvoie le plateau entier, donc
  /// rien de ce qui s'est passé pendant la coupure n'est perdu.
  ///
  /// [accessToken] est relu à chaque tentative : un jeton a une durée de vie
  /// plus courte qu'une soirée de jeu, et celui qui a servi à ouvrir le
  /// premier socket peut être périmé à la troisième reconnexion.
  Stream<RemoteSessionBoard> watch(
    String sessionId, {
    required Future<String?> Function() accessToken,
  }) async* {
    while (true) {
      final token = await accessToken();
      // Sans jeton, rien à écouter : inutile de marteler le serveur.
      if (token == null) return;

      final messages = StreamController<RemoteSessionBoard>();
      IOWebSocketChannel? channel;

      try {
        channel = IOWebSocketChannel.connect(
          Uri.parse('$wsOrigin/api/v1/sessions/$sessionId/board/live'),
          headers: {'Authorization': 'Bearer $token'},
          // Sans cela, un réseau qui disparaît sans prévenir — un tunnel, un
          // Wi-Fi qui ne route plus — laisse le socket ouvert pour toujours
          // et le joueur regarde un plateau figé en croyant qu'il ne bouge
          // pas.
          pingInterval: const Duration(seconds: 20),
        );

        channel.stream.listen(
          (event) {
            final board = _decode(event);
            if (board != null) messages.add(board);
          },
          onError: (_) => messages.close(),
          onDone: messages.close,
          cancelOnError: true,
        );

        yield* messages.stream;
      } finally {
        await channel?.sink.close();
        await messages.close();
      }

      // Le canal est tombé. **On le dit avant de retenter**, au lieu de se
      // reconnecter en silence : un plateau qui se figera sans un mot se lit
      // comme un plateau que le MJ n'a pas touché, et c'est précisément ce
      // qu'un plateau partagé ne doit pas laisser croire. Le bandeau tombe de
      // lui-même à la reconnexion, que le serveur ouvre en renvoyant le
      // plateau entier.
      yield* Stream<RemoteSessionBoard>.error(const BoardInterrupted());

      // La boucle reprend après une pause : un serveur qui refuse la
      // connexion la refuserait tout autant si on la retentait aussitôt, en
      // boucle serrée.
      await Future<void>.delayed(_reconnectDelay);
    }
  }

  /// `https` devient `wss`, une URL de développement en clair reste en clair.
  String get wsOrigin => origin.startsWith('https')
      ? origin.replaceFirst('https', 'wss')
      : origin.replaceFirst('http', 'ws');

  /// Un message qu'on ne sait pas lire est ignoré, pas propagé en erreur : le
  /// serveur peut apprendre à dire autre chose avant que cette version de
  /// l'app ne soit à jour, et un plateau qui disparaîtrait pour un message
  /// inconnu serait pire que le même plateau une seconde de retard.
  RemoteSessionBoard? _decode(Object? event) {
    if (event is! String) return null;

    try {
      final decoded = jsonDecode(event);
      if (decoded is! Map) return null;
      if (decoded['type'] != 'board') return null;

      final board = decoded['board'];
      if (board is! Map) return null;

      return RemoteSessionBoard.fromJson(board.cast<String, dynamic>());
    } catch (_) {
      return null;
    }
  }
}
