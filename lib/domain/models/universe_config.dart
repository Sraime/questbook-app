/// Data-driven description of one universe's character sheet, parsed from
/// `assets/universes/<systemId>.json` (see that file for the shipped
/// Cthulhu v7 config, and `data/universe/universe_config_loader.dart` for
/// how it's loaded). Adding a new game system means adding a new JSON file
/// with this shape — no Dart change required for its catalogue of
/// characteristics/skills/occupations/resources. Only the *math* behind the
/// formula/condition strings below is Dart code, and it's itself generic —
/// see `domain/rules/formula_evaluator.dart` and `domain/rules/config_rules_engine.dart`.
library;

/// A rule set's full character-sheet definition: id/name/description plus
/// the [CharacterSheetConfig] that actually drives character creation and
/// the sheet screen.
class UniverseConfig {
  const UniverseConfig({
    required this.id,
    required this.name,
    required this.description,
    required this.version,
    required this.rulebookPdfUrl,
    required this.characterSheet,
  });

  final String id;
  final String name;
  final String description;
  final String version;
  final String rulebookPdfUrl;
  final CharacterSheetConfig characterSheet;

  factory UniverseConfig.fromJson(Map<String, dynamic> json) {
    return UniverseConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      version: json['version'] as String? ?? '',
      rulebookPdfUrl: json['rulebook_pdf_url'] as String? ?? '',
      characterSheet: CharacterSheetConfig.fromJson(
        json['character_sheet'] as Map<String, dynamic>,
      ),
    );
  }
}

/// Everything character creation/the sheet screen need: the catalogue of
/// characteristics/skills/occupations/resources, plus the two formulas that
/// aren't tied to a single stat (skill-point budget, crit/fumble thresholds).
class CharacterSheetConfig {
  const CharacterSheetConfig({
    required this.characteristics,
    required this.skills,
    required this.occupations,
    required this.resources,
    required this.skillPointsFormula,
    this.criticalSuccessMax = 5,
    this.criticalFailureMin = 96,
  });

  final List<CharacteristicConfig> characteristics;
  final List<SkillConfig> skills;
  final List<OccupationConfig> occupations;
  final List<ResourceConfig> resources;

  /// Arithmetic expression (see [FormulaEvaluator]) referencing
  /// characteristic keys, e.g. `"EDU * 4 + INT * 2"`.
  final String skillPointsFormula;
  final int criticalSuccessMax;
  final int criticalFailureMin;

  factory CharacterSheetConfig.fromJson(Map<String, dynamic> json) {
    return CharacterSheetConfig(
      characteristics: (json['characteristics'] as List<dynamic>)
          .map((e) => CharacteristicConfig.fromJson(e as Map<String, dynamic>))
          .toList(),
      skills: (json['skills'] as List<dynamic>)
          .map((e) => SkillConfig.fromJson(e as Map<String, dynamic>))
          .toList(),
      occupations: (json['occupations'] as List<dynamic>? ?? const [])
          .map((e) => OccupationConfig.fromJson(e as Map<String, dynamic>))
          .toList(),
      resources: (json['resources'] as List<dynamic>? ?? const [])
          .map((e) => ResourceConfig.fromJson(e as Map<String, dynamic>))
          .toList(),
      skillPointsFormula: json['skill_points_formula'] as String? ?? '0',
      criticalSuccessMax: json['critical_success_max'] as int? ?? 5,
      criticalFailureMin: json['critical_failure_min'] as int? ?? 96,
    );
  }

  CharacteristicConfig characteristicByKey(String key) => characteristics.firstWhere(
        (c) => c.key == key,
        orElse: () => throw ArgumentError('Unknown characteristic "$key"'),
      );

  /// Characteristics rolled by the player at creation (tap-to-roll circles),
  /// in config order.
  List<CharacteristicConfig> get rollableCharacteristics =>
      characteristics.where((c) => c.calculationMethod == CalculationMethod.roll).toList();

  /// Characteristics computed automatically once the rollable ones are
  /// known (no dice shown), in config order.
  List<CharacteristicConfig> get derivedCharacteristics =>
      characteristics.where((c) => c.calculationMethod == CalculationMethod.derived).toList();

  /// Looks up an occupation by its display [name] (characters store their
  /// occupation as a free-text name, not the config key).
  OccupationConfig? occupationByName(String? name) {
    if (name == null) return null;
    for (final o in occupations) {
      if (o.name == name) return o;
    }
    return null;
  }
}

enum CalculationMethod { roll, derived }

