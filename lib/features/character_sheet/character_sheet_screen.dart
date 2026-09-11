import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../design_system/components/qb_badge.dart';
import '../../design_system/components/qb_button.dart';
import '../../design_system/components/qb_card.dart';
import '../../design_system/components/qb_icon_button.dart';
import '../../design_system/components/qb_input.dart';
import '../../design_system/components/qb_inventory_row.dart';
import '../../design_system/components/qb_page_background.dart';
import '../../design_system/components/qb_stat_dial.dart';
import '../../design_system/components/qb_stat_grid.dart';
import '../../design_system/components/qb_tabs.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/spacing.dart';
import '../../design_system/tokens/typography.dart';
import '../../app/providers.dart';
import '../../app/remote_providers.dart';
import '../../domain/models/character.dart';
import '../../domain/models/creation_mode_config.dart';
import '../../domain/models/tone.dart';
import 'providers/character_detail_provider.dart';
import 'widgets/resource_edit_dialog.dart';
import 'widgets/skill_roll_dialog.dart';

/// Screens 1c (Aperçu) / 1d (Inventaire) — a single sheet screen, tabs
/// toggled in-page, matching the mockup.
class CharacterSheetScreen extends ConsumerStatefulWidget {
  const CharacterSheetScreen({super.key, required this.characterId});

  final String characterId;

  @override
  ConsumerState<CharacterSheetScreen> createState() =>
      _CharacterSheetScreenState();
}

class _CharacterSheetScreenState extends ConsumerState<CharacterSheetScreen> {
  String _tab = 'Aperçu';

