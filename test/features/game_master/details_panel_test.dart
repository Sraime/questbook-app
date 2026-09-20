import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:questbook/app/remote_providers.dart';
import 'package:questbook/data/remote/remote_scenario.dart';
import 'package:questbook/data/remote/remote_table.dart';
import 'package:questbook/data/remote/session_api.dart';
import 'package:questbook/design_system/components/qb_button.dart';
import 'package:questbook/features/game_master/panels/details_panel.dart';
import 'package:questbook/features/scenarios/providers/scenario_providers.dart';

/// Ce que le volet demande à l'API, et rien d'autre : le reste des appels
/// n'a pas à exister pour que ces tests tiennent.
class _FakeSessionApi implements SessionApi {
  String? updatedTitle;
  DateTime? updatedStartsAt;
  String? cancelledId;

  @override
  Future<RemoteGameSession> update(
    String id, {
    String? title,
    String? description,
    DateTime? startsAt,
    String? location,
    String? scenarioId,
    bool clearScenario = false,
  }) async {
    updatedTitle = title;
    updatedStartsAt = startsAt;
    return _session;
  }

  @override
  Future<RemoteGameSession> cancel(String id) async {
    cancelledId = id;
    return _session;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} non simulé');
}

final _now = DateTime.utc(2026, 9, 19, 20);

final _session = RemoteGameSession(
  id: 'session-1',
  tableId: 'table-1',
  title: 'Chapitre III — Les ruines',
  description: null,
  startsAt: _now,
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
    RemoteGameSession? session,
    VoidCallback? onCancelled,
  }) async {
    final api = _FakeSessionApi();

    // Le formulaire et le bouton d'annulation tiennent sur une page bien plus
    // haute que les 600 points par défaut ; sans cela, la fin du volet n'est
    // jamais construite.
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 1600);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionApiProvider.overrideWithValue(api),
          downloadedScenariosProvider
              .overrideWith((ref) async => const <RemoteScenarioDetail>[]),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: DetailsPanel(
              tableId: 'table-1',
              session: session ?? _session,
              onCancelled: onCancelled ?? () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    return api;
  }

  testWidgets('enregistrer n’envoie que ce qui a bougé', (tester) async {
    final api = await pumpPanel(tester);

    await tester.enterText(
      find.widgetWithText(TextField, 'Chapitre III — Les ruines'),
      'Chapitre IV — Le puits',
    );
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    expect(api.updatedTitle, 'Chapitre IV — Le puits');
    expect(
      api.updatedStartsAt,
      isNull,
      reason: 'une date renvoyée telle quelle réveillerait toute la table',
    );
  });

  testWidgets('enregistrer laisse le MJ dans son volet', (tester) async {
    await pumpPanel(tester);

    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    expect(
      find.text('Session enregistrée'),
      findsOneWidget,
      reason: 'corriger une heure ne doit pas sortir de la partie en cours',
    );
    expect(find.byType(DetailsPanel), findsOneWidget);
  });

  testWidgets('annuler la session referme le mode MJ', (tester) async {
    var closed = false;
    final api = await pumpPanel(tester, onCancelled: () => closed = true);

    await tester.tap(find.widgetWithText(QBButton, 'Annuler la session'));
    await tester.pumpAndSettle();

    // Le dialogue reprend le même libellé : c'est le bouton du dialogue qu'on
    // veut, pas celui du volet resté derrière.
    await tester.tap(find.widgetWithText(TextButton, 'Annuler la session'));
    await tester.pumpAndSettle();

    expect(api.cancelledId, 'session-1');
    expect(closed, isTrue);
  });

  testWidgets('une session déjà annulée ne s’annule pas deux fois',
      (tester) async {
    await pumpPanel(
      tester,
      session: RemoteGameSession(
        id: 'session-1',
        tableId: 'table-1',
        title: _session.title,
        description: null,
        startsAt: _now,
        location: _session.location,
        status: 'cancelled',
        attendances: const [],
        myStatus: null,
        myCharacter: null,
        scenarioId: null,
        scenario: null,
      ),
    );

    expect(find.text('Cette session est annulée.'), findsOneWidget);
    expect(find.widgetWithText(QBButton, 'Annuler la session'), findsNothing);
  });
}
