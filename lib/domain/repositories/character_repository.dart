import '../models/character.dart';
import '../models/character_resource.dart';
import '../models/character_stat.dart';

/// Everything the app needs to read/write character sheets, independent of
/// where the data actually lives. `LocalCharacterRepository` (Drift) is the
/// only implementation today; a future `RemoteCharacterRepository` backed by
/// the Questbook API implements the same contract so screens/providers never
/// need to change when the API arrives.
abstract interface class CharacterRepository {
  Stream<List<Character>> watchAll();

  Stream<Character?> watchById(String id);

  Future<Character> create({
    required String systemId,
    required String name,
    String? occupation,
    String? description,
    required List<CharacterStat> stats,
    required List<CharacterResource> resources,
  });

  Future<void> updateResourceCurrent(
    String characterId,
    String resourceKey,
    int newCurrent,
  );

  Future<void> updateStatValue(
    String characterId,
    String statKey,
    int newValue,
  );

  Future<void> addInventoryItem(
    String characterId, {
    required String name,
    int qty = 1,
    String? weight,
  });

  Future<void> removeInventoryItem(String itemId);

  /// Soft delete: the row survives locally as a tombstone until the API has
  /// been told about it, so the deletion reaches the user's other devices.
  Future<void> delete(String characterId);
}
