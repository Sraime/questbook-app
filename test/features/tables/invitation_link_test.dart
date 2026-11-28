import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:questbook/app/remote_providers.dart';
import 'package:questbook/data/remote/api_client.dart';
import 'package:questbook/data/remote/api_exception.dart';
import 'package:questbook/data/remote/remote_table.dart';
import 'package:questbook/data/remote/table_api.dart';
import 'package:questbook/data/remote/token_store.dart';
import 'package:questbook/features/auth/login_screen.dart';
import 'package:questbook/features/tables/invitation_link.dart';

/// The emailed link now carries a single-use code that whichever account is
/// signed in spends. These tests pin the app's half: reading the code out of
/// both shapes of link, keeping it while nobody is signed in, and spending it
/// exactly once.

const _code = 'Zm9vYmFyLWJhel9xdXgtMTIz';

class _FakeTableApi extends TableApi {
  _FakeTableApi() : super(ApiClient('http://127.0.0.1:1', TokenStore()));

  final redeemed = <String>[];
  ApiException? failure;

  @override
  Future<RemoteGameTable> redeemInvitation(String code) async {
    redeemed.add(code);
    if (failure case final error?) throw error;
    return RemoteGameTable.fromJson({
      'id': 'table-1',
      'title': 'Les Inspecteurs Chavillois',
      'ownerId': 'gm-1',
      'role': 'player',
      'createdAt': '2026-09-01T10:00:00.000Z',
      'updatedAt': '2026-09-01T10:00:00.000Z',
      'members': <dynamic>[],
      'pendingInvitations': <dynamic>[],
      'nextSessionAt': null,
    });
  }
}

void main() {
  group('invitationCodeOf', () {
    test('reads the code out of the emailed https link', () {
      expect(
        invitationCodeOf(Uri.parse('https://questbook.nextuscorp.com/invitations/$_code')),
        _code,
      );
    });

    test('reads it out of the button of the web page', () {
      expect(invitationCodeOf(Uri.parse('questbook://invitations/$_code')), _code);
    });

    test('tolerates a trailing slash', () {
      expect(
        invitationCodeOf(Uri.parse('https://questbook.nextuscorp.com/invitations/$_code/')),
        _code,
      );
    });

    test('ignores every other link', () {
      for (final link in [
        'https://questbook.nextuscorp.com/conditions-utilisation',
        'https://questbook.nextuscorp.com/invitations/',
        'https://questbook.nextuscorp.com/invitations/$_code/accept',
        'https://ailleurs.example.com/invitations/$_code',
        'http://questbook.nextuscorp.com/invitations/$_code',
        'questbook://tables/$_code',
        'https://questbook.nextuscorp.com/invitations/pas%20un%20code',
      ]) {
        expect(invitationCodeOf(Uri.parse(link)), isNull, reason: link);
      }
    });
  });

  group('InvitationLinkHandler', () {
    late StreamController<Uri> links;
    late _FakeTableApi api;
    late List<String> opened;

    setUp(() {
      links = StreamController<Uri>.broadcast();
      api = _FakeTableApi();
      opened = [];
    });

    tearDown(() => links.close());

    ProviderContainer container() => ProviderContainer(
          overrides: [
            incomingLinksProvider.overrideWithValue(links.stream),
            tableApiProvider.overrideWithValue(api),
            openJoinedTableProvider.overrideWithValue(opened.add),
          ],
        );

    Future<void> mount(WidgetTester tester, ProviderContainer container) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: InvitationLinkHandler(child: Text('app'))),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('joins the table and opens it when a link arrives', (tester) async {
      final scope = container();
      addTearDown(scope.dispose);
      scope.read(pendingInvitationProvider.notifier);
      await mount(tester, scope);

      links.add(Uri.parse('https://questbook.nextuscorp.com/invitations/$_code'));
      await tester.pumpAndSettle();

      expect(api.redeemed, [_code]);
      expect(opened, ['table-1']);
      expect(find.text('Tu as rejoint « Les Inspecteurs Chavillois ».'), findsOneWidget);
      expect(scope.read(pendingInvitationProvider), isNull);
    });

    testWidgets('spends a code that arrived before sign-in once the app shows',
        (tester) async {
      // Le lien a lance l'app, le joueur s'est connecte, puis l'app s'affiche.
      final scope = container();
      addTearDown(scope.dispose);
      scope.read(pendingInvitationProvider.notifier);
      links.add(Uri.parse('questbook://invitations/$_code'));
      await tester.pump();
      expect(scope.read(pendingInvitationProvider), _code);

      await mount(tester, scope);

      expect(api.redeemed, [_code]);
      expect(opened, ['table-1']);
    });

    testWidgets('says why the server refused, and opens nothing', (tester) async {
      api.failure = const ApiException(
        code: 'CONFLICT',
        message: 'Cette invitation a déjà été utilisée.',
        statusCode: 409,
      );
      final scope = container();
      addTearDown(scope.dispose);
      scope.read(pendingInvitationProvider.notifier);
      await mount(tester, scope);

      links.add(Uri.parse('https://questbook.nextuscorp.com/invitations/$_code'));
      await tester.pumpAndSettle();

      expect(find.text('Cette invitation a déjà été utilisée.'), findsOneWidget);
      expect(opened, isEmpty);
      // Le code n'est pas rejoue en boucle.
      expect(api.redeemed, [_code]);
    });

    testWidgets('tells the sign-in screen why it should sign in', (tester) async {
      final scope = container();
      addTearDown(scope.dispose);
      scope.read(pendingInvitationProvider.notifier);
      links.add(Uri.parse('questbook://invitations/$_code'));
      await tester.pump();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: scope,
          child: const MaterialApp(home: LoginScreen()),
        ),
      );

      expect(find.textContaining('rejoindre la table'), findsOneWidget);
      // Rien n'est depense tant que personne n'est connecte.
      expect(api.redeemed, isEmpty);
    });

    testWidgets('leaves alone a link that is not an invitation', (tester) async {
      final scope = container();
      addTearDown(scope.dispose);
      scope.read(pendingInvitationProvider.notifier);
      await mount(tester, scope);

      links.add(Uri.parse('https://questbook.nextuscorp.com/confidentialite'));
      await tester.pumpAndSettle();

      expect(api.redeemed, isEmpty);
    });
  });
}
