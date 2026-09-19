import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/remote/api_exception.dart';
import '../../../data/remote/remote_character.dart';
import '../../../data/remote/remote_table.dart';
import '../../../design_system/components/qb_badge.dart';
import '../../../design_system/components/qb_card.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';
import '../../tables/providers/table_providers.dart';

/// Les fiches des joueurs attendus, dépliées les unes sous les autres.
///
/// Elles viennent de l'API une par une : c'est la présence du joueur à la
/// session qui autorise le MJ à les lire, et il n'existe pas d'appel qui les
/// rendrait toutes d'un coup. Sans réseau, la liste reste donc vide.
class CharactersPanel extends StatelessWidget {
  const CharactersPanel({super.key, required this.session});

  final RemoteGameSession session;

  @override
  Widget build(BuildContext context) {
    final attending = session.accepted
        .where((attendance) => attendance.character != null)
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        QBSpace.s6,
        QBSpace.s5,
        QBSpace.s6,
        QBSpace.s8,
      ),
      children: [
        Text(
          'Personnages joueurs',
          style: QBType.game().copyWith(
            fontWeight: QBType.weightBold,
            fontSize: 16,
            letterSpacing: 16 * QBType.trackingWide,
            color: QBColors.ink900,
          ),
        ),
        const SizedBox(height: QBSpace.s2),
        if (attending.isEmpty)
          Text(
            'Aucun joueur n’a encore rattaché de personnage à cette session. '
            'Les fiches apparaîtront ici dès qu’ils l’auront fait.',
            style: QBType.body().copyWith(
              fontSize: QBType.sm,
              color: QBColors.textMuted,
            ),
          )
        else
          for (final attendance in attending) ...[
            const SizedBox(height: QBSpace.s3),
            _AttendeeCard(sessionId: session.id, attendance: attendance),
          ],
      ],
    );
  }
}

class _AttendeeCard extends ConsumerWidget {
  const _AttendeeCard({required this.sessionId, required this.attendance});

  final String sessionId;
  final RemoteAttendance attendance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sheet = ref.watch(
      attendeeCharacterProvider(
        AttendeeCharacterRef(sessionId: sessionId, userId: attendance.userId),
      ),
    );

    return QBCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: switch (sheet) {
        AsyncData(value: final character) => _Sheet(
            character: character,
            playerLabel: attendance.user.label,
          ),
        AsyncError(error: final error) => _Unavailable(
            playerLabel: attendance.user.label,
            error: error,
          ),
        _ => const Center(
            child: Padding(
              padding: EdgeInsets.all(QBSpace.s4),
              child: CircularProgressIndicator(),
            ),
          ),
      },
    );
  }
}

class _Sheet extends StatelessWidget {
  const _Sheet({required this.character, required this.playerLabel});

  final RemoteCharacter character;
  final String playerLabel;

  @override
  Widget build(BuildContext context) {
    final skills = character.stats.where((stat) => stat.kind == 'skill').toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    character.name,
                    style: QBType.game().copyWith(
                      fontWeight: QBType.weightSemibold,
                      fontSize: 15,
                      color: QBColors.ink900,
                    ),
                  ),
                  Text(
                    character.occupation == null ||
                            character.occupation!.isEmpty
                        ? 'Joué par $playerLabel'
                        : '${character.occupation} · joué par $playerLabel',
                    style: QBType.body().copyWith(
                      fontSize: QBType.xs,
                      color: QBColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Wrap(
              spacing: QBSpace.s2,
              children: [
                for (final resource in character.resources)
                  QBBadge(
                    label:
                        '${resource.label} ${resource.current}/${resource.max}',
                    tone: _toneOf(resource.tone),
                  ),
              ],
            ),
          ],
        ),
        if (skills.isNotEmpty) ...[
          const SizedBox(height: QBSpace.s3),
          // Les meilleures compétences d'abord : pendant une partie, le MJ
          // cherche ce sur quoi le joueur peut réussir, pas la liste complète.
          Wrap(
            spacing: QBSpace.s2,
            runSpacing: 4,
            children: [
              for (final skill in skills.take(8))
                Text(
                  '${skill.label} ${skill.value}%',
                  style: QBType.body().copyWith(
                    fontSize: QBType.xs,
                    color: QBColors.ink700,
                  ),
                ),
            ],
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
  const _Unavailable({required this.playerLabel, required this.error});

  final String playerLabel;
  final Object error;

  @override
  Widget build(BuildContext context) {
    final api = error is ApiException ? error as ApiException : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          playerLabel,
          style: QBType.game().copyWith(
            fontWeight: QBType.weightSemibold,
            fontSize: 15,
            color: QBColors.ink900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          api != null && api.isMissing
              ? 'Cette fiche n’est plus consultable. Le joueur a peut-être '
                  'changé de personnage.'
              : api?.message ?? 'Impossible de charger la fiche.',
          style: QBType.body().copyWith(
            fontSize: QBType.xs,
            color: QBColors.semanticDanger,
          ),
        ),
      ],
    );
  }
}
