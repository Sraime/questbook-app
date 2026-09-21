import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/remote_providers.dart';
import '../../data/remote/api_exception.dart';
import '../../data/remote/remote_shop_item.dart';
import '../../design_system/components/qb_badge.dart';
import '../../design_system/components/qb_button.dart';
import '../../design_system/components/qb_icon_button.dart';
import '../../design_system/components/qb_page_background.dart';
import '../../design_system/components/qb_toast.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/spacing.dart';
import '../../design_system/tokens/typography.dart';
import '../scenarios/providers/scenario_providers.dart';
import 'providers/shop_providers.dart';
import 'shop_artwork.dart';

class ShopItemScreen extends ConsumerWidget {
  const ShopItemScreen({super.key, required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref.watch(shopItemProvider(itemId));

    return QBPageBackground(
      child: SafeArea(
        bottom: false,
        child: item.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _Message(
            error is ApiException ? error.message : 'Article introuvable.',
          ),
          data: (item) => _Article(item: item),
        ),
      ),
    );
  }
}

class _Article extends ConsumerStatefulWidget {
  const _Article({required this.item});

  final RemoteShopItemDetail item;

  @override
  ConsumerState<_Article> createState() => _ArticleState();
}

class _ArticleState extends ConsumerState<_Article> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 90),
      children: [
        Row(
          children: [
            QBIconButton(
              icon: const Icon(LucideIcons.arrowLeft, size: 18),
              label: 'Retour à la boutique',
              onPressed: () => context.go('/boutique'),
            ),
          ],
        ),
        const SizedBox(height: QBSpace.s4),
        Center(
          child: SizedBox(
            width: 140,
            height: 140,
            child: ShopArtwork(imageKey: item.imageKey),
          ),
        ),
        const SizedBox(height: QBSpace.s5),
        Text(
          item.title,
          style: QBType.game().copyWith(
            fontWeight: QBType.weightBold,
            fontSize: 22,
            color: QBColors.ink900,
          ),
        ),
        const SizedBox(height: QBSpace.s3),
        Row(
          children: [
            QBTag(label: item.type.label),
            const SizedBox(width: QBSpace.s2),
            if (item.owned)
              const QBBadge(label: 'Possédé', tone: QBTone.success)
            else
              Text(
                item.priceLabel,
                style: QBType.mono().copyWith(
                  fontSize: QBType.md,
                  fontWeight: QBType.weightBold,
                  color: QBColors.leather700,
                ),
              ),
          ],
        ),
        const SizedBox(height: QBSpace.s5),
        Text(
          item.description,
          style: QBType.body().copyWith(
            fontSize: QBType.sm,
            height: 1.5,
            color: QBColors.textBody,
          ),
        ),
        const SizedBox(height: QBSpace.s6),
        if (!item.owned)
          QBButton(
            label: _busy ? 'Un instant…' : 'Obtenir',
            // Acheter est une écriture : hors ligne, le bouton attend comme
            // partout ailleurs dans l'app.
            onPressed: _busy || !ref.watch(canWriteProvider) ? null : _buy,
          )
        else if (item.scenarioId case final scenarioId?)
          // Une aventure obtenue n'est pas encore lisible : son texte vit sur
          // le serveur jusqu'à ce qu'on le télécharge. Le geste suit donc
          // l'achat sur la même page, plutôt que d'envoyer le lecteur le
          // chercher dans le menu des scénarios.
          _ScenarioActions(scenarioId: scenarioId)
        else
          Text(
            'Cet article est à toi. Tu le retrouveras parmi tes assets.',
            style: QBType.body().copyWith(
              fontSize: QBType.sm,
              color: QBColors.textMuted,
            ),
          ),
      ],
    );
  }

  Future<void> _buy() async {
    setState(() => _busy = true);
    try {
      await purchaseShopItem(ref, widget.item.id);
      if (!mounted) return;
      showQBToast(
        context,
        '« ${widget.item.title} » est à toi.',
        tone: QBTone.success,
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      showQBToast(context, error.message, tone: QBTone.danger);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

/// Ce qui reste à faire d'une aventure une fois qu'elle est à soi : la
/// télécharger, puis la lire.
class _ScenarioActions extends ConsumerStatefulWidget {
  const _ScenarioActions({required this.scenarioId});

  final String scenarioId;

  @override
  ConsumerState<_ScenarioActions> createState() => _ScenarioActionsState();
}

class _ScenarioActionsState extends ConsumerState<_ScenarioActions> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final downloaded = ref.watch(downloadedScenarioProvider(widget.scenarioId));

    // Tant qu'on ne sait pas, ne rien promettre : un bouton « Télécharger »
    // affiché une fraction de seconde sur une aventure déjà sur l'appareil
    // ferait douter de ce qui est enregistré.
    if (downloaded.isLoading && !downloaded.hasValue) {
      return const Center(child: CircularProgressIndicator());
    }

    if (downloaded.value != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          QBButton(
            label: 'Ouvrir',
            iconLeft: const Icon(LucideIcons.bookOpen, size: 16),
            onPressed: () => context.go('/scenarios/${widget.scenarioId}'),
          ),
          const SizedBox(height: QBSpace.s2),
          Text(
            'Téléchargée sur cet appareil. Tu la retrouveras dans Scénarios, '
            'et tu pourras la rattacher à une session.',
            style: QBType.body().copyWith(
              fontSize: QBType.xs,
              color: QBColors.textMuted,
            ),
          ),
        ],
      );
    }

    // Pas de verrou hors ligne, contrairement à l'achat : le même bouton dans
    // l'écran des scénarios n'en a pas, et la même action refusée d'un côté
    // et offerte de l'autre ferait passer l'un des deux pour cassé. Sans
    // réseau, l'appel échoue et le dit.
    return QBButton(
      label: _busy ? 'Téléchargement…' : 'Télécharger',
      iconLeft: const Icon(LucideIcons.download, size: 16),
      onPressed: _busy ? null : _download,
    );
  }

  Future<void> _download() async {
    setState(() => _busy = true);
    try {
      await downloadScenario(ref, widget.scenarioId);
      if (!mounted) return;
      showQBToast(context, 'Aventure téléchargée', tone: QBTone.success);
    } on ApiException catch (error) {
      if (!mounted) return;
      showQBToast(context, error.message, tone: QBTone.danger);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(QBSpace.s6),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: QBType.body().copyWith(
            fontSize: QBType.sm,
            color: QBColors.textMuted,
          ),
        ),
      ),
    );
  }
}
