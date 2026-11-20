import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/components/qb_badge.dart';
import '../../../design_system/components/qb_button.dart';
import '../../../design_system/components/qb_dialog.dart';
import '../../../design_system/components/qb_dice_roller.dart';
import '../../../design_system/components/qb_select.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../domain/models/character.dart';
import '../../../domain/rules/rules_engine.dart';
import '../providers/character_detail_provider.dart';

/// Screen 1f — "Lancer de dés" modal.
class SkillRollDialog extends ConsumerStatefulWidget {
  const SkillRollDialog({super.key, required this.character});

  final Character character;

  static Future<void> show(BuildContext context, Character character) {
    return showQBDialog(
      context: context,
      title: 'Lancer de dé',
      width: 320,
      builder: (context) => SkillRollDialog(character: character),
    );
  }

  @override
  ConsumerState<SkillRollDialog> createState() => _SkillRollDialogState();
}

class _SkillRollDialogState extends ConsumerState<SkillRollDialog> {
  late String _skillKey;
  int? _result;
  CheckOutcome? _outcome;

  @override
  void initState() {
    super.initState();
    _skillKey = widget.character.skills.first.key;
  }

  void _roll() {
    final skill =
        widget.character.skills.firstWhere((s) => s.key == _skillKey);
    final result =
        ref.read(characterActionsProvider).rollSkillCheck(skill.value);
    setState(() {
      _result = result.roll;
      _outcome = result.outcome;
    });
  }

  @override
  Widget build(BuildContext context) {
    final skills = widget.character.skills;
    final skill = skills.firstWhere((s) => s.key == _skillKey);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        QBSelect(
          label: 'Compétence',
          value: skill.label,
          options: [for (final s in skills) s.label],
          onChanged: (label) {
            if (label == null) return;
            setState(() {
              _skillKey = skills.firstWhere((s) => s.label == label).key;
              _result = null;
              _outcome = null;
            });
          },
        ),
        const SizedBox(height: QBSpace.s4),
        QBDiceRoller(
          skill: skill.label,
          percent: skill.value,
          result: _result,
          onRoll: _roll,
        ),
        if (_outcome != null) ...[
          const SizedBox(height: QBSpace.s4),
          Center(child: _outcomeBadge(_outcome!)),
        ],
        const SizedBox(height: QBSpace.s4),
        QBButton(
          label: 'Relancer',
          variant: QBButtonVariant.primary,
          expand: true,
          onPressed: _roll,
        ),
      ],
    );
  }

  Widget _outcomeBadge(CheckOutcome outcome) {
    final (label, tone) = switch (outcome) {
      CheckOutcome.criticalSuccess => ('Réussite critique', QBTone.success),
      CheckOutcome.success => ('Réussite', QBTone.success),
      CheckOutcome.failure => ('Échec', QBTone.danger),
      CheckOutcome.criticalFailure => ('Échec critique', QBTone.danger),
    };
    return QBBadge(label: label, tone: tone);
  }
}
