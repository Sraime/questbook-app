import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:questbook/features/assets/assets_library_screen.dart';
import 'package:questbook/features/assets/providers/owned_assets_provider.dart';
import 'package:questbook/features/game_master/models/board_catalog.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> pumpLibrary(
    WidgetTester tester, {
    Set<String> ownedKeys = const {},
  }) async {
    // Haut, pour que tout le catalogue soit posé d'un coup : une ListView ne
    // monte que ce qui est à l'écran, et la vitrine se juge entière.
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 2400);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          boardCatalogueProvider
              .overrideWithValue(boardAssetSectionsFor(ownedKeys)),
        ],
        child: const MaterialApp(home: AssetsLibraryScreen()),
      ),
    );
  }

  testWidgets('un pion acheté rejoint la vitrine', (tester) async {
    await pumpLibrary(tester, ownedKeys: const {'grand_ancien'});

    expect(find.text('Ma collection'), findsOneWidget);
    expect(find.text('Le Grand Ancien'), findsOneWidget);
  });

  testWidgets('shelves the pions by category', (tester) async {
    await pumpLibrary(tester);

    expect(find.text('Assets'), findsOneWidget);
    expect(find.text('Personnages'), findsOneWidget);
    expect(find.text('Environnement'), findsOneWidget);
    expect(find.text('Effets'), findsOneWidget);
  });

  testWidgets('shows everything the game master can actually pose',
      (tester) async {
    await pumpLibrary(tester);

    // Le catalogue est la source, l'écran n'en est que la vitrine : un pion
    // ajouté au mode MJ doit apparaître ici sans qu'on y pense, et un écran
    // qui n'en montrerait qu'une partie mentirait sur ce dont on dispose.
    for (final section in boardAssetSections) {
      expect(find.text(section.title), findsOneWidget);
      for (final asset in section.assets) {
        expect(
          find.text(asset.name),
          findsOneWidget,
          reason: '${asset.name} manque à la bibliothèque',
        );
      }
    }
  });
}
