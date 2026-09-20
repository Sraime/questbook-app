import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:questbook/app/remote_providers.dart';
import 'package:questbook/data/remote/remote_table.dart';
import 'package:questbook/features/tables/providers/table_providers.dart';
import 'package:questbook/features/tables/table_detail_screen.dart';

/// Une séance ne s'éteint pas à l'heure dite : on joue, et la partie déborde.
/// Ces tests fixent les deux bornes que le serveur envoie — jusqu'où elle
/// reste à animer, et jusqu'où on s'y inscrit.
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  final now = DateTime.now();

  RemoteGameTable tableFor(TableRole role) => RemoteGameTable(
        id: 'table-1',
        title: 'Les ombres d’Arkham',
        ownerId: 'gm-1',
        role: role,
        createdAt: now,
        updatedAt: now,
        members: [
          RemoteTableMember(
            userId: 'gm-1',
            role: TableRole.gameMaster,
            joinedAt: now,
            user: const RemoteUser(
              id: 'gm-1',
              displayName: 'Marie',
              pictureUrl: null,
            ),
          ),
        ],
        pendingInvitations: const [],
        nextSessionAt: null,
      );

  RemoteGameSession sessionAt({
    required Duration startsIn,
    DateTime? answersCloseAt,
    AttendanceStatus? myStatus,
  }) {
    final startsAt = now.add(startsIn);
    return RemoteGameSession(
      id: 'session-1',
      tableId: 'table-1',
      title: 'Chapitre III — Les ruines',
      description: null,
      startsAt: startsAt,
      location: 'Chez Marie',
      status: 'scheduled',
      attendances: const [],
      myStatus: myStatus,
      myCharacter: null,
      scenarioId: null,
      scenario: null,
      closesAt: startsAt.add(const Duration(hours: 24)),
      answersCloseAt: answersCloseAt ?? startsAt,
    );
  }

  Future<void> pumpTable(
    WidgetTester tester, {
    required RemoteGameSession session,
    TableRole role = TableRole.gameMaster,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 800);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          canWriteProvider.overrideWithValue(true),
          tableDetailProvider.overrideWith(
            (ref, tableId) async =>
                TableDetail(table: tableFor(role), sessions: [session]),
          ),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/tables/table-1',
            routes: [
              GoRoute(
                path: '/tables/:id',
                builder: (context, state) =>
                    const TableDetailScreen(tableId: 'table-1'),
              ),
              GoRoute(
                path: '/tables/:id/sessions/:sessionId/mj',
                builder: (context, state) =>
                    const Scaffold(body: Text('mode mj')),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('Jusqu’où la séance reste à animer', () {
    test('elle vit encore deux heures après son début', () {
      final session = sessionAt(startsIn: const Duration(hours: -2));

      expect(session.isPast, isFalse);
      expect(session.isUnderway, isTrue);
    });

    test('elle bascule dans le passé au bout de vingt-quatre heures', () {
      final session = sessionAt(startsIn: const Duration(hours: -25));

      expect(session.isPast, isTrue);
      expect(session.isUnderway, isFalse);
    });

    test('une séance annulée ne s’anime pas, même à son heure', () {
      final startsAt = now.subtract(const Duration(hours: 1));
      final session = RemoteGameSession(
        id: 'session-1',
        tableId: 'table-1',
        title: 'Chapitre III',
        description: null,
        startsAt: startsAt,
        location: 'Chez Marie',
        status: 'cancelled',
        attendances: const [],
        myStatus: null,
        myCharacter: null,
        closesAt: startsAt.add(const Duration(hours: 24)),
        answersCloseAt: startsAt,
      );

      expect(session.isUnderway, isFalse);
      expect(session.acceptsAnswers, isFalse);
    });

    testWidgets('le MJ peut encore l’animer en pleine partie', (tester) async {
      await pumpTable(
        tester,
        session: sessionAt(startsIn: const Duration(hours: -2)),
      );

      expect(find.bySemanticsLabel(RegExp('Animer la session')), findsOneWidget);
    });

    testWidgets('elle rejoint les séances passées au bout de vingt-quatre '
        'heures', (tester) async {
      await pumpTable(
        tester,
        session: sessionAt(startsIn: const Duration(hours: -25)),
      );

      expect(find.text('Sessions passées'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('Animer la session')), findsNothing);
    });
  });

  group('Jusqu’où les joueurs s’inscrivent', () {
    testWidgets('avant le début, les deux boutons sont là', (tester) async {
      await pumpTable(
        tester,
        role: TableRole.player,
        session: sessionAt(startsIn: const Duration(days: 2)),
      );

      expect(find.text('Je viens'), findsOneWidget);
      expect(find.text('Je passe'), findsOneWidget);
    });

    testWidgets('la partie commencée, ils cèdent la place à une explication',
        (tester) async {
      await pumpTable(
        tester,
        role: TableRole.player,
        session: sessionAt(
          startsIn: const Duration(hours: -2),
          myStatus: AttendanceStatus.yes,
        ),
      );

      expect(find.text('Je viens'), findsNothing);
      expect(find.text('Je passe'), findsNothing);
      expect(
        find.textContaining('La partie a commencé'),
        findsOneWidget,
        reason: 'des boutons qui disparaissent sans un mot se cherchent',
      );
      expect(find.textContaining('Tu as dit que tu venais'), findsOneWidget);
    });

    testWidgets('une séance proposée pour tout de suite laisse une heure',
        (tester) async {
      // « Il est 18h, on joue à 18h30 ? » : le serveur repousse la fermeture
      // à une heure après la création, sans quoi le retardataire n'aurait
      // jamais le temps de répondre.
      await pumpTable(
        tester,
        role: TableRole.player,
        session: sessionAt(
          startsIn: const Duration(minutes: -5),
          answersCloseAt: now.add(const Duration(minutes: 50)),
        ),
      );

      expect(find.text('Je viens'), findsOneWidget);
    });
  });

  group('Une réponse mise en cache par une version d’avant la règle', () {
    test('retombe sur les bornes d’aujourd’hui', () {
      final startsAt = now.subtract(const Duration(hours: 2));
      final session = RemoteGameSession.fromJson({
        'id': 'session-1',
        'tableId': 'table-1',
        'title': 'Chapitre III',
        'description': null,
        'startsAt': startsAt.toUtc().toIso8601String(),
        'location': 'Chez Marie',
        'status': 'scheduled',
        'attendances': const [],
        'myStatus': null,
        'myCharacter': null,
      });

      expect(session.closesAt, startsAt.add(const Duration(hours: 24)));
      expect(session.answersCloseAt, startsAt);
      expect(session.isUnderway, isTrue);
    });
  });
}
