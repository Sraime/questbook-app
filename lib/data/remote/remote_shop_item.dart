/// Wire format of the shop catalogue.
///
/// The server never says what a token looks like — that stays with the app,
/// as `board_catalog.dart` already shows — so an article carries keys the
/// client resolves: [imageKey] names a picture bundled with the app, and
/// [assetKey] names the token an `asset` purchase unlocks.
library;

/// The three kinds of article the catalogue can hold.
///
/// Decoded permissively: the server may learn a fourth kind before this app is
/// updated, and a listing that threw on it would take the whole shop down
/// rather than the one row it cannot name.
enum ShopItemType {
  asset('asset', 'Asset'),
  scenario('scenario', 'Scénario'),
  pack('pack', 'Pack'),
  unknown('unknown', 'Article');

  const ShopItemType(this.wire, this.label);

  final String wire;
  final String label;

  static ShopItemType fromWire(String value) {
    for (final type in values) {
      if (type.wire == value) return type;
    }
    return unknown;
  }
}

class RemoteShopItem {
  const RemoteShopItem({
    required this.id,
    required this.title,
    required this.type,
    required this.priceCents,
    required this.imageKey,
    required this.assetKey,
    required this.owned,
  });

  factory RemoteShopItem.fromJson(Map<String, dynamic> json) => RemoteShopItem(
        id: json['id'] as String,
        title: json['title'] as String,
        type: ShopItemType.fromWire(json['type'] as String),
        priceCents: json['priceCents'] as int,
        imageKey: json['imageKey'] as String,
        assetKey: json['assetKey'] as String?,
        owned: json['owned'] as bool? ?? false,
      );

  final String id;
  final String title;
  final ShopItemType type;
  final int priceCents;
  final String imageKey;
  final String? assetKey;
  final bool owned;

  /// Un prix, toujours en euros — « 0 € » compris, qui est un prix comme un
  /// autre et se lit dans la même colonne que les autres.
  ///
  /// Les centimes ne s'écrivent que s'il y en a : « 0,00 € » et « 5,00 € »
  /// alourdissent sans rien préciser.
  String get priceLabel {
    final euros = priceCents ~/ 100;
    final cents = priceCents % 100;
    if (cents == 0) return '$euros €';
    return '$euros,${cents.toString().padLeft(2, '0')} €';
  }
}

class RemoteShopItemDetail extends RemoteShopItem {
  const RemoteShopItemDetail({
    required super.id,
    required super.title,
    required super.type,
    required super.priceCents,
    required super.imageKey,
    required super.assetKey,
    required super.owned,
    required this.description,
    required this.scenarioId,
  });

  factory RemoteShopItemDetail.fromJson(Map<String, dynamic> json) =>
      RemoteShopItemDetail(
        id: json['id'] as String,
        title: json['title'] as String,
        type: ShopItemType.fromWire(json['type'] as String),
        priceCents: json['priceCents'] as int,
        imageKey: json['imageKey'] as String,
        assetKey: json['assetKey'] as String?,
        owned: json['owned'] as bool? ?? false,
        description: json['description'] as String,
        scenarioId: json['scenarioId'] as String?,
      );

  final String description;
  final String? scenarioId;
}
