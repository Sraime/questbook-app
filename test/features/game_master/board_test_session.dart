import 'package:flutter_riverpod/misc.dart';
import 'package:questbook/data/remote/remote_table.dart';
import 'package:questbook/features/game_master/providers/game_master_providers.dart';

/// La session sous un plateau de test : personne d'inscrit par défaut.
RemoteGameSession boardTestSession({
  List<RemoteAttendance> attendances = const [],
}) =>
    RemoteGameSession(
      id: 'session-1',
      tableId: 'table-1',
      title: 'Chapitre III — Les ruines',
      description: null,
      startsAt: DateTime.utc(2026, 9, 19, 20),
      location: 'Chez Marie',
      status: 'scheduled',
      attendances: attendances,
      myStatus: null,
      myCharacter: null,
      scenarioId: null,
      scenario: null,
    );

/// Les PNJ de cette session, sans passer par le réseau.
Override boardTestNpcs([List<RemoteNpc> npcs = const []]) =>
    sessionNpcsProvider.overrideWith((ref, sessionId) async => npcs);
