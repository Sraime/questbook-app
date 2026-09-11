import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/database.dart';
import '../data/local/local_character_repository.dart';
import '../data/local/local_game_system_repository.dart';
import '../data/local/seed/seed_runner.dart';
import '../domain/models/creation_mode_config.dart';
import '../domain/models/universe_config.dart';
import '../domain/repositories/character_repository.dart';
import '../domain/repositories/game_system_repository.dart';
import '../domain/rules/config_rules_engine.dart';
import '../domain/rules/rules_engine.dart';

/// Every creation-mode config bundled under `assets/universes/` (one per
/// universe + ruleset, e.g. Call of Cthulhu "Classique") — see
/// `data/universe/universe_assets_loader.dart`. `main()` loads them all once
/// before `runApp` and overrides this provider with the parsed list, so the
/// "Univers"/"Mode de création" pickers in character creation can offer
/// every bundled option without any further Dart change when a new JSON
/// file is added.
final availableCreationModesProvider = Provider<List<CreationModeConfig>>((ref) {
  throw UnimplementedError(
    'availableCreationModesProvider must be overridden in main() with the '
    'result of loadAllCreationModeConfigs() before runApp().',
  );
});

/// Looks up a bundled config by its `id` (e.g. a character's `systemId`),
/// wherever it needs to be rendered/interpreted with the exact ruleset it
/// was created under.
final creationModeByIdProvider = Provider.family<CreationModeConfig?, String>((ref, id) {
  for (final config in ref.watch(availableCreationModesProvider)) {
    if (config.id == id) return config;
  }
  return null;
});

/// The id of the creation-mode config currently selected in the "Univers" /
/// "Mode de création" pickers at the top of character creation — defaults
/// to the first bundled config (set via [SelectedCreationModeIdNotifier]'s
/// constructor argument, overridden in `main()`). Selecting a different
/// universe or mode resets the rest of the creation draft (see
/// `characterCreationProvider`), since occupations/characteristics/skills
/// all come from this config.
class SelectedCreationModeIdNotifier extends Notifier<String> {
  SelectedCreationModeIdNotifier([this._initialId]);

  final String? _initialId;

  @override
  String build() {
    final id = _initialId;
    if (id == null) {
      throw UnimplementedError(
        'selectedCreationModeIdProvider must be overridden in main() with a '
        'default id (e.g. the first loadAllCreationModeConfigs() result).',
      );
    }
    return id;
  }

  void select(String id) => state = id;
}

final selectedCreationModeIdProvider =
    NotifierProvider<SelectedCreationModeIdNotifier, String>(
  SelectedCreationModeIdNotifier.new,
);

final selectedCreationModeProvider = Provider<CreationModeConfig>((ref) {
  final id = ref.watch(selectedCreationModeIdProvider);
  final config = ref.watch(creationModeByIdProvider(id));
  if (config == null) {
    throw StateError('No bundled creation mode config with id "$id".');
  }
  return config;
});

/// Every universe config bundled under `assets/universes/universe_*.json`
/// (one per setting, e.g. Call of Cthulhu) — see
/// `data/universe/universe_assets_loader.dart`. Holds the metadata/constants
/// shared by every creation mode of that universe (name, description,
/// rulebook URL, crit/fumble thresholds).
final availableUniversesProvider = Provider<List<UniverseConfig>>((ref) {
  throw UnimplementedError(
    'availableUniversesProvider must be overridden in main() with the '
    'result of loadAllUniverseConfigs() before runApp().',
  );
});

/// Looks up a bundled universe config by its [UniverseConfig.name], which
/// is what [CreationModeConfig.universeName] matches against.
final universeByNameProvider = Provider.family<UniverseConfig?, String>((ref, name) {
  for (final universe in ref.watch(availableUniversesProvider)) {
    if (universe.name == name) return universe;
  }
  return null;
});

/// The [UniverseConfig] the currently selected creation mode belongs to.
final selectedUniverseProvider = Provider<UniverseConfig>((ref) {
  final mode = ref.watch(selectedCreationModeProvider);
  final universe = ref.watch(universeByNameProvider(mode.universeName));
  if (universe == null) {
    throw StateError('No bundled universe config named "${mode.universeName}".');
  }
  return universe;
});

/// Single Drift connection for the app's lifetime. Swapping to a remote
/// backend later never touches this file's *consumers* — only the
/// repository providers below would gain a `Remote*Repository` alternative.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Ensures every bundled creation mode's GameSystem row exists before any
/// screen reads it (idempotent — see `seedDatabase`). main.dart awaits this
/// once at startup.
final databaseInitProvider = FutureProvider<void>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final configs = ref.watch(availableCreationModesProvider);
  for (final config in configs) {
    await seedDatabase(db, config);
  }
});

final characterRepositoryProvider = Provider<CharacterRepository>((ref) {
  return LocalCharacterRepository(ref.watch(appDatabaseProvider));
});

final gameSystemRepositoryProvider = Provider<GameSystemRepository>((ref) {
  return LocalGameSystemRepository(ref.watch(appDatabaseProvider));
});

/// [ConfigRulesEngine] generalizes across any universe describable by the
/// JSON config shape, so this only needs to pick *which* config drives it.
/// Used by character creation (the config the player just selected) and,
/// pragmatically, by the sheet screen's dice-roll modal too — the latter
/// technically ought to use the *viewed character's own* `systemId` rather
/// than the current creation selection, but with a single bundled config
/// today the two always coincide. Revisit via `rulesEngineProvider.family`
/// keyed by systemId if/when that starts to matter.
final rulesEngineProvider = Provider<RulesEngine>((ref) {
  return ConfigRulesEngine(
    ref.watch(selectedCreationModeProvider),
    ref.watch(selectedUniverseProvider),
  );
});
