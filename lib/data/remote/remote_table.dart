/// Wire format of the collaborative half of Questbook: tables, their members,
/// invitations, sessions and notifications.
///
/// Unlike characters, none of this is ever stored on the device, so these are
/// the only models the tables feature has — there is no domain counterpart to
/// map onto. Mapping stays hand-written, matching `remote_character.dart`.
library;

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
    required this.email,
    required this.displayName,
    required this.pictureUrl,
  });

  factory RemoteUser.fromJson(Map<String, dynamic> json) => RemoteUser(
        id: json['id'] as String,
        email: json['email'] as String,
        displayName: json['displayName'] as String?,
        pictureUrl: json['pictureUrl'] as String?,
      );

  final String id;
  final String email;
  final String? displayName;
  final String? pictureUrl;

  /// Players who never set a Google display name are still recognisable by
  /// the address their game master typed to invite them.
  String get label => displayName?.trim().isNotEmpty == true
      ? displayName!.trim()
      : email;
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

class RemoteGameTable {
  const RemoteGameTable({
    required this.id,
    required this.title,
    required this.universeLabel,
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
        universeLabel: json['universeLabel'] as String?,
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
  final String? universeLabel;
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

class RemoteAttendance {
  const RemoteAttendance({
    required this.userId,
    required this.status,
    required this.respondedAt,
    required this.user,
  });

  factory RemoteAttendance.fromJson(Map<String, dynamic> json) => RemoteAttendance(
        userId: json['userId'] as String,
        status: AttendanceStatus.parse(json['status'] as String),
        respondedAt: DateTime.parse(json['respondedAt'] as String).toLocal(),
        user: RemoteUser.fromJson((json['user'] as Map).cast<String, dynamic>()),
      );

  final String userId;
  final AttendanceStatus status;
  final DateTime respondedAt;
  final RemoteUser user;
}

class RemoteGameSession {
  const RemoteGameSession({
    required this.id,
    required this.tableId,
    required this.title,
    required this.description,
    required this.startsAt,
    required this.location,
    required this.status,
    required this.attendances,
    required this.myStatus,
  });

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

  bool get isCancelled => status == 'cancelled';

  bool get isPast => startsAt.isBefore(DateTime.now());

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
