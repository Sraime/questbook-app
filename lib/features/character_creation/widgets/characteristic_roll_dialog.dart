import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/components/qb_badge.dart';
import '../../../design_system/components/qb_button.dart';
import '../../../design_system/components/qb_dialog.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';
import '../../../domain/rules/rules_engine.dart';
import '../providers/character_creation_provider.dart';

/// Screen 1i — "Lancer une caractéristique" modal shown from the creation
/// screen when tapping a still-pending characteristic circle.
class CharacteristicRollDialog extends ConsumerStatefulWidget {
  const CharacteristicRollDialog({
    super.key,
    required this.characteristicKey,
    required this.characteristicLabel,
    this.bonusLabel,
  });

  final String characteristicKey;
  final String characteristicLabel;
  final String? bonusLabel;

  static Future<void> show(
    BuildContext context, {
    required String characteristicKey,
    required String characteristicLabel,
    String? bonusLabel,
  }) {
    return showQBDialog(
      context: context,
      title: characteristicLabel,
      width: 320,
      builder: (context) => CharacteristicRollDialog(
        characteristicKey: characteristicKey,
        characteristicLabel: characteristicLabel,
        bonusLabel: bonusLabel,
      ),
    );
  }

  @override
  ConsumerState<CharacteristicRollDialog> createState() =>
      _CharacteristicRollDialogState();
}

class _CharacteristicRollDialogState
    extends ConsumerState<CharacteristicRollDialog> {
  CharacteristicRoll? _roll;

  void _performRoll() {
    final roll = ref
        .read(characterCreationProvider.notifier)
        .rollCharacteristic(widget.characteristicKey);
    setState(() => _roll = roll);
  }

  @override
  void initState() {
    super.initState();
    // Defer the first roll until after this frame finishes building: the
    // dialog's initState still runs as part of the widget tree build, and
    // Riverpod forbids modifying provider state while building.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _performRoll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final roll = _roll;
    if (roll == null) {
      return const SizedBox(
        height: 220,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Lance 3d6 pour déterminer ta caractéristique.',
          textAlign: TextAlign.center,
          style: QBType.body().copyWith(
            fontSize: QBType.sm,
            color: QBColors.textMuted,
          ),
        ),
        const SizedBox(height: QBSpace.s4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final die in roll.dice) ...[
              _DieFace(value: die),
              const SizedBox(width: QBSpace.s3),
            ],
          ],
        ),
        const SizedBox(height: QBSpace.s3),
        Text(
          '${roll.diceSum} (dés) × 5 + ${roll.bonus} (bonus)',
          style: QBType.mono().copyWith(
            fontSize: QBType.sm,
            color: QBColors.textMuted,
          ),
        ),
        const SizedBox(height: QBSpace.s2),
        Text(
          '${roll.total}',
          style: QBType.game().copyWith(
            fontSize: 44,
            fontWeight: QBType.weightBold,
            color: QBColors.ink900,
          ),
        ),
        if (widget.bonusLabel != null) ...[
          const SizedBox(height: 2),
          QBBadge(label: widget.bonusLabel!, tone: QBTone.info),
        ],
        const SizedBox(height: QBSpace.s4),
        Row(
          children: [
            Expanded(
              child: QBButton(
                label: 'Relancer',
                variant: QBButtonVariant.ghost,
                expand: true,
                onPressed: _performRoll,
              ),
            ),
            const SizedBox(width: QBSpace.s3),
            Expanded(
              child: QBButton(
                label: 'Valider',
                variant: QBButtonVariant.primary,
                expand: true,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Renders one d6 face as a 3x3 pip grid, matching the mockup's dice-face
/// layout algorithm.
class _DieFace extends StatelessWidget {
  const _DieFace({required this.value});

  final int value;

  static const _layouts = {
    1: [4],
    2: [0, 8],
    3: [0, 4, 8],
    4: [0, 2, 6, 8],
    5: [0, 2, 4, 6, 8],
    6: [0, 2, 3, 5, 6, 8],
  };

  @override
  Widget build(BuildContext context) {
    final on = _layouts[value] ?? const [];
    return Container(
      width: 52,
      height: 52,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: QBColors.surfaceRaised,
        borderRadius: BorderRadius.circular(QBRadius.md),
        border: Border.all(color: QBColors.ink900, width: 3),
        boxShadow: const [BoxShadow(color: Color(0x59000000), offset: Offset(0, 3))],
      ),
      child: GridView.count(
        crossAxisCount: 3,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          for (var i = 0; i < 9; i++)
            Center(
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: on.contains(i) ? QBColors.ink900 : Colors.transparent,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
