import 'package:material_ui/material_ui.dart';
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
            child: ShopArtwork.of(item),
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
            QBTag(label: shopItemTypeLabel(ref, item.type, item.assetKey)),
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
        if (item.contents.isNotEmpty) ...[
          const SizedBox(height: QBSpace.s5),
          _BundleContents(entries: item.contents),
        ],
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
        else if (item.contents.any((entry) => entry.isScenario))
          _BundleScenarios(
            entries: [
              for (final entry in item.contents)
                if (entry.isScenario && entry.scenarioId != null) entry,
            ],
          )
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
      showQBToast(context, 'Scénario téléchargé', tone: QBTone.success);
    } on ApiException catch (error) {
      if (!mounted) return;
      showQBToast(context, error.message, tone: QBTone.danger);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

/// Ce que donne un bundle, élément par élément, et ce que le lecteur a déjà :
/// l'obtenir quand même est permis, mais ne doit pas surprendre.
class _BundleContents extends ConsumerWidget {
  const _BundleContents({required this.entries});

  final List<RemoteBundleEntry> entries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Contenu',
          style: QBType.game().copyWith(
            fontWeight: QBType.weightSemibold,
            fontSize: 15,
            color: QBColors.ink900,
          ),
        ),
        const SizedBox(height: QBSpace.s2),
        for (final entry in entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: QBSpace.s1),
            child: Row(
              children: [
                SizedBox(
                  width: 36,
                  height: 36,
                  child: entry.isScenario
                      ? const ShopArtwork(imageKey: 'scroll')
                      : ShopArtwork(imageKey: 'asset', assetKey: entry.assetKey),
                ),
                const SizedBox(width: QBSpace.s2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.title,
                        style: QBType.body().copyWith(
                          fontSize: QBType.sm,
                          fontWeight: QBType.weightSemibold,
                          color: QBColors.textBody,
                        ),
                      ),
                      Text(
                        entry.isScenario
                            ? 'Scénario'
                            : shopItemTypeLabel(
                                ref,
                                ShopItemType.asset,
                                entry.assetKey,
                              ),
                        style: QBType.mono().copyWith(
                          fontSize: QBType.xs,
                          color: QBColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (entry.owned)
                  const QBBadge(label: 'Déjà possédé', tone: QBTone.success),
              ],
            ),
          ),
      ],
    );
  }
}

/// Les scénarios d'un bundle obtenu, à télécharger sans aller les chercher
/// un par un dans le menu des scénarios.
class _BundleScenarios extends ConsumerStatefulWidget {
  const _BundleScenarios({required this.entries});

  final List<RemoteBundleEntry> entries;

  @override
  ConsumerState<_BundleScenarios> createState() => _BundleScenariosState();
}

class _BundleScenariosState extends ConsumerState<_BundleScenarios> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final states = {
      for (final entry in widget.entries)
        entry.scenarioId!: ref.watch(downloadedScenarioProvider(entry.scenarioId!)),
    };

    if (states.values.any((state) => state.isLoading && !state.hasValue)) {
      return const Center(child: CircularProgressIndicator());
    }

    final missing = [
      for (final entry in widget.entries)
        if (states[entry.scenarioId]!.value == null) entry,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (missing.isNotEmpty) ...[
          QBButton(
            label: _busy
                ? 'Téléchargement…'
                : missing.length == 1
                    ? 'Télécharger le scénario'
                    : 'Télécharger les ${missing.length} scénarios',
            iconLeft: const Icon(LucideIcons.download, size: 16),
            onPressed: _busy ? null : () => _download(missing),
          ),
          const SizedBox(height: QBSpace.s2),
          Text(
            'Une fois téléchargés, tu les retrouveras dans Scénarios, et tu '
            'pourras les rattacher à une session. Les pions et les cartes '
            'sont déjà dans tes assets.',
            style: QBType.body().copyWith(
              fontSize: QBType.xs,
              color: QBColors.textMuted,
            ),
          ),
        ] else
          for (final entry in widget.entries) ...[
            QBButton(
              label: 'Ouvrir « ${entry.title} »',
              iconLeft: const Icon(LucideIcons.bookOpen, size: 16),
              onPressed: () => context.go('/scenarios/${entry.scenarioId}'),
            ),
            const SizedBox(height: QBSpace.s2),
          ],
      ],
    );
  }

  /// Un par un, et le premier échec arrête tout : les suivants échoueraient
  /// pour la même raison, et un seul message vaut mieux que trois.
  Future<void> _download(List<RemoteBundleEntry> missing) async {
    setState(() => _busy = true);
    try {
      for (final entry in missing) {
        await downloadScenario(ref, entry.scenarioId!);
      }
      if (!mounted) return;
      showQBToast(
        context,
        missing.length == 1 ? 'Scénario téléchargé' : 'Scénarios téléchargés',
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
