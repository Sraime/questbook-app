import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../domain/models/creation_mode_config.dart';
import '../database.dart';

/// Inserts one creation mode's GameSystem row on first launch, from the
/// already-parsed [CreationModeConfig] (see
/// `data/universe/universe_assets_loader.dart`). Idempotent — safe to call
/// for every bundled config on every app start. No demo characters/tables
/// are seeded; Home/Tables start in their empty state.
Future<void> seedDatabase(AppDatabase db, CreationModeConfig config) async {
  await db.into(db.gameSystems).insertOnConflictUpdate(
        GameSystemsCompanion.insert(
          id: config.id,
          name: config.displayName,
          occupationSuggestions: Value(
            jsonEncode([for (final o in config.characterSheet.occupations) o.name]),
          ),
        ),
      );
}
