import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/remote_providers.dart';
import '../../../data/remote/api_exception.dart';
import '../../../data/remote/remote_shop_item.dart';
import '../../assets/providers/hosted_assets_provider.dart';
import '../../assets/providers/owned_assets_provider.dart';
import '../../scenarios/providers/scenario_providers.dart';

/// The whole catalogue, owned articles included — a shop that hid what you
/// have not bought would have nothing to sell.
///
/// Not cached for offline reading, unlike tables and scenarios: there is
/// nothing to do here without a network, since buying is a write. The offline
/// banner and the disabled button say so on their own.
final shopCatalogueProvider = FutureProvider<List<RemoteShopItem>>((ref) async {
  // Refetched when the account changes: `owned` belongs to a person, and a
  // catalogue left over from the previous session would offer articles
  // already held, or withhold ones that are not.
  ref.watch(authControllerProvider.select((auth) => auth.value?.id));
  return ref.watch(shopApiProvider).list();
});

final shopItemProvider =
    FutureProvider.family<RemoteShopItemDetail, String>((ref, id) async {
  return ref.watch(shopApiProvider).get(id);
});

/// L'image propre d'un article — celle d'un bundle — gardée sur l'appareil à
/// côté de celles des pions, sous `cover-<id>-<hash>`. Une clé d'asset ne
/// contient jamais de tiret : les deux ne peuvent pas se confondre.
///
/// `null` tant qu'elle n'a pas pu descendre : la vignette garde son repli.
final shopCoverProvider =
    FutureProvider.family<String?, ({String id, String hash})>((ref, cover) async {
  final files = await ref.watch(hostedAssetFilesProvider.future);
  final key = 'cover-${cover.id}';
  final file = files.fileFor(key, cover.hash);
  if (!await file.exists()) {
    try {
      await files.save(key, cover.hash, await ref.read(shopApiProvider).image(cover.id));
    } on ApiException {
      return null;
    }
  }
  return file.path;
});

/// Relit aussi les assets hébergés : un pion ou une carte ajouté au
/// backoffice pendant que l'app tournait doit avoir son image et son rayon
/// dans la boutique, sans relancer. C'est la source qu'on invalide, pas une
/// de ses vues, qui ne ferait que relire l'ancienne liste.
Future<void> refreshShop(WidgetRef ref) async {
  ref.invalidate(shopCatalogueProvider);
  ref.invalidate(hostedDownloadsProvider);
  await ref.read(shopCatalogueProvider.future);
}

/// Buys the article and returns it owned.
///
/// Both the list and the article's own page are invalidated, so the buy
/// button disappears wherever it is showing rather than only where it was
/// pressed. So is the owned asset list: a piece bought during a session has
/// to turn up in the drawer without signing out and back in. And the
/// scenario list, which a bundle fills as much as a scenario article does.
Future<RemoteShopItemDetail> purchaseShopItem(WidgetRef ref, String id) async {
  final bought = await ref.read(shopApiProvider).purchase(id);
  ref.invalidate(shopCatalogueProvider);
  ref.invalidate(shopItemProvider(id));
  ref.invalidate(ownedAssetKeysProvider);
  ref.invalidate(hostedDownloadsProvider);
  ref.invalidate(scenariosOverviewProvider);
  return bought;
}
