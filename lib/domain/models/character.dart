import 'package:freezed_annotation/freezed_annotation.dart';

import 'character_resource.dart';
import 'character_stat.dart';
import 'inventory_item.dart';

part 'character.freezed.dart';

@freezed
abstract class Character with _$Character {
  const factory Character({
    required String id,
    required String systemId,
    required String name,
    String? occupation,
    String? description,
    @Default(1) int level,
    required DateTime createdAt,
    @Default([]) List<CharacterResource> resources,
    @Default([]) List<CharacterStat> stats,
    @Default([]) List<InventoryItem> inventory,
  }) = _Character;

  const Character._();

  List<CharacterStat> get characteristics {
    final list = stats.where((s) => s.kind == StatKind.characteristic).toList();
    list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return list;
  }

  List<CharacterStat> get skills {
    final list = stats.where((s) => s.kind == StatKind.skill).toList();
    list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return list;
  }

  List<CharacterStat> get attributes {
    final list = stats.where((s) => s.kind == StatKind.attribute).toList();
    list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return list;
  }

  CharacterResource? resourceByKey(String key) =>
      resources.cast<CharacterResource?>().firstWhere(
            (r) => r?.key == key,
            orElse: () => null,
          );
}
