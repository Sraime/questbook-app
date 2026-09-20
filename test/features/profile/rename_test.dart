import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:questbook/app/remote_providers.dart';
import 'package:questbook/data/auth/auth_repository.dart';
import 'package:questbook/data/remote/api_exception.dart';
import 'package:questbook/data/remote/auth_tokens.dart';
import 'package:questbook/design_system/components/qb_icon_button.dart';
import 'package:questbook/features/profile/profile_screen.dart';

const _account = AuthUser(
  id: 'user-1',
  email: 'marie@example.com',
  displayName: 'Marie',
  pictureUrl: null,
);

/// Ne sert qu'au renommage : tout le reste du cycle de vie du compte n'a pas
/// besoin d'exister pour ces tests.
class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.failure});

  final ApiException? failure;
  final List<String> renamed = [];

  @override
  Future<AuthUser?> restoreSession() async => _account;

  @override
  Future<AuthUser> rename(String displayName) async {
    if (failure case final error?) throw error;
    renamed.add(displayName);
    return AuthUser(
      id: _account.id,
      email: _account.email,
      displayName: displayName,
      pictureUrl: null,
    );
  }

  @override
  Future<AuthUser> signInWithGoogle() async => _account;

  @override
  Future<void> signOut() async {}
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<_FakeAuthRepository> pumpProfile(
    WidgetTester tester, {
    ApiException? failure,
  }) async {
    final repository = _FakeAuthRepository(failure: failure);

    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(600, 1200);
    addTearDown(tester.view.reset);

    // Sans identifiant client Google compilé dans le binaire, le contrôleur
    // démarre hors ligne et ne consulte jamais le dépôt : le compte est donc
    // posé à la main, comme dans les autres tests qui en ont besoin.
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
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

    return repository;
  }

  Future<void> openDialog(WidgetTester tester) async {
    await tester.tap(find.byType(QBIconButton));
    await tester.pumpAndSettle();
  }

  testWidgets('le profil montre le pseudo du compte', (tester) async {
    await pumpProfile(tester);

    expect(find.text('Marie'), findsOneWidget);
    expect(find.text('Connecté avec marie@example.com.'), findsOneWidget);
  });

  testWidgets('renommer envoie le nouveau nom et referme', (tester) async {
    final repository = await pumpProfile(tester);
    await openDialog(tester);

    await tester.enterText(find.byType(TextField), 'Le Gardien');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    expect(repository.renamed, ['Le Gardien']);
    expect(find.text('Le Gardien'), findsOneWidget);
    expect(
      find.text('Changer de pseudo'),
      findsNothing,
      reason: 'le dialogue se referme une fois le pseudo enregistré',
    );
  });

  testWidgets('un pseudo vide ne part pas au serveur', (tester) async {
    final repository = await pumpProfile(tester);
    await openDialog(tester);

    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    expect(repository.renamed, isEmpty);
    expect(find.text('Choisis un pseudo.'), findsOneWidget);
  });

  testWidgets('un refus du serveur se lit dans le dialogue', (tester) async {
    await pumpProfile(
      tester,
      failure: const ApiException(
        statusCode: 400,
        code: 'BAD_REQUEST',
        message: 'Ce pseudo ne convient pas.',
      ),
    );
    await openDialog(tester);

    await tester.enterText(find.byType(TextField), 'Le Gardien');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    expect(find.text('Ce pseudo ne convient pas.'), findsOneWidget);
  });
}
