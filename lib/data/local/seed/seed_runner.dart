import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../domain/models/universe_config.dart';
import '../database.dart';

/// Inserts the active universe's GameSystem row on first launch, from the
/// already-parsed [UniverseConfig] (see `data/universe/universe_config_loader.dart`).
/// Idempotent — safe to call on every app start. No demo characters/tables
/// are seeded; Home/Tables start in their empty state.
Future<void> seedDatabase(AppDatabase db, UniverseConfig config) async {
  await db.into(db.gameSystems).insertOnConflictUpdate(
        GameSystemsCompanion.insert(
          id: config.id,
          name: config.name,
          occupationSuggestions: Value(
            jsonEncode([for (final o in config.characterSheet.occupations) o.name]),
          ),
        ),
      );
}
