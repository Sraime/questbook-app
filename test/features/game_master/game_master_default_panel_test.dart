import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:questbook/app/remote_providers.dart';
import 'package:questbook/data/auth/auth_repository.dart';
import 'package:questbook/data/local/database.dart';
import 'package:questbook/data/local/session_board_dao.dart';
import 'package:questbook/data/remote/auth_tokens.dart';
import 'package:questbook/data/remote/remote_table.dart';
import 'package:questbook/features/game_master/game_master_screen.dart';
import 'package:questbook/features/game_master/panels/board_panel.dart';
import 'package:questbook/features/game_master/panels/details_panel.dart';
import 'package:questbook/features/game_master/providers/game_master_providers.dart';
import 'package:questbook/features/tables/providers/table_providers.dart';

const _account = AuthUser(
  id: 'gm-1',
  email: 'marie@example.com',
  displayName: 'Marie',
  pictureUrl: null,
);

/// Le mode MJ n'a besoin du compte que pour savoir à qui appartient le
/// plateau rangé sur l'appareil.
class _FakeAuthRepository implements AuthRepository {
  @override
  Future<AuthUser?> restoreSession() async => _account;

  @override
  Future<AuthUser> signInWithGoogle() async => _account;

  @override
  Future<AuthUser> rename(String displayName) async => _account;

  @override
  Future<void> deleteAccount() async {}

  @override
  Future<void> signOut() async {}
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  final now = DateTime.utc(2026, 9, 19);

  final table = RemoteGameTable(
    id: 'table-1',
    title: 'Les ombres d’Arkham',
    ownerId: 'gm-1',
    role: TableRole.gameMaster,
    createdAt: now,
    updatedAt: now,
    members: const [],
    pendingInvitations: const [],
    nextSessionAt: null,
  );

  final session = RemoteGameSession(
    id: 'session-1',
    tableId: 'table-1',
    title: 'Chapitre III — Les ruines',
    description: null,
    startsAt: now.add(const Duration(days: 2)),
    location: 'Chez Marie',
    status: 'scheduled',
    attendances: const [],
    myStatus: null,
    myCharacter: null,
    scenarioId: null,
    scenario: null,
  );

  Future<void> pumpGameMaster(WidgetTester tester, {required Size screen}) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = screen;
    addTearDown(tester.view.reset);

    // Comme ailleurs : sans identifiant client Google compilé dans le binaire,
    // le contrôleur démarre hors ligne, donc le compte est posé à la main.
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
        sessionBoardDaoProvider.overrideWithValue(SessionBoardDao(db)),
        canWriteProvider.overrideWithValue(true),
        tableDetailProvider.overrideWith(
          (ref, tableId) async => TableDetail(table: table, sessions: [session]),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(authControllerProvider.future);
    container.read(authControllerProvider.notifier).state =
        const AsyncValue.data(_account);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: GameMasterScreen(tableId: 'table-1', sessionId: 'session-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('le mode MJ s’ouvre sur les détails de la séance, pas sur le '
      'plateau', (tester) async {
    await pumpGameMaster(tester, screen: const Size(1280, 800));

    expect(find.byType(DetailsPanel), findsOneWidget);
    expect(find.byType(BoardPanel), findsNothing);
  });

  testWidgets('sur téléphone aussi', (tester) async {
    await pumpGameMaster(tester, screen: const Size(412, 915));

    expect(find.byType(DetailsPanel), findsOneWidget);
    expect(find.byType(BoardPanel), findsNothing);
  });

  testWidgets('le volet s’appelle Détails', (tester) async {
    await pumpGameMaster(tester, screen: const Size(1280, 800));

    expect(find.text('Général'), findsNothing);
    // Dans le rail et en tête du volet lui-même.
    expect(find.text('Détails'), findsNWidgets(2));
  });
}
