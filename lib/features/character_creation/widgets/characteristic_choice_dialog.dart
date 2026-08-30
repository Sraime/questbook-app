import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/components/qb_button.dart';
import '../../../design_system/components/qb_dialog.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';
import '../providers/character_creation_provider.dart';

/// Modal shown from the creation screen when tapping a characteristic whose
/// value is picked from a fixed list instead of rolled (e.g. a "point-buy"
/// mode's FOR/DEX/…, see `CharacterSheetConfig.numericChoiceCharacteristics`).
/// Deliberately mirrors [CharacteristicRollDialog]'s popup shell/flow — same
/// dialog, same "pick, then confirm" pattern — swapping the dice for a list
/// of selectable values.
class CharacteristicChoiceDialog extends ConsumerWidget {
  const CharacteristicChoiceDialog({
    super.key,
    required this.characteristicKey,
    required this.characteristicLabel,
    required this.choices,
  });

  final String characteristicKey;
  final String characteristicLabel;
  final List<String> choices;

  static Future<void> show(
    BuildContext context, {
    required String characteristicKey,
    required String characteristicLabel,
    required List<String> choices,
  }) {
    return showQBDialog(
      context: context,
      title: characteristicLabel,
      width: 320,
      builder: (context) => CharacteristicChoiceDialog(
        characteristicKey: characteristicKey,
        characteristicLabel: characteristicLabel,
        choices: choices,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(characterCreationProvider);
    final notifier = ref.read(characterCreationProvider.notifier);
    final selectedIndex = state.choiceCharacteristics[characteristicKey];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Choisis une valeur pour cette caractéristique.',
          textAlign: TextAlign.center,
          style: QBType.body().copyWith(
            fontSize: QBType.sm,
            color: QBColors.textMuted,
          ),
        ),
        const SizedBox(height: QBSpace.s4),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: QBSpace.s2,
          runSpacing: QBSpace.s2,
          children: [
            for (var i = 0; i < choices.length; i++)
              QBButton(
                label: choices[i],
                size: QBButtonSize.sm,
                variant: selectedIndex != null && i == selectedIndex
                    ? QBButtonVariant.primary
                    : QBButtonVariant.ghost,
                onPressed: () => notifier.setChoiceCharacteristic(characteristicKey, i),
              ),
          ],
        ),
        const SizedBox(height: QBSpace.s4),
        QBButton(
          label: 'Valider',
          variant: QBButtonVariant.primary,
          expand: true,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ],
    );
  }
}
