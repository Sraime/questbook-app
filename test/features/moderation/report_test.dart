import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:questbook/app/remote_providers.dart';
import 'package:questbook/data/auth/auth_repository.dart';
import 'package:questbook/data/remote/api_exception.dart';
import 'package:questbook/data/remote/auth_tokens.dart';
import 'package:questbook/data/remote/remote_character.dart';
import 'package:questbook/data/remote/remote_table.dart';
import 'package:questbook/data/remote/report_api.dart';
import 'package:questbook/design_system/components/qb_button.dart';
import 'package:questbook/features/tables/providers/table_providers.dart';
import 'package:questbook/features/tables/table_detail_screen.dart';
import 'package:questbook/features/tables/widgets/attendee_character_sheet.dart';

const _robin = AuthUser(
  id: 'p-1',
  email: 'robin@example.com',
  displayName: 'Robin',
  pictureUrl: null,
);

const _marie = AuthUser(
  id: 'gm-1',
  email: 'marie@example.com',
  displayName: 'Marie',
  pictureUrl: null,
);

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository(this.account);

  final AuthUser account;

  @override
  Future<AuthUser?> restoreSession() async => account;

  @override
  Future<AuthUser> signInWithGoogle() async => account;

  @override
  Future<AuthUser> rename(String displayName) async => account;

  @override
  Future<void> deleteAccount() async {}

  @override
  Future<AuthUser> acceptTerms() async => throw UnimplementedError();

  @override
  Future<void> signOut() async {}
}

/// Note ce qui part au serveur, et peut refuser comme lui.
class _RecordingReportApi implements ReportApi {
  _RecordingReportApi({this.failure});

  final ApiException? failure;

  final List<({ReportableContent type, String id, String reason})> sent = [];

  @override
  Future<void> report({
    required ReportableContent contentType,
    required String contentId,
    required String reason,
  }) async {
    if (failure case final error?) throw error;
    sent.add((type: contentType, id: contentId, reason: reason));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} non simulé');
}

