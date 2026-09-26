import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../data/remote/remote_scenario.dart';
import '../../design_system/components/qb_card.dart';
import '../../design_system/components/qb_icon_button.dart';
import '../../design_system/components/qb_markdown.dart';
import '../../design_system/components/qb_page_background.dart';
import '../../design_system/components/qb_reader_dialog.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/spacing.dart';
import '../../design_system/tokens/typography.dart';
import 'providers/scenario_providers.dart';
import 'scenario_outline.dart';

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

/// Le scénario entier, d'une traite, avec de quoi ne pas s'y perdre.
///
/// Défile d'un bloc plutôt que par une `ListView` paresseuse, et c'est
/// volontaire : sauter à une section demande que cette section existe
/// vraiment dans l'arbre, ce qu'une liste qui ne construit que le visible ne
/// garantit pas. Un scénario tient en quelques milliers de mots, le prix est
/// payable.
class _Document extends StatefulWidget {
  const _Document({required this.scenario});

  final RemoteScenarioDetail scenario;

  @override
  State<_Document> createState() => _DocumentState();
}

class _DocumentState extends State<_Document> {
  final _scroll = ScrollController();
  final _entries = <_OutlineEntry>[];
  late final List<MarkdownSection> _rundown;
  var _showBackToTop = false;

  @override
  void initState() {
    super.initState();
    _rundown = splitByHeadings(widget.scenario.rundownMarkdown);
    _buildOutline();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  /// Le sommaire est construit une fois, et les clés qu'il porte sont celles
  /// que les sections poseront plus bas : c'est ce qui les relie.
  void _buildOutline() {
    final scenario = widget.scenario;

    _entries.add(_OutlineEntry('Contexte'));
    _entries.add(_OutlineEntry('Déroulé'));
    for (final section in _rundown) {
      final title = section.title;
      if (title != null) _entries.add(_OutlineEntry(title, indented: true));
    }
    if (scenario.npcs.isNotEmpty) _entries.add(_OutlineEntry('Personnages'));
    if (scenario.clues.isNotEmpty) _entries.add(_OutlineEntry('Indices'));
  }

  _OutlineEntry _entry(String label) =>
      _entries.firstWhere((entry) => entry.label == label);

  /// Le bouton n'apparaît qu'une fois le sommaire hors de vue : proposer de
  /// remonter à qui le regarde déjà n'a pas de sens, et il mangerait un coin
  /// de l'écran pour rien.
  void _onScroll() {
    final show = _scroll.offset > 400;
    if (show != _showBackToTop) setState(() => _showBackToTop = show);
  }

  Future<void> _goTo(_OutlineEntry entry) async {
    final target = entry.key.currentContext;
    if (target == null) return;

    await Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      alignment: 0.05,
    );
  }

  void _backToTop() {
    _scroll.animateTo(
      0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scenario = widget.scenario;

    return Stack(
      children: [
        SingleChildScrollView(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 90),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
              _Outline(entries: _entries, onGoTo: _goTo),
              const SizedBox(height: QBSpace.s5),
              _Section(
                key: _entry('Contexte').key,
                title: 'Contexte',
                markdown: scenario.context,
              ),
              const SizedBox(height: QBSpace.s5),
              _SectionTitle('Déroulé', key: _entry('Déroulé').key),
              for (final section in _rundown) ...[
                const SizedBox(height: QBSpace.s2),
                // Le titre reste dans le markdown de sa section : c'est
                // `QBMarkdown` qui décide à quoi ressemble un titre, et le
                // découpage ne doit rien y changer.
                KeyedSubtree(
                  key: section.title == null
                      ? null
                      : _entry(section.title!).key,
                  child: QBMarkdown(section.markdown),
                ),
              ],
              // Les PNJ avant les indices, comme dans la séance : le MJ
              // prépare des visages, puis ce qu'il en fera sortir.
              //
              // Des cartes et non de la prose déroulée, là encore comme en
              // séance : une aventure en compte une douzaine, et les lire
              // toutes pour retrouver le pharmacien de Salins revient à
              // relire le scénario.
              if (scenario.npcs.isNotEmpty) ...[
                const SizedBox(height: QBSpace.s5),
                _SectionTitle('Personnages', key: _entry('Personnages').key),
                const _SectionHint('Tes joueurs ne les voient pas.'),
                for (final npc in scenario.npcs) ...[
                  const SizedBox(height: QBSpace.s3),
                  _EntryCard(
                    title: npc.name,
                    preview: npc.description,
                    contentMarkdown: npc.description,
                  ),
                ],
              ],
              if (scenario.clues.isNotEmpty) ...[
                const SizedBox(height: QBSpace.s5),
                _SectionTitle('Indices', key: _entry('Indices').key),
                const _SectionHint(
                  'Le mode MJ les retrouve pendant la séance, prêts à '
                  'transmettre.',
                ),
                for (final clue in scenario.clues) ...[
                  const SizedBox(height: QBSpace.s3),
                  _EntryCard(
                    title: clue.title,
                    contentMarkdown: clue.contentMarkdown,
                  ),
                ],
              ],
            ],
          ),
        ),
        if (_showBackToTop)
          Positioned(
            right: 18,
            bottom: 24,
            child: QBIconButton(
              icon: const Icon(
                LucideIcons.arrowUp,
                size: 20,
                color: QBColors.paper50,
              ),
              label: 'Revenir au sommaire',
              size: 48,
              variant: QBIconButtonVariant.solid,
              onPressed: _backToTop,
            ),
          ),
      ],
    );
  }
}

