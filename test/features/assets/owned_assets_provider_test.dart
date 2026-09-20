import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:questbook/app/providers.dart';
import 'package:questbook/app/remote_providers.dart';
import 'package:questbook/data/local/database.dart';
import 'package:questbook/data/remote/api_client.dart';
import 'package:questbook/data/remote/api_exception.dart';
import 'package:questbook/data/remote/auth_tokens.dart';
import 'package:questbook/data/remote/shop_api.dart';
import 'package:questbook/data/remote/token_store.dart';
import 'package:questbook/features/assets/providers/owned_assets_provider.dart';
/// Un pion acheté sert pendant une partie, c'est-à-dire autour d'une table où
/// le réseau va et vient. Ces tests couvrent le marché passé : la boutique dit
/// ce que le compte possède, et ce qu'elle a dit la dernière fois reste sous
/// la main quand elle ne répond plus.

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

class _FakeShopApi extends ShopApi {
  _FakeShopApi() : super(ApiClient('http://127.0.0.1:1', TokenStore()));

  ApiException? failure;
  bool ownsGrandAncien = true;

  @override
  Future<dynamic> listRaw() async {
    if (failure case final error?) throw error;
    return {
      'items': [
        {
          'id': 'item-1',
          'title': 'Le Grand Ancien',
          'type': 'asset',
          'priceCents': 0,
          'imageKey': 'logo_mark',
          'assetKey': 'grand_ancien',
          'owned': ownsGrandAncien,
        },
        // Un scénario s'achète aussi, mais ne se pose pas sur un plateau : il
        // n'a rien à faire dans le tiroir, possédé ou non.
        {
          'id': 'item-2',
          'title': 'Le manoir Corbitt',
          'type': 'scenario',
          'priceCents': 500,
          'imageKey': 'logo_mark',
          'assetKey': null,
          'owned': true,
        },
      ],
    };
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late _FakeShopApi shop;
  late ProviderContainer container;

  Future<void> signIn(AuthUser user) async {
    await container.read(authControllerProvider.future);
    container.read(authControllerProvider.notifier).state =
        AsyncValue.data(user);
  }

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    shop = _FakeShopApi();

    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        shopApiProvider.overrideWithValue(shop),
      ],
    );
    addTearDown(container.dispose);

    await signIn(_user);
  });

  tearDown(() => db.close());

  test('ne retient que les assets, et seulement ceux qu’on possède', () async {
    expect(await container.read(ownedAssetKeysProvider.future), {
      'grand_ancien',
    });
  });

  test('un article non acheté ne donne pas son pion', () async {
    shop.ownsGrandAncien = false;

    expect(await container.read(ownedAssetKeysProvider.future), isEmpty);
  });

  /// Les cas en panne se lisent sur l'`AsyncValue` plutôt qu'en attendant la
  /// `Future` : c'est ce qu'un écran regarde, et c'est aussi la seule forme
  /// qui dise quelque chose ici, un provider que personne n'écoute étant jeté
  /// pendant que sa requête est encore en l'air.
  Future<AsyncValue<Set<String>>> settledOwnedKeys() async {
    final subscription = container.listen(ownedAssetKeysProvider, (_, _) {});
    addTearDown(subscription.close);
    await pumpEventQueue();
    return container.read(ownedAssetKeysProvider);
  }

  test('hors réseau, la collection reste celle de la dernière réponse',
      () async {
    await container.read(ownedAssetKeysProvider.future);

    shop.failure = _networkDown;
    container.invalidate(ownedAssetKeysProvider);

    // Une partie se joue parfois sans couverture : le MJ doit garder sous la
    // main les pions qu'il a payés.
    expect((await settledOwnedKeys()).value, {'grand_ancien'});
  });

  test('sans rien en mémoire, la panne reste une panne', () async {
    shop.failure = _networkDown;

    // Rien à rejouer : mieux vaut dire que la boutique est injoignable que
    // laisser croire à un compte sans le moindre achat.
    expect((await settledOwnedKeys()).error, isA<ApiException>());
  });

  test('le catalogue de pions range l’achat dans son rayon', () async {
    await container.read(ownedAssetKeysProvider.future);

    final personnages = container.read(boardCatalogueProvider).first;
    expect(personnages.title, 'Personnages');
    expect(personnages.assets.last.name, 'Le Grand Ancien');
  });
}

