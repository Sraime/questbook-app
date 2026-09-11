import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/remote/api_exception.dart';
import '../../../data/remote/remote_character.dart';
import '../../../design_system/components/qb_badge.dart';
import '../../../design_system/components/qb_card.dart';
import '../../../design_system/components/qb_stat_dial.dart';
import '../../../design_system/components/qb_stat_grid.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';
import '../providers/table_providers.dart';

/// The sheet of another player at the same session, in read-only form. It is
/// their character: nothing here writes, and there is deliberately no dice
/// roller or resource editor.
Future<void> showAttendeeCharacterSheet(
  BuildContext context, {
  required String sessionId,
  required String userId,
  required String playerLabel,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AttendeeSheet(
      sessionId: sessionId,
      userId: userId,
      playerLabel: playerLabel,
    ),
  );
}

class _AttendeeSheet extends ConsumerWidget {
  const _AttendeeSheet({
    required this.sessionId,
    required this.userId,
    required this.playerLabel,
  });

  final String sessionId;
  final String userId;
  final String playerLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final character = ref.watch(
      attendeeCharacterProvider(
        AttendeeCharacterRef(sessionId: sessionId, userId: userId),
      ),
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, controller) => Container(
        decoration: const BoxDecoration(
          color: QBColors.paper100,
          borderRadius: BorderRadius.vertical(top: Radius.circular(QBRadius.lg)),
        ),
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
        child: switch (character) {
          AsyncData(value: final sheet) =>
            _Sheet(sheet: sheet, playerLabel: playerLabel, controller: controller),
          AsyncError(error: final error) => _Unavailable(error: error),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

class _Sheet extends StatelessWidget {
  const _Sheet({
    required this.sheet,
    required this.playerLabel,
    required this.controller,
  });

  final RemoteCharacter sheet;
  final String playerLabel;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    final characteristics =
        sheet.stats.where((stat) => stat.kind == 'characteristic').toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final skills = sheet.stats.where((stat) => stat.kind == 'skill').toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return ListView(
      controller: controller,
      children: [
        Center(
          child: Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: QBColors.borderHairline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: QBSpace.s4),
        Text(
          sheet.name,
          style: QBType.game().copyWith(
            fontWeight: QBType.weightBold,
            fontSize: 20,
            color: QBColors.ink900,
          ),
        ),
        Text(
          sheet.occupation == null || sheet.occupation!.isEmpty
              ? 'Joué par $playerLabel'
              : '${sheet.occupation} · joué par $playerLabel',
          style: QBType.body().copyWith(
            fontSize: QBType.sm,
            color: QBColors.textMuted,
          ),
        ),
        if (sheet.resources.isNotEmpty) ...[
          const SizedBox(height: QBSpace.s3),
          Wrap(
            spacing: QBSpace.s2,
            runSpacing: QBSpace.s2,
            children: [
              for (final resource in sheet.resources)
                QBBadge(
                  label: '${resource.label} ${resource.current}/${resource.max}',
                  tone: _toneOf(resource.tone),
                ),
            ],
          ),
        ],
        if (characteristics.isNotEmpty) ...[
          const SizedBox(height: QBSpace.s5),
          _SectionLabel('Caractéristiques'),
          QBStatGrid(
            children: [
              for (final stat in characteristics)
                QBStatDial(label: stat.key, value: stat.value),
            ],
          ),
        ],
        if (skills.isNotEmpty) ...[
          const SizedBox(height: QBSpace.s5),
          _SectionLabel('Compétences'),
          QBCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < skills.length; i++)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                    decoration: BoxDecoration(
                      border: i < skills.length - 1
                          ? const Border(
                              bottom: BorderSide(color: QBColors.borderHairline),
                            )
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          skills[i].label,
                          style: QBType.body().copyWith(
                            fontSize: QBType.sm,
                            color: QBColors.ink900,
                          ),
                        ),
                        Text(
                          '${skills[i].value}%',
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
        ],
        if (sheet.inventory.isNotEmpty) ...[
          const SizedBox(height: QBSpace.s5),
          _SectionLabel('Inventaire'),
          for (final item in sheet.inventory)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                item.qty > 1 ? '${item.name} ×${item.qty}' : item.name,
                style: QBType.body().copyWith(
                  fontSize: QBType.sm,
                  color: QBColors.textBody,
                ),
              ),
            ),
        ],
      ],
    );
  }

  QBTone _toneOf(String tone) => switch (tone) {
        'danger' => QBTone.danger,
        'success' => QBTone.success,
        'warning' => QBTone.warning,
        'info' => QBTone.info,
        _ => QBTone.neutral,
      };
}

class _Unavailable extends StatelessWidget {
  const _Unavailable({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final api = error is ApiException ? error as ApiException : null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Text(
          api != null && api.isMissing
              ? 'Cette fiche n’est plus consultable. Le joueur a peut-être '
                  'changé de personnage.'
              : api?.message ?? 'Impossible de charger la fiche.',
          textAlign: TextAlign.center,
          style: QBType.body().copyWith(
            fontSize: QBType.sm,
            color: QBColors.textMuted,
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: QBType.game().copyWith(
          fontWeight: QBType.weightSemibold,
          fontSize: 13,
          letterSpacing: 13 * QBType.trackingWide,
          color: QBColors.leather800,
        ),
      ),
    );
  }
}
