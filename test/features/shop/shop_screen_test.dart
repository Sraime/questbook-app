import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:questbook/app/remote_providers.dart';
import 'package:questbook/data/remote/api_exception.dart';
import 'package:questbook/data/remote/remote_scenario.dart';
import 'package:questbook/data/remote/remote_shop_item.dart';
import 'package:questbook/data/remote/shop_api.dart';
import 'package:questbook/design_system/components/qb_button.dart';
import 'package:questbook/features/scenarios/providers/scenario_providers.dart';
import 'package:questbook/features/tables/providers/table_providers.dart';
import 'package:questbook/features/shop/shop_item_screen.dart';
import 'package:questbook/features/shop/shop_screen.dart';

/// Stands in for the API so the shop can be exercised without a server. The
/// purchase flips `owned`, exactly as the real one does.
class _FakeShopApi implements ShopApi {
  _FakeShopApi(this._items);

  List<RemoteShopItemDetail> _items;
  int purchases = 0;
  ApiException? failPurchaseWith;

  @override
  Future<List<RemoteShopItem>> list() async => _items;

  @override
  Future<dynamic> listRaw() async => {'items': const []};

  @override
  Future<RemoteShopItemDetail> get(String id) async =>
      _items.firstWhere((item) => item.id == id);

  @override
  Future<RemoteShopItemDetail> purchase(String id) async {
    purchases++;
    if (failPurchaseWith case final failure?) throw failure;

    _items = [
      for (final item in _items)
        if (item.id == id) _ownedCopy(item) else item,
    ];
    return _items.firstWhere((item) => item.id == id);
  }
}

RemoteShopItemDetail _item({
  String id = 'item-1',
  String title = 'Le Grand Ancien',
  ShopItemType type = ShopItemType.asset,
  int priceCents = 0,
  bool owned = false,
}) {
  return RemoteShopItemDetail(
    id: id,
    title: title,
    type: type,
    priceCents: priceCents,
    imageKey: 'logo_mark',
    assetKey: 'grand_ancien',
    owned: owned,
    description: 'Le pion qui porte l’emblème de Questbook.',
    scenarioId: null,
  );
}

RemoteShopItemDetail _scenarioItem({
  String id = 'item-2',
  String title = 'Le Dernier Train de Nuit',
  bool owned = false,
}) {
  return RemoteShopItemDetail(
    id: id,
    title: title,
    type: ShopItemType.scenario,
    priceCents: 0,
    imageKey: 'scroll',
    assetKey: null,
    owned: owned,
    description: 'Un wagon-lit entre Paris et Marseille, une porte fermée de '
        'l’intérieur, et un passager qui n’est jamais descendu.',
    scenarioId: 'sc-1',
  );
}

const _downloaded = RemoteScenarioDetail(
  id: 'sc-1',
  title: 'Le Dernier Train de Nuit',
  description: 'Un wagon-lit entre Paris et Marseille.',
  minRecommendedPlayers: 3,
  maxRecommendedPlayers: 5,
  averageDurationMinutes: 210,
  context: 'Gare de Lyon, novembre 1926.',
  rundownMarkdown: '## Mise en place',
  npcs: [],
  clues: [],
);

