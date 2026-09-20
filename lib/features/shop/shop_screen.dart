import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/remote/api_exception.dart';
import '../../data/remote/remote_shop_item.dart';
import '../../design_system/components/qb_badge.dart';
import '../../design_system/components/qb_card.dart';
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

    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: QBSpace.s4),
          _ItemCard(item: items[i]),
        ],
      ],
    );
  }
}

/// A card says the four things the shelf has to say — picture, title, type,
/// price — and nothing else. What the article actually is belongs to its own
/// page, where there is room to read it.
class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item});

  final RemoteShopItem item;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/boutique/${item.id}'),
      behavior: HitTestBehavior.opaque,
      child: QBCard(
        padding: const EdgeInsets.all(QBSpace.s4),
        child: Row(
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: ShopArtwork(imageKey: item.imageKey),
            ),
            const SizedBox(width: QBSpace.s4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.title,
                    style: QBType.game().copyWith(
                      fontWeight: QBType.weightBold,
                      fontSize: 15,
                      color: QBColors.ink900,
                    ),
                  ),
                  const SizedBox(height: QBSpace.s2),
                  Row(
                    children: [
                      QBTag(label: item.type.label),
                      const SizedBox(width: QBSpace.s2),
                      // Owned wins over the price: what it used to cost is of
                      // no interest once it is yours.
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
