import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/remote_providers.dart';
import '../../../data/remote/api_exception.dart';
import '../../../data/remote/remote_character.dart';
import '../../../data/remote/remote_table.dart';
import '../../../design_system/components/qb_badge.dart';
import '../../../design_system/components/qb_button.dart';
import '../../../design_system/components/qb_card.dart';
import '../../../design_system/components/qb_icon_button.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';
import '../../character_sheet/widgets/own_character_sheet.dart';
import '../../tables/providers/table_providers.dart';
import '../../tables/widgets/attendee_character_sheet.dart';
import '../models/session_seat.dart';
import '../providers/game_master_providers.dart';
import '../widgets/npc_dialog.dart';
import '../../../design_system/components/qb_reader_dialog.dart';

/// Qui sera là ce soir : les fiches des joueurs attendus, puis — pour le MJ
/// seul — tout le reste de la distribution : créatures, indicateurs, esprits.
///
/// Les fiches des joueurs viennent de l'API une par une : c'est la présence à
/// la session qui autorise à les lire, et il n'existe pas d'appel qui les
/// rendrait toutes d'un coup. Sans réseau, la liste reste donc vide.
class CharactersPanel extends ConsumerWidget {
  const CharactersPanel({
    super.key,
    required this.session,
    this.seat = SessionSeat.gameMaster,
    this.compact = false,
  });

  final RemoteGameSession session;

  /// Le volet sert aux deux rôles, mais pas au même titre : le joueur y
  /// retrouve ses camarades de table, le MJ y ajoute en plus ce qu'ils vont
  /// rencontrer.
  final SessionSeat seat;

  /// Sur un écran étroit, le bouton d'ajout ne tient pas à côté du titre de sa
  /// section : il passe dessous.
  final bool compact;

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
          'Investigateurs',
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
            'Aucun joueur n’a encore rattaché d’investigateur à cette '
            'session. Les fiches apparaîtront ici dès qu’ils l’auront fait.',
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
        // Les PNJ sont la préparation du MJ — « tes joueurs ne les voient
        // pas » est écrit dans la section elle-même. Un joueur s'arrête donc
        // aux investigateurs, et le filet qui les sépare avec.
        if (seat.isGameMaster) ...[
          // Les investigateurs et les PNJ se suivent : sans filet, la seconde
          // liste se lit comme la suite de la première.
          const SizedBox(height: QBSpace.s5),
          Container(height: 1, color: QBColors.borderHairline),
          const SizedBox(height: QBSpace.s5),
          _NpcSection(sessionId: session.id, compact: compact),
        ],
      ],
    );
  }
}

/// Tout ce qui est à la table sans être un joueur. Rangé sous les fiches et
/// non dans un volet à part : le MJ y cherche la même chose — qui est là, et
/// ce qu'il sait de lui.
class _NpcSection extends ConsumerWidget {
  const _NpcSection({required this.sessionId, required this.compact});

  final String sessionId;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final npcs = ref.watch(sessionNpcsProvider(sessionId));

    // Le titre entier ne laisse pas la place d'un bouton sur un téléphone :
    // il tient déjà presque toute la largeur à lui seul. L'abréviation, elle,
    // laisse la ligne respirer, et le sous-titre juste en dessous dit en
    // toutes lettres de quoi il s'agit.
    final title = Text(
      compact ? 'PNJ' : 'Personnages non-joueurs',
      style: QBType.game().copyWith(
        fontWeight: QBType.weightBold,
        fontSize: 16,
        letterSpacing: 16 * QBType.trackingWide,
        color: QBColors.ink900,
      ),
    );

