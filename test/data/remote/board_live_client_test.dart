import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:questbook/data/remote/board_live_client.dart';
import 'package:questbook/data/remote/remote_table.dart';

/// Un vrai serveur WebSocket, et non un canal simulé : ce que ces tests
/// vérifient est justement ce que fait le client quand la socket tombe, et une
/// socket qui tombe pour de bon n'est pas quelque chose qu'un faux imite bien.
class _Server {
  _Server(this._server);

  static Future<_Server> start() async =>
      _Server(await HttpServer.bind(InternetAddress.loopbackIPv4, 0));

  final HttpServer _server;

  String get origin => 'http://127.0.0.1:${_server.port}';

  final List<String?> tokens = [];

  /// Chaque connexion reçoit le plateau de la liste, dans l'ordre, puis la
  /// socket est fermée depuis le serveur — la coupure qu'on veut voir
  /// annoncée.
  void serve(List<String> boards) {
    var visit = 0;

    _server.listen((request) async {
      tokens.add(request.headers.value('authorization'));
      final socket = await WebSocketTransformer.upgrade(request);
      final board = boards[visit.clamp(0, boards.length - 1)];
      visit++;

      socket.add(jsonEncode({
        'type': 'board',
        'board': {'tokens': board, 'mapId': null, 'revision': visit},
      }));
      await socket.close();
    });
  }

  Future<void> stop() => _server.close(force: true);
}

/// Les [count] premiers événements du flux, erreurs comprises, puis on se
/// détourne. L'abonnement n'est pas attendu à l'annulation : le générateur
/// dort peut-être dans son délai de reconnexion, et rien n'oblige à attendre
/// son réveil pour conclure.
Future<List<Object>> firstEvents(
  Stream<RemoteSessionBoard> stream,
  int count,
) async {
  final seen = <Object>[];
  final enough = Completer<void>();

  void note(Object event) {
    seen.add(event);
    if (seen.length >= count && !enough.isCompleted) enough.complete();
  }

  final subscription = stream.listen(note, onError: note);
  await enough.future.timeout(const Duration(seconds: 20));
  unawaited(subscription.cancel());

  return seen;
}

void main() {
  test('un plateau qui tombe le dit, puis se rattrape', () async {
    final server = await _Server.start();
    addTearDown(server.stop);
    server.serve([
      '[]',
      '[{"id":"a","kind":"character","color":"red","x":0.5,"y":0.5}]',
    ]);

    final client = BoardLiveClient(origin: server.origin);

    // Le premier plateau, la chute annoncée, puis le plateau que la
    // reconnexion rapporte.
    final seen = await firstEvents(
      client.watch('session-1', accessToken: () async => 'jeton'),
      3,
    );

    expect(seen[0], isA<RemoteSessionBoard>());
    expect(
      seen[1],
      isA<BoardInterrupted>(),
      reason: 'sans cela le joueur regarde un plateau figé sans le savoir',
    );
    expect(seen[2], isA<RemoteSessionBoard>());
    expect((seen[2] as RemoteSessionBoard).tokens, contains('character'));
  });

  test('le jeton est relu à chaque tentative', () async {
    final server = await _Server.start();
    addTearDown(server.stop);
    server.serve(['[]']);

    var issued = 0;
    final client = BoardLiveClient(origin: server.origin);

    await firstEvents(
      client.watch(
        'session-1',
        accessToken: () async => 'jeton-${++issued}',
      ),
      3,
    );

    // Un jeton vit moins longtemps qu'une soirée de jeu : celui qui a ouvert
    // la première socket peut être périmé à la troisième reconnexion.
    expect(server.tokens, contains('Bearer jeton-1'));
    expect(server.tokens, contains('Bearer jeton-2'));
  });

  test('sans jeton, on n’écoute rien et on ne martèle pas le serveur',
      () async {
    final server = await _Server.start();
    addTearDown(server.stop);
    server.serve(['[]']);

    final client = BoardLiveClient(origin: server.origin);

    await expectLater(
      client.watch('session-1', accessToken: () async => null),
      emitsDone,
    );
    expect(server.tokens, isEmpty);
  });

  test('une URL sécurisée écoute en wss', () {
    expect(
      BoardLiveClient(origin: 'https://questbook.nextuscorp.com').wsOrigin,
      'wss://questbook.nextuscorp.com',
    );
    expect(
      BoardLiveClient(origin: 'http://10.0.2.2:3000').wsOrigin,
      'ws://10.0.2.2:3000',
    );
  });
}
