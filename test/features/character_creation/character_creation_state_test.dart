import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:questbook/app/providers.dart';
import 'package:questbook/data/universe/universe_assets_loader.dart';
import 'package:questbook/domain/models/creation_mode_config.dart';
import 'package:questbook/domain/models/universe_config.dart';
import 'package:questbook/features/character_creation/providers/character_creation_provider.dart';

void main() {
  late CreationModeConfig simplifie;

  setUpAll(() {
    final universeRaw =
        File('assets/universes/universe_call_of_cthulhu.json').readAsStringSync();
    final universe = UniverseConfig.fromJson(jsonDecode(universeRaw) as Map<String, dynamic>);
    final entry = universe.creationModes.firstWhere((c) => c.id == 'call_of_cthulhu_simplifie');
    final modeRaw =
        File('assets/universes/${entry.configurationFile}').readAsStringSync();
    simplifie = buildCreationModeConfig(
      universe,
      entry,
      jsonDecode(modeRaw) as Map<String, dynamic>,
    );
  });

  test('Simplifié pre-fills numeric choices from default, leaves Chance empty', () {
    final state = CharacterCreationState.initial(simplifie);
    expect(state.resolvedCharacteristics['FOR'], 40);
    expect(state.resolvedCharacteristics['DEX'], 50);
    expect(state.resolvedCharacteristics['APP'], 60);
    expect(state.resolvedCharacteristics['INT'], 70);
    expect(state.resolvedCharacteristics['TAI'], 80);
    expect(state.characteristics['CHA'], isNull);
    expect(state.allCharacteristicsRolled, isFalse);
  });

  test('age input is clamped to the configured min/max', () {
    final container = _containerFor(simplifie);
    addTearDown(container.dispose);
    final notifier = container.read(characterCreationProvider.notifier);

    notifier.setGlobalAttributeValue('age', 1);
    expect(container.read(characterCreationProvider).globalAttributeValues['age'], 5);

    notifier.setGlobalAttributeValue('age', 200);
    expect(container.read(characterCreationProvider).globalAttributeValues['age'], 100);

    notifier.setGlobalAttributeValue('age', 33);
    expect(container.read(characterCreationProvider).globalAttributeValues['age'], 33);
  });

  test('skill increments stop once the configured max total is reached', () {
    final config = CreationModeConfig(
      id: 'test_mode',
      universeName: 'Test',
      creationModeName: 'Test',
      characterSheet: CharacterSheetConfig(
        characteristics: const [],
        skills: const [
          SkillConfig(key: 'nager', name: 'Nager', description: '', baseValue: 98, max: 100),
        ],
        occupations: const [],
        resources: const [],
        personalSkillPointsFormula: '100',
      ),
    );
    final container = _containerFor(config);
    addTearDown(container.dispose);
    final notifier = container.read(characterCreationProvider.notifier);
    final skill = config.characterSheet.skillByKey('nager');

    notifier.incrementSkill('nager');
    notifier.incrementSkill('nager');
    notifier.incrementSkill('nager');

    final state = container.read(characterCreationProvider);
    expect(state.valueFor(skill), 100);
    expect(state.skillAllocated['nager'], 2);
  });
}

ProviderContainer _containerFor(CreationModeConfig config) {
  return ProviderContainer(
    overrides: [
      availableCreationModesProvider.overrideWithValue([config]),
      selectedCreationModeIdProvider.overrideWith(() => SelectedCreationModeIdNotifier(config.id)),
    ],
  );
}
