/// Data-driven description of one *creation mode*: a character-creation
/// ruleset for a given universe. A universe (e.g. "Call of Cthulhu") can
/// have several creation modes — e.g. CoC7's "Simplifié", where
/// characteristics are chosen from a list instead of rolled — each listed
/// in that universe's `assets/universes/universe_<id>.json`
/// (`UniverseConfig.creationModes`) and shipped as its own JSON file
/// holding only the [CharacterSheetConfig] fields that actually differ
/// from that universe's shared `general_configuration` (see
/// `CharacterSheetConfig.merge` and
/// `data/universe/universe_assets_loader.dart` for how the two are
/// discovered, loaded and combined). Adding a creation mode means adding a
/// new JSON file plus one entry in the universe file — no Dart change
/// required. Only the *math* behind the formula/condition strings below is
/// Dart code, and it's itself generic — see
/// `domain/rules/formula_evaluator.dart` and
/// `domain/rules/config_rules_engine.dart`.
library;

/// One creation-mode ruleset's full character-sheet definition: which
/// universe/mode it belongs to, plus the [CharacterSheetConfig] that
/// actually drives character creation and the sheet screen.
class CreationModeConfig {
  const CreationModeConfig({
    required this.id,
    required this.universeName,
    required this.creationModeName,
    this.creationModeDescription,
    required this.characterSheet,
  });

  /// Unique across every shipped config — stored on `Character.systemId` so
  /// a character can always be traced back to the exact ruleset it was
  /// created under, even if other creation modes are added later.
  final String id;

  /// The universe this ruleset belongs to (e.g. `"Call of Cthulhu"`) —
  /// matched against [UniverseConfig.name] (see
  /// `domain/models/universe_config.dart`) for the metadata/constants
  /// shared by every mode of that universe. Several creation modes can
  /// share the same [universeName].
  final String universeName;

  /// The specific ruleset within that universe (e.g. `"Classique"`, or
  /// `"Simplifié"`).
  final String creationModeName;

  /// Short rule explanation shown to the player under the "Mode de
  /// création" picker (e.g. how characteristics are assigned in this
  /// mode), or null if the mode doesn't need one.
  final String? creationModeDescription;

  final CharacterSheetConfig characterSheet;

