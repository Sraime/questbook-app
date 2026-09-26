import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:questbook/app/remote_providers.dart';
import 'package:questbook/data/auth/auth_repository.dart';
import 'package:questbook/data/local/database.dart';
import 'package:questbook/data/local/session_board_dao.dart';
import 'package:questbook/data/remote/auth_tokens.dart';
import 'package:questbook/data/remote/remote_table.dart';
import 'package:questbook/features/game_master/game_master_screen.dart';
import 'package:questbook/features/game_master/providers/game_master_providers.dart';
import 'package:questbook/features/tables/providers/table_providers.dart';

const _account = AuthUser(
  id: 'gm-1',
  email: 'marie@example.com',
  displayName: 'Marie',
  pictureUrl: null,
);

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<AuthUser?> restoreSession() async => _account;

  @override
  Future<AuthUser> signInWithGoogle() async => _account;

  @override
  Future<AuthUser> signInWithApple() async => _account;

  @override
  Future<AuthUser> rename(String displayName) async => _account;

  @override
  Future<void> deleteAccount() async {}

  @override
  Future<AuthUser> acceptTerms() async => throw UnimplementedError();

  @override
  Future<void> signOut() async {}
}

/// La barre d'onglets du mode compact, et la place qu'il lui reste.
///
/// Elle a porté six volets, l'actif nommé, puis sept. Le septième a mangé ce
/// qui restait, et « Détails » s'est affiche « Dét… » sans que rien ne le
/// signale : c'est ce silence que ce fichier remplace.
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  final now = DateTime.utc(2026, 9, 19);

  final session = RemoteGameSession(
    id: 'session-1',
    tableId: 'table-1',
    title: 'Chapitre III',
    description: null,
    startsAt: now.add(const Duration(days: 2)),
    location: 'Chez Marie',
    status: 'scheduled',
    attendances: const [],
    myStatus: null,
    myCharacter: null,
  );

  /// Le canal du plateau, que le siege du joueur ouvre en arrivant.
  late StreamController<RemoteSessionBoard> live;
  setUp(() => live = StreamController<RemoteSessionBoard>.broadcast());
  tearDown(() => live.close());

  Future<void> pump(WidgetTester tester, {required TableRole role}) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    // Un des telephones les plus etroits encore en service : si la barre tient
    // ici, elle tient partout.
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 780);
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
        sessionBoardDaoProvider.overrideWithValue(SessionBoardDao(db)),
        canWriteProvider.overrideWithValue(true),
        tableDetailProvider.overrideWith(
          (ref, tableId) async => TableDetail(
            table: RemoteGameTable(
              id: 'table-1',
              title: 'Les ombres d’Arkham',
              ownerId: 'gm-1',
              role: role,
              createdAt: now,
              updatedAt: now,
              members: const [],
              pendingInvitations: const [],
              nextSessionAt: null,
            ),
            sessions: [session],
          ),
        ),
        liveSessionBoardProvider.overrideWith((ref, sessionId) => live.stream),
      ],
    );
    addTearDown(container.dispose);
    await container.read(authControllerProvider.future);
    container.read(authControllerProvider.notifier).state =
        const AsyncValue.data(_account);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: GameMasterScreen(tableId: 'table-1', sessionId: 'session-1'),
        ),
      ),
    );

    // Sans plateau pousse, le volet du joueur tourne sa roue d'attente et
    // `pumpAndSettle` ne rend jamais la main.
    await tester.pump();
    live.add(const RemoteSessionBoard(mapId: null, tokens: '[]', revision: 0));
    await tester.pumpAndSettle();
  }

  /// Rien a l'ecran ne montre un libelle de volet ampute. C'est la regression
  /// elle-meme : « Détails » devenu « Dét… » sur fond dore.
  void aucunLibelleCoupe(WidgetTester tester, SessionSeat seat) {
    final coupes = tester
        .widgetList<Text>(find.byType(Text))
        .map((widget) => widget.data ?? '')
        .where((texte) => texte.endsWith('…'))
        .where(
          (texte) => seat.panels.any(
            (panel) => seat
                .labelFor(panel)
                .startsWith(texte.substring(0, texte.length - 1)),
          ),
        );

    expect(
      coupes,
      isEmpty,
      reason: 'un libelle coupe renseigne moins qu’une icone seule',
    );
  }

  testWidgets('les sept volets du MJ tiennent, et aucun n’est nomme a moitie',
      (tester) async {
    await pump(tester, role: TableRole.gameMaster);

    const seat = SessionSeat.gameMaster;
    expect(seat.panels.length, 7);

    // L'icone de chaque volet est la : c'est par elle qu'on navigue.
    for (final panel in seat.panels) {
      expect(
        find.byIcon(panel.icon),
        findsWidgets,
        reason: '${seat.labelFor(panel)} doit rester atteignable',
      );
    }

    aucunLibelleCoupe(tester, seat);
  });

  testWidgets('les trois volets du joueur aussi', (tester) async {
    await pump(tester, role: TableRole.player);

    const seat = SessionSeat.player;
    for (final panel in seat.panels) {
      expect(
        find.byIcon(panel.icon),
        findsWidgets,
        reason: '${seat.labelFor(panel)} doit rester atteignable',
      );
    }

    // Trois volets laissent la place de nommer celui qu'on regarde, et le
    // joueur n'a pas l'habitude de l'ecran qu'a le MJ.
    expect(find.text(seat.labelFor(seat.landing)), findsWidgets);
    aucunLibelleCoupe(tester, seat);
  });
}
