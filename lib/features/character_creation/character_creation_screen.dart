import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../design_system/components/qb_badge.dart';
import '../../design_system/components/qb_button.dart';
import '../../design_system/components/qb_card.dart';
import '../../design_system/components/qb_input.dart';
import '../../design_system/components/qb_page_background.dart';
import '../../design_system/components/qb_select.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/spacing.dart';
import '../../design_system/tokens/typography.dart';
import '../../domain/models/universe_config.dart';
import 'providers/character_creation_provider.dart';
import 'widgets/characteristic_roll_dialog.dart';

/// Screen 1b — Créer un personnage.
class CharacterCreationScreen extends ConsumerStatefulWidget {
  const CharacterCreationScreen({super.key});

  @override
  ConsumerState<CharacterCreationScreen> createState() =>
      _CharacterCreationScreenState();
}

class _CharacterCreationScreenState
    extends ConsumerState<CharacterCreationScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _rollStat(String key, String label) async {
    final notifier = ref.read(characterCreationProvider.notifier);
    await CharacteristicRollDialog.show(
      context,
      characteristicKey: key,
      characteristicLabel: label,
      bonusLabel: notifier.occupationBonusLabelFor(key),
    );
  }

  Future<void> _submit() async {
    final id = await ref.read(characterCreationProvider.notifier).submit();
    if (!mounted) return;
    context.go('/perso/$id');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(characterCreationProvider);
    final config = ref.watch(universeConfigProvider);
    final sheet = config.characterSheet;

    return QBPageBackground(
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 24, 18, 90),
          children: [
            Text(
              'Crée ton personnage',
              style: QBType.game().copyWith(
                fontWeight: QBType.weightBold,
                fontSize: 22,
                color: QBColors.ink900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Décris-le en quelques mots, ou laisse Questbook générer '
              'ses statistiques.',
              style: QBType.body().copyWith(
                fontSize: QBType.sm,
                color: QBColors.textMuted,
              ),
            ),
            const SizedBox(height: QBSpace.s5),
            QBCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  QBInput(
                    label: 'Nom du personnage',
                    controller: _nameController,
                    hint: 'Laisse vide pour un nom généré',
                    onChanged:
                        ref.read(characterCreationProvider.notifier).setName,
                  ),
                  const SizedBox(height: QBSpace.s4),
                  QBSelect(
                    label: 'Occupation',
                    value: state.occupation,
                    options: [for (final o in sheet.occupations) o.name],
                    onChanged: ref
                        .read(characterCreationProvider.notifier)
                        .setOccupation,
                  ),
                  const SizedBox(height: QBSpace.s4),
                  QBInput(
                    label: 'Décris ton personnage',
                    controller: _descriptionController,
                    placeholder:
                        'Une occultiste solitaire, ancienne bibliothécaire '
                        'à Arkham…',
                    maxLines: 3,
                    onChanged: ref
                        .read(characterCreationProvider.notifier)
                        .setDescription,
                  ),
                  const SizedBox(height: QBSpace.s4),
                  QBButton(
                    label: 'Tirage aléatoire',
                    variant: QBButtonVariant.secondary,
                    expand: true,
                    onPressed: () => ref
                        .read(characterCreationProvider.notifier)
                        .rollAllCharacteristics(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: QBSpace.s4),
            QBCard(
              padding: const EdgeInsets.all(QBSpace.s3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(6, 6, 6, 12),
                    child: Text(
                      'Caractéristiques',
                      style: QBType.game().copyWith(
                        fontWeight: QBType.weightSemibold,
                        fontSize: 15,
                        color: QBColors.leather800,
                      ),
                    ),
                  ),
                  Wrap(
                    alignment: WrapAlignment.center,
                    runSpacing: 10,
                    children: [
                      for (final c in sheet.rollableCharacteristics)
                        _StatPreviewCircle(
                          label: c.name,
                          value: state.characteristics[c.key],
                          onTap: () => _rollStat(c.key, c.name),
                        ),
                      for (final d in sheet.derivedCharacteristics)
                        _StatPreviewCircle(
                          label: d.name,
                          value: state.allCharacteristicsRolled
                              ? _derivedValue(state, d.key)
                              : null,
                          isAuto: true,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: QBSpace.s4),
            QBCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Compétences',
                    style: QBType.game().copyWith(
                      fontWeight: QBType.weightSemibold,
                      fontSize: 15,
                      color: QBColors.leather800,
                    ),
                  ),
                  const SizedBox(height: QBSpace.s2),
                  QBBadge(
                    label: '${state.skillPointsRemaining} restants',
                    tone: QBTone.info,
                  ),
                  const SizedBox(height: QBSpace.s3),
                  Text(
                    'Répartis tes ${state.skillPointsTotal} points de '
                    'compétence au-dessus de la valeur de base.',
                    style: QBType.body().copyWith(
                      fontSize: QBType.xs,
                      color: QBColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: QBSpace.s3),
                  for (final skill in sheet.skills)
                    _SkillAllocationRow(skill: skill),
                ],
              ),
            ),
            const SizedBox(height: QBSpace.s4),
            QBButton(
              label: 'Créer mon personnage',
              variant: QBButtonVariant.primary,
              expand: true,
              onPressed: state.isSubmitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }

  int _derivedValue(CharacterCreationState state, String key) {
    // Recomputed on the fly for display only; submit() does the real
    // computation via the rules engine.
    final rules = ref.read(characterCreationProvider.notifier);
    return rules
        .previewDerived(state.resolvedCharacteristics)[key] ??
        0;
  }
}

class _StatPreviewCircle extends StatelessWidget {
  const _StatPreviewCircle({
    required this.label,
    required this.value,
    this.onTap,
    this.isAuto = false,
  });

  final String label;
  final int? value;
  final VoidCallback? onTap;
  final bool isAuto;

  @override
  Widget build(BuildContext context) {
    final pending = value == null && !isAuto;

    final Widget circle = Container(
      width: 64,
      height: 64,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isAuto
              ? const Color(0x40241A12)
              : (pending ? QBColors.juicyGoldBottom : const Color(0x66000000)),
          width: 3,
        ),
        gradient: isAuto
            ? null
            : RadialGradient(
                center: const Alignment(-0.36, -0.44),
                colors: pending
                    ? [
                        const Color(0x80FFF6DF),
                        QBColors.gemTopaz.withValues(alpha: 0.4),
                        QBColors.juicyGoldBottom.withValues(alpha: 0.33),
                      ]
                    : const [Color(0xFFFFF6DF), QBColors.gemTopaz, QBColors.juicyGoldBottom],
                stops: const [0, 0.45, 1],
              ),
        color: isAuto ? QBColors.surfaceSunken : null,
        boxShadow: pending || isAuto
            ? null
            : const [BoxShadow(color: Color(0x59000000), offset: Offset(0, 3))],
      ),
      child: Text(
        value?.toString() ?? '+',
        style: QBType.game().copyWith(
          fontWeight: QBType.weightBold,
          fontSize: pending ? 24 : 19,
          color: isAuto ? QBColors.ink500 : QBColors.ink900,
        ),
      ),
    );

    return SizedBox(
      width: 78,
      child: Column(
        children: [
          GestureDetector(onTap: onTap, child: circle),
          const SizedBox(height: QBSpace.s2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: QBType.game().copyWith(
              fontSize: 12,
              fontWeight: QBType.weightSemibold,
              color: QBColors.leather800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillAllocationRow extends ConsumerWidget {
  const _SkillAllocationRow({required this.skill});

  final SkillConfig skill;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(characterCreationProvider);
    final notifier = ref.read(characterCreationProvider.notifier);
    final value = state.valueFor(skill);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: QBColors.borderHairline)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  skill.name,
                  style: QBType.body()
                      .copyWith(fontSize: QBType.sm, color: QBColors.ink900),
                ),
                Text(
                  'base ${skill.baseDisplay}',
                  style: QBType.mono()
                      .copyWith(fontSize: 10, color: QBColors.textMuted),
                ),
              ],
            ),
          ),
          _StepperButton(
            label: '−',
            onTap: () => notifier.decrementSkill(skill.key),
          ),
          SizedBox(
            width: 38,
            child: Text(
              '$value%',
              textAlign: TextAlign.center,
              style: QBType.mono().copyWith(
                fontWeight: QBType.weightBold,
                fontSize: 14,
                color: QBColors.ink900,
              ),
            ),
          ),
          _StepperButton(
            label: '+',
            filled: true,
            onTap: () => notifier.incrementSkill(skill.key),
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(QBRadius.sm),
          gradient: filled
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [QBColors.juicyGoldTop, QBColors.juicyGoldBottom],
                )
              : null,
          color: filled ? null : QBColors.surfaceSunken,
          border: Border.all(
            color: filled ? const Color(0x59000000) : QBColors.borderStrong,
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: QBType.game().copyWith(
            fontWeight: QBType.weightBold,
            fontSize: 13,
            color: QBColors.ink900,
          ),
        ),
      ),
    );
  }
}