/// Une entrée du sommaire, et la clé de la section qu'elle vise.
class _OutlineEntry {
  _OutlineEntry(this.label, {this.indented = false});

  final String label;

  /// Les scènes du déroulé sont décalées sous « Déroulé » : le sommaire dit
  /// alors d'un coup d'œil ce qui est une partie de l'écran et ce qui est une
  /// partie de l'aventure.
  final bool indented;
  final GlobalKey key = GlobalKey();
}

/// Où l'on est, et où l'on peut aller.
///
/// Les titres viennent du markdown de l'auteur, pas d'une liste tenue à la
/// main : une aventure ajoutée au catalogue a son sommaire sans que personne
/// n'y pense.
class _Outline extends StatelessWidget {
  const _Outline({required this.entries, required this.onGoTo});

  final List<_OutlineEntry> entries;
  final Future<void> Function(_OutlineEntry) onGoTo;

  @override
  Widget build(BuildContext context) {
    return QBCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Sommaire',
            style: QBType.game().copyWith(
              fontWeight: QBType.weightSemibold,
              fontSize: 15,
              color: QBColors.ink900,
            ),
          ),
          for (final entry in entries)
            Semantics(
              button: true,
              label: 'Aller à ${entry.label}',
              excludeSemantics: true,
              child: GestureDetector(
                onTap: () => onGoTo(entry),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: EdgeInsets.only(
                    top: QBSpace.s2,
                    left: entry.indented ? QBSpace.s4 : 0,
                  ),
                  child: Text(
                    entry.label,
                    style: QBType.body().copyWith(
                      fontSize: entry.indented ? QBType.xs : QBType.sm,
                      color: entry.indented
                          ? QBColors.ink700
                          : QBColors.leather700,
                      fontWeight: entry.indented
                          ? QBType.weightRegular
                          : QBType.weightSemibold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: QBType.game().copyWith(
        fontWeight: QBType.weightSemibold,
        fontSize: 18,
        color: QBColors.ink900,
      ),
    );
  }
}

class _SectionHint extends StatelessWidget {
  const _SectionHint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
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

/// Un personnage ou un indice de l'aventure, réduit à sa ligne.
///
/// Le même geste que dans les volets du mode MJ : on parcourt des titres, on
/// touche, et le texte s'ouvre en grand. [preview] n'est donné qu'aux
/// personnages — un nom seul ne dit pas qui c'est, alors qu'un titre d'indice
/// se suffit, et l'annoncer ici le déflorerait.
class _EntryCard extends StatelessWidget {
  const _EntryCard({
    required this.title,
    required this.contentMarkdown,
    this.preview,
  });

  final String title;
  final String contentMarkdown;
  final String? preview;

  @override
  Widget build(BuildContext context) {
    final preview = this.preview;

    return Semantics(
      button: true,
      label: 'Lire $title',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => showQBReaderDialog(
          context,
          title: title,
          contentMarkdown: contentMarkdown,
        ),
        behavior: HitTestBehavior.opaque,
        child: QBCard(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: QBType.game().copyWith(
                        fontWeight: QBType.weightSemibold,
                        fontSize: 15,
                        color: QBColors.ink900,
                      ),
                    ),
                    if (preview != null && preview.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        preview,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: QBType.body().copyWith(
                          fontSize: QBType.xs,
                          color: QBColors.ink700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: QBSpace.s2),
              const Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: QBColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({super.key, required this.title, required this.markdown});

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
