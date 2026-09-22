import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:questbook/app/providers.dart';
import 'package:questbook/app/remote_providers.dart';
import 'package:questbook/data/auth/auth_repository.dart';
import 'package:questbook/data/local/database.dart';
import 'package:questbook/data/remote/api_exception.dart';
import 'package:questbook/data/remote/auth_tokens.dart';
import 'package:questbook/design_system/components/qb_button.dart';
import 'package:questbook/features/profile/profile_screen.dart';
import 'package:questbook/features/tables/providers/table_providers.dart';

const _account = AuthUser(
  id: 'user-1',
  email: 'marie@example.com',
  displayName: 'Marie',
  pictureUrl: null,
);

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.failure});

  final ApiException? failure;
  int deletions = 0;

  @override
  Future<AuthUser?> restoreSession() async => _account;

  @override
  Future<void> deleteAccount() async {
    if (failure case final error?) throw error;
    deletions++;
  }

  @override
  Future<AuthUser> rename(String displayName) async => _account;

  @override
  Future<AuthUser> signInWithGoogle() async => _account;

  @override
  Future<AuthUser> signInWithApple() async => _account;

  @override
  Future<AuthUser> acceptTerms() async => throw UnimplementedError();

  @override
  Future<void> signOut() async {}
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  late AppDatabase database;

  setUp(() => database = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => database.close());

  Future<(_FakeAuthRepository, ProviderContainer)> pumpProfile(
    WidgetTester tester, {
    ApiException? failure,
    Future<TablesOverview>? tables,
  }) async {
    final repository = _FakeAuthRepository(failure: failure);

    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(700, 1600);
    addTearDown(tester.view.reset);

    final container = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWithValue(repository),
      appDatabaseProvider.overrideWithValue(database),
      tablesOverviewProvider.overrideWith(
        (ref) =>
            tables ?? Future.value(const TablesOverview(tables: [], invitations: [])),
      ),
    ]);
    addTearDown(container.dispose);
    await container.read(authControllerProvider.future);
    container.read(authControllerProvider.notifier).state =
        const AsyncValue.data(_account);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();

    return (repository, container);
  }

  Future<void> openDialog(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(QBButton, 'Supprimer mon compte'));
    await tester.pumpAndSettle();
  }

  testWidgets('rien ne s’efface tant que les tables sont inconnues',
      (tester) async {
    final (repository, _) = await pumpProfile(
      tester,
      // La liste des tables n'arrive jamais : le decompte reste inconnu.
      tables: Completer<TablesOverview>().future,
    );

    await openDialog(tester);

    expect(find.text('Vérification de tes tables…'), findsOneWidget);
    await tester.tap(find.widgetWithText(QBButton, 'Supprimer définitivement'));
    await tester.pumpAndSettle();

    expect(
      repository.deletions,
      0,
      reason: 'confirmer avant de savoir ce qu’on efface ne doit rien effacer',
    );
  });

  testWidgets('la suppression demande confirmation avant de partir',
      (tester) async {
    final (repository, _) = await pumpProfile(tester);

    await openDialog(tester);
    expect(
      repository.deletions,
      0,
      reason: 'ouvrir le dialogue ne supprime rien',
    );
    expect(find.text('Supprimer définitivement'), findsOneWidget);

    await tester.tap(find.widgetWithText(QBButton, 'Annuler'));
    await tester.pumpAndSettle();

    expect(repository.deletions, 0);
    expect(find.text('Supprimer définitivement'), findsNothing);
  });

  testWidgets('confirmer efface le compte et ferme la session',
      (tester) async {
    final (repository, container) = await pumpProfile(tester);

    // Un personnage laisse derriere lui : il doit disparaitre avec le compte,
    // puisque rien ne le remontera jamais plus.
    await database.customStatement(
      "INSERT INTO characters (id, system_id, name, level, created_at, "
      "updated_at) VALUES ('c1', 'call_of_cthulhu_classique', 'Ernest', 1, 0, 0)",
    );

    await openDialog(tester);
    await tester.tap(find.widgetWithText(QBButton, 'Supprimer définitivement'));
    await tester.pumpAndSettle();

    expect(repository.deletions, 1);
    expect(container.read(authControllerProvider).value, isNull);

    final left = await database.customSelect('SELECT * FROM characters').get();
    expect(left, isEmpty);
  });

  testWidgets('un refus du serveur laisse le compte en place', (tester) async {
    final (_, container) = await pumpProfile(
      tester,
      failure: const ApiException(
        statusCode: 500,
        code: 'INTERNAL',
        message: 'Le serveur n’a pas pu supprimer le compte.',
      ),
    );

    await openDialog(tester);
    await tester.tap(find.widgetWithText(QBButton, 'Supprimer définitivement'));
    await tester.pumpAndSettle();

    expect(find.text('Le serveur n’a pas pu supprimer le compte.'),
        findsOneWidget);
    expect(
      container.read(authControllerProvider).value,
      isNotNull,
      reason: 'le compte existe encore, l’appareil doit rester connecté',
    );
  });
}
