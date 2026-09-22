import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:questbook/app/providers.dart';
import 'package:questbook/app/remote_providers.dart';
import 'package:questbook/data/auth/auth_repository.dart';
import 'package:questbook/data/remote/auth_tokens.dart';
import 'package:questbook/data/remote/remote_character.dart';
import 'package:questbook/data/remote/remote_table.dart';
import 'package:questbook/data/universe/universe_assets_loader.dart';
import 'package:questbook/design_system/components/qb_button.dart';
import 'package:questbook/domain/models/character.dart';
import 'package:questbook/domain/models/creation_mode_config.dart';
import 'package:questbook/domain/models/universe_config.dart';
import 'package:questbook/domain/models/character_resource.dart';
import 'package:questbook/domain/models/character_stat.dart';
import 'package:questbook/domain/models/tone.dart';
import 'package:questbook/features/character_sheet/providers/character_detail_provider.dart';
import 'package:questbook/features/game_master/models/session_seat.dart';
import 'package:questbook/features/game_master/panels/characters_panel.dart';
import 'package:questbook/features/game_master/providers/game_master_providers.dart';
import 'package:questbook/features/tables/providers/table_providers.dart';

/// Une partie fait perdre des points de vie, et le joueur n'a pas à quitter la
/// séance pour les décompter. Sa fiche s'ouvre donc modifiable depuis le volet
/// Investigateurs ; celles de ses camarades, non.
const _me = AuthUser(
  id: 'user-moi',
  email: 'moi@example.com',
  displayName: 'Robin',
  pictureUrl: null,
);

/// Sans cela, le vrai contrôleur restaure « personne » une microtâche plus
/// tard et efface le compte posé à la main — la fiche cesserait alors d'être
/// la mienne, ce que ces tests cherchent précisément à distinguer.
class _FakeAuthRepository implements AuthRepository {
  @override
  Future<AuthUser?> restoreSession() async => _me;

  @override
  Future<AuthUser> signInWithGoogle() async => _me;

  @override
  Future<AuthUser> rename(String displayName) async => _me;

  @override
  Future<void> deleteAccount() async {}

  @override
  Future<AuthUser> acceptTerms() async => throw UnimplementedError();

  @override
  Future<void> signOut() async {}
}

/// Ce que l'API rend d'une fiche : c'est cette copie-là que la carte affiche,
/// pour soi comme pour les autres.
RemoteCharacter remote({required String id, required String name}) =>
    RemoteCharacter(
      id: id,
      systemId: 'call_of_cthulhu_classique',
      name: name,
      occupation: 'Détective privé',
      description: null,
      level: 1,
      createdAt: DateTime.utc(2026, 9, 1),
      updatedAt: DateTime.utc(2026, 9, 1),
      deletedAt: null,
      stats: const [
        RemoteStat(
          id: 'stat-1',
          kind: 'skill',
          key: 'psychologie',
          label: 'Psychologie',
          value: 60,
          base: null,
          sortOrder: 0,
        ),
      ],
      resources: const [
        RemoteResource(
          id: 'res-1',
          key: 'PV',
          label: 'PV',
          current: 13,
          max: 13,
          tone: 'danger',
        ),
      ],
      inventory: const [],
    );

/// La copie locale, celle que la fiche modifiable lit et écrit.
final _local = Character(
  id: 'char-moi',
  systemId: 'call_of_cthulhu_classique',
  name: 'Ernest Lavoie',
  occupation: 'Détective privé',
  createdAt: DateTime.utc(2026, 9, 1),
  resources: const [
    CharacterResource(
      id: 'res-1',
      characterId: 'char-moi',
      key: 'PV',
      label: 'PV',
      current: 13,
      max: 13,
      tone: Tone.danger,
    ),
  ],
  stats: const [
    CharacterStat(
      id: 'stat-1',
      characterId: 'char-moi',
      kind: StatKind.skill,
      key: 'psychologie',
      label: 'Psychologie',
      value: 60,
      sortOrder: 0,
    ),
  ],
);

RemoteAttendance attendee({
  required String userId,
  required String displayName,
  required String characterId,
  required String characterName,
}) =>
    RemoteAttendance(
      userId: userId,
      user: RemoteUser(id: userId, displayName: displayName, pictureUrl: null),
      status: AttendanceStatus.yes,
      respondedAt: DateTime.utc(2026, 9, 21, 14),
      character: RemoteAttendanceCharacter(
        id: characterId,
        name: characterName,
        occupation: 'Détective privé',
      ),
    );

