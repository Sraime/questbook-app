import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../domain/models/character_resource.dart';
import '../../../domain/models/character_stat.dart';
import '../../../domain/models/creation_mode_config.dart';
import '../../../domain/models/tone.dart';
import '../../../domain/rules/formula_evaluator.dart';
import '../../../domain/rules/rules_engine.dart';

/// Draft state for the character-creation flow (the Univers/Mode de
/// création pickers + screen 1b + the 1i characteristic-roll modal).
/// Nothing is persisted until [submit] — the repository only sees the
/// finished character.
///
/// The characteristics/skills/occupations catalogue comes from [config]
/// (the player's currently selected `CreationModeConfig`, see
/// `selectedCreationModeProvider`) rather than a static import, so a new
/// universe or creation mode needs no change here — only a new JSON file.
class CharacterCreationState {
  CharacterCreationState({
    required this.config,
    required this.name,
    required this.occupation,
    required this.description,
    required this.characteristics,
    required this.skillAllocated,
    this.occupationSkillAllocated = const {},
    this.occupationSkillChoiceSelections = const [],
    this.choiceCharacteristics = const {},
    this.globalAttributeValues = const {},
    this.isSubmitting = false,
  });

  factory CharacterCreationState.initial(CreationModeConfig config) => CharacterCreationState(
        config: config,
        name: '',
        occupation: null,
        description: '',
        characteristics: {
          for (final c in config.characterSheet.rollableCharacteristics) c.key: null,
        },
        skillAllocated: {
          for (final s in config.characterSheet.skills) s.key: 0,
        },
        // Only pre-filled when the config gives this option an explicit
        // `default` — otherwise it stays null (pending), same as a rolled
        // characteristic before the dice are tapped, until the player
        // actively picks a value. See `CharacteristicConfig.defaultValue`.
        choiceCharacteristics: {
          for (final c in config.characterSheet.choiceCharacteristics)
            c.key: c.defaultChoiceIndex,
        },
        globalAttributeValues: {
          for (final a in config.characterSheet.globalAttributes)
            a.key: a.type == GlobalAttributeType.choice
                ? (a.choices.isEmpty ? 0 : (a.choices.length - 1) ~/ 2)
                : (a.min ?? 0),
        },
      );

  final CreationModeConfig config;
  final String name;
  final String? occupation;
  final String description;
  final Map<String, int?> characteristics;
  final Map<String, int> skillAllocated;

  /// Selected option index for each [CharacterSheetConfig.choiceCharacteristics],
  /// keyed by characteristic key — null until the player picks one, unless
  /// the characteristic has a configured [CharacteristicConfig.defaultValue].
  final Map<String, int?> choiceCharacteristics;

  /// Current value for each [CharacterSheetConfig.globalAttributes], keyed
  /// by attribute key — the raw number for
  /// [GlobalAttributeType.integer] (CoC7: age), or the picked option's
  /// index for [GlobalAttributeType.choice] (CoC7: Fortune), same
  /// convention as [choiceCharacteristics].
  final Map<String, int> globalAttributeValues;

  /// Points spent from the *selected occupation's own* budget (see
  /// [OccupationConfig.occupationSkillPointsFormula]), keyed by skill —
  /// separate from [skillAllocated], which draws from the universe-wide
  /// [CharacterSheetConfig.personalSkillPointsFormula] pool.
  final Map<String, int> occupationSkillAllocated;

  /// One entry per [OccupationConfig.occupationSkillChoices] slot on the
  /// selected occupation; each holds the skill key the player picked for
  /// that "plus one skill of your choice" slot, or null while unset.
  final List<String?> occupationSkillChoiceSelections;

  final bool isSubmitting;

