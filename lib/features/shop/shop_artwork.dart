import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/spacing.dart';

/// The picture of an article.
///
/// The server sends a key, not a URL — nothing hosts files yet — so the
/// mapping to a bundled image lives here, on the side that draws. A key this
/// version does not know falls back to a neutral mark rather than a broken
/// frame: the catalogue may grow before the app is updated, and an article
/// one cannot picture is still an article one can read about and buy.
class ShopArtwork extends StatelessWidget {
  const ShopArtwork({super.key, required this.imageKey});

  final String imageKey;

  static const _assets = {
    'logo_mark': 'assets/brand/logo-mark.png',
  };

  @override
  Widget build(BuildContext context) {
    final asset = _assets[imageKey];

    // Sans fond, comme les pions du plateau : une image d'article se montre
    // telle qu'elle est, et l'enfermer dans une alvéole la ferait passer pour
    // une vignette de plus.
    return Padding(
      padding: const EdgeInsets.all(QBSpace.s2),
      child: asset == null
          ? Center(
              child: Icon(
                LucideIcons.package,
                size: 28,
                color: QBColors.textMuted,
              ),
            )
          : Image.asset(asset, fit: BoxFit.contain),
    );
  }
}