final _session = RemoteGameSession(
  id: 'session-1',
  tableId: 'table-1',
  title: 'La maison de Water Street',
  description: null,
  startsAt: DateTime.utc(2026, 9, 21, 14, 25),
  location: 'Chez Hélène',
  status: 'scheduled',
  attendances: [
    attendee(
      userId: 'user-moi',
      displayName: 'Robin',
      characterId: 'char-moi',
      characterName: 'Ernest Lavoie',
    ),
    attendee(
      userId: 'user-autre',
      displayName: 'Hélène',
      characterId: 'char-autre',
      characterName: 'Alice Merevin',
    ),
  ],
  myStatus: AttendanceStatus.yes,
  myCharacter: const RemoteAttendanceCharacter(
    id: 'char-moi',
    name: 'Ernest Lavoie',
    occupation: 'Détective privé',
  ),
  scenarioId: null,
  scenario: null,
);

void main() {
  // La fenêtre d'une jauge passe par le moteur de règles, qui veut un univers
  // chargé : c'est le vrai fichier de l'application qu'on lui donne.
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

  Future<void> pumpPanel(
    WidgetTester tester, {
    SessionSeat seat = SessionSeat.player,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(500, 1400);
    addTearDown(tester.view.reset);

    final container = ProviderContainer(overrides: [
      availableUniversesProvider.overrideWithValue([universe]),
      availableCreationModesProvider.overrideWithValue([classique]),
      selectedCreationModeIdProvider
          .overrideWith(() => SelectedCreationModeIdNotifier(classique.id)),
      authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
      canWriteProvider.overrideWithValue(true),
      // Le volet du MJ liste aussi ses PNJ ; sans réponse, la roue tourne
      // pour toujours et l'écran ne se pose jamais.
      sessionNpcsProvider.overrideWith((ref, id) async => const []),
      attendeeCharacterProvider.overrideWith(
        (ref, key) async => key.userId == 'user-moi'
            ? remote(id: 'char-moi', name: 'Ernest Lavoie')
            : remote(id: 'char-autre', name: 'Alice Merevin'),
      ),
      characterDetailProvider.overrideWith((ref, id) => Stream.value(_local)),
    ]);
    addTearDown(container.dispose);

    await container.read(authControllerProvider.future);
    container.read(authControllerProvider.notifier).state =
        const AsyncValue.data(_me);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: CharactersPanel(
              session: _session,
              seat: seat,
              compact: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('sa propre fiche s’ouvre modifiable, sans quitter la séance',
      (tester) async {
    await pumpPanel(tester);

    await tester.tap(find.text('Ernest Lavoie'));
    await tester.pumpAndSettle();

    // Les trois gestes que la carte réclamait : la jauge, l'inventaire, le dé.
    expect(find.widgetWithText(QBButton, 'Lancer un dé'), findsOneWidget);
    expect(find.text('Inventaire'), findsOneWidget);
    expect(find.text('Aperçu'), findsOneWidget);
  });

  testWidgets('la jauge s’ajuste depuis la séance', (tester) async {
    await pumpPanel(tester);

    await tester.tap(find.text('Ernest Lavoie'));
    await tester.pumpAndSettle();

    // Toucher la jauge ouvre la même fenêtre que sous `/perso/:id`.
    await tester.tap(find.text('PV 13/13').last);
    await tester.pumpAndSettle();

    expect(find.text('Points de vie'), findsOneWidget);
  });

  testWidgets('celle d’un camarade reste en lecture', (tester) async {
    await pumpPanel(tester);

    await tester.tap(find.text('Alice Merevin'));
    await tester.pumpAndSettle();

    expect(
      find.widgetWithText(QBButton, 'Lancer un dé'),
      findsNothing,
      reason: 'on ne joue pas l’investigateur d’un autre',
    );
    expect(find.text('Compétences'), findsOneWidget);
  });

  testWidgets('le MJ ne modifie la fiche de personne', (tester) async {
    await pumpPanel(tester, seat: SessionSeat.gameMaster);

    await tester.tap(find.text('Alice Merevin'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(QBButton, 'Lancer un dé'), findsNothing);
  });
}
