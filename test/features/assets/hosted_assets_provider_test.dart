import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:questbook/app/providers.dart';
import 'package:questbook/app/remote_providers.dart';
import 'package:questbook/data/local/database.dart';
import 'package:questbook/data/local/hosted_asset_files.dart';
import 'package:questbook/data/remote/api_client.dart';
import 'package:questbook/data/remote/api_exception.dart';
import 'package:questbook/data/remote/asset_api.dart';
import 'package:questbook/data/remote/auth_tokens.dart';
import 'package:questbook/data/remote/shop_api.dart';
import 'package:questbook/data/remote/token_store.dart';
import 'package:questbook/features/assets/providers/hosted_assets_provider.dart';
import 'package:questbook/features/assets/providers/owned_assets_provider.dart';
import 'package:questbook/features/game_master/models/board_token.dart';
import 'package:questbook/features/shop/providers/shop_providers.dart';
import 'package:material_ui/material_ui.dart';

/// Les pions ajoutés au backoffice : leur image vient du serveur, descend une
/// fois, et reste sur l'appareil pour les parties sans réseau.

const _user = AuthUser(
  id: 'user-1',
  email: 'joueur@example.com',
  displayName: 'Joueur',
  pictureUrl: null,
);

const _networkDown = ApiException(
  code: 'NETWORK_ERROR',
  message: 'Impossible de joindre le serveur Questbook.',
);

final _png = Uint8List.fromList([0x89, 0x50, 0x4e, 0x47, 1, 2, 3]);

class _FakeAssetApi extends AssetApi {
  _FakeAssetApi() : super(ApiClient('http://127.0.0.1:1', TokenStore()));

  ApiException? failure;
  String hash = 'aaa';
  final downloads = <String>[];

  /// Ce que le backoffice ajoute pendant que l'app tourne.
  final added = <RemoteAsset>[];

  @override
  Future<List<RemoteAsset>> list() async {
    if (failure case final error?) throw error;
    return [
      RemoteAsset(
        key: 'shoggoth',
        name: 'Profond Shoggoth',
        kind: 'character',
        imageHash: hash,
      ),
      const RemoteAsset(
        key: 'crypte',
        name: 'Crypte de Kingsport',
        kind: 'map',
        imageHash: 'ccc',
        width: 300,
        height: 200,
      ),
      ...added,
    ];
  }

  @override
  Future<Uint8List> image(String key) async {
    if (failure case final error?) throw error;
    downloads.add(key);
    return _png;
  }
}

class _FakeShopApi extends ShopApi {
  _FakeShopApi() : super(ApiClient('http://127.0.0.1:1', TokenStore()));

