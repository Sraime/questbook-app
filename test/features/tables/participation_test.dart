import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:questbook/app/remote_providers.dart';
import 'package:questbook/data/remote/remote_table.dart';
import 'package:questbook/data/remote/session_api.dart';
import 'package:questbook/design_system/components/qb_button.dart';
import 'package:questbook/domain/models/character.dart';
import 'package:questbook/features/home/providers/character_list_provider.dart';
import 'package:questbook/features/tables/providers/table_providers.dart';
import 'package:questbook/features/tables/table_detail_screen.dart';

/// Note ce qu'un joueur répond. Le reste de l'API doit échouer bruyamment :
/// ce test ne parle que de la participation.
class _RecordingSessionApi implements SessionApi {
  _RecordingSessionApi(this.answered);

  /// Ce que le serveur rendrait. L'écran le jette et recharge la table ; il
  /// est là pour que l'appel ait une réponse, pas pour être relu.
  final RemoteGameSession answered;

  final List<({AttendanceStatus status, String? characterId})> answers = [];
  final List<String?> characters = [];

  @override
  Future<RemoteGameSession> setAttendance(
    String id,
    AttendanceStatus status, {
    String? characterId,
  }) async {
    answers.add((status: status, characterId: characterId));
    return answered;
  }

  @override
  Future<RemoteGameSession> setAttendanceCharacter(
    String id,
    String? characterId,
  ) async {
    characters.add(characterId);
    return answered;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

/// Venir à une séance et y participer : deux gestes, deux règles.
///
/// Confirmer sa venue demande un investigateur — une chaise sans fiche ne
/// sert ni le MJ ni le joueur. Participer n'ouvre l'écran de la séance qu'une
/// fois la partie commencée.
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  final now = DateTime.now();

  final table = RemoteGameTable(
    id: 'table-1',
    title: 'Les ombres d’Arkham',
    ownerId: 'gm-1',
    role: TableRole.player,
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

  final ernest = Character(
    id: 'char-1',
    systemId: 'call_of_cthulhu_classique',
    name: 'Ernest Blackwood',
    occupation: 'Antiquaire',
    createdAt: now,
  );

  RemoteGameSession sessionAt({
    required Duration startsIn,
    AttendanceStatus? myStatus,
    RemoteAttendanceCharacter? myCharacter,
    String status = 'scheduled',
  }) {
    final startsAt = now.add(startsIn);
    return RemoteGameSession(
      id: 'session-1',
      tableId: 'table-1',
      title: 'Chapitre III — Les ruines',
      description: null,
      startsAt: startsAt,
      location: 'Chez Marie',
      status: status,
      attendances: const [],
      myStatus: myStatus,
      myCharacter: myCharacter,
      closesAt: startsAt.add(const Duration(hours: 24)),
      answersCloseAt: startsAt,
    );
  }

  const registered = RemoteAttendanceCharacter(
    id: 'char-1',
    name: 'Ernest Blackwood',
    occupation: 'Antiquaire',
  );

  Future<_RecordingSessionApi> pumpTable(
    WidgetTester tester, {
    required RemoteGameSession session,
    List<Character> characters = const [],
  }) async {
    final api = _RecordingSessionApi(session);

    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 800);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          canWriteProvider.overrideWithValue(true),
          sessionApiProvider.overrideWithValue(api),
          characterListProvider.overrideWith((ref) => Stream.value(characters)),
          tableDetailProvider.overrideWith(
            (ref, tableId) async =>
                TableDetail(table: table, sessions: [session]),
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
                    const Scaffold(body: Text('écran de la séance')),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    return api;
  }

  group('Confirmer sa venue', () {
    testWidgets('« Je viens » demande d’abord avec qui', (tester) async {
      final api = await pumpTable(
        tester,
        session: sessionAt(startsIn: const Duration(days: 2)),
        characters: [ernest],
      );

      await tester.tap(find.text('Je viens'));
      await tester.pumpAndSettle();

      // Rien n'est parti : la fenêtre est ouverte, la réponse attend le nom.
      expect(api.answers, isEmpty);
      expect(find.text('Avec qui viens-tu ?'), findsOneWidget);
      expect(find.textContaining('Ernest Blackwood'), findsOneWidget);
    });

    testWidgets('choisir un investigateur répond pour de bon', (tester) async {
      final api = await pumpTable(
        tester,
        session: sessionAt(startsIn: const Duration(days: 2)),
        characters: [ernest],
      );

      await tester.tap(find.text('Je viens'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Ernest Blackwood'));
      await tester.pumpAndSettle();

      // Un seul appel : venir et dire avec qui sont une même décision, et
      // deux requêtes laisseraient une réponse sans fiche si la seconde
      // échouait.
      expect(api.answers, hasLength(1));
      expect(api.answers.single.status, AttendanceStatus.yes);
      expect(api.answers.single.characterId, 'char-1');
      expect(api.characters, isEmpty);
    });

    testWidgets('refermer la fenêtre revient à n’avoir rien répondu',
        (tester) async {
      final api = await pumpTable(
        tester,
        session: sessionAt(startsIn: const Duration(days: 2)),
        characters: [ernest],
      );

      await tester.tap(find.text('Je viens'));
      await tester.pumpAndSettle();
      Navigator.of(tester.element(find.text('Avec qui viens-tu ?'))).pop();
      await tester.pumpAndSettle();

      expect(api.answers, isEmpty);
    });

    testWidgets('sans investigateur, la fenêtre dit où en créer un',
        (tester) async {
      await pumpTable(
        tester,
        session: sessionAt(startsIn: const Duration(days: 2)),
      );

      await tester.tap(find.text('Je viens'));
      await tester.pumpAndSettle();

      expect(find.textContaining('onglet Investigateurs'), findsOneWidget);
    });

    testWidgets('« Je passe » ne demande personne', (tester) async {
      final api = await pumpTable(
        tester,
        session: sessionAt(startsIn: const Duration(days: 2)),
        characters: [ernest],
      );

      await tester.tap(find.text('Je passe'));
      await tester.pumpAndSettle();

      expect(api.answers, hasLength(1));
      expect(api.answers.single.status, AttendanceStatus.no);
    });
  });

  group('Participer à la séance', () {
    testWidgets('le bouton n’apparaît qu’une fois la partie commencée',
        (tester) async {
      await pumpTable(
        tester,
        session: sessionAt(
          startsIn: const Duration(days: 2),
          myStatus: AttendanceStatus.yes,
          myCharacter: registered,
        ),
      );

      expect(find.widgetWithText(QBButton, 'Participer'), findsNothing);
    });

    testWidgets('il ouvre l’écran de la séance', (tester) async {
      await pumpTable(
        tester,
        session: sessionAt(
          startsIn: const Duration(hours: -2),
          myStatus: AttendanceStatus.yes,
          myCharacter: registered,
        ),
      );

      await tester.tap(find.widgetWithText(QBButton, 'Participer'));
      await tester.pumpAndSettle();

      expect(find.text('écran de la séance'), findsOneWidget);
    });

    testWidgets('qui a dit passer ne participe pas', (tester) async {
      await pumpTable(
        tester,
        session: sessionAt(
          startsIn: const Duration(hours: -2),
          myStatus: AttendanceStatus.no,
        ),
      );

      expect(find.widgetWithText(QBButton, 'Participer'), findsNothing);
      expect(find.textContaining('La partie a commencé'), findsOneWidget);
    });

    testWidgets('la séance passée se referme sur tout le monde',
        (tester) async {
      await pumpTable(
        tester,
        session: sessionAt(
          startsIn: const Duration(hours: -25),
          myStatus: AttendanceStatus.yes,
          myCharacter: registered,
        ),
      );

      expect(find.widgetWithText(QBButton, 'Participer'), findsNothing);
      expect(find.text('Sessions passées'), findsOneWidget);
    });

    testWidgets('changer d’investigateur reste possible en pleine partie',
        (tester) async {
      // Le MJ a compté ses joueurs, mais qui joue quoi bouge encore une fois
      // la table assise : un investigateur meurt, un autre le remplace.
      await pumpTable(
        tester,
        session: sessionAt(
          startsIn: const Duration(hours: -2),
          myStatus: AttendanceStatus.yes,
          myCharacter: registered,
        ),
      );

      expect(find.text('Tu joues Ernest Blackwood'), findsOneWidget);
    });
  });
}
