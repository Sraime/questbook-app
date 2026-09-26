import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:questbook/app/remote_providers.dart';
import 'package:questbook/data/remote/api_exception.dart';
import 'package:questbook/data/remote/remote_table.dart';
import 'package:questbook/data/remote/session_api.dart';
import 'package:questbook/design_system/components/qb_button.dart';
import 'package:questbook/design_system/components/qb_dialog.dart';
import 'package:questbook/features/game_master/panels/clues_panel.dart';

/// Les seuls appels que le volet attend. Le reste du client n'a pas à exister
/// pour que ces tests tiennent.
class _FakeSessionApi implements SessionApi {
  _FakeSessionApi({this.failure});

  final ApiException? failure;

  List<RemoteClue> stored = const [];
  final List<(String, String)> created = [];
  final List<String> deleted = [];
  (String, List<String>)? shared;
  (String, String?, String?)? patched;

  @override
  Future<List<RemoteClue>> listClues(String sessionId) async {
    if (failure case final error?) throw error;
    return stored;
  }

  @override
  Future<RemoteClue> createClue(
    String sessionId, {
    required String title,
    String? contentMarkdown,
  }) async {
    created.add((title, contentMarkdown ?? ''));
    final clue = RemoteClue(
      id: 'clue-${created.length}',
      title: title,
      kind: 'markdown',
      contentMarkdown: contentMarkdown ?? '',
      sharedWith: const [],
    );
    stored = [...stored, clue];
    return clue;
  }

  @override
  Future<RemoteClue> updateClue(
    String sessionId,
    String clueId, {
    String? title,
    String? contentMarkdown,
  }) async {
    patched = (clueId, title, contentMarkdown);
    stored = [
      for (final clue in stored)
        if (clue.id == clueId)
          RemoteClue(
            id: clue.id,
            title: title ?? clue.title,
            kind: clue.kind,
            contentMarkdown: contentMarkdown ?? clue.contentMarkdown,
            sharedWith: clue.sharedWith,
          )
        else
          clue,
    ];
    return stored.firstWhere((clue) => clue.id == clueId);
  }

  @override
  Future<void> deleteClue(String sessionId, String clueId) async {
    deleted.add(clueId);
    stored = stored.where((clue) => clue.id != clueId).toList();
  }

