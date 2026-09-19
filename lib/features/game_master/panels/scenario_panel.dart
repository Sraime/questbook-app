import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/remote/remote_scenario.dart';
import '../../../data/remote/remote_table.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';
import '../../scenarios/providers/scenario_providers.dart';
import '../../scenarios/scenario_detail_screen.dart';

/// Le scénario rattaché à la session : contexte, déroulé et annexes.
///
/// Lu depuis la copie téléchargée, jamais depuis l'API. Un scénario se prépare
/// avant la partie ; pendant, le MJ ne doit dépendre de rien.
class ScenarioPanel extends ConsumerWidget {
  const ScenarioPanel({super.key, required this.session});

  final RemoteGameSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linked = session.scenario;
    if (linked == null) {
      return const _Message(
        'Aucun scénario n’est rattaché à cette session. Tu peux en choisir un '
        'en modifiant la session depuis la table.',
      );
    }

    final downloaded = ref.watch(downloadedScenarioProvider(linked.id));

    return switch (downloaded) {
      AsyncData(value: final scenario) => scenario == null
          ? _Message(
              '« ${linked.title} » n’est pas sur cet appareil. Télécharge-le '
              'depuis l’onglet Scénarios pour l’avoir sous la main pendant la '
              'partie.',
            )
          : _Document(scenario: scenario),
      AsyncError() => const _Message('Scénario illisible.'),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

class _Document extends StatelessWidget {
  const _Document({required this.scenario});

  final RemoteScenarioDetail scenario;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        QBSpace.s6,
        QBSpace.s5,
        QBSpace.s6,
        QBSpace.s8,
      ),
      children: [
        Text(
          scenario.title,
          style: QBType.game().copyWith(
            fontWeight: QBType.weightBold,
            fontSize: 18,
            color: QBColors.ink900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${scenario.playersLabel} · ${scenario.durationLabel}',
          style: QBType.body().copyWith(
            fontSize: QBType.xs,
            color: QBColors.textMuted,
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
              fontSize: 15,
              color: QBColors.ink900,
            ),
          ),
          for (final annex in scenario.annexes) ...[
            const SizedBox(height: QBSpace.s4),
            _Section(title: annex.title, markdown: annex.contentMarkdown),
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
            fontSize: 14,
            color: QBColors.ink900,
          ),
        ),
        const SizedBox(height: QBSpace.s2),
        ScenarioMarkdown(markdown),
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
      padding: const EdgeInsets.all(QBSpace.s6),
      child: Text(
        text,
        style: QBType.body().copyWith(
          fontSize: QBType.sm,
          color: QBColors.textMuted,
        ),
      ),
    );
  }
}