/// One characteristic (primary or derived) on the sheet: either rolled with
/// [calculationFormula] (dice + arithmetic, e.g. `"3D6*5"`), computed with
/// [calculationFormula] as pure arithmetic (e.g. `"DEX / 2"`), or computed
/// via [conditionTable] (first matching condition wins).
class CharacteristicConfig {
  const CharacteristicConfig({
    required this.key,
    required this.name,
    required this.description,
    required this.calculationMethod,
    this.calculationFormula,
    this.conditionTable,
  });

  final String key;
  final String name;
  final String description;
  final CalculationMethod calculationMethod;
  final String? calculationFormula;
  final List<ConditionTableEntry>? conditionTable;

  factory CharacteristicConfig.fromJson(Map<String, dynamic> json) {
    return CharacteristicConfig(
      key: json['key'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      calculationMethod: json['calculation_method'] == 'roll'
          ? CalculationMethod.roll
          : CalculationMethod.derived,
      calculationFormula: json['calculation_formula'] as String?,
      conditionTable: (json['condition_table'] as List<dynamic>?)
          ?.map((e) => ConditionTableEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// One row of a characteristic's `condition_table`: [value] is either a
/// literal number or a formula string (e.g. the "over 444" tiers) — both
/// are handled identically by [FormulaEvaluator].
class ConditionTableEntry {
  const ConditionTableEntry({required this.condition, required this.value});

  final String condition;
  final Object value;

  factory ConditionTableEntry.fromJson(Map<String, dynamic> json) {
    return ConditionTableEntry(
      condition: json['condition'] as String,
      value: json['value'] as Object,
    );
  }
}

/// One skill on the sheet: either a flat [baseValue] (percentage points) or
/// a [baseFormula] for the handful of skills derived from a characteristic
/// (Esquive = DEX/2, Langue maternelle = ÉDU).
class SkillConfig {
  const SkillConfig({
    required this.key,
    required this.name,
    required this.description,
    this.baseValue,
    this.baseFormula,
  });

  final String key;
  final String name;
  final String description;
  final int? baseValue;
  final String? baseFormula;

  /// Short label for the "base X" hint under a skill row.
  String get baseDisplay => baseFormula ?? '${baseValue ?? 0} %';

  factory SkillConfig.fromJson(Map<String, dynamic> json) {
    return SkillConfig(
      key: json['key'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      baseValue: json['base_value'] as int?,
      baseFormula: json['base_formula'] as String?,
    );
  }
}

/// A flat bonus one occupation grants to a specific characteristic (by
/// short key, e.g. `"EDU"`) or skill (by key, e.g. `"medecine"`).
class StatBonus {
  const StatBonus({required this.target, required this.flatBonus});

  final String target;
  final int flatBonus;

  factory StatBonus.fromJson(Map<String, dynamic> json) {
    final target = json['characteristic'] ?? json['skill'];
    return StatBonus(target: target as String, flatBonus: json['flat_bonus'] as int);
  }
}

/// One occupation choice offered at creation, with the bonuses it grants.
class OccupationConfig {
  const OccupationConfig({
    required this.key,
    required this.name,
    required this.description,
    this.characteristicsBonus = const [],
    this.skillsBonus = const [],
  });

  final String key;
  final String name;
  final String description;
  final List<StatBonus> characteristicsBonus;
  final List<StatBonus> skillsBonus;

  int characteristicBonusFor(String characteristicKey) {
    for (final b in characteristicsBonus) {
      if (b.target == characteristicKey) return b.flatBonus;
    }
    return 0;
  }

  int skillBonusFor(String skillKey) {
    for (final b in skillsBonus) {
      if (b.target == skillKey) return b.flatBonus;
    }
    return 0;
  }

  factory OccupationConfig.fromJson(Map<String, dynamic> json) {
    return OccupationConfig(
      key: json['key'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      characteristicsBonus: (json['characteristics_bonus'] as List<dynamic>? ?? const [])
          .map((e) => StatBonus.fromJson(e as Map<String, dynamic>))
          .toList(),
      skillsBonus: (json['skills_bonus'] as List<dynamic>? ?? const [])
          .map((e) => StatBonus.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// A trackable resource (HP/Sanity/Magic-style), computed once at creation
/// from [formula] and then tracked as current/max — see
/// `domain/models/character_resource.dart`.
class ResourceConfig {
  const ResourceConfig({
    required this.key,
    required this.label,
    required this.description,
    required this.formula,
    required this.tone,
  });

  final String key;
  final String label;
  final String description;
  final String formula;

  /// Matches `Tone.values.byName(...)` — one of neutral/danger/success/warning/info.
  final String tone;

  factory ResourceConfig.fromJson(Map<String, dynamic> json) {
    return ResourceConfig(
      key: json['key'] as String,
      label: json['label'] as String,
      description: json['description'] as String? ?? '',
      formula: json['formula'] as String,
      tone: json['tone'] as String? ?? 'neutral',
    );
  }
}
