import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:questbook/app/remote_providers.dart';
import 'package:questbook/data/auth/auth_repository.dart';
import 'package:questbook/data/remote/auth_tokens.dart';
import 'package:questbook/data/remote/remote_table.dart';
import 'package:questbook/design_system/components/qb_button.dart';
import 'package:questbook/features/tables/providers/table_providers.dart';
import 'package:questbook/features/tables/table_detail_screen.dart';

const _marie = AuthUser(
  id: 'gm-1',
  email: 'marie@example.com',
  displayName: 'Marie',
  pictureUrl: null,
);

/// L'écran a besoin de savoir qui le lit : c'est ce qui décide des gestes
/// qu'on peut porter sur soi-même, et de ceux qu'on ne peut pas.
class _FakeAuthRepository implements AuthRepository {
  @override
  Future<AuthUser?> restoreSession() async => _marie;

  @override
  Future<AuthUser> signInWithGoogle() async => _marie;

  @override
  Future<AuthUser> rename(String displayName) async => _marie;

  @override
  Future<void> deleteAccount() async {}

  @override
  Future<void> signOut() async {}
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  final now = DateTime.utc(2026, 9, 19);

  RemoteTableMember member(String id, String name, TableRole role) =>
      RemoteTableMember(
        userId: id,
        role: role,
        joinedAt: now,
        user: RemoteUser(id: id, displayName: name, pictureUrl: null),
      );

  RemoteGameTable tableWith(List<RemoteTableMember> members) =>
      RemoteGameTable(
        id: 'table-1',
        title: 'Les ombres d’Arkham',
        ownerId: 'gm-1',
        role: TableRole.gameMaster,
        createdAt: now,
        updatedAt: now,
        members: members,
        pendingInvitations: const [],
        nextSessionAt: null,
      );

  final soloTable = tableWith([member('gm-1', 'Marie', TableRole.gameMaster)]);

  final sharedTable = tableWith([
    member('gm-1', 'Marie', TableRole.gameMaster),
    member('p-1', 'Robin', TableRole.player),
  ]);

  Future<void> pump(WidgetTester tester, RemoteGameTable table) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(412, 915);
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
        canWriteProvider.overrideWithValue(true),
        tableDetailProvider.overrideWith(
          (ref, tableId) async =>
              TableDetail(table: table, sessions: const []),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(authControllerProvider.future);
    container.read(authControllerProvider.notifier).state =
        const AsyncValue.data(_marie);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: TableDetailScreen(tableId: 'table-1')),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  QBButton buttonNamed(WidgetTester tester, String label) =>
      tester.widget<QBButton>(find.widgetWithText(QBButton, label));

  testWidgets('proposer et inviter restent des boutons, mais en sourdine',
      (tester) async {
    await pump(tester, soloTable);

    for (final label in ['+ Proposer', '+ Inviter']) {
      expect(find.widgetWithText(QBButton, label), findsOneWidget);
      expect(
        buttonNamed(tester, label).variant,
        QBButtonVariant.ghost,
        reason: 'deux pavés dorés criaient plus fort que les sections '
            'qu’ils coiffent',
      );
      expect(buttonNamed(tester, label).size, QBButtonSize.sm);
    }
  });

  testWidgets('chaque joueur porte une icône, et le MJ la sienne',
      (tester) async {
    await pump(tester, sharedTable);

    expect(
      find.byIcon(LucideIcons.bookOpen),
      findsOneWidget,
      reason: 'le livre désigne celui qui mène, sans lire la mention en petit',
    );
    expect(find.byIcon(LucideIcons.user), findsOneWidget);
  });

  testWidgets('les actions sur un joueur tiennent derrière trois points',
      (tester) async {
    await pump(tester, sharedTable);

    // Les deux boutons jumeaux d'avant ont disparu de la ligne.
    expect(find.byIcon(LucideIcons.crown), findsNothing);
    expect(find.byIcon(LucideIcons.userMinus), findsNothing);

    expect(
      find.byIcon(LucideIcons.ellipsisVertical),
      findsOneWidget,
      reason: 'le MJ n’a pas de menu sur lui-même, seulement sur ses joueurs',
    );

    await tester.tap(find.byIcon(LucideIcons.ellipsisVertical));
    await tester.pumpAndSettle();

    expect(find.text('Désigner comme MJ'), findsOneWidget);
    expect(find.text('Retirer de la table'), findsOneWidget);
    expect(find.text('Signaler ce joueur'), findsOneWidget);
  });

  testWidgets('dissoudre la table n’est plus un pavé rouge', (tester) async {
    await pump(tester, soloTable);

    expect(
      find.widgetWithText(QBButton, 'Dissoudre la table'),
      findsNothing,
      reason: 'le geste le plus rare de l’écran ne doit pas être le plus gros',
    );
    expect(find.text('Dissoudre la table'), findsOneWidget);
    expect(find.byIcon(LucideIcons.trash2), findsOneWidget);
  });

  testWidgets('il reste un geste, et il demande confirmation', (tester) async {
    await pump(tester, soloTable);

    await tester.tap(find.text('Dissoudre la table'));
    await tester.pumpAndSettle();

    expect(find.text('Dissoudre la table ?'), findsOneWidget);
  });
}
