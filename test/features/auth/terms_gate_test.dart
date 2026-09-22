import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:questbook/app/auth_gate.dart';
import 'package:questbook/app/providers.dart';
import 'package:questbook/app/remote_providers.dart';
import 'package:questbook/data/auth/auth_repository.dart';
import 'package:questbook/data/local/database.dart';
import 'package:questbook/data/remote/auth_tokens.dart';

/// Le consentement se demande au compte, pas a l'appareil : c'est le serveur
/// qui porte la date, et l'app ne fait que la lire. D'ou le point sensible que
/// ces tests tiennent — un compte cree avant la publication des conditions
/// arrive avec `termsAcceptedAt` nul et doit etre arrete, alors meme qu'il a
/// une session valide et n'a rien fait de mal.
class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository(this._user, {this.failure});

  AuthUser? _user;

  /// Ce qui casse au moment d'accepter, s'il doit casser quelque chose.
  final Object? failure;

  int acceptCalls = 0;

  @override
  Future<AuthUser?> restoreSession() async => _user;

  @override
  Future<AuthUser> acceptTerms() async {
    acceptCalls++;
    if (failure case final error?) throw error;
    _user = AuthUser(
      id: _user!.id,
      email: _user!.email,
      displayName: _user!.displayName,
      pictureUrl: _user!.pictureUrl,
      termsAcceptedAt: DateTime.utc(2026, 9, 22),
    );
    return _user!;
  }

  @override
  Future<AuthUser> signInWithGoogle() async => throw UnimplementedError();

  @override
  Future<AuthUser> signInWithApple() async => throw UnimplementedError();

  @override
  Future<AuthUser> rename(String displayName) async => throw UnimplementedError();

  @override
  Future<void> deleteAccount() async => throw UnimplementedError();

  @override
  Future<void> signOut() async {
    _user = null;
  }
}

void main() {
  // `signOut` vide les caches en partant : sans base, le bouton de sortie
  // echouerait avant d'avoir efface la session.
  late AppDatabase database;

  setUp(() => database = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => database.close());

  AuthUser account({DateTime? accepted}) => AuthUser(
        id: 'u-1',
        email: 'robin@example.com',
        displayName: 'Robin',
        pictureUrl: null,
        termsAcceptedAt: accepted,
      );

  Future<_FakeAuthRepository> pumpGate(
    WidgetTester tester, {
    required AuthUser user,
    Object? failure,
  }) async {
    final repository = _FakeAuthRepository(user, failure: failure);

    // Les builds de test n'ont pas de client OAuth, si bien que le controleur
    // se declare hors ligne et rend `null` sans consulter le depot. On lui
    // pose donc la session a la main, comme le font les autres tests d'ecran.
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        appDatabaseProvider.overrideWithValue(database),
        remoteEnabledProvider.overrideWithValue(true),
      ],
    );
    addTearDown(container.dispose);
    await container.read(authControllerProvider.future);
    container.read(authControllerProvider.notifier).state =
        AsyncValue.data(user);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('fr'),
          home: AuthGate(child: Text('le reste de l’app')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    return repository;
  }

  testWidgets('un compte qui n’a rien signe ne voit pas l’app',
      (tester) async {
    await pumpGate(tester, user: account());

    expect(find.text('Avant de t’asseoir'), findsOneWidget);
    expect(find.text('le reste de l’app'), findsNothing);
  });

  testWidgets('accepter ouvre le passage, et une seule fois', (tester) async {
    final repository = await pumpGate(tester, user: account());

    await tester.tap(find.text('J’accepte'));
    await tester.pumpAndSettle();

    expect(repository.acceptCalls, 1);
    expect(find.text('le reste de l’app'), findsOneWidget);
  });

  testWidgets('un compte qui a signe ne le repasse pas au lancement suivant',
      (tester) async {
    final repository = await pumpGate(
      tester,
      user: account(accepted: DateTime.utc(2026, 9, 1)),
    );

    expect(find.text('le reste de l’app'), findsOneWidget);
    expect(repository.acceptCalls, 0);
  });

  testWidgets('une panne imprevue laisse une sortie plutot qu’un bouton eteint',
      (tester) async {
    // Le trousseau iOS qui refuse d'ecrire, une reponse illisible : rien de
    // tout cela n'est une `ApiException`. Sur un ecran qui barre l'app et
    // grise ses deux boutons pendant l'envoi, laisser filer reviendrait a
    // enfermer — il ne resterait qu'a tuer l'app.
    await pumpGate(
      tester,
      user: account(),
      failure: StateError('le trousseau a refuse'),
    );

    await tester.tap(find.text('J’accepte'));
    await tester.pumpAndSettle();

    expect(find.textContaining('le trousseau a refuse'), findsOneWidget);
    expect(find.text('J’accepte'), findsOneWidget);

    // Et la sortie repond de nouveau.
    await tester.tap(find.text('Non merci, me déconnecter'));
    await tester.pumpAndSettle();
    expect(find.text('Avant de t’asseoir'), findsNothing);
  });

  testWidgets('refuser deconnecte plutot que d’enfermer', (tester) async {
    await pumpGate(tester, user: account());

    // Sans cette issue, le seul moyen de se retirer serait de desinstaller.
    await tester.tap(find.text('Non merci, me déconnecter'));
    await tester.pumpAndSettle();

    expect(find.text('Avant de t’asseoir'), findsNothing);
  });
}
