import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/remote_providers.dart';
import '../../../data/remote/api_exception.dart';
import '../../../data/remote/remote_character.dart';
import '../../../data/remote/remote_table.dart';
import '../../../design_system/components/qb_badge.dart';
import '../../../design_system/components/qb_card.dart';
import '../../../design_system/components/qb_icon_button.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';
import '../../tables/providers/table_providers.dart';
import '../../tables/widgets/attendee_character_sheet.dart';
import '../providers/game_master_providers.dart';
import '../widgets/npc_dialog.dart';

/// Qui sera là ce soir : les fiches des joueurs attendus, puis tout le reste
/// de la distribution — créatures, indicateurs, esprits.
///
/// Les fiches des joueurs viennent de l'API une par une : c'est la présence du
/// joueur à la session qui autorise le MJ à les lire, et il n'existe pas
/// d'appel qui les rendrait toutes d'un coup. Sans réseau, la liste reste donc
/// vide.
class CharactersPanel extends ConsumerWidget {
  const CharactersPanel({super.key, required this.session});

  final RemoteGameSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        const SizedBox(height: 2),
        if (attending.isNotEmpty)
          Text(
            'Touche une fiche pour la déplier en entier.',
            style: QBType.body().copyWith(
              fontSize: QBType.xs,
              color: QBColors.textMuted,
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
        const SizedBox(height: QBSpace.s6),
        _NpcSection(sessionId: session.id),
      ],
    );
  }
}

/// Tout ce qui est à la table sans être un joueur. Rangé sous les fiches et
/// non dans un volet à part : le MJ y cherche la même chose — qui est là, et
/// ce qu'il sait de lui.
class _NpcSection extends ConsumerWidget {
  const _NpcSection({required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final npcs = ref.watch(sessionNpcsProvider(sessionId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Personnages non-joueurs',
                style: QBType.game().copyWith(
                  fontWeight: QBType.weightBold,
                  fontSize: 16,
                  letterSpacing: 16 * QBType.trackingWide,
                  color: QBColors.ink900,
                ),
              ),
            ),
            QBIconButton(
              icon: const Icon(LucideIcons.plus, size: 18),
              label: 'Ajouter un personnage non-joueur',
              size: 36,
              onPressed: () => showNpcDialog(context, sessionId: sessionId),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          'Créatures, indicateurs, esprits. Tes joueurs ne les voient pas.',
          style: QBType.body().copyWith(
            fontSize: QBType.xs,
            color: QBColors.textMuted,
          ),
        ),
        switch (npcs) {
          AsyncData(value: final list) when list.isEmpty => Padding(
              padding: const EdgeInsets.only(top: QBSpace.s3),
              child: Text(
                'Rien pour l’instant. Note ici ce que tes joueurs vont '
                'rencontrer.',
                style: QBType.body().copyWith(
                  fontSize: QBType.sm,
                  color: QBColors.textMuted,
                ),
              ),
            ),
          AsyncData(value: final list) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final npc in list) ...[
                  const SizedBox(height: QBSpace.s3),
                  _NpcCard(sessionId: sessionId, npc: npc),
                ],
              ],
            ),
          AsyncError(error: final error) => Padding(
              padding: const EdgeInsets.only(top: QBSpace.s3),
              child: Text(
                error is ApiException
                    ? error.message
                    : 'Impossible de charger les personnages non-joueurs.',
                style: QBType.body().copyWith(
                  fontSize: QBType.sm,
                  color: QBColors.semanticDanger,
                ),
              ),
            ),
          _ => const Padding(
              padding: EdgeInsets.all(QBSpace.s4),
              child: Center(child: CircularProgressIndicator()),
            ),
        },
      ],
    );
  }
}

class _NpcCard extends ConsumerWidget {
  const _NpcCard({required this.sessionId, required this.npc});

  final String sessionId;
  final RemoteNpc npc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Semantics(
      container: true,
      button: true,
      label: 'Modifier ${npc.name}',
      child: GestureDetector(
        onTap: () => showNpcDialog(context, sessionId: sessionId, existing: npc),
        behavior: HitTestBehavior.opaque,
        child: QBCard(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      npc.name,
                      style: QBType.game().copyWith(
                        fontWeight: QBType.weightSemibold,
                        fontSize: 15,
                        color: QBColors.ink900,
                      ),
                    ),
                    if (npc.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        npc.description,
                        style: QBType.body().copyWith(
                          fontSize: QBType.xs,
                          color: QBColors.ink700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: QBSpace.s2),
              QBIconButton(
                icon: const Icon(LucideIcons.trash2, size: 16),
                label: 'Retirer ${npc.name}',
                size: 36,
                onPressed: () => _confirmRemoval(context, ref),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmRemoval(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Retirer ${npc.name} ?'),
        content: const Text('Sa description sera perdue.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Non'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(sessionApiProvider).deleteNpc(sessionId, npc.id);
      ref.invalidate(sessionNpcsProvider(sessionId));
    } on ApiException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    }
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

    // Le résumé tient en une carte, mais le MJ a parfois besoin de tout :
    // caractéristiques, compétences, inventaire. C'est la même fiche que
    // celle ouverte depuis la table, en lecture seule.
    final open = sheet.hasValue
        ? () => showAttendeeCharacterSheet(
              context,
              sessionId: sessionId,
              userId: attendance.userId,
              playerLabel: attendance.user.label,
            )
        : null;

    return Semantics(
      button: open != null,
      label: open == null ? null : 'Ouvrir la fiche de ${sheet.value!.name}',
      child: GestureDetector(
        onTap: open,
        behavior: HitTestBehavior.opaque,
        child: QBCard(
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
        ),
      ),
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
            const SizedBox(width: QBSpace.s2),
            const Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: QBColors.leather800,
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