  @override
  Future<dynamic> listRaw() async => {
        'items': [
          {
            'id': 'item-1',
            'title': 'Profond Shoggoth',
            'type': 'asset',
            'priceCents': 0,
            'imageKey': 'asset',
            'assetKey': 'shoggoth',
            'owned': true,
          },
          {
            'id': 'item-2',
            'title': 'Crypte de Kingsport',
            'type': 'asset',
            'priceCents': 0,
            'imageKey': 'asset',
            'assetKey': 'crypte',
            'owned': true,
          },
        ],
      };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late _FakeAssetApi assets;
  late Directory root;
  late ProviderContainer container;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    assets = _FakeAssetApi();
    root = await Directory.systemTemp.createTemp('hosted_assets_');

    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        assetApiProvider.overrideWithValue(assets),
        shopApiProvider.overrideWithValue(_FakeShopApi()),
        hostedAssetFilesProvider
            .overrideWith((ref) async => HostedAssetFiles(root)),
      ],
    );
    addTearDown(container.dispose);

    await container.read(authControllerProvider.future);
    container.read(authControllerProvider.notifier).state =
        const AsyncValue.data(_user);
  });

  tearDown(() async {
    await db.close();
    await root.delete(recursive: true);
  });

  test('télécharge l’image et en fait un pion dessinable', () async {
    final hosted = await container.read(hostedAssetsProvider.future);

    final shoggoth = hosted['shoggoth']!;
    expect(shoggoth.name, 'Profond Shoggoth');
    expect(shoggoth.kind, BoardTokenKind.character);
    expect(await File(shoggoth.imageFile!).readAsBytes(), _png);
  });

  test('une image déjà sur l’appareil ne se retélécharge pas', () async {
    await container.read(hostedAssetsProvider.future);
    container.invalidate(hostedDownloadsProvider);
    await container.read(hostedAssetsProvider.future);

    expect(assets.downloads, unorderedEquals(['shoggoth', 'crypte']));
  });

  test('une image remplacée descend, et l’ancienne s’efface', () async {
    await container.read(hostedAssetsProvider.future);

    assets.hash = 'bbb';
    container.invalidate(hostedDownloadsProvider);
    final hosted = await container.read(hostedAssetsProvider.future);

    expect(assets.downloads.where((key) => key == 'shoggoth'), hasLength(2));
    expect(hosted['shoggoth']!.imageFile, endsWith('shoggoth-bbb'));
    expect(
      root.listSync().map((entry) => entry.uri.pathSegments.last),
      unorderedEquals(['shoggoth-bbb', 'crypte-ccc']),
    );
  });

  test('hors réseau, le pion reste dessiné', () async {
    await container.read(hostedAssetsProvider.future);

    assets.failure = _networkDown;
    container.invalidate(hostedDownloadsProvider);
    final hosted = await container.read(hostedAssetsProvider.future);

    // Une partie se joue parfois sans couverture : le plateau garde ses
    // créatures plutôt que de les rendre en ronds de couleur.
    expect(hosted['shoggoth']!.imageFile, isNotNull);
  });

  test('un pion hébergé et possédé rejoint son rayon dans le tiroir', () async {
    await container.read(hostedAssetsProvider.future);
    await container.read(ownedAssetKeysProvider.future);

    final personnages = container.read(boardCatalogueProvider).first;
    expect(personnages.assets.last.name, 'Profond Shoggoth');
    expect(personnages.assets.last.imageFile, isNotNull);
  });

  test('une carte n’est pas un pion : elle ne va dans aucun rayon', () async {
    final tokens = await container.read(hostedAssetsProvider.future);
    await container.read(ownedAssetKeysProvider.future);

    expect(tokens.keys, ['shoggoth']);
    expect(
      container
          .read(boardCatalogueProvider)
          .expand((section) => section.assets)
          .map((asset) => asset.key),
      isNot(contains('crypte')),
    );
  });

  testWidgets(
      'une carte ajoutée au backoffice après le lancement arrive en '
      'tirant la boutique', (tester) async {
    late WidgetRef captured;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: Consumer(
          builder: (context, ref, _) {
            captured = ref;
            return const SizedBox();
          },
        ),
      ),
    );

    await tester.runAsync(() async {
      await container.read(hostedMapsProvider.future);
      assets.added.add(
        const RemoteAsset(
          key: 'chantier',
          name: 'Chantier de minage',
          kind: 'map',
          imageHash: 'ddd',
          width: 1312,
          height: 1199,
        ),
      );

      await refreshShop(captured);
      final maps = await container.read(hostedMapsProvider.future);

      // Inconnue, elle se rangeait parmi les pions, sans image.
      expect(maps['chantier']?.file, isNotNull);
    });
  });

  test('une carte possédée rejoint celles de l’app, à ses proportions',
      () async {
    await container.read(hostedMapsProvider.future);
    await container.read(ownedAssetKeysProvider.future);

    final maps = container.read(boardMapsCatalogueProvider);
    expect(maps.map((map) => map.id), ['manoir', 'grille', 'crypte']);

    final crypte = maps.last;
    expect(crypte.label, 'Crypte de Kingsport');
    expect(crypte.aspectRatio, 300 / 200);
    expect(await File(crypte.file!).readAsBytes(), _png);
  });
}
