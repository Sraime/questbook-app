import 'api_client.dart';

/// Ce que le blocage vient de défaire. Le serveur le compte parce que lui
/// seul sait à quelles tables les deux comptes se croisaient : l'app n'en
/// connaît qu'une, celle d'où part le geste.
class BlockOutcome {
  const BlockOutcome({
    required this.tablesLeft,
    required this.playersRemoved,
  });

  factory BlockOutcome.fromJson(Map<String, dynamic> json) => BlockOutcome(
        tablesLeft: json['tablesLeft'] as int,
        playersRemoved: json['playersRemoved'] as int,
      );

  /// Tables qu'on vient de quitter, n'y étant que joueur.
  final int tablesLeft;

  /// Tables dont l'autre a été retiré, parce qu'on les mène.
  final int playersRemoved;
}

/// Un seul geste, et rien pour le défaire : le blocage est définitif, ici
/// comme sur le serveur. Ce qu'il promet, c'est de ne plus croiser
/// quelqu'un, et une promesse qu'on retire d'un bouton n'en est pas une.
class BlockApi {
  BlockApi(this._client);

  final ApiClient _client;

  /// Bloquer est idempotent, mais ses conséquences se rejouent : c'est
  /// voulu, une table rejointe depuis le premier blocage doit se défaire
  /// comme les autres.
  Future<BlockOutcome> block(String userId) {
    return _client.send(
      (dio) => dio.post<dynamic>('/blocks', data: {'userId': userId}),
      parse: (data) => BlockOutcome.fromJson((data as Map).cast<String, dynamic>()),
    );
  }
}
