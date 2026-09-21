import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/remote_providers.dart';
import '../../design_system/components/qb_badge.dart';
import '../../design_system/components/qb_card.dart';
import '../../design_system/components/qb_page_background.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/spacing.dart';
import '../../design_system/tokens/typography.dart';
import '../../domain/models/character.dart';
import '../../domain/models/tone.dart';
import 'providers/character_list_provider.dart';

/// Screen 1a — Accueil.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final charactersAsync = ref.watch(characterListProvider);

    return QBPageBackground(
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 24, 18, 90),
          children: [
            Text(
              'Mes investigateurs',
              style: QBType.game().copyWith(
                fontWeight: QBType.weightBold,
                fontSize: 22,
                color: QBColors.ink900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Les personnages que tu joues dans tes aventures.',
              style: QBType.body().copyWith(
                fontSize: QBType.sm,
                color: QBColors.textMuted,
              ),
            ),
            const SizedBox(height: QBSpace.s5),
            charactersAsync.when(
              data: (characters) => _CharacterList(characters: characters),
              loading: () =>
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              error: (error, stack) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Text('Erreur : $error'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CharacterList extends ConsumerWidget {
  const _CharacterList({required this.characters});

  final List<Character> characters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canWrite = ref.watch(canWriteProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Pour beaucoup, c'est le premier écran de leur première partie : il
        // dit ce qu'est un investigateur plutôt que de constater qu'il n'y en
        // a pas. Le mot vient de l'univers, et personne ne le devine.
        if (characters.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tu n’as pas encore d’investigateur.',
                  style: QBType.body().copyWith(
                    fontSize: QBType.base,
                    fontWeight: QBType.weightSemibold,
                    color: QBColors.textBody,
                  ),
                ),
                const SizedBox(height: QBSpace.s2),
                Text(
                  'C’est le personnage que tu incarnes à la table : un nom, '
                  'un métier, ce qu’il sait faire — et une santé mentale qui '
                  's’effrite à mesure qu’il comprend ce qu’il n’aurait pas dû '
                  'voir. Le maître du jeu raconte l’histoire, ton '
                  'investigateur y enquête.',
                  style: QBType.body().copyWith(
                    fontSize: QBType.sm,
                    color: QBColors.textMuted,
                  ),
                ),
                const SizedBox(height: QBSpace.s2),
                Text(
                  'Crées-en un pour rejoindre une partie.',
                  style: QBType.body().copyWith(
                    fontSize: QBType.sm,
                    color: QBColors.textMuted,
                  ),
                ),
              ],
            ),
          )
        else
          for (final character in characters) ...[
            GestureDetector(
              onTap: () => context.go('/perso/${character.id}'),
              child: QBCard(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            character.name,
                            style: QBType.game().copyWith(
                              fontWeight: QBType.weightSemibold,
                              fontSize: 15,
                              color: QBColors.ink900,
                            ),
                          ),
                          if (character.occupation case final occupation?) ...[
                            const SizedBox(height: 2),
                            Text(
                              occupation,
                              style: QBType.body().copyWith(
                                fontSize: QBType.xs,
                                color: QBColors.textMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    _HpBadge(character: character),
                  ],
                ),
              ),
            ),
            const SizedBox(height: QBSpace.s4 - 2),
          ],
        // A character created without a network could not be attributed to
        // the account until the next sync, and the session it was meant for
        // would have started by then.
        if (canWrite)
          GestureDetector(
            onTap: () => context.go('/perso/create'),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                // Mockup uses a dashed border; Flutter has no built-in dashed
                // BoxBorder, so this uses a solid one at the same weight/color.
                border: Border.all(color: QBColors.borderStrong, width: 3),
                borderRadius: BorderRadius.circular(QBRadius.lg),
              ),
              alignment: Alignment.center,
              child: Text(
                '+ Nouvel investigateur',
                style: QBType.game().copyWith(
                  fontWeight: QBType.weightSemibold,
                  fontSize: 15,
                  color: QBColors.leather700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _HpBadge extends StatelessWidget {
  const _HpBadge({required this.character});

  final Character character;

  @override
  Widget build(BuildContext context) {
    final pv = character.resourceByKey('PV');
    if (pv == null) return const SizedBox.shrink();
    final ratio = pv.max == 0 ? 0.0 : pv.current / pv.max;
    final tone = ratio > 0.66
        ? Tone.success
        : ratio > 0.33
            ? Tone.warning
            : Tone.danger;
    return QBBadge(label: 'PV ${pv.current}/${pv.max}', tone: _mapTone(tone));
  }

  QBTone _mapTone(Tone tone) => switch (tone) {
        Tone.neutral => QBTone.neutral,
        Tone.danger => QBTone.danger,
        Tone.success => QBTone.success,
        Tone.warning => QBTone.warning,
        Tone.info => QBTone.info,
      };
}
