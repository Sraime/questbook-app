import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/spacing.dart';
import '../assets/providers/hosted_assets_provider.dart';

/// The picture of an article.
///
/// An asset added from the backoffice is pictured by the image the server
/// hosts, found through its [assetKey]. Everything else sends a key, not a
/// URL, and the mapping to a bundled image lives here, on the side that
/// draws. A key this version does not know falls back to a neutral mark
/// rather than a broken frame: the catalogue may grow before the app is
/// updated, and an article one cannot picture is still an article one can
/// read about and buy.
class ShopArtwork extends ConsumerWidget {
  const ShopArtwork({super.key, required this.imageKey, this.assetKey});

  final String imageKey;
  final String? assetKey;

  static const _assets = {
    'logo_mark': 'assets/brand/logo-mark.png',
  };

  /// Les clés qu'aucune image n'illustre encore, mais qu'un glyphe dit mieux
  /// que le colis du repli : une aventure n'est pas un article inconnu.
  static const _glyphs = {
    'scroll': LucideIcons.scrollText,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hosted = assetKey == null
        ? null
        : ref.watch(hostedAssetsProvider).value?[assetKey]?.imageFile;
    final asset = _assets[imageKey];
    final glyph = _glyphs[imageKey];

    // Sans fond, comme les pions du plateau : une image d'article se montre
    // telle qu'elle est, et l'enfermer dans une alvéole la ferait passer pour
    // une vignette de plus.
    return Padding(
      padding: const EdgeInsets.all(QBSpace.s2),
      child: hosted != null
          ? Image.file(File(hosted), fit: BoxFit.contain)
          : asset != null
          ? Image.asset(asset, fit: BoxFit.contain)
          : LayoutBuilder(
              builder: (context, constraints) => Center(
                child: Icon(
                  glyph ?? LucideIcons.package,
                  // Un glyphe suit la place qu'on lui donne, là où une image
                  // s'y adapte d'elle-même : sans cela, la même icône
                  // occuperait la vignette du rayon et se perdrait sur la
                  // page de l'article.
                  size: math.min(constraints.biggest.shortestSide, 64),
                  color: QBColors.textMuted,
                ),
              ),
            ),
    );
  }
}
