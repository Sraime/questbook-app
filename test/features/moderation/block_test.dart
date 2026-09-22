import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:questbook/app/remote_providers.dart';
import 'package:questbook/data/auth/auth_repository.dart';
import 'package:questbook/data/remote/api_exception.dart';
import 'package:questbook/data/remote/auth_tokens.dart';
import 'package:questbook/data/remote/block_api.dart';
import 'package:questbook/data/remote/remote_table.dart';
import 'package:questbook/design_system/components/qb_button.dart';
import 'package:questbook/features/profile/profile_screen.dart';
import 'package:questbook/features/tables/providers/table_providers.dart';
import 'package:questbook/features/tables/table_detail_screen.dart';

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
  Future<void> signOut() async {}
}

/// Le serveur seul sait combien de tables les deux comptes partageaient.
/// Celui-ci répond ce qu'on lui a dit de répondre, pour que l'app soit jugée
/// sur ce qu'elle en fait.
class _FakeBlockApi implements BlockApi {
  _FakeBlockApi({
    this.tablesLeft = 0,
    this.playersRemoved = 0,
    this.failure,
    List<BlockedUser> blocked = const [],
  }) : _blocked = [...blocked];

  final int tablesLeft;
  final int playersRemoved;
  final ApiException? failure;
  final List<BlockedUser> _blocked;

  final List<String> blockCalls = [];
  final List<String> unblockCalls = [];

  @override
  Future<List<BlockedUser>> list() async => _blocked;

  @override
  Future<BlockOutcome> block(String userId) async {
    if (failure case final error?) throw error;
    blockCalls.add(userId);
    return BlockOutcome(
      user: BlockedUser(
        userId: userId,
        displayName: 'Marie',
        pictureUrl: null,
        blockedAt: DateTime.now(),
      ),
      tablesLeft: tablesLeft,
      playersRemoved: playersRemoved,
    );
  }

  @override
  Future<void> unblock(String userId) async {
    unblockCalls.add(userId);
    _blocked.removeWhere((person) => person.userId == userId);
  }
}

