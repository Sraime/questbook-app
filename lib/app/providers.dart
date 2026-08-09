import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/database.dart';
import '../data/local/local_character_repository.dart';
import '../data/local/local_game_system_repository.dart';
import '../data/local/local_table_repository.dart';
import '../data/local/seed/seed_runner.dart';
import '../domain/models/universe_config.dart';
import '../domain/repositories/character_repository.dart';
import '../domain/repositories/game_system_repository.dart';
import '../domain/repositories/table_repository.dart';
import '../domain/rules/config_rules_engine.dart';
import '../domain/rules/rules_engine.dart';

/// The active universe's character-sheet config (characteristics, skills,
/// occupations + bonuses, resources, roll formulas), parsed from
/// `assets/universes/<systemId>.json` — see
/// `data/universe/universe_config_loader.dart`. `main()` loads it once
/// before `runApp` and overrides this provider with the parsed value, so
/// every other provider/screen below can read it synchronously. Once a
/// second universe is bundled, this becomes a `.family` keyed by the
/// player's chosen systemId (loaded lazily) instead of a single override.
final universeConfigProvider = Provider<UniverseConfig>((ref) {
  throw UnimplementedError(
    'universeConfigProvider must be overridden in main() with the result '
    'of loadUniverseConfig() before runApp().',
  );
});

/// Single Drift connection for the app's lifetime. Swapping to a remote
/// backend later never touches this file's *consumers* — only the
/// repository providers below would gain a `Remote*Repository` alternative.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Ensures the active universe's GameSystem row exists before any screen
/// reads it. main.dart awaits this once at startup.
final databaseInitProvider = FutureProvider<void>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final config = ref.watch(universeConfigProvider);
  await seedDatabase(db, config);
});

final characterRepositoryProvider = Provider<CharacterRepository>((ref) {
  return LocalCharacterRepository(ref.watch(appDatabaseProvider));
});

final gameSystemRepositoryProvider = Provider<GameSystemRepository>((ref) {
  return LocalGameSystemRepository(ref.watch(appDatabaseProvider));
});

final tableRepositoryProvider = Provider<TableRepository>((ref) {
  return LocalTableRepository(ref.watch(appDatabaseProvider));
});

/// Only one ruleset is bundled today (Cthulhu v7, via [universeConfigProvider]).
/// [ConfigRulesEngine] itself already generalizes across any universe
/// describable by the JSON config shape — when a second system is added,
/// this becomes a `Map<String, RulesEngine>` keyed by systemId rather than
/// a new Dart implementation.
final rulesEngineProvider = Provider<RulesEngine>((ref) {
  return ConfigRulesEngine(ref.watch(universeConfigProvider));
});
