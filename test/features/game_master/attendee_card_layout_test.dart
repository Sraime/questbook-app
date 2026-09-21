import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:questbook/data/remote/remote_character.dart';
import 'package:questbook/data/remote/remote_table.dart';
import 'package:questbook/design_system/components/qb_badge.dart';
import 'package:questbook/features/game_master/models/session_seat.dart';
import 'package:questbook/features/game_master/panels/characters_panel.dart';
import 'package:questbook/features/tables/providers/table_providers.dart';

/// Une fiche telle que l'API la rend : trois jauges et un nom qui ne tient pas
/// à côté d'elles sur un téléphone.
final _ernest = RemoteCharacter(
  id: 'char-1',
  systemId: 'call_of_cthulhu_classique',
  name: 'Ernest Lavoie',
  occupation: 'Détective privé',
  description: null,
  level: 1,
  createdAt: DateTime.utc(2026, 9, 1),
  updatedAt: DateTime.utc(2026, 9, 1),
  deletedAt: null,
  stats: const [
    RemoteStat(
      id: 'stat-1',
      kind: 'skill',
      key: 'psychologie',
      label: 'Psychologie',
      value: 60,
      base: null,
      sortOrder: 0,
    ),
  ],
  resources: const [
    RemoteResource(
      id: 'res-1',
      key: 'hp',
      label: 'PV',
      current: 13,
      max: 13,
      tone: 'danger',
    ),
    RemoteResource(
      id: 'res-2',
      key: 'san',
      label: 'SAN',
      current: 50,
      max: 50,
      tone: 'info',
    ),
    RemoteResource(
      id: 'res-3',
      key: 'mp',
      label: 'PM',
      current: 10,
      max: 10,
      tone: 'warning',
    ),
  ],
  inventory: const [],
);

final _session = RemoteGameSession(
  id: 'session-1',
  tableId: 'table-1',
  title: 'La maison de Water Street',
  description: null,
  startsAt: DateTime.utc(2026, 9, 21, 14, 25),
  location: 'Chez Hélène',
  status: 'scheduled',
  attendances: [
    RemoteAttendance(
      userId: 'user-2',
      user: const RemoteUser(
        id: 'user-2',
        displayName: 'Questbook',
        pictureUrl: null,
      ),
      status: AttendanceStatus.yes,
      respondedAt: DateTime.utc(2026, 9, 21, 14),
      character: const RemoteAttendanceCharacter(
        id: 'char-1',
        name: 'Ernest Lavoie',
        occupation: 'Détective privé',
      ),
    ),
  ],
  myStatus: AttendanceStatus.yes,
  myCharacter: const RemoteAttendanceCharacter(
    id: 'char-1',
    name: 'Ernest Lavoie',
    occupation: 'Détective privé',
  ),
  scenarioId: null,
  scenario: null,
);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> pumpPanel(WidgetTester tester, {required Size size}) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          attendeeCharacterProvider.overrideWith((ref, key) async => _ernest),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: CharactersPanel(
              session: _session,
              seat: SessionSeat.player,
              compact: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Le volet n'était lu que sur la tablette d'un MJ avant que les joueurs
  /// puissent participer à une séance. Sur un téléphone, les trois jauges
  /// prenaient toute la ligne et ne laissaient au nom qu'une colonne d'une
  /// lettre de large, en débordant quand même.
  testWidgets('sur un téléphone, la fiche d’un joueur ne déborde pas',
      (tester) async {
    await pumpPanel(tester, size: const Size(411, 890));

    expect(tester.takeException(), isNull);

    final name = find.text('Ernest Lavoie');
    expect(name, findsOneWidget);
    expect(
      tester.getRect(name).height,
      lessThan(32),
      reason: 'un nom sur une seule ligne, pas une lettre par ligne',
    );
  });

  /// Les jauges passent sous l'identité plutôt que de lui disputer sa ligne,
  /// comme sur la fiche que le joueur ouvre depuis l'accueil.
  testWidgets('les jauges se rangent sous le nom', (tester) async {
    await pumpPanel(tester, size: const Size(411, 890));

    final name = find.text('Ernest Lavoie');
    final gauge = find.byType(QBBadge).first;

    expect(
      tester.getRect(gauge).top,
      greaterThanOrEqualTo(tester.getRect(name).bottom),
    );
  });

  testWidgets('sur un grand écran non plus', (tester) async {
    await pumpPanel(tester, size: const Size(1000, 1400));

    expect(tester.takeException(), isNull);
    expect(find.text('Ernest Lavoie'), findsOneWidget);
    expect(find.byType(QBBadge), findsNWidgets(3));
  });
}
