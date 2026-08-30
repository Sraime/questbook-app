import 'dart:convert';

import 'package:flutter/services.dart' show AssetManifest, rootBundle;

import '../../domain/models/creation_mode_config.dart';
import '../../domain/models/universe_config.dart';

/// Discovers and parses every universe bundled under `assets/universes/`
/// (declared as a whole-folder Flutter asset in `pubspec.yaml`), then
/// derives every creation mode from them:
///
/// - `universe_<id>.json` — one per universe (setting). Besides its own
///   metadata/constants, it holds a `general_configuration` object (the
///   character-sheet catalogue shared by every mode of that universe) and
///   a `creation_modes` index listing each mode's identity plus which
///   *other* file in this same folder holds its overrides — see
///   [loadAllUniverseConfigs] and `domain/models/universe_config.dart`.
/// - every file referenced by a `creation_modes[].configuration_file` — a
///   creation mode's own `character_sheet`, holding only what actually
///   differs from its universe's `general_configuration` (e.g. a
///   characteristic's `calculation_method`, while its `name`/`description`
///   stay inherited) — see [loadAllCreationModeConfigs] and
///   `CharacterSheetConfig.merge`.
///
/// Both are called once in `main()`, before `runApp` — see
/// `availableCreationModesProvider`/`availableUniversesProvider` in
/// `app/providers.dart` for how the parsed lists are then threaded through
/// the app as provider overrides. Adding a new universe means a new
/// `universe_<id>.json`; adding a creation mode to an existing universe
/// means a new override file plus one entry in that universe's
/// `creation_modes` — no Dart change either way.
const _universesDir = 'assets/universes/';
const _universeFilePrefix = '${_universesDir}universe_';

Future<List<UniverseConfig>> loadAllUniverseConfigs() async {
  final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  final paths = manifest
      .listAssets()
      .where((path) => path.startsWith(_universeFilePrefix) && path.endsWith('.json'))
      .toList()
    ..sort();

  final configs = <UniverseConfig>[];
  for (final path in paths) {
    final raw = await rootBundle.loadString(path);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    configs.add(UniverseConfig.fromJson(json));
  }
  return configs;
}

/// Resolves every [UniverseConfig.creationModes] entry across [universes]
/// into its actual [CreationModeConfig], merging each mode's own override
/// file with its universe's shared `general_configuration` — see
/// [buildCreationModeConfig].
Future<List<CreationModeConfig>> loadAllCreationModeConfigs(
  List<UniverseConfig> universes,
) async {
  final configs = <CreationModeConfig>[];
  for (final universe in universes) {
    for (final entry in universe.creationModes) {
      final raw = await rootBundle.loadString('$_universesDir${entry.configurationFile}');
      final modeFileJson = jsonDecode(raw) as Map<String, dynamic>;
      configs.add(buildCreationModeConfig(universe, entry, modeFileJson));
    }
  }
  return configs;
}

/// Combines one [UniverseConfig]'s [UniverseConfig.generalConfigurationJson]
/// with a single creation mode's own decoded override file ([modeFileJson],
/// i.e. `{"character_sheet": {...}}`) into the [CreationModeConfig] the rest
/// of the app consumes. Exposed (rather than kept private) so tests can
/// exercise the exact merge used at runtime without going through
/// `rootBundle`/`dart:io` twice.
CreationModeConfig buildCreationModeConfig(
  UniverseConfig universe,
  CreationModeEntry entry,
  Map<String, dynamic> modeFileJson,
) {
  final overrides = modeFileJson['character_sheet'] as Map<String, dynamic>? ?? const {};
  return CreationModeConfig(
    id: entry.id,
    universeName: universe.name,
    creationModeName: entry.name,
    creationModeDescription: entry.description,
    characterSheet: CharacterSheetConfig.merge(
      general: universe.generalConfigurationJson,
      overrides: overrides,
    ),
  );
}