    // Libellé et non icône seule, comme « + Inviter » sur l'écran d'une
    // table : c'est le même geste, il a la même forme. Il se raccourcit avec
    // le titre — sous un titre « PNJ », « + Ajouter » ne laisse aucun doute.
    final add = QBButton(
      label: compact ? '+ Ajouter' : '+ Ajouter un PNJ',
      size: QBButtonSize.sm,
      onPressed: () => showNpcDialog(context, sessionId: sessionId),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [Expanded(child: title), add]),
        // Le sous-titre se colle au titre, sauf quand le bouton lui passe
        // au-dessus : l'ombre portée descend de 8 points et déborde de 14 de
        // plus, elle salirait la ligne juste en dessous.
        SizedBox(height: compact ? QBSpace.s4 : 2),
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
    // Un PNJ livré par l'aventure s'ouvre en lecture : le MJ le joue, il ne
    // le réécrit pas. Et sa description y tient en entier, là où la carte n'en
    // montre que les premières lignes.
    final fromScenario = !npc.isEditable;

    return Semantics(
      container: true,
      button: true,
      label: fromScenario ? 'Lire ${npc.name}' : 'Modifier ${npc.name}',
      child: GestureDetector(
        onTap: () => fromScenario
            ? showQBReaderDialog(
                context,
                title: npc.name,
                contentMarkdown: npc.description,
              )
            : showNpcDialog(context, sessionId: sessionId, existing: npc),
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
                        maxLines: fromScenario ? 3 : null,
                        overflow: fromScenario ? TextOverflow.ellipsis : null,
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
              // Sans ces deux mots, l'absence de corbeille ressemblerait à une
              // panne. Avec eux, elle se lit comme une règle.
              if (fromScenario)
                Text(
                  'du scénario',
                  style: QBType.body().copyWith(
                    fontSize: QBType.xs,
                    color: QBColors.textMuted,
                    fontStyle: FontStyle.italic,
                  ),
                )
              else
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
    final reference =
        AttendeeCharacterRef(sessionId: sessionId, userId: attendance.userId);
    final sheet = ref.watch(attendeeCharacterProvider(reference));

    // Une partie fait perdre des points de vie et ramasser des objets : sa
    // propre fiche s'ouvre donc modifiable, la même que sous `/perso/:id`.
    // Celle d'un camarade reste en lecture seule — c'est son investigateur,
    // et le MJ n'y touche pas davantage.
    final mine =
        ref.watch(authControllerProvider).value?.id == attendance.userId;

    final open = !sheet.hasValue
        ? null
        : mine
            ? () => _editMine(context, ref, reference)
            : () => showAttendeeCharacterSheet(
                  context,
                  sessionId: sessionId,
                  userId: attendance.userId,
                  playerLabel: attendance.user.label,
                );

    return Semantics(
      button: open != null,
      label: open == null
          ? null
          : mine
              ? 'Modifier la fiche de ${sheet.value!.name}'
              : 'Ouvrir la fiche de ${sheet.value!.name}',
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

  /// La carte, elle, vient du serveur : après une modification faite en
  /// local, elle porterait encore les anciennes valeurs. On la relit donc en
  /// refermant la feuille, ce que #114 rend immédiat — la fiche est déjà
  /// partie au moment où l'on rouvre les yeux dessus.
  Future<void> _editMine(
    BuildContext context,
    WidgetRef ref,
    AttendeeCharacterRef reference,
  ) async {
    final characterId = attendance.character?.id;
    if (characterId == null) return;

    await showOwnCharacterSheet(context, characterId: characterId);
    ref.invalidate(attendeeCharacterProvider(reference));
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
            const SizedBox(width: QBSpace.s2),
            const Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: QBColors.leather800,
            ),
          ],
        ),
        // Sous l'identité et non à côté, comme sur la fiche que le joueur
        // ouvre depuis l'accueil. Trois jauges tiennent la largeur d'un
        // téléphone à elles seules : en haut de la même ligne, elles ne
        // laissaient au nom qu'une colonne d'une lettre de large, et
        // débordaient quand même.
        if (character.resources.isNotEmpty) ...[
          const SizedBox(height: QBSpace.s3),
          Wrap(
            spacing: QBSpace.s2,
            runSpacing: QBSpace.s2,
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
                  'changé d’investigateur.'
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