  /// Display label combining both, e.g. `"Call of Cthulhu — Classique"`.
  String get displayName => '$universeName — $creationModeName';
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
    required this.personalSkillPointsFormula,
    this.globalAttributes = const [],
  });

  final List<CharacteristicConfig> characteristics;
  final List<SkillConfig> skills;
  final List<OccupationConfig> occupations;
  final List<ResourceConfig> resources;

  /// Extra character info that isn't a game-mechanical characteristic (not
  /// rolled, not fed into any formula) but is still specific to this
  /// universe rather than generic to every character (unlike name/
  /// description, which every universe shares and so live outside this
  /// config entirely) — CoC7: age (a number) and Fortune (a fixed list of
  /// social-status labels). See [GlobalAttributeConfig].
  final List<GlobalAttributeConfig> globalAttributes;

  /// The rule for how many points the player has to freely distribute
  /// across *any* skill at creation (CoC7 calls these "personal interest
  /// points": `"INT * 2"`). Each game system defines its own rule here —
  /// see [FormulaEvaluator]. This is separate from the flat, non-spendable
  /// bonuses an occupation grants to specific skills (see
  /// [OccupationConfig.skillsBonus]).
  final String personalSkillPointsFormula;

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
      personalSkillPointsFormula: json['personal_skill_points'] as String? ?? '0',
      globalAttributes: (json['global_attributes'] as List<dynamic>? ?? const [])
          .map((e) => GlobalAttributeConfig.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Builds a creation mode's actual [CharacterSheetConfig] by combining a
  /// universe's shared [UniverseConfig.generalConfigurationJson] with that
  /// specific mode's own `character_sheet` JSON — the raw override object
  /// straight out of its config file (e.g. `call_of_cthulhu_classique.json`).
  ///
  /// Every list (`global_attributes`/`characteristics`/`resources`/
  /// `skills`/`occupations`) is merged **by `key`**: an entry present in
  /// both is combined field-by-field with [overrides] winning (so a mode
  /// can override just `calculation_method` on a characteristic while its
  /// `name`/`description` stay inherited from the general one); an entry
  /// only in [overrides] is a mode-specific addition (e.g. CoC7's
  /// "Classique" adds a `mythe_de_cthulhu` skill no other mode has); an
  /// entry only in [general] is inherited unchanged. `personal_skill_points`
  /// is a plain scalar override (mode's value if set, else the general
  /// one, else `"0"`).
  factory CharacterSheetConfig.merge({
    required Map<String, dynamic> general,
    required Map<String, dynamic> overrides,
  }) {
    return CharacterSheetConfig.fromJson({
      'personal_skill_points':
          overrides['personal_skill_points'] ?? general['personal_skill_points'],
      'global_attributes': _mergeEntriesByKey(
        general['global_attributes'] as List<dynamic>?,
        overrides['global_attributes'] as List<dynamic>?,
      ),
      'characteristics': _mergeEntriesByKey(
        general['characteristics'] as List<dynamic>?,
        overrides['characteristics'] as List<dynamic>?,
      ),
      'resources': _mergeEntriesByKey(
        general['resources'] as List<dynamic>?,
        overrides['resources'] as List<dynamic>?,
      ),
      'skills': _mergeEntriesByKey(
        general['skills'] as List<dynamic>?,
        overrides['skills'] as List<dynamic>?,
      ),
      'occupations': _mergeEntriesByKey(
        general['occupations'] as List<dynamic>?,
        overrides['occupations'] as List<dynamic>?,
      ),
    });
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

  /// Every characteristic the player picks from a fixed list of options
  /// instead of rolling or computing, in config order — both the numeric
  /// ("point-buy" primary characteristics, see [numericChoiceCharacteristics])
  /// and text ("flavor", see [flavorChoiceCharacteristics]) flavors.
  List<CharacteristicConfig> get choiceCharacteristics =>
      characteristics.where((c) => c.calculationMethod == CalculationMethod.choice).toList();

  /// [choiceCharacteristics] whose [CharacteristicConfig.choices] are all
  /// numbers (e.g. a "point-buy" mode where FOR/DEX/… are picked from
  /// `["40", "50", "60", "70", "80"]` instead of rolled) — these are
  /// primary characteristics like any other, just assigned differently, so
  /// they belong with [rollableCharacteristics] in the "Caractéristiques"
  /// section rather than treated as flavor text.
  List<CharacteristicConfig> get numericChoiceCharacteristics =>
      choiceCharacteristics.where((c) => c.isNumericChoice).toList();

  /// [choiceCharacteristics] whose options are plain text (CoC7's Fortune:
  /// "Indigent"… "Richissime") — purely descriptive, never fed into a
  /// formula, so they're surfaced next to the occupation picker instead.
  List<CharacteristicConfig> get flavorChoiceCharacteristics =>
      choiceCharacteristics.where((c) => !c.isNumericChoice).toList();

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

/// Merges two `key`-identified lists of raw JSON objects — the building
/// block of [CharacterSheetConfig.merge] — keeping [general]'s order for
/// entries it defines, appending any [overrides]-only entries after.
List<Map<String, dynamic>> _mergeEntriesByKey(
  List<dynamic>? general,
  List<dynamic>? overrides,
) {
  final merged = <String, Map<String, dynamic>>{};
  final order = <String>[];
  for (final entry in general ?? const []) {
    final map = entry as Map<String, dynamic>;
    final key = map['key'] as String;
    merged[key] = Map<String, dynamic>.from(map);
    order.add(key);
  }
  for (final entry in overrides ?? const []) {
    final map = entry as Map<String, dynamic>;
    final key = map['key'] as String;
    final existing = merged[key];
    merged[key] = existing == null ? Map<String, dynamic>.from(map) : {...existing, ...map};
    if (existing == null) order.add(key);
  }
  return [for (final key in order) merged[key]!];
}

enum CalculationMethod { roll, derived, choice }

/// A "global attribute" is a bit of character info specific to a universe
/// but outside the roll/derive/choice mechanics of [CharacteristicConfig] —
/// it's never a formula input, just recorded and displayed. CoC7 uses this
/// for age (a free number) and Fortune (a fixed list of social-status
/// labels, picked right after the occupation).
enum GlobalAttributeType { integer, choice }

class GlobalAttributeConfig {
  const GlobalAttributeConfig({
    required this.key,
    required this.name,
    this.description = '',
    required this.type,
    this.choices = const [],
  });

  final String key;
  final String name;
  final String description;
  final GlobalAttributeType type;

  /// Options for a [GlobalAttributeType.choice] attribute, in display
  /// order — the persisted stat value is the index into this list, same
  /// convention as [CharacteristicConfig.choices].
  final List<String> choices;

  factory GlobalAttributeConfig.fromJson(Map<String, dynamic> json) {
    return GlobalAttributeConfig(
      key: json['key'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      type: switch (json['type']) {
        'choice' => GlobalAttributeType.choice,
        _ => GlobalAttributeType.integer,
      },
      choices: (json['choices'] as List<dynamic>? ?? const [])
          .map((e) => e as String)
          .toList(),
    );
  }
}

/// One characteristic (primary or derived) on the sheet: either rolled with
/// [calculationFormula] (dice + arithmetic, e.g. `"3D6*5"`), computed with
/// [calculationFormula] as pure arithmetic (e.g. `"DEX / 2"`), computed via
/// [conditionTable] (first matching condition wins), or picked by the
/// player from [choices] (CoC7's Fortune: no dice, no formula — just a
/// fixed list of text options, stored as the option's index).
class CharacteristicConfig {
  const CharacteristicConfig({
    required this.key,
    required this.name,
    required this.description,
    required this.calculationMethod,
    this.calculationFormula,
    this.conditionTable,
    this.choices = const [],
  });

  final String key;
  final String name;
  final String description;
  final CalculationMethod calculationMethod;
  final String? calculationFormula;
  final List<ConditionTableEntry>? conditionTable;

  /// Options for a [CalculationMethod.choice] characteristic, in display
  /// order. For a text/flavor choice (Fortune), the persisted stat value is
  /// the index into this list; for a numeric choice (see [isNumericChoice]),
  /// it's the actual chosen number — see [choiceValueAt].
  final List<String> choices;

  /// True when every [choices] option parses as a number — signals a
  /// "point-buy" primary characteristic (e.g. `["40", "50", "60", "70",
  /// "80"]`) rather than a plain-text flavor pick (e.g. Fortune's
  /// `["Indigent", …]`). Drives both where the picker shows up in the UI
  /// and how the pick feeds into formulas — see
  /// [CharacterSheetConfig.numericChoiceCharacteristics].
  bool get isNumericChoice =>
      choices.isNotEmpty && choices.every((c) => num.tryParse(c) != null);

  /// The actual numeric value of the option at [choiceIndex], for a
  /// [isNumericChoice] characteristic — used wherever a rolled/derived
  /// characteristic's value would be (formulas, resources…). Falls back to
  /// the index itself for non-numeric choices, which are display-only and
  /// never referenced by a formula.
  num choiceValueAt(int choiceIndex) {
    if (choices.isEmpty) return 0;
    final clamped = choiceIndex.clamp(0, choices.length - 1);
    return num.tryParse(choices[clamped]) ?? clamped;
  }

  factory CharacteristicConfig.fromJson(Map<String, dynamic> json) {
    return CharacteristicConfig(
      key: json['key'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      calculationMethod: switch (json['calculation_method']) {
        'roll' => CalculationMethod.roll,
        'choice' => CalculationMethod.choice,
        _ => CalculationMethod.derived,
      },
      calculationFormula: json['calculation_formula'] as String?,
      conditionTable: (json['condition_table'] as List<dynamic>?)
          ?.map((e) => ConditionTableEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      choices: (json['choices'] as List<dynamic>? ?? const [])
          .map((e) => e as String)
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
    this.occupationSkillPointsFormula,
    this.occupationSkills = const [],
    this.occupationSkillChoices = 0,
  });

  final String key;
  final String name;
  final String description;
  final List<StatBonus> characteristicsBonus;
  final List<StatBonus> skillsBonus;

  /// The rule for how many points the player has to distribute across this
  /// occupation's own skill list at creation (CoC7's "occupation points",
  /// e.g. `"EDU * 4"` or `"EDU * 2 + Max(FOR, DEX) * 2"`). Separate from
  /// [CharacterSheetConfig.personalSkillPointsFormula], which can go on
  /// *any* skill; these can only be spent on [occupationSkills] (plus any
  /// player-picked [occupationSkillChoices] slots).
  final String? occupationSkillPointsFormula;

  /// Keys of the skills this occupation's point budget can be spent on.
  final List<String> occupationSkills;

  /// Number of "plus one skill of your choice" slots: the player picks
  /// this many *additional* skills (from the full catalogue) that also
  /// become eligible for the occupation's point budget.
  final int occupationSkillChoices;

  /// Whether this occupation defines the occupation-skill-points mechanic
  /// at all (older/simpler configs may omit it entirely).
  bool get hasOccupationSkillPoints =>
      occupationSkillPointsFormula != null && occupationSkills.isNotEmpty;

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
      occupationSkillPointsFormula: json['occupation_skill_points_formula'] as String?,
      occupationSkills: (json['occupation_skills'] as List<dynamic>? ?? const [])
          .map((e) => e as String)
          .toList(),
      occupationSkillChoices: json['occupation_skill_choices'] as int? ?? 0,
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
