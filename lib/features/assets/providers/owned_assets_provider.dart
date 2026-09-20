import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../app/remote_providers.dart';
import '../../../data/local/remote_cache_dao.dart';
import '../../../data/remote/api_exception.dart';
import '../../../data/remote/remote_shop_item.dart';
import '../../../data/remote/shop_api.dart';
import '../../game_master/models/board_catalog.dart';

/// Les pions que le compte a achetés, par leur clé.
///
/// Lues dans le catalogue de la boutique, qui porte déjà `owned` et
/// `assetKey` sur chaque article : c'est précisément pour éviter un second
/// point d'entrée que le serveur les met dans son résumé.
///
/// La boutique elle-même ne se garde pas hors ligne — il n'y a rien à y faire
/// sans réseau. Ces clés, si : une partie se joue autour d'une table, parfois
/// sans couverture, et un MJ dont les pions achetés disparaîtraient du tiroir
/// à ce moment-là n'aurait aucun moyen de les retrouver. D'où la lecture à
/// part plutôt qu'un branchement sur `shopCatalogueProvider` : les deux ne
/// veulent pas la même chose d'une panne.
final ownedAssetKeysProvider = FutureProvider<Set<String>>((ref) async {
  final user = ref.watch(authControllerProvider).value;
  if (user == null) return const {};

  final api = ref.watch(shopApiProvider);
  final cache = RemoteCacheDao(ref.watch(appDatabaseProvider));

  try {
    final keys = _keysOf(ShopApi.parseList(await api.listRaw()));
    await cache.write(RemoteCacheDao.ownedAssetsKey, user.id, keys.toList());
    return keys;
  } on ApiException catch (error) {
    if (!error.isRetryable) rethrow;
    final cached = await cache.read(RemoteCacheDao.ownedAssetsKey, user.id);
    if (cached == null) rethrow;
    return {...(cached.data as List).cast<String>()};
  }
});

Set<String> _keysOf(List<RemoteShopItem> items) => {
      for (final item in items)
        if (item.assetKey case final key? when item.owned) key,
    };

/// Le catalogue de pions tel que ce compte le voit : le socle, puis sa
/// collection.
///
/// Rend le socle seul tant que la boutique n'a pas répondu, au lieu de faire
/// patienter : le tiroir du MJ doit s'ouvrir tout de suite, et les pions
/// achetés le rejoignent une fraction de seconde plus tard.
final boardCatalogueProvider = Provider<List<BoardAssetSection>>((ref) {
  final owned = ref.watch(ownedAssetKeysProvider).value ?? const <String>{};
  return boardAssetSectionsFor(owned);
});
