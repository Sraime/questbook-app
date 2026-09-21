import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../app/remote_providers.dart';
import '../../../domain/models/character.dart';
import '../../../domain/repositories/character_repository.dart';
import '../../../domain/rules/rules_engine.dart';

final characterDetailProvider =
    StreamProvider.family<Character?, String>((ref, id) {
  return ref.watch(characterRepositoryProvider).watchById(id);
});

final characterActionsProvider = Provider<CharacterActions>((ref) {
  return CharacterActions(
    ref.watch(characterRepositoryProvider),
    ref.watch(rulesEngineProvider),
    (id) => ref.read(syncControllerProvider.notifier).pushCharacter(id),
  );
});

/// Thin wrapper around the repository + rules engine for everything the
/// sheet screen and its modals (dice roll, resource edit) do.
///
/// Every write lands in Drift first — the screen reads from there, so the
/// gauge moves under the finger whatever the network is doing — then leaves
/// for the server straight away. The two steps are not interchangeable: a
/// sheet is read at the same moment by the game master, from the server's
/// copy, and a round trip in between would make the table wait on a tap.
class CharacterActions {
  CharacterActions(this._repo, this._rules, this._push);

  final CharacterRepository _repo;
  final RulesEngine _rules;
  final Future<void> Function(String characterId) _push;

  SkillCheckResult rollSkillCheck(int targetValue) =>
      _rules.rollSkillCheck(targetValue);

  Future<void> adjustResource(
    String characterId,
    String key,
    int delta, {
    required int current,
    required int max,
  }) async {
    final next = (current + delta).clamp(0, max);
    await _repo.updateResourceCurrent(characterId, key, next);
    await _push(characterId);
  }

  Future<void> addInventoryItem(
    String characterId, {
    required String name,
    int qty = 1,
    String? weight,
  }) async {
    await _repo.addInventoryItem(characterId, name: name, qty: qty, weight: weight);
    await _push(characterId);
  }

  /// [characterId] is not read to find the item — the repository does that
  /// from [itemId] alone. It says which sheet to send afterwards.
  Future<void> removeInventoryItem(String characterId, String itemId) async {
    await _repo.removeInventoryItem(itemId);
    await _push(characterId);
  }
}
