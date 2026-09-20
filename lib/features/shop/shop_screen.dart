import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/remote/api_exception.dart';
import '../../data/remote/remote_shop_item.dart';
import '../../design_system/components/qb_badge.dart';
import '../../design_system/components/qb_page_background.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/spacing.dart';
import '../../design_system/tokens/typography.dart';
import '../tables/providers/table_providers.dart';
import 'providers/shop_providers.dart';
import 'shop_artwork.dart';

class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return QBPageBackground(
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => refreshShop(ref),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 24, 18, 90),
            children: [
              Text(
                'Boutique',
                style: QBType.game().copyWith(
                  fontWeight: QBType.weightBold,
                  fontSize: 22,
                  color: QBColors.ink900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Pions et aventures à ajouter à ta collection.',
                style: QBType.body().copyWith(
                  fontSize: QBType.sm,
                  color: QBColors.textMuted,
                ),
              ),
              const SizedBox(height: QBSpace.s5),
              if (!ref.watch(isSignedInProvider))
                Text(
                  'Connecte-toi pour voir la boutique.',
                  style: QBType.body().copyWith(
                    fontSize: QBType.sm,
                    color: QBColors.textMuted,
                  ),
                )
              else
                ref.watch(shopCatalogueProvider).when(
                  data: (items) => _Catalogue(items: items),
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, _) => Text(
                    error is ApiException
                        ? error.message
                        : 'Boutique indisponible.',
                    style: QBType.body().copyWith(
                      fontSize: QBType.sm,
                      color: QBColors.semanticDanger,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Catalogue extends StatelessWidget {
  const _Catalogue({required this.items});

  final List<RemoteShopItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Text(
        'Rien en rayon pour le moment.',
        style: QBType.body().copyWith(
          fontSize: QBType.sm,
          color: QBColors.textMuted,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Le même calcul que le tiroir du mode MJ, pour que les deux rayons
        // se ressemblent : deux vignettes par ligne au minimum, davantage dès
        // qu'il y a la place.
        const gap = QBSpace.s2;
        final columns = math.max(2, (constraints.maxWidth / 150).floor());
        final side = (constraints.maxWidth - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final item in items)
              SizedBox(width: side, child: _ItemTile(item: item)),
          ],
        );
      },
    );
  }
}

/// Une vignette dit les quatre choses du rayon — image, type, titre, prix —
/// et rien de plus. Ce qu'est vraiment l'article appartient à sa page, où il
/// y a la place de le lire.
///
/// Même chrome que les pions du tiroir du mode MJ : on y prend et on y repose
/// les mêmes objets, les montrer autrement ici laisserait croire à deux
/// catalogues sans rapport.
class _ItemTile extends StatelessWidget {
  const _ItemTile({required this.item});

  final RemoteShopItem item;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/boutique/${item.id}'),
      behavior: HitTestBehavior.opaque,
      child: Semantics(
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
              AspectRatio(
                aspectRatio: 1,
                child: ShopArtwork(imageKey: item.imageKey),
              ),
              const SizedBox(height: QBSpace.s2),
              Text(
                item.type.label,
                style: QBType.mono().copyWith(
                  fontSize: QBType.xs,
                  letterSpacing: QBType.xs * QBType.trackingWide,
                  color: QBColors.textMuted,
                ),
              ),
              _TileTitle(item.title),
              const SizedBox(height: QBSpace.s2),
              // Possédé l'emporte sur le prix : ce qu'il coûtait n'intéresse
              // plus personne une fois qu'il est à vous.
              if (item.owned)
                const QBBadge(label: 'Possédé', tone: QBTone.success)
              else
                Text(
                  item.priceLabel,
                  style: QBType.mono().copyWith(
                    fontSize: QBType.sm,
                    fontWeight: QBType.weightBold,
                    color: QBColors.leather700,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Le titre d'un article, toujours sur la même hauteur : deux lignes
/// réservées, sinon « Le Grand Ancien » et « Pack » ne poseraient pas leur
/// prix au même niveau dans une même rangée.
class _TileTitle extends StatelessWidget {
  const _TileTitle(this.text);

  static const double _lineHeight = 1.2;
  static const double _height = 13 * _lineHeight * 2;

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
        style: QBType.game().copyWith(
          fontWeight: QBType.weightBold,
          fontSize: 13,
          height: _lineHeight,
          color: QBColors.ink900,
        ),
      ),
    );
  }
}