/// Bloquer est le geste que les stores exigent à côté du signalement, et le
/// seul qui change quelque chose pour celui qui vient de subir : signaler
/// réveille le support, bloquer vide la chaise d'en face.
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

  RemoteGameTable tableSeenAs(TableRole role, {bool withoutRobin = false}) =>
      RemoteGameTable(
        id: 'table-1',
        title: 'Les ombres d’Arkham',
        ownerId: 'gm-1',
        role: role,
        createdAt: now,
        updatedAt: now,
        members: [
          member('gm-1', 'Marie', TableRole.gameMaster),
          if (!withoutRobin) member('p-1', 'Robin', TableRole.player),
        ],
        pendingInvitations: const [],
        nextSessionAt: null,
      );

  /// Un routeur plutôt qu'un `MaterialApp` nu : quitter la table est la
  /// moitié du geste, et sans route où atterrir il ne se vérifie pas.
  GoRouter routerFor(Widget screen) => GoRouter(
        initialLocation: '/tables/table-1',
        routes: [
          GoRoute(
            path: '/tables',
            builder: (_, _) => const Scaffold(body: Text('mes tables')),
          ),
          GoRoute(
            path: '/tables/table-1',
            builder: (_, _) => Scaffold(body: screen),
          ),
        ],
      );

  Future<_FakeBlockApi> pumpTable(
    WidgetTester tester, {
    TableRole role = TableRole.player,
    int tablesLeft = 0,
    int playersRemoved = 0,
    ApiException? failure,
  }) async {
    final api = _FakeBlockApi(
      tablesLeft: tablesLeft,
      playersRemoved: playersRemoved,
      failure: failure,
    );
    final me = role == TableRole.gameMaster ? _marie : _robin;

    // Comme le serveur : la deuxième lecture ne renvoie plus le joueur que le
    // blocage a sorti de la table. Ce que l'écran en montre dépend donc de
    // savoir qu'il faut relire.
    var reads = 0;

    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(412, 915);
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(_FakeAuthRepository(me)),
        blockApiProvider.overrideWithValue(api),
        canWriteProvider.overrideWithValue(true),
        tableDetailProvider.overrideWith(
          (ref, tableId) async => TableDetail(
            table: tableSeenAs(role, withoutRobin: reads++ > 0),
            sessions: const [],
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(authControllerProvider.future);
    container.read(authControllerProvider.notifier).state = AsyncValue.data(me);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: routerFor(const TableDetailScreen(tableId: 'table-1')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    return api;
  }

  Future<void> openMenuOf(WidgetTester tester, String name) async {
    await tester.tap(
      find.descendant(
        of: find.ancestor(of: find.text(name), matching: find.byType(Row)).first,
        matching: find.byIcon(LucideIcons.ellipsisVertical),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> confirm(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(QBButton, 'Bloquer'));
    await tester.pumpAndSettle();
  }

  testWidgets('un joueur bloque son MJ, et quitte la table dans le geste',
      (tester) async {
    final api = await pumpTable(tester, tablesLeft: 1);

    await openMenuOf(tester, 'Marie');
    await tester.tap(find.text('Bloquer ce joueur'));
    await tester.pumpAndSettle();

    // La fenêtre annonce ce qui va se défaire : l'apprendre après coup, en
    // voyant une table manquer à l'accueil, se lit comme une panne.
    expect(find.textContaining('tu quittes celles où tu n’es que joueur'),
        findsOneWidget);

    await confirm(tester);

    expect(api.blockCalls, ['gm-1']);
    expect(find.text('mes tables'), findsOneWidget);
    expect(
      find.text('Marie est bloqué : tu as quitté votre table commune.'),
      findsOneWidget,
    );
  });

  testWidgets('le MJ bloque son joueur, et garde sa table', (tester) async {
    final api = await pumpTable(
      tester,
      role: TableRole.gameMaster,
      playersRemoved: 1,
    );

    await openMenuOf(tester, 'Robin');
    await tester.tap(find.text('Bloquer ce joueur'));
    await tester.pumpAndSettle();
    await confirm(tester);

    expect(api.blockCalls, ['p-1']);
    // Partir laisserait une salle que plus personne ne peut animer : c'est
    // l'autre qui sort, et le MJ reste où il était.
    expect(find.text('mes tables'), findsNothing);
    expect(find.text('Les ombres d’Arkham'), findsOneWidget);
    // Mais la liste des joueurs se relit : garder à l'écran celui qu'on
    // vient de retirer laisserait croire que le geste n'a rien fait.
    expect(find.text('Robin'), findsNothing);
  });

  testWidgets('personne ne se bloque soi-même', (tester) async {
    await pumpTable(tester);

    await openMenuOf(tester, 'Marie');
    expect(find.text('Bloquer ce joueur'), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.ancestor(of: find.text('Robin'), matching: find.byType(Row)).first,
        matching: find.byIcon(LucideIcons.ellipsisVertical),
      ),
      findsNothing,
    );
  });

  testWidgets('un refus du serveur laisse la fenêtre ouverte', (tester) async {
    final api = await pumpTable(
      tester,
      failure: const ApiException(
        statusCode: 400,
        code: 'VALIDATION_ERROR',
        message: 'On ne se bloque pas soi-même.',
      ),
    );

    await openMenuOf(tester, 'Marie');
    await tester.tap(find.text('Bloquer ce joueur'));
    await tester.pumpAndSettle();
    await confirm(tester);

    expect(api.blockCalls, isEmpty);
    expect(find.text('On ne se bloque pas soi-même.'), findsOneWidget);
    // Toujours là : refermer sur une erreur la ferait disparaître avec elle.
    expect(find.widgetWithText(QBButton, 'Bloquer'), findsOneWidget);
    expect(find.text('mes tables'), findsNothing);
  });

  Future<_FakeBlockApi> pumpProfile(
    WidgetTester tester, {
    required List<BlockedUser> blocked,
  }) async {
    final api = _FakeBlockApi(blocked: blocked);

    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(412, 915);
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(_FakeAuthRepository(_robin)),
        blockApiProvider.overrideWithValue(api),
        canWriteProvider.overrideWithValue(true),
      ],
    );
    addTearDown(container.dispose);
    await container.read(authControllerProvider.future);
    container.read(authControllerProvider.notifier).state =
        const AsyncValue.data(_robin);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();

    return api;
  }

  testWidgets('le profil est le seul endroit d’où l’on revient dessus',
      (tester) async {
    final api = await pumpProfile(
      tester,
      blocked: [
        BlockedUser(
          userId: 'gm-1',
          displayName: 'Marie',
          pictureUrl: null,
          blockedAt: now,
        ),
      ],
    );

    expect(find.text('Joueurs bloqués'), findsOneWidget);
    expect(find.text('Marie'), findsOneWidget);

    await tester.tap(find.byIcon(LucideIcons.userCheck));
    await tester.pumpAndSettle();

    expect(api.unblockCalls, ['gm-1']);
    // La carte s'en va avec sa dernière ligne : un rayon vide n'apprend rien.
    expect(find.text('Joueurs bloqués'), findsNothing);
  });

  testWidgets('et n’annonce rien tant qu’on n’a bloqué personne',
      (tester) async {
    await pumpProfile(tester, blocked: const []);

    expect(find.text('Joueurs bloqués'), findsNothing);
  });
}
