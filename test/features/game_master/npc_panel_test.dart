import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:questbook/app/remote_providers.dart';
import 'package:questbook/data/remote/api_exception.dart';
import 'package:questbook/data/remote/remote_table.dart';
import 'package:questbook/data/remote/session_api.dart';
import 'package:questbook/design_system/components/qb_button.dart';
import 'package:questbook/features/game_master/panels/characters_panel.dart';

/// Les seuls appels que la section attend. Le reste du client n'a pas à
/// exister pour que ces tests tiennent.
class _FakeSessionApi implements SessionApi {
  _FakeSessionApi({this.failure});

  final ApiException? failure;

  List<RemoteNpc> stored = const [];
  final List<(String, String)> created = [];
  final List<String> deleted = [];
  (String, String?, String?)? patched;

  @override
  Future<List<RemoteNpc>> listNpcs(String sessionId) async {
    if (failure case final error?) throw error;
    return stored;
  }

  @override
  Future<RemoteNpc> createNpc(
    String sessionId, {
    required String name,
    String? description,
  }) async {
    created.add((name, description ?? ''));
    final npc = RemoteNpc(
      id: 'npc-${created.length}',
      name: name,
      description: description ?? '',
    );
    stored = [...stored, npc];
    return npc;
  }

  @override
  Future<RemoteNpc> updateNpc(
    String sessionId,
    String npcId, {
    String? name,
    String? description,
  }) async {
    patched = (npcId, name, description);
    stored = [
      for (final npc in stored)
        if (npc.id == npcId)
          RemoteNpc(
            id: npc.id,
            name: name ?? npc.name,
            description: description ?? npc.description,
          )
        else
          npc,
    ];
    return stored.firstWhere((npc) => npc.id == npcId);
  }

  @override
  Future<void> deleteNpc(String sessionId, String npcId) async {
    deleted.add(npcId);
    stored = stored.where((npc) => npc.id != npcId).toList();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} non simulé');
}

final _session = RemoteGameSession(
  id: 'session-1',
  tableId: 'table-1',
  title: 'Chapitre III — Les ruines',
  description: null,
  startsAt: DateTime.utc(2026, 9, 19, 20),
  location: 'Chez Marie',
  status: 'scheduled',
  attendances: const [],
  myStatus: null,
  myCharacter: null,
  scenarioId: null,
  scenario: null,
);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<_FakeSessionApi> pumpPanel(
    WidgetTester tester, {
    List<RemoteNpc> npcs = const [],
    ApiException? failure,
    bool compact = false,
  }) async {
    final api = _FakeSessionApi(failure: failure)..stored = npcs;

    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = compact
        ? const Size(411, 890)
        : const Size(800, 1600);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sessionApiProvider.overrideWithValue(api)],
        child: MaterialApp(
          home: Scaffold(
            body: CharactersPanel(session: _session, compact: compact),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    return api;
  }

  Future<void> openAddDialog(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(QBButton, '+ Ajouter un PNJ'));
    await tester.pumpAndSettle();
  }

  testWidgets('les personnages des joueurs sont des investigateurs',
      (tester) async {
    await pumpPanel(tester);

    expect(find.text('Investigateurs'), findsOneWidget);
    expect(
      find.text('Personnages joueurs'),
      findsNothing,
      reason: 'l’app ne parle plus que de l’univers de Cthulhu',
    );
    expect(
      find.text('Personnages non-joueurs'),
      findsOneWidget,
      reason: 'un PNJ reste un PNJ : seuls ceux des joueurs sont renommés',
    );
  });

  testWidgets('sur un écran étroit, titre et bouton tiennent sur une ligne',
      (tester) async {
    await pumpPanel(tester, compact: true);

    // En toutes lettres, le titre prenait presque toute la largeur : il
    // passait sur deux lignes et le bouton venait à cheval sur le sous-titre.
    final title = find.text('PNJ');
    expect(title, findsOneWidget);
    expect(tester.getRect(title).height, lessThan(24));

    final button = find.widgetWithText(QBButton, '+ Ajouter');
    expect(
      tester.getRect(button).top,
      lessThan(tester.getRect(title).bottom),
    );

    // Son ombre portée descend de 8 points et déborde de 14 de plus : sans
    // marge, elle salit le sous-titre.
    final subtitle = find.text(
      'Créatures, indicateurs, esprits. Tes joueurs ne les voient pas.',
    );
    expect(subtitle, findsOneWidget);
    expect(
      tester.getRect(subtitle).top - tester.getRect(button).bottom,
      greaterThanOrEqualTo(14),
    );
  });

  testWidgets('la section existe, vide, sous les fiches des joueurs',
      (tester) async {
    await pumpPanel(tester);

    expect(find.text('Personnages non-joueurs'), findsOneWidget);
    expect(
      find.textContaining('Note ici ce que tes joueurs vont rencontrer'),
      findsOneWidget,
    );
  });

  testWidgets('en ajouter un l’envoie et l’affiche', (tester) async {
    final api = await pumpPanel(tester);

    await openAddDialog(tester);

    await tester.enterText(
      find.widgetWithText(TextField, 'Le rôdeur du seuil'),
      'Le rôdeur du seuil',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Ce qu’il veut, ce qu’il sait…'),
      'Ne parle qu’aux initiés.',
    );
    await tester.tap(find.widgetWithText(QBButton, 'Enregistrer'));
    await tester.pumpAndSettle();

    expect(api.created, [('Le rôdeur du seuil', 'Ne parle qu’aux initiés.')]);
    expect(find.text('Le rôdeur du seuil'), findsOneWidget);
    expect(find.text('Ne parle qu’aux initiés.'), findsOneWidget);
  });

  testWidgets('un nom vide ne part pas au serveur', (tester) async {
    final api = await pumpPanel(tester);

    await openAddDialog(tester);

    await tester.tap(find.widgetWithText(QBButton, 'Enregistrer'));
    await tester.pumpAndSettle();

    expect(api.created, isEmpty);
    expect(find.text('Donne-lui un nom.'), findsOneWidget);
  });

  testWidgets('toucher une carte rouvre le même formulaire', (tester) async {
    final api = await pumpPanel(tester, npcs: const [
      RemoteNpc(id: 'npc-1', name: 'Créature', description: 'Au plafond.'),
    ]);

    await tester.tap(find.text('Créature'));
    await tester.pumpAndSettle();

    // Le formulaire s'ouvre rempli : corriger une coquille ne doit pas
    // obliger a tout retaper.
    expect(find.widgetWithText(TextField, 'Créature'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Au plafond.'),
      'Rampe au plafond de la cave.',
    );
    await tester.tap(find.widgetWithText(QBButton, 'Enregistrer'));
    await tester.pumpAndSettle();

    expect(api.patched, ('npc-1', null, 'Rampe au plafond de la cave.'));
    expect(find.text('Rampe au plafond de la cave.'), findsOneWidget);
  });

  testWidgets('le retirer demande confirmation', (tester) async {
    final api = await pumpPanel(tester, npcs: const [
      RemoteNpc(id: 'npc-1', name: 'Créature', description: ''),
    ]);

    await tester.tap(find.bySemanticsLabel('Retirer Créature'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Non'));
    await tester.pumpAndSettle();
    expect(api.deleted, isEmpty);

    await tester.tap(find.bySemanticsLabel('Retirer Créature'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retirer'));
    await tester.pumpAndSettle();

    expect(api.deleted, ['npc-1']);
    expect(find.text('Créature'), findsNothing);
  });

  testWidgets('sans réseau, la section le dit', (tester) async {
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
