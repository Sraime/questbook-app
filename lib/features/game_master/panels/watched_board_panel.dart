import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../data/remote/api_exception.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/effects.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';
import '../models/board_catalog.dart';
import '../models/board_token.dart';
import '../providers/game_master_providers.dart';
import '../widgets/board_surface.dart';
import '../widgets/board_token_view.dart';

/// Le plateau tel que le MJ le dispose, pour un joueur assis à la table.
///
/// **En lecture seule, et pas seulement désactivé.** Aucun geste n'est câblé :
/// ni tiroir, ni glisser, ni poignées, ni sélection. Un joueur ne pousse
/// jamais rien au serveur, qui le lui refuserait de toute façon — l'écriture
/// est réservée au MJ.
class WatchedBoardPanel extends ConsumerWidget {
  const WatchedBoardPanel({
    super.key,
    required this.sessionId,
    this.compact = false,
  });

  final String sessionId;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(liveSessionBoardProvider(sessionId));

    // Lu en deux questions — « ai-je un plateau ? » et « est-ce qu'il bouge
    // encore ? » — plutôt qu'en filtrant les cas d'`AsyncValue`. Une coupure
    // se présente tantôt en erreur, tantôt en chargement, selon qu'on retente
    // déjà, et les deux portent la dernière valeur connue : ce sont bien deux
    // informations, pas un état parmi d'autres.
    final board = state.hasValue ? state.value : null;
    final interrupted = state.error;

    if (board == null) {
      if (interrupted == null) {
        return const Center(child: CircularProgressIndicator());
      }

      return _Empty(
        message: interrupted is ApiException
            ? interrupted.message
            : 'Impossible de suivre le plateau.',
      );
    }

    final drawn = _Board(
      tokens: BoardToken.decode(board.tokens),
      map: boardMapById(board.mapId),
      compact: compact,
    );

    if (interrupted == null) return drawn;

    // Le plateau d'avant reste affiché pendant qu'on retente : un joueur qui
    // passe sous un tunnel n'a pas à voir la table disparaître.
    return Stack(
      children: [
        drawn,
        Positioned(
          left: QBSpace.s4,
          right: QBSpace.s4,
          bottom: QBSpace.s4,
          child: _Interrupted(error: interrupted),
        ),
      ],
    );
  }
}

/// La carte et les pions, sans rien pour les attraper.
class _Board extends StatelessWidget {
  const _Board({
    required this.tokens,
    required this.map,
    required this.compact,
  });

  final List<BoardToken> tokens;
  final BoardMap map;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(compact ? QBSpace.s3 : QBSpace.s5),
      child: LayoutBuilder(
        builder: (context, constraints) {
          var width = constraints.maxWidth;
          var height = width / map.aspectRatio;
          if (height > constraints.maxHeight) {
            height = constraints.maxHeight;
            width = height * map.aspectRatio;
          }

          final reference = math.min(width, height);

          return Center(
            child: SizedBox(
              width: width,
              height: height,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: QBColors.leather800, width: 3),
                  boxShadow: QBShadows.paperLg,
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(child: BoardSurface(map: map)),
                    for (final token in tokens)
                      Positioned(
                        left: token.x * width - token.size * reference / 2,
                        top: token.y * height - token.size * reference / 2,
                        width: token.size * reference,
                        height: token.size * reference,
                        child: BoardTokenView.of(
                          token,
                          // Le joueur regarde les pions du MJ, pas les siens.
                          // Les illustrations sont dans l'app de tout le
                          // monde ; c'est l'achat qui décide de ce qu'on peut
                          // poser, pas de ce qu'on peut voir. Filtrer ici
                          // rendrait des ronds rouges là où le MJ voit des
                          // créatures.
                          ownedKeys: purchasableBoardAssets.keys.toSet(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Le bandeau discret d'un plateau qui ne se met plus à jour.
class _Interrupted extends StatelessWidget {
  const _Interrupted({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: QBSpace.s4,
        vertical: QBSpace.s3,
      ),
      decoration: BoxDecoration(
        color: QBColors.leather900,
        borderRadius: BorderRadius.circular(QBRadius.md),
        border: Border.all(color: QBColors.gold500, width: 2),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.wifiOff, size: 16, color: QBColors.paper100),
          const SizedBox(width: QBSpace.s3),
          Expanded(
            child: Text(
              switch (error) {
                ApiException(:final message) => message,
                _ => 'Le plateau ne se met plus à jour.',
              },
              style: QBType.body().copyWith(
                fontSize: QBType.xs,
                color: QBColors.paper100,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pas même un plateau d'avant à montrer : le joueur est arrivé trop tard
/// pour la première réponse.
class _Empty extends StatelessWidget {
  const _Empty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(QBSpace.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              LucideIcons.wifiOff,
              size: 28,
              color: QBColors.semanticDanger,
            ),
            const SizedBox(height: QBSpace.s3),
            Text(
              message,
              textAlign: TextAlign.center,
              style: QBType.body().copyWith(
                fontSize: QBType.sm,
                color: QBColors.semanticDanger,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