  /// True once every primary characteristic has a value, however it's
  /// assigned — dice-rolled ([characteristics]) or, for a numeric choice
  /// (point-buy) mode, actually picked by the player rather than just
  /// sitting on a default. Gates the skill-point formulas, which need
  /// every primary characteristic resolved first.
  bool get allCharacteristicsRolled =>
      characteristics.values.every((v) => v != null) &&
      config.characterSheet.numericChoiceCharacteristics
          .every((c) => choiceCharacteristics[c.key] != null);

  /// Every primary characteristic's current value, whichever way it's
  /// assigned: dice-rolled ([characteristics]) or picked from a numeric
  /// list (e.g. a "point-buy" mode's FOR/DEX/…, see
  /// [CharacterSheetConfig.numericChoiceCharacteristics]). Feeds every
  /// formula (derived characteristics, skill bases, resources, skill-point
  /// budgets) — text/flavor choices (Fortune) are deliberately excluded,
  /// since nothing but display ever needs their value. Unpicked/unrolled
  /// characteristics read as 0 here; callers needing to know whether that's
  /// a "real" 0 should check [allCharacteristicsRolled] first.
  Map<String, int> get resolvedCharacteristics {
    final resolved = characteristics.map((k, v) => MapEntry(k, v ?? 0));
    for (final c in config.characterSheet.numericChoiceCharacteristics) {
      final index = choiceCharacteristics[c.key];
      resolved[c.key] = index == null ? 0 : c.choiceValueAt(index).round();
    }
    return resolved;
  }

  /// Display label for the player's current pick on a [choice]
  /// characteristic (e.g. "Moyen" for Fortune), or '' if unset.
  String choiceLabel(CharacteristicConfig choice) {
    final index = choiceCharacteristics[choice.key];
    if (choice.choices.isEmpty || index == null) return '';
    return choice.choices[index.clamp(0, choice.choices.length - 1)];
  }

  /// Display label for the player's current pick on a
  /// [GlobalAttributeType.choice] global attribute (e.g. "Moyen" for
  /// Fortune).
  String globalAttributeChoiceLabel(GlobalAttributeConfig attribute) {
    final index = globalAttributeValues[attribute.key] ?? 0;
    if (attribute.choices.isEmpty) return '';
    return attribute.choices[index.clamp(0, attribute.choices.length - 1)];
  }

  /// The occupation config matching [occupation]'s display name, if any.
  OccupationConfig? get selectedOccupation =>
      config.characterSheet.occupationByName(occupation);

  /// Points the player has to freely distribute across any skill, per the
  /// universe's [CharacterSheetConfig.personalSkillPointsFormula] (CoC7:
  /// `INT * 2`). Zero until every characteristic has been rolled.
  int get skillPointsTotal {
    if (!allCharacteristicsRolled) return 0;
    final vars = Map<String, num>.from(resolvedCharacteristics);
    return FormulaEvaluator.evaluate(config.characterSheet.personalSkillPointsFormula, vars)
        .floor();
  }

  int get skillPointsSpent =>
      skillAllocated.values.fold(0, (a, b) => a + b);

  int get skillPointsRemaining => skillPointsTotal - skillPointsSpent;

  /// Skills the selected occupation's point budget can be spent on: its
  /// fixed [OccupationConfig.occupationSkills] plus whichever skills the
  /// player has picked for the "skill of your choice" slots.
  Set<String> get occupationEligibleSkillKeys {
    final occupation = selectedOccupation;
    if (occupation == null) return const {};
    return {
      ...occupation.occupationSkills,
      for (final choice in occupationSkillChoiceSelections) ?choice,
    };
  }

  /// Points the player has to distribute across the selected occupation's
  /// skill list, per [OccupationConfig.occupationSkillPointsFormula]. Zero
  /// if no occupation is selected, it doesn't define the mechanic, or not
  /// every characteristic has been rolled yet.
  int get occupationSkillPointsTotal {
    final occupation = selectedOccupation;
    final formula = occupation?.occupationSkillPointsFormula;
    if (formula == null || !allCharacteristicsRolled) return 0;
    final vars = Map<String, num>.from(resolvedCharacteristics);
    return FormulaEvaluator.evaluate(formula, vars).floor();
  }

