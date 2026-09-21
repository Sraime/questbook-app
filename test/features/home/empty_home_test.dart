import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:questbook/app/remote_providers.dart';
import 'package:questbook/domain/models/character.dart';
import 'package:questbook/features/home/home_screen.dart';
import 'package:questbook/features/home/providers/character_list_provider.dart';

/// Pour beaucoup, c'est le premier écran de leur première partie. « Aucun
/// investigateur » ne leur apprenait rien : le mot vient de l'univers, et
/// personne ne le devine.
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> pumpHome(
    WidgetTester tester, {
    required List<Character> characters,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(412, 915);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          canWriteProvider.overrideWithValue(true),
          characterListProvider.overrideWith((ref) => Stream.value(characters)),
        ],
        child: const MaterialApp(home: Scaffold(body: HomeScreen())),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('sans investigateur, l’écran explique ce que c’est',
      (tester) async {
    await pumpHome(tester, characters: const []);

    expect(find.text('Tu n’as pas encore d’investigateur.'), findsOneWidget);
    expect(
      find.textContaining('le personnage que tu incarnes à la table'),
      findsOneWidget,
      reason: 'constater l’absence n’apprend rien à qui débute',
    );
    expect(
      find.textContaining('Le maître du jeu raconte l’histoire'),
      findsOneWidget,
    );
  });

  testWidgets('le bouton dit ce qu’il crée', (tester) async {
    await pumpHome(tester, characters: const []);

    expect(find.text('+ Nouvel investigateur'), findsOneWidget);
    expect(
      find.textContaining('légende'),
      findsNothing,
      reason: 'le mot ne disait ni ce qu’on crée ni pourquoi',
    );
  });
}
