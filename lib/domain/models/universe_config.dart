/// Data-driven description of one *universe* (setting), parsed from
/// `assets/universes/universe_<id>.json` — see
/// `data/universe/universe_assets_loader.dart` for how these files are
/// distinguished from creation-mode files (same folder) and discovered.
///
/// A universe holds everything shared by *every* creation mode built on it
/// (see `domain/models/creation_mode_config.dart`): metadata/constants
/// (name, description, rulebook link, crit thresholds) **and** a
/// [generalConfigurationJson] — the same shape as a creation mode's
/// `character_sheet` (characteristics/skills/occupations/resources/global
/// attributes) — that acts as the shared *base* every creation mode is
/// built from. Each creation mode then only ships the JSON file listed in
/// [creationModes] with the fields that actually differ for that ruleset
/// (e.g. a characteristic's `calculation_method` — rolled vs. picked from a
/// list — while its `name`/`description` stay inherited from here). See
/// `CharacterSheetConfig.merge` for how the two are combined.
library;

class UniverseConfig {
  const UniverseConfig({
    required this.id,
    required this.name,
    required this.description,
    required this.rulebookPdfUrl,
    this.criticalSuccessMax = 5,
    this.criticalFailureMin = 96,
    this.creationModes = const [],
    this.generalConfigurationJson = const {},
  });

  /// Unique across every shipped universe.
  final String id;

  /// Display name matched against [CreationModeConfig.universeName] to
  /// find which universe a given creation mode belongs to.
  final String name;
  final String description;
  final String rulebookPdfUrl;

  /// A skill roll at or under this value is always a critical success,
  /// regardless of the skill's own value.
  final int criticalSuccessMax;

  /// A skill roll at or over this value is always a critical failure,
  /// regardless of the skill's own value.
  final int criticalFailureMin;

  /// The index of every creation mode built on this universe — each entry
  /// points to the JSON file holding that mode's overrides on top of
  /// [generalConfigurationJson]. See `loadAllCreationModeConfigs`.
  final List<CreationModeEntry> creationModes;

  /// Raw JSON (not yet parsed into a [CharacterSheetConfig]) for the
  /// `general_configuration` object: the character-sheet catalogue shared
  /// by every mode in [creationModes] before that mode's own overrides are
  /// merged in. Kept raw (rather than eagerly parsed) since a merge has to
  /// happen at the JSON level, per-field, before
  /// `CharacteristicConfig.fromJson`/etc. can run — see
  /// `CharacterSheetConfig.merge`.
  final Map<String, dynamic> generalConfigurationJson;

  factory UniverseConfig.fromJson(Map<String, dynamic> json) {
    return UniverseConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      rulebookPdfUrl: json['rulebook_pdf_url'] as String? ?? '',
      criticalSuccessMax: json['critical_success_max'] as int? ?? 5,
      criticalFailureMin: json['critical_failure_min'] as int? ?? 96,
      creationModes: (json['creation_modes'] as List<dynamic>? ?? const [])
          .map((e) => CreationModeEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      generalConfigurationJson:
          json['general_configuration'] as Map<String, dynamic>? ?? const {},
    );
  }
}

/// One entry in a [UniverseConfig]'s [UniverseConfig.creationModes] index:
/// this mode's identity (id/name/description) plus which file under
/// `assets/universes/` holds its overrides on the universe's shared
/// [UniverseConfig.generalConfigurationJson].
class CreationModeEntry {
  const CreationModeEntry({
    required this.id,
    required this.name,
    this.description,
    required this.configurationFile,
  });

  /// Unique across every shipped config — stored on `Character.systemId`.
  final String id;

  /// The specific ruleset's display name (e.g. `"Classique"`).
  final String name;

  /// Short rule explanation shown under the "Mode de création" picker, or
  /// null if the mode doesn't need one.
  final String? description;

  /// Filename (relative to `assets/universes/`) of the JSON file holding
  /// this mode's overrides — see `data/universe/universe_assets_loader.dart`.
  final String configurationFile;

  factory CreationModeEntry.fromJson(Map<String, dynamic> json) {
    return CreationModeEntry(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      configurationFile: json['configuration_file'] as String,
    );
  }
}
