import 'api_client.dart';
import 'remote_shop_item.dart';

class ShopApi {
  ShopApi(this._client);

  final ApiClient _client;

  Future<List<RemoteShopItem>> list() async => parseList(await listRaw());

  Future<dynamic> listRaw() {
    return _client.send(
      (dio) => dio.get<dynamic>('/shop/items'),
      parse: (data) => data,
    );
  }

  static List<RemoteShopItem> parseList(Object? data) {
    final items = (data as Map)['items'];
    if (items is! List) return const <RemoteShopItem>[];
    return items
        .whereType<Map>()
        .map((entry) => RemoteShopItem.fromJson(entry.cast<String, dynamic>()))
        .toList(growable: false);
  }

  Future<RemoteShopItemDetail> get(String id) {
    return _client.send(
      (dio) => dio.get<dynamic>('/shop/items/$id'),
      parse: (data) => RemoteShopItemDetail.fromJson(
        (data as Map).cast<String, dynamic>(),
      ),
    );
  }

  /// Hands the article over and returns it owned. Safe to call twice: the
  /// server treats a repeat as the same purchase rather than an error.
  Future<RemoteShopItemDetail> purchase(String id) {
    return _client.send(
      (dio) => dio.post<dynamic>('/shop/items/$id/purchase'),
      parse: (data) => RemoteShopItemDetail.fromJson(
        (data as Map).cast<String, dynamic>(),
      ),
    );
  }
}
