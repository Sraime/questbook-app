import 'dart:convert';
import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:questbook/app/providers.dart';
import 'package:questbook/app/remote_providers.dart';
import 'package:questbook/data/universe/universe_assets_loader.dart';
import 'package:questbook/domain/models/character.dart';
import 'package:questbook/domain/models/creation_mode_config.dart';
import 'package:questbook/domain/models/universe_config.dart';
import 'package:questbook/features/character_sheet/character_sheet_screen.dart';
import 'package:questbook/features/character_sheet/providers/character_detail_provider.dart';

/// Supprimer un investigateur se fait depuis le bas de sa fiche, après une
/// confirmation, et ramène à la liste.
const _label = 'Supprimer l’investigateur';

final _character = Character(
  id: 'char-1',
  systemId: 'call_of_cthulhu_classique',
  name: 'Ernest Lavoie',
  occupation: 'Détective privé',
  createdAt: DateTime.utc(2026, 9, 1),
);

class _RecordingActions implements CharacterActions {
  final deleted = <String>[];

  @override
  Future<void> delete(String characterId) async => deleted.add(characterId);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late UniverseConfig universe;
  late CreationModeConfig classique;

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    final universeRaw = File('assets/universes/universe_call_of_cthulhu.json')
        .readAsStringSync();
    universe = UniverseConfig.fromJson(
      jsonDecode(universeRaw) as Map<String, dynamic>,
    );
    final entry = universe.creationModes
        .firstWhere((c) => c.id == 'call_of_cthulhu_classique');
    final modeRaw =
        File('assets/universes/${entry.configurationFile}').readAsStringSync();
    classique = buildCreationModeConfig(
      universe,
      entry,
      jsonDecode(modeRaw) as Map<String, dynamic>,
    );
  });

  Future<_RecordingActions> pump(
    WidgetTester tester, {
    bool canWrite = true,
    Widget Function(String id)? sheet,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(500, 2400);
    addTearDown(tester.view.reset);

    final actions = _RecordingActions();
    final router = GoRouter(
      initialLocation: '/perso/char-1',
      routes: [
        GoRoute(
          path: '/perso',
          builder: (_, _) => const Scaffold(body: Text('Liste')),
          routes: [
            GoRoute(
              path: ':id',
              builder: (_, state) => Scaffold(
                body: sheet?.call(state.pathParameters['id']!) ??
                    CharacterSheetScreen(
                      characterId: state.pathParameters['id']!,
                    ),
              ),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          availableUniversesProvider.overrideWithValue([universe]),
          availableCreationModesProvider.overrideWithValue([classique]),
          canWriteProvider.overrideWithValue(canWrite),
          characterDetailProvider
              .overrideWith((ref, id) => Stream.value(_character)),
          characterActionsProvider.overrideWithValue(actions),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    return actions;
  }

  testWidgets('se supprime après confirmation, et ramène à la liste',
      (tester) async {
    final actions = await pump(tester);

    await tester.tap(find.text(_label));
    await tester.pumpAndSettle();

    expect(find.text('Supprimer Ernest Lavoie ?'), findsOneWidget);
    expect(find.textContaining('il en sera retiré'), findsOneWidget);

    await tester.tap(find.text('Supprimer'));
    await tester.pumpAndSettle();

    expect(actions.deleted, ['char-1']);
    expect(find.text('Liste'), findsOneWidget);
  });

  testWidgets('« Non » ne supprime rien', (tester) async {
    final actions = await pump(tester);

    await tester.tap(find.text(_label));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Non'));
    await tester.pumpAndSettle();

    expect(actions.deleted, isEmpty);
    expect(find.text('Ernest Lavoie'), findsOneWidget);
  });

  testWidgets('hors ligne, le bouton n’apparaît pas', (tester) async {
    await pump(tester, canWrite: false);

    expect(find.text(_label), findsNothing);
  });

  testWidgets('la fiche ouverte en séance ne le propose pas', (tester) async {
    await pump(
      tester,
      sheet: (id) => CharacterSheetBody(
        characterId: id,
        padding: EdgeInsets.zero,
      ),
    );

    expect(find.text('Ernest Lavoie'), findsOneWidget);
    expect(find.text(_label), findsNothing);
  });
}
