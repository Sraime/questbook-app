import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../domain/models/character_resource.dart';
import '../../../domain/models/character_stat.dart';
import '../../../domain/models/tone.dart';
import '../../../domain/models/universe_config.dart';
import '../../../domain/rules/formula_evaluator.dart';
import '../../../domain/rules/rules_engine.dart';

/// Draft state for the character-creation flow (screen 1b + the 1i
/// characteristic-roll modal). Nothing is persisted until [submit] — the
/// repository only sees the finished character.
///
/// The characteristics/skills/occupations catalogue comes from [config]
/// (the active universe's `UniverseConfig`, loaded from
/// `assets/universes/<systemId>.json`) rather than a static import, so a
/// second universe would need no change here — only a new JSON file.
class CharacterCreationState {
  CharacterCreationState({
    required this.config,
    required this.name,
    required this.occupation,
    required this.description,
    required this.characteristics,
    required this.skillAllocated,
    this.isSubmitting = false,
  });

  factory CharacterCreationState.initial(UniverseConfig config) => CharacterCreationState(
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
      );

  final UniverseConfig config;
  final String name;
  final String? occupation;
  final String description;
  final Map<String, int?> characteristics;
  final Map<String, int> skillAllocated;
  final bool isSubmitting;

  bool get allCharacteristicsRolled =>
      characteristics.values.every((v) => v != null);

  Map<String, int> get resolvedCharacteristics =>
      characteristics.map((k, v) => MapEntry(k, v ?? 0));

  /// The occupation config matching [occupation]'s display name, if any.
  OccupationConfig? get selectedOccupation =>
      config.characterSheet.occupationByName(occupation);

  int get skillPointsTotal {
    if (!allCharacteristicsRolled) return 0;
    final vars = Map<String, num>.from(resolvedCharacteristics);
    return FormulaEvaluator.evaluate(config.characterSheet.skillPointsFormula, vars).floor();
  }

  int get skillPointsSpent =>
      skillAllocated.values.fold(0, (a, b) => a + b);

  int get skillPointsRemaining => skillPointsTotal - skillPointsSpent;

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
      baseValueFor(skill) + (skillAllocated[skill.key] ?? 0);

  CharacterCreationState copyWith({
    String? name,
    Object? occupation = _unset,
    String? description,
    Map<String, int?>? characteristics,
    Map<String, int>? skillAllocated,
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
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

const _unset = Object();

class CharacterCreationNotifier extends Notifier<CharacterCreationState> {
  @override
  CharacterCreationState build() =>
      CharacterCreationState.initial(ref.watch(universeConfigProvider));

  void setName(String value) => state = state.copyWith(name: value);

  void setOccupation(String? value) => state = state.copyWith(occupation: value);

  void setDescription(String value) => state = state.copyWith(description: value);

  /// The flat bonus the currently-selected occupation grants to
  /// [characteristicKey], if any (0 otherwise).
  int occupationBonusFor(String characteristicKey) =>
      state.selectedOccupation?.characteristicBonusFor(characteristicKey) ?? 0;

  /// Display label for [occupationBonusFor], or null if there's no bonus
  /// to show (no occupation selected, or it doesn't affect this stat).
  String? occupationBonusLabelFor(String characteristicKey) {
    final occupation = state.selectedOccupation;
    if (occupation == null) return null;
    final bonus = occupation.characteristicBonusFor(characteristicKey);
    return bonus == 0 ? null : '${occupation.name} +$bonus';
  }

  /// Rolls [key] using the active universe's dice formula for that
  /// characteristic, applying the selected occupation's bonus (if any).
  CharacteristicRoll rollCharacteristic(String key) {
    final rules = ref.read(rulesEngineProvider);
    final roll = rules.rollCharacteristic(key, bonus: occupationBonusFor(key));
    final updated = Map<String, int?>.from(state.characteristics)..[key] = roll.total;
    state = state.copyWith(characteristics: updated);
    return roll;
  }

  void rollAllCharacteristics() {
    for (final c in state.config.characterSheet.rollableCharacteristics) {
      if (state.characteristics[c.key] == null) {
        rollCharacteristic(c.key);
      }
    }
  }

  /// Read-only preview of the derived characteristics for display before
  /// the character is actually created.
  Map<String, int> previewDerived(Map<String, int> primary) {
    return ref.read(rulesEngineProvider).computeDerivedCharacteristics(primary);
  }

  void incrementSkill(String key) {
    if (state.skillPointsRemaining <= 0) return;
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

  /// Persists the character and returns its new id.
  Future<String> submit() async {
    state = state.copyWith(isSubmitting: true);
    try {
      final repo = ref.read(characterRepositoryProvider);
      final rules = ref.read(rulesEngineProvider);
      final config = state.config;
      final primary = state.resolvedCharacteristics;
      final derived = rules.computeDerivedCharacteristics(primary);
      final allCharacteristics = {...primary, ...derived};

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