  int get occupationSkillPointsSpent =>
      occupationSkillAllocated.values.fold(0, (a, b) => a + b);

  int get occupationSkillPointsRemaining =>
      occupationSkillPointsTotal - occupationSkillPointsSpent;

  /// The skill's catalogue base value (flat or derived from a
  /// characteristic) plus any occupation bonus for that skill — before the
  /// player's own allocated points.
  int baseValueFor(SkillConfig skill) {
    final base = _catalogBaseFor(skill);
    final occupationBonus = selectedOccupation?.skillBonusFor(skill.key) ?? 0;
    return base + occupationBonus;
  }

  int _catalogBaseFor(SkillConfig skill) {
    final formula = skill.baseFormula;
    if (formula == null) return skill.baseValue ?? 0;
    final vars = Map<String, num>.from(resolvedCharacteristics);
    return FormulaEvaluator.evaluate(formula, vars).floor();
  }

  int valueFor(SkillConfig skill) =>
      baseValueFor(skill) +
      (skillAllocated[skill.key] ?? 0) +
      (occupationSkillAllocated[skill.key] ?? 0);

  CharacterCreationState copyWith({
    String? name,
    Object? occupation = _unset,
    String? description,
    Map<String, int?>? characteristics,
    Map<String, int>? skillAllocated,
    Map<String, int>? occupationSkillAllocated,
    List<String?>? occupationSkillChoiceSelections,
    Map<String, int?>? choiceCharacteristics,
    Map<String, int>? globalAttributeValues,
    bool? isSubmitting,
  }) {
    return CharacterCreationState(
      config: config,
      name: name ?? this.name,
      occupation:
          identical(occupation, _unset) ? this.occupation : occupation as String?,
      description: description ?? this.description,
      characteristics: characteristics ?? this.characteristics,
      skillAllocated: skillAllocated ?? this.skillAllocated,
      occupationSkillAllocated: occupationSkillAllocated ?? this.occupationSkillAllocated,
      occupationSkillChoiceSelections:
          occupationSkillChoiceSelections ?? this.occupationSkillChoiceSelections,
      choiceCharacteristics: choiceCharacteristics ?? this.choiceCharacteristics,
      globalAttributeValues: globalAttributeValues ?? this.globalAttributeValues,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

const _unset = Object();

class CharacterCreationNotifier extends Notifier<CharacterCreationState> {
  @override
  CharacterCreationState build() =>
      CharacterCreationState.initial(ref.watch(selectedCreationModeProvider));

  void setName(String value) => state = state.copyWith(name: value);

  /// Selecting a new occupation invalidates any points already allocated
  /// from the previous occupation's budget — its skill list (and choice
  /// slots) may no longer apply — so both are reset here.
  void setOccupation(String? value) {
    final occupation = state.config.characterSheet.occupationByName(value);
    state = state.copyWith(
      occupation: value,
      occupationSkillAllocated: const {},
      occupationSkillChoiceSelections:
          List<String?>.filled(occupation?.occupationSkillChoices ?? 0, null),
    );
  }

  void setDescription(String value) => state = state.copyWith(description: value);

  /// Sets the player's pick (by option index) for a [CalculationMethod.choice]
  /// characteristic, e.g. a point-buy mode's FOR/DEX/….
  void setChoiceCharacteristic(String key, int index) {
    final updated = Map<String, int?>.from(state.choiceCharacteristics)..[key] = index;
    state = state.copyWith(choiceCharacteristics: updated);
  }

  /// Sets the value of a [CharacterSheetConfig.globalAttributes] entry —
  /// the raw number for an integer attribute (CoC7: age), clamped to its
  /// configured [GlobalAttributeConfig.min]/[GlobalAttributeConfig.max] if
  /// any, or the picked option's index for a choice attribute (CoC7:
  /// Fortune).
  void setGlobalAttributeValue(String key, int value) {
    final attribute = state.config.characterSheet.globalAttributes
        .firstWhere((a) => a.key == key, orElse: () => throw ArgumentError('Unknown global attribute "$key"'));
    final resolved = attribute.type == GlobalAttributeType.integer
        ? _clampToRange(value, attribute.min, attribute.max)
        : value;
    final updated = Map<String, int>.from(state.globalAttributeValues)..[key] = resolved;
    state = state.copyWith(globalAttributeValues: updated);
  }

  /// Rolls [key] using the active universe's dice formula for that
  /// characteristic.
  CharacteristicRoll rollCharacteristic(String key) {
    final rules = ref.read(rulesEngineProvider);
    final roll = rules.rollCharacteristic(key);
    final updated = Map<String, int?>.from(state.characteristics)..[key] = roll.total;
    state = state.copyWith(characteristics: updated);
    return roll;
  }

  /// Read-only preview of the derived characteristics for display before
  /// the character is actually created.
  Map<String, int> previewDerived(Map<String, int> primary) {
    return ref.read(rulesEngineProvider).computeDerivedCharacteristics(primary);
  }

  void incrementSkill(String key) {
    if (state.skillPointsRemaining <= 0) return;
    final skill = state.config.characterSheet.skillByKey(key);
    if (skill.max != null && state.valueFor(skill) >= skill.max!) return;
    final updated = Map<String, int>.from(state.skillAllocated);
    updated[key] = (updated[key] ?? 0) + 1;
    state = state.copyWith(skillAllocated: updated);
  }

  void decrementSkill(String key) {
    final current = state.skillAllocated[key] ?? 0;
    if (current <= 0) return;
    final updated = Map<String, int>.from(state.skillAllocated);
    updated[key] = current - 1;
    state = state.copyWith(skillAllocated: updated);
  }

  /// Spends one point from the selected occupation's own budget on [key].
  /// No-op if [key] isn't one of its eligible skills or the budget is
  /// already fully spent.
  void incrementOccupationSkill(String key) {
    if (!state.occupationEligibleSkillKeys.contains(key)) return;
    if (state.occupationSkillPointsRemaining <= 0) return;
    final skill = state.config.characterSheet.skillByKey(key);
    if (skill.max != null && state.valueFor(skill) >= skill.max!) return;
    final updated = Map<String, int>.from(state.occupationSkillAllocated);
    updated[key] = (updated[key] ?? 0) + 1;
    state = state.copyWith(occupationSkillAllocated: updated);
  }

  void decrementOccupationSkill(String key) {
    final current = state.occupationSkillAllocated[key] ?? 0;
    if (current <= 0) return;
    final updated = Map<String, int>.from(state.occupationSkillAllocated);
    updated[key] = current - 1;
    state = state.copyWith(occupationSkillAllocated: updated);
  }

  /// Sets which skill the "skill of your choice" slot at [slotIndex]
  /// applies to. Passing null clears that slot. Any points already spent
  /// on the slot's *previous* skill are dropped, since it stops being
  /// eligible for the occupation budget once the slot points elsewhere.
  void setOccupationSkillChoice(int slotIndex, String? skillKey) {
    final selections = state.occupationSkillChoiceSelections;
    if (slotIndex < 0 || slotIndex >= selections.length) return;
    final previous = selections[slotIndex];
    final updatedSelections = List<String?>.from(selections);
    updatedSelections[slotIndex] = skillKey;

    var updatedAllocated = state.occupationSkillAllocated;
    final stillEligible = updatedSelections.contains(previous) ||
        (state.selectedOccupation?.occupationSkills.contains(previous) ?? false);
    if (previous != null && !stillEligible && updatedAllocated.containsKey(previous)) {
      updatedAllocated = Map<String, int>.from(updatedAllocated)..remove(previous);
    }

    state = state.copyWith(
      occupationSkillChoiceSelections: updatedSelections,
      occupationSkillAllocated: updatedAllocated,
    );
  }

  /// Persists the character and returns its new id.
  Future<String> submit() async {
    state = state.copyWith(isSubmitting: true);
    try {
      final repo = ref.read(characterRepositoryProvider);
      final rules = ref.read(rulesEngineProvider);
      final config = state.config;
      final primary = state.resolvedCharacteristics;
      final derived = rules.computeDerivedCharacteristics(primary);
      // Numeric choices (e.g. point-buy FOR/DEX/…) are already resolved to
      // their real value in `primary` above; only flavor/text choices
      // (Fortune) still need their raw option index persisted, so the
      // sheet can map it back to a label later.
      final allCharacteristics = {
        ...primary,
        ...derived,
        for (final c in config.characterSheet.flavorChoiceCharacteristics)
          c.key: state.choiceCharacteristics[c.key] ?? 0,
      };

      var order = 0;
      final stats = <CharacterStat>[];
      for (final c in config.characterSheet.characteristics) {
        stats.add(_draftStat(
          kind: StatKind.characteristic,
          key: c.key,
          label: c.name,
          value: allCharacteristics[c.key] ?? 0,
          sortOrder: order++,
        ));
      }
      var skillOrder = 0;
      for (final s in config.characterSheet.skills) {
        stats.add(_draftStat(
          kind: StatKind.skill,
          key: s.key,
          label: s.name,
          value: state.valueFor(s),
          base: s.baseDisplay,
          sortOrder: skillOrder++,
        ));
      }
      var attributeOrder = 0;
      for (final a in config.characterSheet.globalAttributes) {
        stats.add(_draftStat(
          kind: StatKind.attribute,
          key: a.key,
          label: a.name,
          value: state.globalAttributeValues[a.key] ?? 0,
          sortOrder: attributeOrder++,
        ));
      }

      final resourceVars = Map<String, num>.from(allCharacteristics);
      final resources = [
        for (final r in config.characterSheet.resources)
          _draftResource(
            key: r.key,
            label: r.label,
            value: FormulaEvaluator.evaluate(r.formula, resourceVars).floor().clamp(0, 999),
            tone: Tone.values.byName(r.tone),
          ),
      ];

      final created = await repo.create(
        systemId: config.id,
        name: state.name.trim().isEmpty ? 'Aventurier sans nom' : state.name.trim(),
        occupation: state.occupation,
        description: state.description.trim().isEmpty ? null : state.description.trim(),
        stats: stats,
        resources: resources,
      );
      return created.id;
    } finally {
      state = state.copyWith(isSubmitting: false);
    }
  }

  // The repository assigns real ids/characterId when it inserts — these
  // drafts only carry the values it needs to persist.
  CharacterStat _draftStat({
    required StatKind kind,
    required String key,
    required String label,
    required int value,
    String? base,
    required int sortOrder,
  }) {
    return CharacterStat(
      id: '',
      characterId: '',
      kind: kind,
      key: key,
      label: label,
      value: value,
      base: base,
      sortOrder: sortOrder,
    );
  }

  CharacterResource _draftResource({
    required String key,
    required String label,
    required int value,
    required Tone tone,
  }) {
    return CharacterResource(
      id: '',
      characterId: '',
      key: key,
      label: label,
      current: value,
      max: value,
      tone: tone,
    );
  }
}

final characterCreationProvider =
    NotifierProvider<CharacterCreationNotifier, CharacterCreationState>(
  CharacterCreationNotifier.new,
);

/// Clamps [value] to `[min, max]`, either bound being a no-op when null.
int _clampToRange(int value, int? min, int? max) {
  var result = value;
  if (min != null && result < min) result = min;
  if (max != null && result > max) result = max;
  return result;
}
