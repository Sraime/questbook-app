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
import '../../domain/models/creation_mode_config.dart';
import 'providers/character_creation_provider.dart';
import 'widgets/characteristic_choice_dialog.dart';
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
  final Map<String, TextEditingController> _attributeControllers = {};

  /// Lazily creates (and remembers) the text controller for an integer
  /// [GlobalAttributeConfig] (e.g. age) — cleared alongside the name/
  /// description controllers whenever the universe/creation mode changes.
  TextEditingController _attributeController(String key, int initialValue) {
    return _attributeControllers.putIfAbsent(
      key,
      () => TextEditingController(text: initialValue.toString()),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    for (final controller in _attributeControllers.values) {
      controller.dispose();
    }
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

  Future<void> _pickChoiceStat(String key, String label, List<String> choices) async {
    await CharacteristicChoiceDialog.show(
      context,
      characteristicKey: key,
      characteristicLabel: label,
      choices: choices,
    );
  }

  Future<void> _submit() async {
    final id = await ref.read(characterCreationProvider.notifier).submit();
    if (!mounted) return;
    context.go('/perso/$id');
  }

  @override
  Widget build(BuildContext context) {
    // Switching universe/creation mode resets the whole draft (see
    // `selectedCreationModeProvider`/`characterCreationProvider.build()`) —
    // the name/description fields are local `TextEditingController`s, so
    // they need clearing explicitly to stay in sync.
    ref.listen(selectedCreationModeIdProvider, (previous, next) {
      if (previous != null && previous != next) {
        _nameController.clear();
        _descriptionController.clear();
        for (final controller in _attributeControllers.values) {
          controller.dispose();
        }
        _attributeControllers.clear();
      }
    });

    final state = ref.watch(characterCreationProvider);
    final config = state.config;
    final sheet = config.characterSheet;
    final availableModes = ref.watch(availableCreationModesProvider);
    final modesForUniverse =
        availableModes.where((c) => c.universeName == config.universeName).toList();

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
              'Donne-lui vie en quelques mots, puis choisis son occupation.',
              style: QBType.body().copyWith(
                fontSize: QBType.sm,
                color: QBColors.textMuted,
              ),
            ),
            const SizedBox(height: QBSpace.s5),
            // Univers, nom, description puis mode de création, dans cet
            // ordre et dans une seule section : Univers/Mode de création
            // déterminent quelle config pilote tout le reste (occupations,
            // caractéristiques, compétences…), donc ils encadrent les deux
            // champs qui, eux, ne dépendent d'aucun univers.
            QBCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  QBSelect(
                    label: 'Univers',
                    value: config.universeName,
                    options: [
                      for (final name in {for (final c in availableModes) c.universeName})
                        name,
                    ],
                    onChanged: (name) {
                      if (name == null) return;
                      final firstForUniverse =
                          availableModes.firstWhere((c) => c.universeName == name);
                      ref
                          .read(selectedCreationModeIdProvider.notifier)
                          .select(firstForUniverse.id);
                    },
                  ),
                  const SizedBox(height: QBSpace.s4),
                  QBInput(
                    label: 'Nom du personnage',
                    controller: _nameController,
                    hint: 'Laisse vide pour un nom généré',
                    onChanged:
                        ref.read(characterCreationProvider.notifier).setName,
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
                  QBSelect(
                    label: 'Mode de création',
                    value: config.creationModeName,
                    options: [for (final c in modesForUniverse) c.creationModeName],
                    onChanged: (name) {
                      if (name == null) return;
                      final match = modesForUniverse
                          .firstWhere((c) => c.creationModeName == name);
                      ref.read(selectedCreationModeIdProvider.notifier).select(match.id);
                    },
                  ),
                  if (config.creationModeDescription case final description?) ...[
                    const SizedBox(height: QBSpace.s2),
                    Text(
                      description,
                      style: QBType.body().copyWith(
                        fontSize: QBType.xs,
                        color: QBColors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: QBSpace.s4),
            QBCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  QBSelect(
                    label: 'Occupation',
                    value: state.occupation,
                    options: [for (final o in sheet.occupations) o.name],
                    onChanged: ref
                        .read(characterCreationProvider.notifier)
                        .setOccupation,
                  ),
                  for (final a in sheet.globalAttributes) ...[
                    const SizedBox(height: QBSpace.s4),
                    if (a.type == GlobalAttributeType.choice)
                      QBSelect(
                        label: a.name,
                        value: state.globalAttributeChoiceLabel(a),
                        options: a.choices,
                        onChanged: (value) {
                          if (value == null) return;
                          ref
                              .read(characterCreationProvider.notifier)
                              .setGlobalAttributeValue(a.key, a.choices.indexOf(value));
                        },
                      )
                    else
                      QBInput(
                        label: a.name,
                        controller: _attributeController(
                          a.key,
                          state.globalAttributeValues[a.key] ?? 0,
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          ref
                              .read(characterCreationProvider.notifier)
                              .setGlobalAttributeValue(a.key, int.tryParse(value) ?? 0);
                        },
                      ),
                  ],
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
                          label: c.key,
                          value: state.characteristics[c.key],
                          onTap: () => _rollStat(c.key, c.name),
                        ),
                      // Some modes assign primary characteristics by
                      // picking from a fixed numeric list instead of
                      // rolling dice (e.g. a "point-buy" mode) — same
                      // tap-a-circle-to-open-a-popup style as a roll, just
                      // a value picker inside instead of dice.
                      for (final c in sheet.numericChoiceCharacteristics)
                        _StatPreviewCircle(
                          label: c.key,
                          value: state.resolvedCharacteristics[c.key],
                          onTap: () => _pickChoiceStat(c.key, c.name, c.choices),
                        ),
                      for (final d in sheet.derivedCharacteristics)
                        _StatPreviewCircle(
                          label: d.key,
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
            _SkillsCard(sheet: sheet),
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

/// Single "Compétences" card: the two point pools (occupation in gold,
/// personal in blue), the "skill of your choice" pickers if the selected
/// occupation offers any, then every skill with both bonus steppers and
/// its running total.
class _SkillsCard extends ConsumerWidget {
  const _SkillsCard({required this.sheet});

  final CharacterSheetConfig sheet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(characterCreationProvider);
    final notifier = ref.read(characterCreationProvider.notifier);
    final occupation = state.selectedOccupation;
    final hasOccupationPoints = occupation?.hasOccupationSkillPoints ?? false;

    return QBCard(
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
          Wrap(
            spacing: QBSpace.s2,
            runSpacing: QBSpace.s2,
            children: [
              if (hasOccupationPoints)
                QBBadge(
                  label: "${state.occupationSkillPointsRemaining} pts d'occupation",
                  tone: QBTone.warning,
                ),
              QBBadge(
                label: '${state.skillPointsRemaining} pts personnels',
                tone: QBTone.info,
              ),
            ],
          ),
          const SizedBox(height: QBSpace.s3),
          Text(
            hasOccupationPoints
                ? "Les points d'occupation de « ${occupation!.name} » (jaune) ne "
                    "s'appliquent qu'à ses compétences ; tes points personnels "
                    '(bleu) sur n\'importe laquelle.'
                : 'Répartis tes points de compétence personnels au-dessus de '
                    'la valeur de base.',
            style: QBType.body().copyWith(
              fontSize: QBType.xs,
              color: QBColors.textMuted,
            ),
          ),
          if (hasOccupationPoints && occupation!.occupationSkillChoices > 0) ...[
            const SizedBox(height: QBSpace.s3),
            for (var i = 0; i < occupation.occupationSkillChoices; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: QBSpace.s2),
                child: QBSelect(
                  label: "Compétence d'occupation bonus ${i + 1}",
                  value: _choiceSkillName(sheet, state, i),
                  options: [
                    for (final s in sheet.skills)
                      if (!_isExcludedFromChoice(occupation, state, i, s.key)) s.name,
                  ],
                  onChanged: (name) {
                    final skill = name == null
                        ? null
                        : sheet.skills.firstWhere((s) => s.name == name);
                    notifier.setOccupationSkillChoice(i, skill?.key);
                  },
                ),
              ),
          ],
          const SizedBox(height: QBSpace.s2),
          for (final skill in sheet.skills) _SkillRow(skill: skill),
        ],
      ),
    );
  }

  String? _choiceSkillName(
    CharacterSheetConfig sheet,
    CharacterCreationState state,
    int slotIndex,
  ) {
    if (slotIndex >= state.occupationSkillChoiceSelections.length) return null;
    final key = state.occupationSkillChoiceSelections[slotIndex];
    if (key == null) return null;
    return sheet.skills.firstWhere((s) => s.key == key).name;
  }

  bool _isExcludedFromChoice(
    OccupationConfig occupation,
    CharacterCreationState state,
    int slotIndex,
    String skillKey,
  ) {
    if (occupation.occupationSkills.contains(skillKey)) return true;
    for (var i = 0; i < state.occupationSkillChoiceSelections.length; i++) {
      if (i == slotIndex) continue;
      if (state.occupationSkillChoiceSelections[i] == skillKey) return true;
    }
    return false;
  }
}

class _SkillRow extends ConsumerWidget {
  const _SkillRow({required this.skill});

  final SkillConfig skill;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(characterCreationProvider);
    final notifier = ref.read(characterCreationProvider.notifier);

    final hasOccupationPoints = state.selectedOccupation?.hasOccupationSkillPoints ?? false;
    final eligibleForOccupation = state.occupationEligibleSkillKeys.contains(skill.key);
    final occAllocated = state.occupationSkillAllocated[skill.key] ?? 0;
    final persoAllocated = state.skillAllocated[skill.key] ?? 0;
    final total = state.valueFor(skill);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: QBColors.borderHairline)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
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
                  if (eligibleForOccupation) ...[
                    const SizedBox(height: 2),
                    Text(
                      "compétence d'occupation",
                      style: QBType.mono().copyWith(
                        fontSize: 9,
                        fontWeight: QBType.weightBold,
                        color: QBColors.juicyGoldBottom,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: QBSpace.s2),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (hasOccupationPoints) ...[
                _BonusStepper(
                  value: occAllocated,
                  gradientColors: const [QBColors.juicyGoldTop, QBColors.juicyGoldBottom],
                  onDecrement: eligibleForOccupation && occAllocated > 0
                      ? () => notifier.decrementOccupationSkill(skill.key)
                      : null,
                  onIncrement: eligibleForOccupation && state.occupationSkillPointsRemaining > 0
                      ? () => notifier.incrementOccupationSkill(skill.key)
                      : null,
                ),
                const SizedBox(height: 4),
              ],
              _BonusStepper(
                value: persoAllocated,
                gradientColors: const [QBColors.juicyBlueTop, QBColors.juicyBlueBottom],
                onDecrement:
                    persoAllocated > 0 ? () => notifier.decrementSkill(skill.key) : null,
                onIncrement: state.skillPointsRemaining > 0
                    ? () => notifier.incrementSkill(skill.key)
                    : null,
              ),
              const SizedBox(height: 6),
              Text(
                'Total $total%',
                style: QBType.mono().copyWith(
                  fontWeight: QBType.weightBold,
                  fontSize: 14,
                  color: QBColors.ink900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One −/value/+ line spending from a single pool (occupation or
/// personal), tinted with [gradientColors] to match that pool's badge.
class _BonusStepper extends StatelessWidget {
  const _BonusStepper({
    required this.value,
    required this.gradientColors,
    required this.onDecrement,
    required this.onIncrement,
  });

  final int value;
  final List<Color> gradientColors;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepperButton(label: '−', size: 22, onTap: onDecrement),
        SizedBox(
          width: 28,
          child: Text(
            '+$value',
            textAlign: TextAlign.center,
            style: QBType.mono().copyWith(
              fontWeight: QBType.weightBold,
              fontSize: 12,
              color: QBColors.ink900,
            ),
          ),
        ),
        _StepperButton(
          label: '+',
          filled: true,
          size: 22,
          gradientColors: gradientColors,
          onTap: onIncrement,
        ),
      ],
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.label,
    required this.onTap,
    this.filled = false,
    this.size = 26,
    this.gradientColors = const [QBColors.juicyGoldTop, QBColors.juicyGoldBottom],
  });

  final String label;
  final VoidCallback? onTap;
  final bool filled;
  final double size;
  final List<Color> gradientColors;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: enabled ? 1 : 0.35,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(QBRadius.sm),
            gradient: filled
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: gradientColors,
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
              fontSize: size >= 26 ? 13 : 11,
              color: QBColors.ink900,
            ),
          ),
        ),
      ),
    );
  }
}
