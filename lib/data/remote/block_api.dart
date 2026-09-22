import 'api_client.dart';

/// Quelqu'un qu'on a bloqué, tel qu'il reste lisible dans le profil : sans
/// son nom, la liste ne servirait qu'à compter, jamais à débloquer.
class BlockedUser {
  const BlockedUser({
    required this.userId,
    required this.displayName,
    required this.pictureUrl,
    required this.blockedAt,
  });

  factory BlockedUser.fromJson(Map<String, dynamic> json) => BlockedUser(
        userId: json['userId'] as String,
        displayName: json['displayName'] as String,
        pictureUrl: json['pictureUrl'] as String?,
        blockedAt: DateTime.parse(json['blockedAt'] as String),
      );

  final String userId;
  final String displayName;
  final String? pictureUrl;
  final DateTime blockedAt;
}

/// Ce que le blocage vient de défaire. Le serveur le compte parce que lui
/// seul sait à quelles tables les deux comptes se croisaient : l'app n'en
/// connaît qu'une, celle d'où part le geste.
class BlockOutcome {
  const BlockOutcome({
    required this.user,
    required this.tablesLeft,
    required this.playersRemoved,
  });

  factory BlockOutcome.fromJson(Map<String, dynamic> json) => BlockOutcome(
        user: BlockedUser.fromJson((json['block'] as Map).cast<String, dynamic>()),
        tablesLeft: json['tablesLeft'] as int,
        playersRemoved: json['playersRemoved'] as int,
      );

  final BlockedUser user;

  /// Tables qu'on vient de quitter, n'y étant que joueur.
  final int tablesLeft;

  /// Tables dont l'autre a été retiré, parce qu'on les mène.
  final int playersRemoved;
}

class BlockApi {
  BlockApi(this._client);

  final ApiClient _client;

  Future<List<BlockedUser>> list() {
    return _client.send(
      (dio) => dio.get<dynamic>('/blocks'),
      parse: (data) => ((data as Map)['blocks'] as List<dynamic>)
          .map((raw) => BlockedUser.fromJson((raw as Map).cast<String, dynamic>()))
          .toList(),
    );
  }

  /// Bloquer est idempotent, mais ses conséquences se rejouent : c'est
  /// voulu, une table rejointe depuis le premier blocage doit se défaire
  /// comme les autres.
  Future<BlockOutcome> block(String userId) {
    return _client.send(
      (dio) => dio.post<dynamic>('/blocks', data: {'userId': userId}),
      parse: (data) => BlockOutcome.fromJson((data as Map).cast<String, dynamic>()),
    );
  }

  /// Débloquer ne rend rien : les tables quittées le restent, et il faudra
  /// une nouvelle invitation.
  Future<void> unblock(String userId) {
    return _client.send(
      (dio) => dio.delete<dynamic>('/blocks/$userId'),
      parse: (_) {},
    );
  }
}