  @override
  Future<RemoteClue> shareClue(
    String sessionId,
    String clueId, {
    required List<String> userIds,
  }) async {
    shared = (clueId, userIds);
    stored = [
      for (final clue in stored)
        if (clue.id == clueId)
          RemoteClue(
            id: clue.id,
            title: clue.title,
            kind: clue.kind,
            contentMarkdown: clue.contentMarkdown,
            sharedWith: userIds,
          )
        else
          clue,
    ];
    return stored.firstWhere((clue) => clue.id == clueId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} non simulé');
}

RemoteTableMember _member(String id, String name, TableRole role) =>
    RemoteTableMember(
      userId: id,
      role: role,
      joinedAt: DateTime.utc(2026, 9, 19),
      user: RemoteUser(id: id, displayName: name, pictureUrl: null),
    );

final _members = [
  _member('gm-1', 'Marie', TableRole.gameMaster),
  _member('p-1', 'Robin', TableRole.player),
  _member('p-2', 'Lena', TableRole.player),
];

const _lettre = RemoteClue(
  id: 'clue-1',
  title: 'La lettre de Corbitt',
  kind: 'markdown',
  contentMarkdown: '## Mon ami\n\nNe descends pas à la cave.',
  sharedWith: [],
);

/// Livré par l'aventure : le MJ le transmet, mais il appartient à son auteur.
const _carnet = RemoteClue(
  id: 'clue-2',
  title: 'Carnet de la crique',
  kind: 'markdown',
  contentMarkdown: '> 12 mars — La lumière n’est plus à moi.',
  sharedWith: [],
  origin: 'scenario',
);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<_FakeSessionApi> pumpPanel(
    WidgetTester tester, {
    List<RemoteClue> clues = const [],
    ApiException? failure,
    bool compact = false,
  }) async {
    final api = _FakeSessionApi(failure: failure)..stored = clues;

    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize =
        compact ? const Size(411, 890) : const Size(800, 1600);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sessionApiProvider.overrideWithValue(api)],
        child: MaterialApp(
          home: Scaffold(
            body: CluesPanel(
              sessionId: 'session-1',
              members: _members,
              compact: compact,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    return api;
  }

  testWidgets('le volet vide invite à en ajouter un', (tester) async {
    await pumpPanel(tester);

    expect(find.text('Indices'), findsOneWidget);
    expect(
      find.textContaining('Ajoute ce que tes joueurs trouveront'),
      findsOneWidget,
    );
  });

  testWidgets('en composer un l’envoie et l’affiche', (tester) async {
    final api = await pumpPanel(tester);

    await tester.tap(find.widgetWithText(QBButton, '+ Ajouter un indice'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'La lettre de Corbitt'),
      'La lettre de Corbitt',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Ce que tes joueurs vont lire…'),
      'Ne descends pas.',
    );
    await tester.tap(find.widgetWithText(QBButton, 'Enregistrer'));
    await tester.pumpAndSettle();

    expect(api.created, [('La lettre de Corbitt', 'Ne descends pas.')]);
    expect(find.text('La lettre de Corbitt'), findsOneWidget);
  });

  testWidgets('un titre vide ne part pas au serveur', (tester) async {
    final api = await pumpPanel(tester);

    await tester.tap(find.widgetWithText(QBButton, '+ Ajouter un indice'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(QBButton, 'Enregistrer'));
    await tester.pumpAndSettle();

    expect(api.created, isEmpty);
    expect(find.text('Donne-lui un titre.'), findsOneWidget);
  });

  /// La liste se parcourt du regard : un titre par carte, et c'est tout. Qui
  /// a reçu quoi se lit dans la fenêtre de partage, cases cochées.
  testWidgets('la liste ne porte que des titres', (tester) async {
    await pumpPanel(tester, clues: const [
      _lettre,
      RemoteClue(
        id: 'clue-2',
        title: 'Le plan',
        kind: 'markdown',
        contentMarkdown: 'Trois pièces.',
        sharedWith: ['p-1', 'p-2'],
      ),
    ]);

    expect(find.text('La lettre de Corbitt'), findsOneWidget);
    expect(find.text('Le plan'), findsOneWidget);
    expect(find.textContaining('joueur'), findsNothing);
    expect(find.text('Non transmis'), findsNothing);
  });

  testWidgets('le contenu s’ouvre dans une fenêtre, rendu et non en markdown '
      'brut', (tester) async {
    await pumpPanel(tester, clues: const [_lettre]);

    // Dans la liste, la carte ne montre que son titre.
    expect(find.textContaining('Ne descends pas'), findsNothing);

    await tester.tap(find.text('La lettre de Corbitt'));
    await tester.pumpAndSettle();

    expect(find.byType(QBDialog), findsOneWidget);
    expect(find.textContaining('Ne descends pas'), findsOneWidget);
    expect(
      find.textContaining('## Mon ami'),
      findsNothing,
      reason: 'le MJ relit ce que le joueur lira, pas la source',
    );
  });

  testWidgets('partager coche des noms, et le MJ n’en fait pas partie',
      (tester) async {
    final api = await pumpPanel(tester, clues: const [_lettre]);

    await tester.tap(find.text('La lettre de Corbitt'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(QBButton, 'Partager'));
    await tester.pumpAndSettle();

    expect(find.text('Robin'), findsOneWidget);
    expect(find.text('Lena'), findsOneWidget);
    expect(
      find.text('Marie'),
      findsNothing,
      reason: 'le MJ ne se transmet rien à lui-même',
    );

    await tester.tap(find.text('Robin'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(QBButton, 'Valider'));
    await tester.pumpAndSettle();

    expect(api.shared?.$1, 'clue-1');
    expect(api.shared?.$2, ['p-1']);
  });

  /// Reprendre un indice est le même geste, avec un nom de moins. Il ne doit
  /// donc pas y avoir de second bouton, ni de refus quand la liste se vide.
  testWidgets('tout décocher reprend l’indice à tout le monde', (tester) async {
    final api = await pumpPanel(tester, clues: const [
      RemoteClue(
        id: 'clue-1',
        title: 'La lettre',
        kind: 'markdown',
        contentMarkdown: 'X',
        sharedWith: ['p-1'],
      ),
    ]);

    await tester.tap(find.text('La lettre'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(QBButton, 'Partager'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Robin'));
    await tester.pumpAndSettle();

    // Le libellé dit l'état d'arrivée : « Partager » mentirait ici.
    expect(
      find.widgetWithText(QBButton, 'Ne le montrer à personne'),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(QBButton, 'Ne le montrer à personne'));
    await tester.pumpAndSettle();

    expect(api.shared?.$1, 'clue-1');
    expect(api.shared?.$2, isEmpty);
  });

  /// Vu sur l'émulateur : l'indice disait « 2 joueurs » alors qu'un seul nom
  /// était coché. Le second destinataire n'était plus joueur de la table, si
  /// bien qu'aucune case ne le montrait — et valider le renvoyait au serveur.
  testWidgets('valider n’ouvre l’indice qu’aux noms montrés', (tester) async {
    final api = await pumpPanel(tester, clues: const [
      RemoteClue(
        id: 'clue-1',
        title: 'La lettre',
        kind: 'markdown',
        contentMarkdown: 'X',
        sharedWith: ['p-1', 'gm-1'],
      ),
    ]);

    await tester.tap(find.text('La lettre'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(QBButton, 'Partager'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(QBButton, 'Valider'));
    await tester.pumpAndSettle();

    expect(api.shared?.$2, ['p-1']);
  });

  /// Les trois gestes au même endroit, parce qu'on les prend au même moment.
  /// Supprimer vivait au fond du formulaire de modification, ce qui demandait
  /// d'ouvrir une correction pour ne rien corriger.
  testWidgets('le supprimer se fait depuis sa lecture, en deux temps',
      (tester) async {
    final api = await pumpPanel(tester, clues: const [_lettre]);

    await tester.tap(find.text('La lettre de Corbitt'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Supprimer cet indice'));
    await tester.pumpAndSettle();
    expect(api.deleted, isEmpty);

    await tester.tap(find.text('Confirmer : personne ne le lira plus'));
    await tester.pumpAndSettle();

    expect(api.deleted, ['clue-1']);
  });

  testWidgets('le formulaire de modification ne sait qu’enregistrer',
      (tester) async {
    await pumpPanel(tester, clues: const [_lettre]);

    await tester.tap(find.text('La lettre de Corbitt'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(QBButton, 'Modifier'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(QBButton, 'Enregistrer'), findsOneWidget);
    expect(find.text('Supprimer cet indice'), findsNothing);
    expect(find.text('Partager'), findsNothing);
  });

  testWidgets('corriger un indice n’envoie que le champ touché',
      (tester) async {
    final api = await pumpPanel(tester, clues: const [_lettre]);

    await tester.tap(find.text('La lettre de Corbitt'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(QBButton, 'Modifier'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'La lettre de Corbitt'),
      'La lettre de Corbitt, relue',
    );
    await tester.tap(find.widgetWithText(QBButton, 'Enregistrer'));
    await tester.pumpAndSettle();

    expect(api.patched, ('clue-1', 'La lettre de Corbitt, relue', null));
    expect(find.text('La lettre de Corbitt, relue'), findsOneWidget);
  });

  /// Ne rien envoyer du tout, et surtout pas un patch vide : le serveur le
  /// refuse, à juste titre, et le MJ lisait « Request payload is invalid »
  /// pour avoir enregistré ce qu'il n'avait pas touché.
  testWidgets('enregistrer sans avoir rien touché referme la fenêtre',
      (tester) async {
    final api = await pumpPanel(tester, clues: const [_lettre]);

    await tester.tap(find.text('La lettre de Corbitt'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(QBButton, 'Modifier'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(QBButton, 'Enregistrer'));
    await tester.pumpAndSettle();

    expect(api.patched, isNull);
    expect(find.byType(QBDialog), findsNothing);
  });

  /// Le scénario l'a écrit pour qu'on le transmette : c'est le seul geste qui
  /// reste, et le seul qui ait du sens.
  testWidgets('un indice du scénario se partage, et ne se touche pas',
      (tester) async {
    await pumpPanel(tester, clues: const [_carnet]);

    expect(find.text('du scénario'), findsOneWidget);

    await tester.tap(find.text('Carnet de la crique'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(QBButton, 'Partager'), findsOneWidget);
    expect(find.widgetWithText(QBButton, 'Modifier'), findsNothing);
    expect(find.text('Supprimer cet indice'), findsNothing);
  });

  testWidgets('celui que le MJ a écrit garde ses trois gestes', (tester) async {
    await pumpPanel(tester, clues: const [_lettre]);

    expect(find.text('du scénario'), findsNothing);

    await tester.tap(find.text('La lettre de Corbitt'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(QBButton, 'Partager'), findsOneWidget);
    expect(find.widgetWithText(QBButton, 'Modifier'), findsOneWidget);
    expect(find.text('Supprimer cet indice'), findsOneWidget);
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
