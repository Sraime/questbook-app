import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../design_system/components/qb_page_background.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/spacing.dart';
import '../../design_system/tokens/typography.dart';
// Le catalogue vit chez le mode MJ, qui est le seul à en poser sur un
// plateau ; cet écran n'en est qu'une vitrine et ne le redéclare pas, sous
// peine de lister un jour des pions qui n'existent plus.
import '../game_master/models/board_catalog.dart';
import '../game_master/widgets/board_token_view.dart';

/// Ce dont le MJ dispose pour meubler un plateau, consultable hors d'une
/// partie.
///
/// Le tiroir du mode MJ montre déjà ces pions, mais seulement une fois la
/// session ouverte, sur une tablette : on ne pouvait pas savoir avant de
/// s'asseoir à la table ce qu'on aurait sous la main.
class AssetsLibraryScreen extends StatelessWidget {
  const AssetsLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return QBPageBackground(
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 24, 18, 90),
          children: [
            Text(
              'Assets',
              style: QBType.game().copyWith(
                fontWeight: QBType.weightBold,
                fontSize: 22,
                color: QBColors.ink900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Les pions que tu peux poser sur un plateau quand tu animes une '
              'session.',
              style: QBType.body().copyWith(
                fontSize: QBType.sm,
                color: QBColors.textMuted,
              ),
            ),
            const SizedBox(height: QBSpace.s5),
            for (final section in boardAssetSections) ...[
              _Section(section: section),
              const SizedBox(height: QBSpace.s5),
            ],
            Text(
              'Les illustrations viendront plus tard : pour l’instant un pion '
              'se reconnaît à sa forme et à sa couleur.',
              style: QBType.body().copyWith(
                fontSize: QBType.xs,
                color: QBColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.section});

  final BoardAssetSection section;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.title,
          style: QBType.game().copyWith(
            fontWeight: QBType.weightSemibold,
            fontSize: 13,
            color: QBColors.leather700,
          ),
        ),
        const SizedBox(height: QBSpace.s3),
        LayoutBuilder(
          builder: (context, constraints) {
            // Quatre colonnes sur un téléphone, davantage dès qu'il y a la
            // place. Quatre et non trois parce que les rayons vont par
            // quatre : à trois, chacun se coupait en une rangée pleine et un
            // pion orphelin en dessous.
            const gap = QBSpace.s2;
            final columns = math.max(4, (constraints.maxWidth / 120).floor());
            final side = (constraints.maxWidth - gap * (columns - 1)) / columns;

            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final asset in section.assets)
                  SizedBox(width: side, child: _AssetTile(asset: asset)),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _AssetTile extends StatelessWidget {
  const _AssetTile({required this.asset});

  final BoardAsset asset;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: QBSpace.s2,
          vertical: QBSpace.s3,
        ),
        decoration: BoxDecoration(
          color: QBColors.paper50,
          border: Border.all(color: QBColors.borderDefault),
          borderRadius: BorderRadius.circular(QBRadius.md),
        ),
          child: Column(
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: BoardTokenPreview.of(asset),
              ),
            const SizedBox(height: QBSpace.s2),
            _TileLabel(asset.name),
          ],
        ),
      ),
    );
  }
}

/// Le nom d'un pion, toujours sur la même hauteur : deux lignes réservées,
/// sinon « Zone carrée » et « Joueur rouge » ne se répondraient pas dans une
/// même rangée.
class _TileLabel extends StatelessWidget {
  const _TileLabel(this.text);

  static const double _lineHeight = 1.2;
  static const double _height = QBType.xs * _lineHeight * 2;

  final String text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _height,
      child: Text(
        text,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: QBType.body().copyWith(
          fontSize: QBType.xs,
          height: _lineHeight,
          color: QBColors.ink700,
        ),
      ),
    );
  }
}
