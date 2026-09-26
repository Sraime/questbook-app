import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:questbook/app/remote_providers.dart';
import 'package:questbook/data/remote/api_exception.dart';
import 'package:questbook/data/remote/remote_table.dart';
import 'package:questbook/data/remote/session_api.dart';
import 'package:questbook/design_system/components/qb_button.dart';
import 'package:questbook/design_system/components/qb_card.dart';
import 'package:questbook/design_system/components/qb_dialog.dart';
import 'package:questbook/features/game_master/panels/shared_clues_panel.dart';

/// Le seul appel que le volet du joueur connaisse. Qu'il n'en connaisse qu'un
/// est la moitie de ce que ce fichier verifie : `listClues`, la liste du MJ,
/// n'est pas simulee ici, et un volet qui la demanderait echouerait.
class _FakeSessionApi implements SessionApi {
  _FakeSessionApi({this.failure});

  final ApiException? failure;

  List<RemoteSharedClue> stored = const [];
  int appels = 0;

  @override
  Future<List<RemoteSharedClue>> myClues(String sessionId) async {
    appels++;
    if (failure case final error?) throw error;
    return stored;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} non simulé');
}

const _lettre = RemoteSharedClue(
  id: 'clue-1',
  title: 'La lettre de Corbitt',
  kind: 'markdown',
  contentMarkdown: '## Mon ami\n\nNe descends pas à la cave.',
);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<_FakeSessionApi> pumpPanel(
    WidgetTester tester, {
    List<RemoteSharedClue> clues = const [],
    ApiException? failure,
  }) async {
    final api = _FakeSessionApi(failure: failure)..stored = clues;

    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(411, 890);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sessionApiProvider.overrideWithValue(api)],
        child: const MaterialApp(
          home: Scaffold(body: SharedCluesPanel(sessionId: 'session-1')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    return api;
  }

  /// Le cas courant en debut de partie, et donc celui qu'on verra le plus.
  testWidgets('sans rien de transmis, le volet ne laisse rien deviner',
      (tester) async {
    await pumpPanel(tester);

    expect(find.text('Rien pour l’instant.'), findsOneWidget);

    // Ni carte, ni titre, ni le moindre chiffre : un « 0 sur 4 » suffirait a
    // dire au joueur qu'il en existe trois qu'on lui cache.
    expect(find.byType(QBCard), findsNothing);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Text && RegExp(r'\d').hasMatch(widget.data ?? ''),
      ),
      findsNothing,
    );
  });

  testWidgets('un indice ouvert se lit dans une fenêtre, rendu et non en '
      'markdown brut', (tester) async {
    await pumpPanel(tester, clues: const [_lettre]);

    // Dans la liste, il ne montre que son titre : le joueur qui en a ramasse
    // cinq cherche celui d'avant-hier.
    expect(find.text('La lettre de Corbitt'), findsOneWidget);
    expect(find.textContaining('Ne descends pas'), findsNothing);

    await tester.tap(find.text('La lettre de Corbitt'));
    await tester.pumpAndSettle();

    expect(find.byType(QBDialog), findsOneWidget);
    expect(find.textContaining('Ne descends pas'), findsOneWidget);
    expect(find.textContaining('## Mon ami'), findsNothing);
  });

  testWidgets('le joueur n’a aucun geste sur ce qu’il lit', (tester) async {
    await pumpPanel(tester, clues: const [_lettre]);
    await tester.tap(find.text('La lettre de Corbitt'));
    await tester.pumpAndSettle();

    // Pas « desactive » : les boutons du MJ n'existent pas de ce cote, ni
    // dans la liste, ni au bas de la fenetre de lecture.
    expect(find.byType(QBButton), findsNothing);
    expect(find.textContaining('Ajouter'), findsNothing);
    expect(find.text('Partager'), findsNothing);
    expect(find.text('Modifier'), findsNothing);
  });

  /// Pas de temps reel : c'est l'ouverture du volet qui va chercher ce qui a
  /// ete transmis entre-temps. Si la liste restait en cache, un indice ouvert
  /// pendant la partie n'arriverait jamais.
  testWidgets('rouvrir le volet redemande la liste', (tester) async {
    final api = _FakeSessionApi()..stored = const [_lettre];
    final ouvert = ValueNotifier(true);
    addTearDown(ouvert.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sessionApiProvider.overrideWithValue(api)],
        child: MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder<bool>(
              valueListenable: ouvert,
              builder: (context, visible, _) => visible
                  ? const SharedCluesPanel(sessionId: 'session-1')
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(api.appels, 1);

    // Le joueur part regarder le plateau, puis revient.
    ouvert.value = false;
    await tester.pumpAndSettle();
    ouvert.value = true;
    await tester.pumpAndSettle();

    expect(api.appels, 2);
  });

  testWidgets('sans réseau, le volet le dit', (tester) async {
    await pumpPanel(
      tester,
      failure: const ApiException(
        code: 'NETWORK_ERROR',
        message: 'Impossible de joindre le serveur Questbook.',
      ),
    );

    expect(
      find.text('Impossible de joindre le serveur Questbook.'),
      findsOneWidget,
    );
  });
}
