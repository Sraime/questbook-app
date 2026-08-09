import 'package:freezed_annotation/freezed_annotation.dart';

part 'game_system.freezed.dart';

/// A rule set (e.g. "Appel de Cthulhu v7") — defines which occupations are
/// suggested at character creation. The characteristics/skills/resources a
/// system uses live in its `assets/universes/<id>.json` config (see
/// `domain/models/universe_config.dart` and `domain/rules/config_rules_engine.dart`)
/// rather than modeled here, so adding a new system never requires a schema
/// change.
@freezed
abstract class GameSystem with _$GameSystem {
  const factory GameSystem({
    required String id,
    required String name,
    @Default([]) List<String> occupationSuggestions,
  }) = _GameSystem;
}