/// Signaler est ce qu'Apple attend d'une app à contenu généré, et c'est aussi
/// le seul recours d'un joueur contre le maître du jeu de sa table : il ne
/// peut ni le retirer ni s'en plaindre à personne d'autre.
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  final now = DateTime.now();

  RemoteTableMember member(String id, String name, TableRole role) =>
      RemoteTableMember(
        userId: id,
        role: role,
        joinedAt: now,
        user: RemoteUser(id: id, displayName: name, pictureUrl: null),
      );

  RemoteGameTable tableSeenAs(TableRole role) => RemoteGameTable(
        id: 'table-1',
        title: 'Les ombres d’Arkham',
        ownerId: 'gm-1',
        role: role,
        createdAt: now,
        updatedAt: now,
        members: [
          member('gm-1', 'Marie', TableRole.gameMaster),
          member('p-1', 'Robin', TableRole.player),
        ],
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
    closesAt: now.add(const Duration(days: 3)),
    answersCloseAt: now.add(const Duration(days: 2)),
  );

  Future<_RecordingReportApi> pumpTable(
    WidgetTester tester, {
    TableRole role = TableRole.player,
    ApiException? failure,
  }) async {
    final api = _RecordingReportApi(failure: failure);

    // Qui lit l'écran suit le rôle : la table du MJ est celle de Marie, pas
    // celle de Robin vue depuis le siège d'en face.
    final me = role == TableRole.gameMaster ? _marie : _robin;

    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(412, 915);
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(_FakeAuthRepository(me)),
        reportApiProvider.overrideWithValue(api),
        canWriteProvider.overrideWithValue(true),
        tableDetailProvider.overrideWith(
          (ref, tableId) async =>
              TableDetail(table: tableSeenAs(role), sessions: [session]),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(authControllerProvider.future);
    container.read(authControllerProvider.notifier).state = AsyncValue.data(me);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: TableDetailScreen(tableId: 'table-1')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    return api;
  }

  /// Le menu du titre de la table est le premier de l'écran, celui de la
  /// carte de séance le deuxième : la liste les rend dans cet ordre.
  Future<void> openMenu(WidgetTester tester, int index) async {
    await tester.tap(find.byIcon(LucideIcons.ellipsisVertical).at(index));
    await tester.pumpAndSettle();
  }

  Future<void> fillAndSend(WidgetTester tester, String reason) async {
    await tester.enterText(find.byType(TextField), reason);
    await tester.tap(find.widgetWithText(QBButton, 'Signaler'));
    await tester.pumpAndSettle();
  }

  testWidgets('un joueur peut signaler la table de son MJ', (tester) async {
    final api = await pumpTable(tester);

    await openMenu(tester, 0);
    expect(find.text('Signaler cette table'), findsOneWidget);

    await tester.tap(find.text('Signaler cette table'));
    await tester.pumpAndSettle();
    await fillAndSend(tester, 'Le titre est une insulte.');

    expect(api.sent, [
      (
        type: ReportableContent.table,
        id: 'table-1',
        reason: 'Le titre est une insulte.',
      ),
    ]);
  });

  testWidgets('et la séance qu’il y trouve', (tester) async {
    final api = await pumpTable(tester);

    await openMenu(tester, 1);
    await tester.tap(find.text('Signaler cette séance'));
    await tester.pumpAndSettle();
    await fillAndSend(tester, 'La description part en vrille.');

    expect(api.sent.single.type, ReportableContent.session);
    expect(api.sent.single.id, 'session-1');
  });

  testWidgets('et le maître du jeu lui-même', (tester) async {
    final api = await pumpTable(tester);

    // Sur la ligne de Marie : celle de Robin, c'est lui.
    await tester.tap(
      find.descendant(
        of: find.ancestor(
          of: find.text('Marie'),
          matching: find.byType(Row),
        ).first,
        matching: find.byIcon(LucideIcons.ellipsisVertical),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Signaler ce joueur'));
    await tester.pumpAndSettle();
    await fillAndSend(tester, 'Il insulte ses joueurs à chaque séance.');

    expect(api.sent.single.type, ReportableContent.user);
    expect(api.sent.single.id, 'gm-1');
  });

  testWidgets('personne ne peut se signaler soi-même', (tester) async {
    await pumpTable(tester);

    // Robin lit l'écran : sa propre ligne ne porte aucun menu, et le MJ ne
    // voit pas de quoi signaler ce qu'il a écrit lui-même.
    expect(
      find.descendant(
        of: find.ancestor(
          of: find.text('Robin'),
          matching: find.byType(Row),
        ).first,
        matching: find.byIcon(LucideIcons.ellipsisVertical),
      ),
      findsNothing,
    );
  });

  testWidgets('le MJ ne signale ni sa table ni sa séance', (tester) async {
    await pumpTable(tester, role: TableRole.gameMaster);

    // Il n'en reste qu'un, celui de son joueur : le titre et la carte de
    // séance n'en portent pas, puisqu'il a écrit l'un et l'autre.
    expect(find.byIcon(LucideIcons.ellipsisVertical), findsOneWidget);

    await openMenu(tester, 0);
    expect(find.text('Retirer de la table'), findsOneWidget);
    expect(find.text('Signaler cette table'), findsNothing);
    expect(find.text('Signaler cette séance'), findsNothing);
  });

  testWidgets('un motif vide ne part pas au serveur', (tester) async {
    final api = await pumpTable(tester);

    await openMenu(tester, 0);
    await tester.tap(find.text('Signaler cette table'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(QBButton, 'Signaler'));
    await tester.pumpAndSettle();

    expect(api.sent, isEmpty);
    expect(find.text('Dis ce que tu reproches à cette table.'), findsOneWidget);
  });

  testWidgets('la fiche d’un camarade se signale depuis son entête',
      (tester) async {
    final api = _RecordingReportApi();

    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(412, 915);
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(_FakeAuthRepository(_robin)),
        reportApiProvider.overrideWithValue(api),
        canWriteProvider.overrideWithValue(true),
        attendeeCharacterProvider.overrideWith(
          (ref, key) async => RemoteCharacter(
            id: 'char-marie',
            systemId: 'call_of_cthulhu_classique',
            name: 'Ernest Blackwood',
            occupation: 'Antiquaire',
            description: null,
            level: 1,
            createdAt: now,
            updatedAt: now,
            deletedAt: null,
            stats: const [],
            resources: const [],
            inventory: const [],
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(authControllerProvider.future);
    container.read(authControllerProvider.notifier).state =
        const AsyncValue.data(_robin);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showAttendeeCharacterSheet(
                  context,
                  sessionId: 'session-1',
                  userId: 'gm-1',
                  playerLabel: 'Marie',
                ),
                child: const Text('ouvrir'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(LucideIcons.ellipsisVertical));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Signaler cet investigateur'));
    await tester.pumpAndSettle();
    await fillAndSend(tester, 'Une fiche écrite pour choquer.');

    expect(api.sent.single.type, ReportableContent.investigator);
    expect(api.sent.single.id, 'char-marie');
  });

  testWidgets('un refus du serveur se lit dans la fenêtre', (tester) async {
    await pumpTable(
      tester,
      failure: const ApiException(
        statusCode: 409,
        code: 'CONFLICT',
        message: 'Tu as déjà signalé ce contenu.',
      ),
    );

    await openMenu(tester, 0);
    await tester.tap(find.text('Signaler cette table'));
    await tester.pumpAndSettle();
    await fillAndSend(tester, 'Encore.');

    expect(find.text('Tu as déjà signalé ce contenu.'), findsOneWidget);
  });
}
