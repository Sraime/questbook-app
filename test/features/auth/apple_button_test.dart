import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:questbook/features/auth/login_screen.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Apple exige une seconde porte sur son store, mais elle n'a rien a faire
/// ailleurs : sur Android le paquet passe par un detour navigateur, pour un
/// besoin qui n'existe pas la-bas. Le bouton se decide donc sur la plateforme,
/// et c'est exactement ce qui se casse sans bruit — une condition perdue dans
/// un refactor laisse un bouton mort sur tous les telephones Android.
void main() {
  /// La bascule doit etre rendue **dans le corps du test** : flutter_test
  /// verifie que les variables de debug sont revenues a leur place avant de
  /// lancer les `tearDown`, et un test qui la laisse posee echoue sur ce seul
  /// motif, sans rapport avec ce qu'il mesurait.
  Future<void> pumpLoginOn(WidgetTester tester, TargetPlatform platform) async {
    debugDefaultTargetPlatformOverride = platform;
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(locale: Locale('fr'), home: LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('sur iOS, les deux portes sont ouvertes', (tester) async {
    await pumpLoginOn(tester, TargetPlatform.iOS);

    expect(find.text('Se connecter avec Google'), findsOneWidget);
    expect(find.byType(SignInWithAppleButton), findsOneWidget);

    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('sur Android, Google seul', (tester) async {
    await pumpLoginOn(tester, TargetPlatform.android);

    expect(find.text('Se connecter avec Google'), findsOneWidget);
    expect(find.byType(SignInWithAppleButton), findsNothing);

    debugDefaultTargetPlatformOverride = null;
  });
}
