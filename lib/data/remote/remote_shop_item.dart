/// Wire format of the shop catalogue.
///
/// The server never says what a token looks like — that stays with the app,
/// as `board_catalog.dart` already shows — so an article carries keys the
/// client resolves: [imageKey] names a picture bundled with the app, and
/// [assetKey] names the token an `asset` purchase unlocks. A bundle is the
/// exception: its picture is sent from the backoffice, and [imageHash] says
/// which version the server holds.
library;

/// The kinds of article the catalogue can hold.
///
/// Decoded permissively: the server may learn another kind before this app is
/// updated, and a listing that threw on it would take the whole shop down
/// rather than the one row it cannot name.
enum ShopItemType {
  asset('asset', 'Asset'),
  scenario('scenario', 'Scénario'),
  bundle('bundle', 'Bundle'),
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
    required this.description,
    required this.priceCents,
    required this.imageKey,
    required this.assetKey,
    required this.owned,
    this.imageHash,
  });

  factory RemoteShopItem.fromJson(Map<String, dynamic> json) => RemoteShopItem(
        id: json['id'] as String,
        title: json['title'] as String,
        type: ShopItemType.fromWire(json['type'] as String),
        // Absente des serveurs d'avant les scénarios en rayon, et d'un cache
        // écrit par eux : une vignette sans description se dessine, une
        // liste qui plante sur une clé manquante ne se dessine pas.
        description: json['description'] as String? ?? '',
        priceCents: json['priceCents'] as int,
        imageKey: json['imageKey'] as String,
        imageHash: json['imageHash'] as String?,
        assetKey: json['assetKey'] as String?,
        owned: json['owned'] as bool? ?? false,
      );

  final String id;
  final String title;
  final ShopItemType type;

  /// Ce dont parle l'article. Une vignette de pion l'ignore ; une aventure en
  /// montre les premières lignes, là où elle s'affiche pleine largeur.
  final String description;

  final int priceCents;
  final String imageKey;

  /// Présent quand le serveur héberge l'image de l'article lui-même — celle
  /// d'un bundle. Le fichier gardé sur l'appareil porte ce hash.
  final String? imageHash;

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

/// Ce qu'un bundle donne : un asset ou un scénario, et si le lecteur l'a déjà.
class RemoteBundleEntry {
  const RemoteBundleEntry({
    required this.isScenario,
    required this.title,
    required this.itemId,
    required this.assetKey,
    required this.scenarioId,
    required this.owned,
  });

  factory RemoteBundleEntry.fromJson(Map<String, dynamic> json) =>
      RemoteBundleEntry(
        isScenario: json['kind'] == 'scenario',
        title: json['title'] as String? ?? '',
        itemId: json['itemId'] as String?,
        assetKey: json['assetKey'] as String?,
        scenarioId: json['scenarioId'] as String?,
        owned: json['owned'] as bool? ?? false,
      );

  final bool isScenario;
  final String title;

  /// L'article `asset`, pour un asset.
  final String? itemId;
  final String? assetKey;
  final String? scenarioId;
  final bool owned;
}

class RemoteShopItemDetail extends RemoteShopItem {
  const RemoteShopItemDetail({
    required super.id,
    required super.title,
    required super.type,
    required super.description,
    required super.priceCents,
    required super.imageKey,
    required super.assetKey,
    required super.owned,
    super.imageHash,
    required this.scenarioId,
    this.contents = const [],
  });

  factory RemoteShopItemDetail.fromJson(Map<String, dynamic> json) =>
      RemoteShopItemDetail(
        id: json['id'] as String,
        title: json['title'] as String,
        type: ShopItemType.fromWire(json['type'] as String),
        description: json['description'] as String? ?? '',
        priceCents: json['priceCents'] as int,
        imageKey: json['imageKey'] as String,
        imageHash: json['imageHash'] as String?,
        assetKey: json['assetKey'] as String?,
        owned: json['owned'] as bool? ?? false,
        scenarioId: json['scenarioId'] as String?,
        contents: [
          for (final entry
              in (json['contents'] as List? ?? const []).whereType<Map>())
            RemoteBundleEntry.fromJson(entry.cast<String, dynamic>()),
        ],
      );

  /// Vers quelle aventure pointe un article `scenario`. Nul pour les autres.
  final String? scenarioId;

  /// Ce que contient un bundle, dans l'ordre du backoffice. Vide sinon.
  final List<RemoteBundleEntry> contents;
}