RemoteShopItemDetail _ownedCopy(RemoteShopItemDetail item) =>
    RemoteShopItemDetail(
      id: item.id,
      title: item.title,
      type: item.type,
      priceCents: item.priceCents,
      imageKey: item.imageKey,
      assetKey: item.assetKey,
      owned: true,
      description: item.description,
      scenarioId: item.scenarioId,
    );

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<_FakeShopApi> pumpShop(
    WidgetTester tester, {
    required List<RemoteShopItemDetail> items,
    bool online = true,
    String at = '/boutique',
    RemoteScenarioDetail? onDevice,
  }) async {
    final api = _FakeShopApi(items);

    // Scaffold comme dans la coquille de l'app : sans lui le toast n'a pas de
    // messager à qui se confier, et l'achat lèverait une erreur ici alors
    // qu'il passe en vrai.
    final router = GoRouter(
      initialLocation: at,
      routes: [
          GoRoute(
          path: '/boutique',
          builder: (context, state) => const Scaffold(body: ShopScreen()),
          routes: [
            GoRoute(
              path: ':id',
              builder: (context, state) => Scaffold(
                body: ShopItemScreen(itemId: state.pathParameters['id']!),
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/scenarios/:id',
          builder: (context, state) => const Scaffold(body: Text('Le déroulé')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          shopApiProvider.overrideWithValue(api),
          isSignedInProvider.overrideWithValue(true),
          canWriteProvider.overrideWithValue(online),
          // Ce qui est déjà sur l'appareil, sans base locale : le téléchargement
          // écrit ailleurs, et c'est l'état affiché qui se vérifie ici.
          downloadedScenarioProvider.overrideWith((ref, id) async => onDevice),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    return api;
  }

  testWidgets('a card shows the picture, title, type and price — no more',
      (tester) async {
    await pumpShop(tester, items: [_item()]);

    expect(find.text('Le Grand Ancien'), findsOneWidget);
    expect(find.text('Asset'), findsOneWidget);
    expect(find.text('0 €'), findsOneWidget);
    // La description appartient à la page de l'article, où il y a la place
    // de la lire.
    expect(find.textContaining('emblème'), findsNothing);
  });

  testWidgets('says so rather than showing an empty shelf', (tester) async {
    await pumpShop(tester, items: []);

    expect(find.text('Rien en rayon pour le moment.'), findsOneWidget);
  });

  testWidgets('opening an article tells the rest', (tester) async {
    await pumpShop(tester, items: [_item()]);

    await tester.tap(find.text('Le Grand Ancien'));
    await tester.pumpAndSettle();

    expect(find.textContaining('emblème'), findsOneWidget);
    expect(find.text('Obtenir'), findsOneWidget);
  });

  testWidgets('buying marks it owned, withdraws the offer and says so',
      (tester) async {
    final api = await pumpShop(
      tester,
      items: [_item()],
      at: '/boutique/item-1',
    );

    await tester.tap(find.text('Obtenir'));
    await tester.pumpAndSettle();

    expect(api.purchases, 1);
    expect(find.text('Possédé'), findsOneWidget);
    expect(find.text('Obtenir'), findsNothing);
    expect(find.textContaining('est à toi'), findsWidgets);
  });

  testWidgets('an article already held is not offered again', (tester) async {
    await pumpShop(
      tester,
      items: [_item(owned: true)],
      at: '/boutique/item-1',
    );

    expect(find.text('Possédé'), findsOneWidget);
    expect(find.text('Obtenir'), findsNothing);
    // Ce qu'il coûtait n'intéresse plus personne une fois qu'il est à vous.
    expect(find.text('0 €'), findsNothing);
  });

  testWidgets('offline, the offer waits like every other write',
      (tester) async {
    await pumpShop(
      tester,
      items: [_item()],
      online: false,
      at: '/boutique/item-1',
    );

    final button = find.text('Obtenir');
    expect(button, findsOneWidget);

    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(find.text('Possédé'), findsNothing);
  });

  testWidgets('a refused purchase surfaces the reason', (tester) async {
    final api = await pumpShop(
      tester,
      items: [_item(priceCents: 499)],
      at: '/boutique/item-1',
    );
    api.failPurchaseWith = const ApiException(
      code: 'BAD_REQUEST',
      message: 'Payment is not available yet',
      statusCode: 400,
    );

    await tester.tap(find.text('Obtenir'));
    await tester.pumpAndSettle();

    expect(find.text('Payment is not available yet'), findsOneWidget);
    expect(find.text('Possédé'), findsNothing);
  });

  testWidgets('a price is written in euros, never as bare cents',
      (tester) async {
    await pumpShop(tester, items: [_item(priceCents: 499)]);

    expect(find.text('4,99 €'), findsOneWidget);
  });

  testWidgets('a round price drops the centimes', (tester) async {
    await pumpShop(tester, items: [_item(priceCents: 500)]);

    expect(find.text('5 €'), findsOneWidget);
  });

  testWidgets('les pions et les scénarios ont chacun leur rayon',
      (tester) async {
    await pumpShop(tester, items: [_item(), _scenarioItem()]);

    expect(find.text('Pions'), findsOneWidget);
    // Le mot du produit, et celui de l'écran où on les retrouve : on
    // n'achète pas une « aventure » pour la relire sous « Scénarios ».
    expect(find.text('Scénarios'), findsOneWidget);
    expect(find.text('Aventures'), findsNothing);
  });

  testWidgets('un scénario se lit en rayon, un pion ne se lit pas',
      (tester) async {
    // On n'achète pas un scénario sur un dessin : sa rangée dit de quoi il
    // parle, là où une vignette de pion garde sa description pour sa page.
    await pumpShop(tester, items: [_item(), _scenarioItem()]);

    expect(find.textContaining('un passager qui n’est jamais descendu'),
        findsOneWidget);
    expect(find.textContaining('emblème'), findsNothing);
  });

  testWidgets('un scénario prend toute la largeur, un pion un tiers',
      (tester) async {
    await pumpShop(tester, items: [_item(), _scenarioItem()]);

    final row = tester.getRect(find.text('Le Dernier Train de Nuit'));
    final tile = tester.getRect(find.text('Le Grand Ancien'));

    expect(row.width, greaterThan(tile.width * 2));
  });

  testWidgets('acheter un scénario laisse place à son téléchargement',
      (tester) async {
    // Pour éviter au joueur d'aller la chercher dans le menu des scénarios.
    final api = await pumpShop(
      tester,
      items: [_scenarioItem()],
      at: '/boutique/item-2',
    );

    await tester.tap(find.text('Obtenir'));
    await tester.pumpAndSettle();

    expect(api.purchases, 1);
    expect(find.text('Obtenir'), findsNothing);
    expect(find.widgetWithText(QBButton, 'Télécharger'), findsOneWidget);
    // Le texte des assets n'a rien à faire là : un scénario ne se retrouve
    // pas parmi les pions.
    expect(find.textContaining('parmi tes assets'), findsNothing);
  });

  testWidgets('un scénario déjà sur l’appareil s’ouvre depuis la boutique',
      (tester) async {
    await pumpShop(
      tester,
      items: [_scenarioItem(owned: true)],
      at: '/boutique/item-2',
      onDevice: _downloaded,
    );

    expect(find.widgetWithText(QBButton, 'Télécharger'), findsNothing);

    await tester.tap(find.widgetWithText(QBButton, 'Ouvrir'));
    await tester.pumpAndSettle();

    expect(find.text('Le déroulé'), findsOneWidget);
  });

  testWidgets('hors ligne, le téléchargement reste offert comme dans Scénarios',
      (tester) async {
    // La même action refusée d'un côté et offerte de l'autre ferait passer
    // l'un des deux écrans pour cassé.
    await pumpShop(
      tester,
      items: [_scenarioItem(owned: true)],
      at: '/boutique/item-2',
      online: false,
    );

    final button = tester.widget<QBButton>(
      find.widgetWithText(QBButton, 'Télécharger'),
    );
    expect(button.onPressed, isNotNull);
  });

  testWidgets('un pion possédé renvoie toujours vers les assets',
      (tester) async {
    await pumpShop(
      tester,
      items: [_item(owned: true)],
      at: '/boutique/item-1',
    );

    expect(find.textContaining('parmi tes assets'), findsOneWidget);
    expect(find.widgetWithText(QBButton, 'Télécharger'), findsNothing);
  });
}
