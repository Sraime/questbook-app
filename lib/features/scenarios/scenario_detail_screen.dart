import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../data/remote/remote_scenario.dart';
import '../../design_system/components/qb_icon_button.dart';
import '../../design_system/components/qb_markdown.dart';
import '../../design_system/components/qb_page_background.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/spacing.dart';
import '../../design_system/tokens/typography.dart';
import 'providers/scenario_providers.dart';

class ScenarioDetailScreen extends ConsumerWidget {
  const ScenarioDetailScreen({super.key, required this.scenarioId});

  final String scenarioId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloaded = ref.watch(downloadedScenarioProvider(scenarioId));

    return QBPageBackground(
      child: SafeArea(
        bottom: false,
        child: downloaded.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _Message('Scénario illisible.'),
          data: (scenario) {
            if (scenario == null) {
              return const _Message(
                'Télécharge ce scénario depuis la liste pour le consulter hors ligne.',
              );
            }
            return _Document(scenario: scenario);
          },
        ),
      ),
    );
  }
}

class _Document extends StatelessWidget {
  const _Document({required this.scenario});

  final RemoteScenarioDetail scenario;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 90),
      children: [
        Row(
          children: [
            QBIconButton(
              icon: const Icon(LucideIcons.arrowLeft, size: 18),
              label: 'Retour aux scénarios',
              onPressed: () => context.go('/scenarios'),
            ),
          ],
        ),
        const SizedBox(height: QBSpace.s4),
        Text(
          scenario.title,
          style: QBType.game().copyWith(
            fontWeight: QBType.weightBold,
            fontSize: 22,
            color: QBColors.ink900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${scenario.playersLabel} · ${scenario.durationLabel}',
          style: QBType.body().copyWith(
            fontSize: QBType.sm,
            color: QBColors.textMuted,
          ),
        ),
        const SizedBox(height: QBSpace.s4),
        Text(
          scenario.description,
          style: QBType.body().copyWith(
            fontSize: QBType.sm,
            color: QBColors.ink800,
          ),
        ),
        const SizedBox(height: QBSpace.s5),
        _Section(title: 'Contexte', markdown: scenario.context),
        const SizedBox(height: QBSpace.s5),
        _Section(title: 'Déroulé', markdown: scenario.rundownMarkdown),
        if (scenario.annexes.isNotEmpty) ...[
          const SizedBox(height: QBSpace.s5),
          Text(
            'Annexes',
            style: QBType.game().copyWith(
              fontWeight: QBType.weightSemibold,
              fontSize: 18,
              color: QBColors.ink900,
            ),
          ),
          const SizedBox(height: QBSpace.s3),
          for (final annex in scenario.annexes) ...[
            Text(
              annex.title,
              style: QBType.body().copyWith(
                fontWeight: QBType.weightSemibold,
                fontSize: QBType.base,
                color: QBColors.ink900,
              ),
            ),
            const SizedBox(height: 6),
            QBMarkdown(annex.contentMarkdown),
            const SizedBox(height: QBSpace.s4),
          ],
        ],
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.markdown});

  final String title;
  final String markdown;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: QBType.game().copyWith(
            fontWeight: QBType.weightSemibold,
            fontSize: 18,
            color: QBColors.ink900,
          ),
        ),
        const SizedBox(height: QBSpace.s2),
        QBMarkdown(markdown),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          QBIconButton(
            icon: const Icon(LucideIcons.arrowLeft, size: 18),
            label: 'Retour aux scénarios',
            onPressed: () => context.go('/scenarios'),
          ),
          const SizedBox(height: QBSpace.s4),
          Text(
            text,
            style: QBType.body().copyWith(
              fontSize: QBType.sm,
              color: QBColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