  @override
  Widget build(BuildContext context) {
    final characterAsync =
        ref.watch(characterDetailProvider(widget.characterId));

    return QBPageBackground(
      child: SafeArea(
        bottom: false,
        child: characterAsync.when(
          data: (character) {
            if (character == null) {
              return const Center(child: Text('Personnage introuvable'));
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(18, 24, 18, 90),
              children: [
                _Header(character: character),
                const SizedBox(height: QBSpace.s4),
                QBTabs(
                  tabs: const ['Aperçu', 'Inventaire'],
                  active: _tab,
                  onChanged: (tab) => setState(() => _tab = tab),
                ),
                const SizedBox(height: QBSpace.s5),
                if (_tab == 'Aperçu')
                  _OverviewTab(character: character)
                else
                  _InventoryTab(character: character),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Erreur : $error')),
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.character});

  final Character character;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canWrite = ref.watch(canWriteProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          character.name,
          style: QBType.game().copyWith(
            fontWeight: QBType.weightBold,
            fontSize: 22,
            color: QBColors.ink900,
          ),
        ),
        if (character.occupation case final occupation?)
          Text(
            occupation,
            style: QBType.body().copyWith(
              fontSize: QBType.sm,
              color: QBColors.textMuted,
            ),
          ),
        const SizedBox(height: QBSpace.s3),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Wrap(
                spacing: QBSpace.s2,
                runSpacing: QBSpace.s2,
                children: [
                  for (final resource in character.resources)
                    GestureDetector(
                      onTap: canWrite
                          ? () => ResourceEditDialog.show(
                                context,
                                characterId: character.id,
                                resourceKey: resource.key,
                                title: _resourceTitle(resource.key),
                              )
                          : null,
                      child: QBBadge(
                        label: '${resource.label} ${resource.current}/${resource.max}',
                        tone: _mapTone(resource.tone),
                      ),
                    ),
                ],
              ),
            ),
            QBIconButton(
              icon: const Icon(LucideIcons.share2, size: 16, color: QBColors.ink700),
              label: 'Partager la fiche',
              size: 36,
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bientôt disponible')),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _resourceTitle(String key) => switch (key) {
        'PV' => 'Points de vie',
        'SAN' => 'Santé mentale',
        'PM' => 'Points de magie',
        _ => key,
      };

  QBTone _mapTone(Tone tone) => switch (tone) {
        Tone.neutral => QBTone.neutral,
        Tone.danger => QBTone.danger,
        Tone.success => QBTone.success,
        Tone.warning => QBTone.warning,
        Tone.info => QBTone.info,
      };
}

class _OverviewTab extends ConsumerWidget {
  const _OverviewTab({required this.character});

  final Character character;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Looked up by the character's own `systemId` (not the creation flow's
    // current selection) so a sheet keeps rendering correctly under its
    // original ruleset even after the player picks a different one.
    final config = ref.watch(creationModeByIdProvider(character.systemId));
    final globalAttributes = {
      for (final a in config?.characterSheet.globalAttributes ?? const [])
        a.key: a,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Caractéristiques'),
        // Four equal-width columns spanning the card: each dial is
        // centered in its cell, so the grid itself is centered and a
        // short last row stays aligned to the same columns (instead of
        // drifting as a separately-centered Wrap run).
        QBStatGrid(
          children: [
            // `stat.key` is already the short code (FOR, DEX…) — more
            // readable than the full name in this small circular dial.
            for (final stat in character.characteristics)
              QBStatDial(label: stat.key, value: stat.value),
          ],
        ),
        if (character.attributes.isNotEmpty) ...[
          const SizedBox(height: QBSpace.s3),
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: QBSpace.s2,
              runSpacing: QBSpace.s2,
              children: [
                // Global attributes (e.g. age, Fortune) aren't game-mechanical
                // characteristics, so they're shown as plain text badges
                // rather than dials — a choice attribute's stored value is
                // an option index (mapped back to its label here), an
                // integer attribute's is the raw number.
                for (final stat in character.attributes)
                  QBBadge(
                    label: '${stat.label} : ${_attributeValueLabel(globalAttributes[stat.key], stat.value)}',
                    tone: QBTone.neutral,
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: QBSpace.s4),
        _sectionTitle('Compétences'),
        QBCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < character.skills.length; i++)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  decoration: BoxDecoration(
                    border: i < character.skills.length - 1
                        ? const Border(bottom: BorderSide(color: QBColors.borderHairline))
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        character.skills[i].label,
                        style: QBType.body()
                            .copyWith(fontSize: QBType.sm, color: QBColors.ink900),
                      ),
                      Text(
                        '${character.skills[i].value}%',
                        style: QBType.mono().copyWith(
                          fontWeight: QBType.weightBold,
                          fontSize: QBType.sm,
                          color: QBColors.ink900,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: QBSpace.s4),
        QBButton(
          label: 'Lancer un dé',
          variant: QBButtonVariant.primary,
          expand: true,
          onPressed: character.skills.isEmpty
              ? null
              : () => SkillRollDialog.show(context, character),
        ),
      ],
    );
  }

  /// For a [GlobalAttributeType.choice] attribute, maps the stored option
  /// index back to its label; for an integer attribute (or if [attribute]
  /// is unknown — config missing/outdated), just shows the raw value.
  String _attributeValueLabel(GlobalAttributeConfig? attribute, int value) {
    if (attribute == null || attribute.type != GlobalAttributeType.choice) {
      return '$value';
    }
    final choices = attribute.choices;
    if (choices.isEmpty) return '$value';
    return choices[value.clamp(0, choices.length - 1)];
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          title,
          style: QBType.game().copyWith(
            fontWeight: QBType.weightSemibold,
            fontSize: 13,
            letterSpacing: 13 * QBType.trackingWide,
            color: QBColors.leather800,
          ),
        ),
      );
}

class _InventoryTab extends ConsumerStatefulWidget {
  const _InventoryTab({required this.character});

  final Character character;

  @override
  ConsumerState<_InventoryTab> createState() => _InventoryTabState();
}

class _InventoryTabState extends ConsumerState<_InventoryTab> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addItem() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    ref
        .read(characterActionsProvider)
        .addInventoryItem(widget.character.id, name: name);
    _nameController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final inventory = widget.character.inventory;
    final canWrite = ref.watch(canWriteProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
          decoration: BoxDecoration(
            color: QBColors.leather900,
            border: Border.all(color: QBColors.slotBorder, width: 3),
            borderRadius: BorderRadius.circular(QBRadius.lg),
          ),
          child: inventory.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Text(
                    'Aucun objet pour l’instant.',
                    style: QBType.body().copyWith(color: QBColors.paper300),
                  ),
                )
              : Column(
                  children: [
                    for (final item in inventory)
                      QBInventoryRow(
                        name: item.name,
                        qty: item.qty,
                        weight: item.weight,
                        onRemove: canWrite
                            ? () => ref
                                .read(characterActionsProvider)
                                .removeInventoryItem(item.id)
                            : null,
                      ),
                  ],
                ),
        ),
        if (canWrite) ...[
          const SizedBox(height: QBSpace.s3),
          QBInput(controller: _nameController, placeholder: 'Ajouter un objet…'),
          const SizedBox(height: QBSpace.s2),
          QBButton(
            label: 'Ajouter',
            variant: QBButtonVariant.secondary,
            expand: true,
            onPressed: _addItem,
          ),
        ],
      ],
    );
  }
}
