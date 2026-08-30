import 'package:freezed_annotation/freezed_annotation.dart';

part 'game_system.freezed.dart';

/// One bundled creation mode (e.g. "Call of Cthulhu — Expert") — defines
/// which occupations are suggested at character creation. The
/// characteristics/skills/resources it uses live in its
/// `assets/universes/<id>.json` config (see
/// `domain/models/creation_mode_config.dart` and `domain/rules/config_rules_engine.dart`)
/// rather than modeled here, so adding a new universe/creation mode never
/// requires a schema change.
@freezed
abstract class GameSystem with _$GameSystem {
  const factory GameSystem({
    required String id,
    required String name,
    @Default([]) List<String> occupationSuggestions,
  }) = _GameSystem;
}
