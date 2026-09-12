import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:questbook/features/rulebook/rulebook_chapter_screen.dart';
import 'package:questbook/features/rulebook/rulebook_screen.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('sommaire names every chapter and none are marked as coming',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: RulebookScreen()));

    expect(find.text('Livre de règle'), findsOneWidget);
    expect(find.text('Sommaire'), findsOneWidget);
    expect(find.text('Tests'), findsOneWidget);
    expect(find.text('Combat'), findsOneWidget);
    expect(find.text('Poursuites'), findsOneWidget);
    expect(find.textContaining('Prochainement'), findsNothing);
  });

  testWidgets('Tests chapter paints its first section on a short viewport',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: RulebookChapterScreen(chapterId: 'tests')),
    );

    expect(find.text('Tests'), findsOneWidget);
    expect(find.text('Niveaux de difficulté'), findsOneWidget);
    expect(find.text('≤ la moitié'), findsOneWidget);
  });

  testWidgets('Combat chapter paints its first section on a short viewport',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: RulebookChapterScreen(chapterId: 'combat')),
    );

    expect(find.text('Combat'), findsOneWidget);
    expect(find.text('Ordre et surprise'), findsOneWidget);
  });

  testWidgets('Santé chapter paints its first section on a short viewport',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: RulebookChapterScreen(chapterId: 'sante')),
    );

    expect(find.text('Santé et dégâts'), findsOneWidget);
    expect(find.text('Points de vie et blessure grave'), findsOneWidget);
  });

  testWidgets('Folie chapter paints its first section on a short viewport',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: RulebookChapterScreen(chapterId: 'folie')),
    );

    expect(find.text('Santé mentale'), findsOneWidget);
    expect(find.textContaining('égale au Pouvoir'), findsOneWidget);
  });

  testWidgets('Poursuites chapter paints its first section on a short viewport',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RulebookChapterScreen(chapterId: 'poursuites'),
      ),
    );

    expect(find.text('Poursuites'), findsOneWidget);
    expect(find.text('Mise en place'), findsOneWidget);
  });
}
