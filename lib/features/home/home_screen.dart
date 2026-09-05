import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../design_system/components/qb_badge.dart';
import '../../design_system/components/qb_card.dart';
import '../../design_system/components/qb_page_background.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/spacing.dart';
import '../../design_system/tokens/typography.dart';
import '../../domain/models/character.dart';
import '../../domain/models/tone.dart';
import '../auth/widgets/account_bar.dart';
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
              'Mes personnages',
              style: QBType.game().copyWith(
                fontWeight: QBType.weightBold,
                fontSize: 22,
                color: QBColors.ink900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Reprends ton aventure ou commence une nouvelle légende.',
              style: QBType.body().copyWith(
                fontSize: QBType.sm,
                color: QBColors.textMuted,
              ),
            ),
            const SizedBox(height: 14),
            const AccountBar(),
            const SizedBox(height: 14),
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

class _CharacterList extends StatelessWidget {
  const _CharacterList({required this.characters});

  final List<Character> characters;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (characters.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Aucun personnage pour l’instant. Et si tu commençais '
              'une nouvelle légende ?',
              style: QBType.body().copyWith(
                fontSize: QBType.base,
                color: QBColors.textMuted,
              ),
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
                          const SizedBox(height: 2),
                          Text(
                            _roleLine(character),
                            style: QBType.body().copyWith(
                              fontSize: QBType.xs,
                              color: QBColors.textMuted,
                            ),
                          ),
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
              '+ Nouvelle légende',
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

  String _roleLine(Character character) {
    final occupation = character.occupation;
    final level = 'niveau ${character.level}';
    return occupation == null ? level : '$occupation — $level';
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
