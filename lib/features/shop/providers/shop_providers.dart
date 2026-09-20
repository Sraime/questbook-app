import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/remote_providers.dart';
import '../../../data/remote/remote_shop_item.dart';
import '../../assets/providers/owned_assets_provider.dart';

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

Future<void> refreshShop(WidgetRef ref) async {
  ref.invalidate(shopCatalogueProvider);
  await ref.read(shopCatalogueProvider.future);
}

/// Buys the article and returns it owned.
///
/// Both the list and the article's own page are invalidated, so the buy
/// button disappears wherever it is showing rather than only where it was
/// pressed. So is the owned asset list: a piece bought during a session has
/// to turn up in the drawer without signing out and back in.
Future<RemoteShopItemDetail> purchaseShopItem(WidgetRef ref, String id) async {
  final bought = await ref.read(shopApiProvider).purchase(id);
  ref.invalidate(shopCatalogueProvider);
  ref.invalidate(shopItemProvider(id));
  ref.invalidate(ownedAssetKeysProvider);
  return bought;
}
