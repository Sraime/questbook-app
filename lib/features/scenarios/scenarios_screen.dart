import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../data/remote/api_exception.dart';
import '../../data/remote/remote_scenario.dart';
import '../../design_system/components/qb_button.dart';
import '../../design_system/components/qb_card.dart';
import '../../design_system/components/qb_page_background.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/spacing.dart';
import '../../design_system/tokens/typography.dart';
import '../tables/providers/table_providers.dart';
import 'providers/scenario_providers.dart';

class ScenariosScreen extends ConsumerWidget {
  const ScenariosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(scenariosOverviewProvider);

    return QBPageBackground(
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => refreshScenarios(ref),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 24, 18, 90),
            children: [
              Text(
                'Scénarios',
                style: QBType.game().copyWith(
                  fontWeight: QBType.weightBold,
                  fontSize: 22,
                  color: QBColors.ink900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Aventures à préparer. Télécharge-les pour les lire hors ligne.',
                style: QBType.body().copyWith(
                  fontSize: QBType.sm,
                  color: QBColors.textMuted,
                ),
              ),
              const SizedBox(height: QBSpace.s5),
              if (!ref.watch(isSignedInProvider))
                Text(
                  'Connecte-toi pour voir les scénarios que tu possèdes.',
                  style: QBType.body().copyWith(
                    fontSize: QBType.sm,
                    color: QBColors.textMuted,
                  ),
                )
              else
                overview.when(
                  data: (data) => _Body(overview: data),
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, _) => Text(
                    error is ApiException
                        ? error.message
                        : 'Scénarios indisponibles.',
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

class _Body extends StatelessWidget {
  const _Body({required this.overview});

  final ScenariosOverview overview;

  @override
  Widget build(BuildContext context) {
    if (overview.scenarios.isEmpty) {
      return Text(
        'Aucun scénario pour l’instant. La boutique arrivera plus tard.',
        style: QBType.body().copyWith(
          fontSize: QBType.sm,
          color: QBColors.textMuted,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (overview.cachedAt != null) ...[
          Text(
            'Copie locale — hors ligne.',
            style: QBType.body().copyWith(
              fontSize: QBType.xs,
              color: QBColors.textMuted,
            ),
          ),
          const SizedBox(height: QBSpace.s3),
        ],
        for (final scenario in overview.scenarios) ...[
          _ScenarioCard(
            scenario: scenario,
            downloaded: overview.isDownloaded(scenario.id),
          ),
          const SizedBox(height: QBSpace.s3),
        ],
      ],
    );
  }
}

class _ScenarioCard extends ConsumerStatefulWidget {
  const _ScenarioCard({required this.scenario, required this.downloaded});

  final RemoteScenarioSummary scenario;
  final bool downloaded;

  @override
  ConsumerState<_ScenarioCard> createState() => _ScenarioCardState();
}

class _ScenarioCardState extends ConsumerState<_ScenarioCard> {
  bool _busy = false;

  Future<void> _download() async {
    setState(() => _busy = true);
    try {
      await downloadScenario(ref, widget.scenario.id);
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scenario = widget.scenario;
    final downloaded = widget.downloaded;

    return QBCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            scenario.title,
            style: QBType.game().copyWith(
              fontWeight: QBType.weightSemibold,
              fontSize: 16,
              color: QBColors.ink900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            scenario.description,
            style: QBType.body().copyWith(
              fontSize: QBType.sm,
              color: QBColors.ink800,
            ),
          ),
          const SizedBox(height: QBSpace.s3),
          Text(
            '${scenario.playersLabel} · ${scenario.durationLabel}',
            style: QBType.body().copyWith(
              fontSize: QBType.xs,
              color: QBColors.textMuted,
            ),
          ),
          const SizedBox(height: QBSpace.s3),
          if (downloaded)
            QBButton(
              label: 'Ouvrir',
              size: QBButtonSize.sm,
              variant: QBButtonVariant.secondary,
              iconLeft: const Icon(LucideIcons.book, size: 14),
              onPressed: () => context.go('/scenarios/${scenario.id}'),
            )
          else
            QBButton(
              label: _busy ? 'Téléchargement…' : 'Télécharger',
              size: QBButtonSize.sm,
              iconLeft: const Icon(LucideIcons.download, size: 14),
              onPressed: _busy ? null : _download,
            ),
        ],
      ),
    );
  }
}
