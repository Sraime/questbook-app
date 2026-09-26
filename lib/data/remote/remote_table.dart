/// Wire format of the collaborative half of Questbook: tables, their members,
/// invitations, sessions and notifications.
///
/// Unlike characters, none of this is ever stored on the device, so these are
/// the only models the tables feature has — there is no domain counterpart to
/// map onto. Mapping stays hand-written, matching `remote_character.dart`.
library;

import 'remote_scenario.dart';

/// Absente d'une réponse mise en cache par une version d'avant le champ.
DateTime? _dateOrNull(Object? raw) =>
    raw is String ? DateTime.parse(raw).toLocal() : null;

List<T> _listOf<T>(Object? raw, T Function(Map<String, dynamic>) parse) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((entry) => parse(entry.cast<String, dynamic>()))
      .toList(growable: false);
}

/// Who a member, inviter or respondent is, as far as the UI needs to know.
class RemoteUser {
  const RemoteUser({
    required this.id,
    this.email,
    required this.displayName,
    required this.pictureUrl,
  });

  factory RemoteUser.fromJson(Map<String, dynamic> json) => RemoteUser(
        id: json['id'] as String,
        email: json['email'] as String?,
        displayName: json['displayName'] as String?,
        pictureUrl: json['pictureUrl'] as String?,
      );

  final String id;

  /// Present only for the signed-in user. Other members never carry an email.
  final String? email;
  final String? displayName;
  final String? pictureUrl;

  /// Must never fall back to [email]: that address is the signed-in user's
  /// own mailbox, not a public handle, and other members do not send one.
  String get label {
    final name = displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return 'Joueur';
  }
}

enum TableRole {
  gameMaster,
  player;

  static TableRole parse(String raw) =>
      raw == 'gm' ? TableRole.gameMaster : TableRole.player;

  bool get isGameMaster => this == TableRole.gameMaster;
}

class RemoteTableMember {
  const RemoteTableMember({
    required this.userId,
    required this.role,
    required this.joinedAt,
    required this.user,
  });

  factory RemoteTableMember.fromJson(Map<String, dynamic> json) =>
      RemoteTableMember(
        userId: json['userId'] as String,
        role: TableRole.parse(json['role'] as String),
        joinedAt: DateTime.parse(json['joinedAt'] as String),
        user: RemoteUser.fromJson((json['user'] as Map).cast<String, dynamic>()),
      );

  final String userId;
  final TableRole role;
  final DateTime joinedAt;
  final RemoteUser user;
}

class RemoteTableInvitation {
  const RemoteTableInvitation({
    required this.id,
    required this.tableId,
    required this.tableTitle,
    required this.email,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    required this.invitedBy,
  });

  factory RemoteTableInvitation.fromJson(Map<String, dynamic> json) =>
      RemoteTableInvitation(
        id: json['id'] as String,
        tableId: json['tableId'] as String,
        tableTitle: json['tableTitle'] as String,
        email: json['email'] as String,
        status: json['status'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        expiresAt: DateTime.parse(json['expiresAt'] as String),
        invitedBy: RemoteUser.fromJson(
          (json['invitedBy'] as Map).cast<String, dynamic>(),
        ),
      );

  final String id;
  final String tableId;
  final String tableTitle;
  final String email;
  final String status;
  final DateTime createdAt;
  final DateTime expiresAt;
  final RemoteUser invitedBy;
}

/// The server still returns a `universeLabel` on tables created before the app
/// became Call of Cthulhu only: it is deliberately left unread.
class RemoteGameTable {
  const RemoteGameTable({
    required this.id,
    required this.title,
    required this.ownerId,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
    required this.members,
    required this.pendingInvitations,
    required this.nextSessionAt,
  });

