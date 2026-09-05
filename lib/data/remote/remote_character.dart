/// Wire format of a character aggregate, mirroring what the API sends and
/// accepts.
///
/// Mapping is hand-written rather than generated, matching how `data/local`
/// already maps Drift rows to domain models, and keeping the transport shape
/// free to diverge from the domain model.
class RemoteCharacter {
  const RemoteCharacter({
    required this.id,
    required this.systemId,
    required this.name,
    required this.occupation,
    required this.description,
    required this.level,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
    required this.stats,
    required this.resources,
    required this.inventory,
  });

  factory RemoteCharacter.fromJson(Map<String, dynamic> json) {
    return RemoteCharacter(
      id: json['id'] as String,
      systemId: json['systemId'] as String,
      name: json['name'] as String,
      occupation: json['occupation'] as String?,
      description: json['description'] as String?,
      level: json['level'] as int? ?? 1,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.parse(json['deletedAt'] as String),
      stats: _listOf(json['stats'], RemoteStat.fromJson),
      resources: _listOf(json['resources'], RemoteResource.fromJson),
      inventory: _listOf(json['inventory'], RemoteInventoryItem.fromJson),
    );
  }

  final String id;
  final String systemId;
  final String name;
  final String? occupation;
  final String? description;
  final int level;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final List<RemoteStat> stats;
  final List<RemoteResource> resources;
  final List<RemoteInventoryItem> inventory;

  bool get isDeleted => deletedAt != null;

  /// Body of `PUT /characters/:id`. Timestamps go out in UTC ISO-8601 with an
  /// explicit offset, which is what the server's schema requires.
  Map<String, dynamic> toJson() => {
        'systemId': systemId,
        'name': name,
        'occupation': occupation,
        'description': description,
        'level': level,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
        'deletedAt': deletedAt?.toUtc().toIso8601String(),
        'stats': stats.map((stat) => stat.toJson()).toList(),
        'resources': resources.map((resource) => resource.toJson()).toList(),
        'inventory': inventory.map((item) => item.toJson()).toList(),
      };
}

class RemoteStat {
  const RemoteStat({
    required this.id,
    required this.kind,
    required this.key,
    required this.label,
    required this.value,
    required this.base,
    required this.sortOrder,
  });

  factory RemoteStat.fromJson(Map<String, dynamic> json) => RemoteStat(
        id: json['id'] as String,
        kind: json['kind'] as String,
        key: json['key'] as String,
        label: json['label'] as String,
        value: json['value'] as int,
        base: json['base'] as String?,
        sortOrder: json['sortOrder'] as int? ?? 0,
      );

  final String id;
  final String kind;
  final String key;
  final String label;
  final int value;
  final String? base;
  final int sortOrder;

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind,
        'key': key,
        'label': label,
        'value': value,
        'base': base,
        'sortOrder': sortOrder,
      };
}

class RemoteResource {
  const RemoteResource({
    required this.id,
    required this.key,
    required this.label,
    required this.current,
    required this.max,
    required this.tone,
  });

  factory RemoteResource.fromJson(Map<String, dynamic> json) => RemoteResource(
        id: json['id'] as String,
        key: json['key'] as String,
        label: json['label'] as String,
        current: json['current'] as int,
        max: json['max'] as int,
        tone: json['tone'] as String? ?? 'neutral',
      );

  final String id;
  final String key;
  final String label;
  final int current;
  final int max;
  final String tone;

  Map<String, dynamic> toJson() => {
        'id': id,
        'key': key,
        'label': label,
        'current': current,
        'max': max,
        'tone': tone,
      };
}

class RemoteInventoryItem {
  const RemoteInventoryItem({
    required this.id,
    required this.name,
    required this.qty,
    required this.weight,
  });

  factory RemoteInventoryItem.fromJson(Map<String, dynamic> json) =>
      RemoteInventoryItem(
        id: json['id'] as String,
        name: json['name'] as String,
        qty: json['qty'] as int? ?? 1,
        weight: json['weight'] as String?,
      );

  final String id;
  final String name;
  final int qty;
  final String? weight;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'qty': qty,
        'weight': weight,
      };
}

/// One page of an incremental pull: what changed, and the cursor to send as
/// `since` next time.
class RemoteSyncPage {
  const RemoteSyncPage({required this.characters, required this.syncedAt});

  factory RemoteSyncPage.fromJson(Map<String, dynamic> json) => RemoteSyncPage(
        characters: _listOf(json['characters'], RemoteCharacter.fromJson),
        syncedAt: DateTime.parse(json['syncedAt'] as String),
      );

  final List<RemoteCharacter> characters;
  final DateTime syncedAt;
}

List<T> _listOf<T>(dynamic raw, T Function(Map<String, dynamic>) fromJson) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((entry) => fromJson(entry.cast<String, dynamic>()))
      .toList();
}