  factory RemoteGameTable.fromJson(Map<String, dynamic> json) => RemoteGameTable(
        id: json['id'] as String,
        title: json['title'] as String,
        ownerId: json['ownerId'] as String,
        role: TableRole.parse(json['role'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        members: _listOf(json['members'], RemoteTableMember.fromJson),
        pendingInvitations: _listOf(
          json['pendingInvitations'],
          RemoteTableInvitation.fromJson,
        ),
        nextSessionAt: json['nextSessionAt'] == null
            ? null
            : DateTime.parse(json['nextSessionAt'] as String).toLocal(),
      );

  final String id;
  final String title;
  final String ownerId;

  /// The signed-in user's own role, sent by the server so the UI never has to
  /// work out who it is looking at.
  final TableRole role;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<RemoteTableMember> members;

  /// Always empty for a player: only the game master handles invitations.
  final List<RemoteTableInvitation> pendingInvitations;
  final DateTime? nextSessionAt;

  bool get isGameMaster => role.isGameMaster;
}

enum AttendanceStatus {
  yes,
  no;

  static AttendanceStatus parse(String raw) =>
      raw == 'yes' ? AttendanceStatus.yes : AttendanceStatus.no;

  String get wire => this == AttendanceStatus.yes ? 'yes' : 'no';
}

/// Just enough of a character to name it in the answers list. The full sheet is
/// fetched separately when someone asks to see it.
class RemoteAttendanceCharacter {
  const RemoteAttendanceCharacter({
    required this.id,
    required this.name,
    required this.occupation,
  });

  factory RemoteAttendanceCharacter.fromJson(Map<String, dynamic> json) =>
      RemoteAttendanceCharacter(
        id: json['id'] as String,
        name: json['name'] as String,
        occupation: json['occupation'] as String?,
      );

  final String id;
  final String name;
  final String? occupation;
}

class RemoteAttendance {
  const RemoteAttendance({
    required this.userId,
    required this.status,
    required this.respondedAt,
    required this.user,
    required this.character,
  });

  factory RemoteAttendance.fromJson(Map<String, dynamic> json) => RemoteAttendance(
        userId: json['userId'] as String,
        status: AttendanceStatus.parse(json['status'] as String),
        respondedAt: DateTime.parse(json['respondedAt'] as String).toLocal(),
        user: RemoteUser.fromJson((json['user'] as Map).cast<String, dynamic>()),
        character: json['character'] == null
            ? null
            : RemoteAttendanceCharacter.fromJson(
                (json['character'] as Map).cast<String, dynamic>(),
              ),
      );

  final String userId;
  final AttendanceStatus status;
  final DateTime respondedAt;
  final RemoteUser user;

  /// Who they are playing, once they have said. Confirming and choosing a
  /// character are two separate moments.
  final RemoteAttendanceCharacter? character;
}

/// Tout ce qui est à la table sans être un joueur : créature, indicateur,
/// esprit. Un nom, une description libre, et rien d'autre — ce n'est pas une
/// fiche d'investigateur.
///
/// Attaché à une session et lisible du seul MJ : le serveur ne le renvoie
/// jamais dans le détail d'une session, il faut aller le chercher.
class RemoteNpc {
  const RemoteNpc({
    required this.id,
    required this.name,
    required this.description,
    this.origin = 'gameMaster',
  });

  factory RemoteNpc.fromJson(Map<String, dynamic> json) => RemoteNpc(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        origin: json['origin'] as String? ?? 'gameMaster',
      );

  final String id;
  final String name;
  final String description;

  /// `scenario` ou `gameMaster`. Une séance joue les deux à la fois : ce que
  /// l'aventure livre, et ce que le MJ a écrit.
  final String origin;

  /// Ce qui vient du scénario appartient à son auteur : le MJ le joue, il ne
  /// le réécrit pas.
  bool get isEditable => origin != 'scenario';
}

/// Un indice tel que le MJ le voit : son contenu, et à qui il l'a ouvert.
///
/// L'inverse du PNJ ci-dessus. Préparé de la même façon, mais destiné à passer
/// de l'autre côté de l'écran — un par un, et seulement à ceux que le MJ
/// désigne. [sharedWith] vide est l'état de repos, pas un cas limite.
class RemoteClue {
  const RemoteClue({
    required this.id,
    required this.title,
    required this.kind,
    required this.contentMarkdown,
    required this.sharedWith,
    this.origin = 'gameMaster',
  });

  factory RemoteClue.fromJson(Map<String, dynamic> json) => RemoteClue(
        id: json['id'] as String,
        title: json['title'] as String,
        kind: json['kind'] as String? ?? 'markdown',
        contentMarkdown: json['contentMarkdown'] as String? ?? '',
        sharedWith: (json['sharedWith'] as List? ?? const [])
            .whereType<String>()
            .toList(growable: false),
        origin: json['origin'] as String? ?? 'gameMaster',
      );

  final String id;
  final String title;
  final String kind;
  final String contentMarkdown;
  final List<String> sharedWith;

  /// `scenario` ou `gameMaster`. Le partage marche pareil des deux côtés —
  /// c'est la raison d'être d'un indice livré avec l'aventure.
  final String origin;

  bool get isFromScenario => origin == 'scenario';

  /// Ce qui vient du scénario appartient à son auteur, et le MJ ne compose
  /// que du markdown : une image vient elle aussi d'ailleurs.
  bool get isEditable => !isFromScenario && kind == 'markdown';
}

/// Un indice tel qu'un joueur le reçoit. Volontairement pas [RemoteClue] avec
/// un champ en moins : la liste des destinataires n'existe pas de ce côté, et
/// un type partagé finirait par la transporter vide plutôt qu'absente.
class RemoteSharedClue {
  const RemoteSharedClue({
    required this.id,
    required this.title,
    required this.kind,
    required this.contentMarkdown,
  });

  factory RemoteSharedClue.fromJson(Map<String, dynamic> json) =>
      RemoteSharedClue(
        id: json['id'] as String,
        title: json['title'] as String,
        kind: json['kind'] as String? ?? 'markdown',
        contentMarkdown: json['contentMarkdown'] as String? ?? '',
      );

  final String id;
  final String title;
  final String kind;
  final String contentMarkdown;
}

/// Le plateau d'une session tel que le serveur le détient : la carte et les
/// pions, comme le MJ les a poussés la dernière fois.
///
/// L'exact inverse du PNJ ci-dessus quant aux droits : tout membre de la table
/// le lit, seul le MJ l'écrit. Un plateau est fait pour être vu.
///
/// [tokens] reste la chaîne JSON opaque que l'app garde déjà en local, si bien
/// qu'ajouter un champ à un pion ne demande rien au serveur. [revision] monte
/// de un à chaque poussée et sert à écarter un message arrivé en retard.
class RemoteSessionBoard {
  const RemoteSessionBoard({
    required this.tokens,
    required this.mapId,
    required this.revision,
  });

  factory RemoteSessionBoard.fromJson(Map<String, dynamic> json) =>
      RemoteSessionBoard(
        tokens: json['tokens'] as String? ?? '[]',
        mapId: json['mapId'] as String?,
        revision: json['revision'] as int? ?? 0,
      );

  /// Ce que répond le serveur quand rien n'a encore été posé, et ce qu'on
  /// affiche tant qu'on n'a pas pu le lui demander.
  static const empty = RemoteSessionBoard(
    tokens: '[]',
    mapId: null,
    revision: 0,
  );

  final String tokens;
  final String? mapId;
  final int revision;
}

class RemoteGameSession {
  /// Non `const` : les deux bornes se calculent à partir de [startsAt] quand
  /// le serveur ne les a pas envoyées.
  RemoteGameSession({
    required this.id,
    required this.tableId,
    required this.title,
    required this.description,
    required this.startsAt,
    required this.location,
    required this.status,
    required this.attendances,
    required this.myStatus,
    required this.myCharacter,
    this.scenarioId,
    this.scenario,
    DateTime? closesAt,
    DateTime? answersCloseAt,
  })  : closesAt = closesAt ?? startsAt.add(const Duration(hours: 24)),
        answersCloseAt = answersCloseAt ?? startsAt;

  factory RemoteGameSession.fromJson(Map<String, dynamic> json) => RemoteGameSession(
        id: json['id'] as String,
        tableId: json['tableId'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        startsAt: DateTime.parse(json['startsAt'] as String).toLocal(),
        location: json['location'] as String,
        status: json['status'] as String,
        attendances: _listOf(json['attendances'], RemoteAttendance.fromJson),
        myStatus: json['myStatus'] == null
            ? null
            : AttendanceStatus.parse(json['myStatus'] as String),
        myCharacter: json['myCharacter'] == null
            ? null
            : RemoteAttendanceCharacter.fromJson(
                (json['myCharacter'] as Map).cast<String, dynamic>(),
              ),
        scenarioId: json['scenarioId'] as String?,
        scenario: json['scenario'] == null
            ? null
            : RemoteSessionScenario.fromJson(
                (json['scenario'] as Map).cast<String, dynamic>(),
              ),
        closesAt: _dateOrNull(json['closesAt']),
        answersCloseAt: _dateOrNull(json['answersCloseAt']),
      );

  final String id;
  final String tableId;
  final String title;
  final String? description;
  final DateTime startsAt;
  final String location;
  final String status;
  final List<RemoteAttendance> attendances;

  /// Null while the signed-in member has not answered, which is deliberately
  /// different from having answered "no".
  final AttendanceStatus? myStatus;

  /// The character the signed-in member is bringing, once they have said.
  final RemoteAttendanceCharacter? myCharacter;

  final String? scenarioId;
  final RemoteSessionScenario? scenario;

  /// Les deux bornes de la séance, calculées par le serveur et lues telles
  /// quelles : la règle lui appartient, et deux implémentations finiraient par
  /// diverger.
  ///
  /// Absentes d'une réponse mise en cache par une version d'avant la règle, le
  /// constructeur retombe alors sur le début de la séance — et pour
  /// [closesAt], sur la fenêtre que le serveur y ajoute aujourd'hui.
  final DateTime closesAt;
  final DateTime answersCloseAt;

  bool get isCancelled => status == 'cancelled';

  bool get isPast => closesAt.isBefore(DateTime.now());

  /// La séance a commencé mais n'est pas finie : c'est le moment de l'animer.
  bool get isUnderway =>
      !isCancelled && !isPast && startsAt.isBefore(DateTime.now());

  /// Un joueur peut encore dire s'il vient.
  bool get acceptsAnswers =>
      !isCancelled && answersCloseAt.isAfter(DateTime.now());

  List<RemoteAttendance> get accepted =>
      attendances.where((a) => a.status == AttendanceStatus.yes).toList();

  List<RemoteAttendance> get declined =>
      attendances.where((a) => a.status == AttendanceStatus.no).toList();
}

class RemoteNotification {
  const RemoteNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.tableId,
    required this.sessionId,
    required this.readAt,
    required this.createdAt,
  });

  factory RemoteNotification.fromJson(Map<String, dynamic> json) =>
      RemoteNotification(
        id: json['id'] as String,
        type: json['type'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        tableId: json['tableId'] as String?,
        sessionId: json['sessionId'] as String?,
        readAt: json['readAt'] == null
            ? null
            : DateTime.parse(json['readAt'] as String).toLocal(),
        createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      );

  final String id;
  final String type;
  final String title;
  final String body;
  final String? tableId;
  final String? sessionId;
  final DateTime? readAt;
  final DateTime createdAt;

  bool get isUnread => readAt == null;
}

/// `GET /notifications` returns the badge count alongside the list, so the
/// navigation bar never needs a second round trip.
class RemoteNotificationPage {
  const RemoteNotificationPage({
    required this.notifications,
    required this.unreadCount,
  });

  factory RemoteNotificationPage.fromJson(Map<String, dynamic> json) =>
      RemoteNotificationPage(
        notifications: _listOf(json['notifications'], RemoteNotification.fromJson),
        unreadCount: json['unreadCount'] as int? ?? 0,
      );

  final List<RemoteNotification> notifications;
  final int unreadCount;
}
