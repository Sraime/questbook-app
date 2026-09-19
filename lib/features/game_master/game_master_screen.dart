import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/remote_providers.dart';
import '../../data/remote/remote_table.dart';
import '../../design_system/components/qb_button.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/spacing.dart';
import '../../design_system/tokens/typography.dart';
import '../tables/providers/table_providers.dart';
import '../tables/table_formatting.dart';
import 'game_master_space.dart';
import 'models/board_token.dart';
import 'panels/board_panel.dart';
import 'panels/characters_panel.dart';
import 'panels/notes_panel.dart';
import 'panels/rules_panel.dart';
import 'panels/scenario_panel.dart';
import 'providers/game_master_providers.dart';

enum GameMasterPanel {
  board('Plateau', LucideIcons.map),
  characters('Personnages', LucideIcons.users),
  rules('Règles', LucideIcons.bookOpen),
  scenario('Scénario', LucideIcons.scroll),
  notes('Notes', LucideIcons.notebookPen);

  const GameMasterPanel(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// L'écran depuis lequel le MJ anime sa session : le plateau et ses pions, les
/// fiches des joueurs, l'aide-mémoire des règles, le scénario et ses notes.
///
/// Vit hors du shell à onglets — c'est le seul écran de l'app dans ce cas. Une
/// partie occupe la tablette entière ; la barre du bas et le tiroir n'y ont
/// rien à faire, et le rail de gauche les remplace.
class GameMasterScreen extends ConsumerStatefulWidget {
  const GameMasterScreen({
    super.key,
    required this.tableId,
    required this.sessionId,
  });

  final String tableId;
  final String sessionId;

  @override
  ConsumerState<GameMasterScreen> createState() => _GameMasterScreenState();
}

class _GameMasterScreenState extends ConsumerState<GameMasterScreen> {
  /// Les notes se tapent lettre par lettre ; les écrire à chaque frappe
  /// ferait une transaction SQLite par caractère.
  static const _notesDebounce = Duration(milliseconds: 500);

  GameMasterPanel _panel = GameMasterPanel.board;

  /// Plateau et notes ne s'affichent que dans leur propre volet, qui en est
  /// le seul manipulateur. Les garder hors de l'état de cet écran évite de
  /// reconstruire le rail et le tiroir à chaque image d'un glissement.
  List<BoardToken> _tokens = const [];
  String _notes = '';
  String? _mapId;
  String? _accountId;
  bool _loaded = false;
  Timer? _notesTimer;

  @override
  void initState() {
    super.initState();

    ref.listenManual(
      authControllerProvider,
      (previous, next) {
        final id = next.value?.id;
        if (id == null || id == _accountId) return;
        _accountId = id;
        unawaited(_load(id));
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _notesTimer?.cancel();
    super.dispose();
  }

  Future<void> _load(String accountId) async {
    final board = await ref
        .read(sessionBoardDaoProvider)
        .read(accountId, widget.sessionId);

    if (!mounted) return;
    setState(() {
      _tokens = BoardToken.decode(board.tokens);
      _notes = board.notes;
      _mapId = board.mapId;
      _loaded = true;
    });
  }

  /// Sans `setState` : rien d'autre à l'écran ne montre les pions, et le
  /// volet qui vient de les changer les a déjà dessinés.
  void _persistTokens(List<BoardToken> tokens) {
    _tokens = tokens;

    final accountId = _accountId;
    if (accountId == null) return;
    unawaited(
      ref.read(sessionBoardDaoProvider).saveTokens(
            accountId,
            widget.sessionId,
            BoardToken.encode(tokens),
          ),
    );
  }

  void _persistMap(String mapId) {
    _mapId = mapId;

    final accountId = _accountId;
    if (accountId == null) return;
    unawaited(
      ref
          .read(sessionBoardDaoProvider)
          .saveMap(accountId, widget.sessionId, mapId),
    );
  }

  void _onNotesChanged(String value) {
    _notes = value;
    _notesTimer?.cancel();
    _notesTimer = Timer(_notesDebounce, () {
      final accountId = _accountId;
      if (accountId == null) return;
      unawaited(
        ref
            .read(sessionBoardDaoProvider)
            .saveNotes(accountId, widget.sessionId, value),
      );
    });
  }

  void _exit() => context.go('/tables/${widget.tableId}');

  @override
  Widget build(BuildContext context) {
    // Mesuré à chaque build : faire pivoter la tablette en portrait au milieu
    // d'une partie doit expliquer la disparition du plateau, pas l'écraser.
    final space = measureGameMasterSpace(MediaQuery.sizeOf(context));
    if (!space.isSufficient) {
      return _Refusal(space: space, onExit: _exit);
    }

    final detail = ref.watch(tableDetailProvider(widget.tableId));
    final session = detail.value?.sessions
        .where((entry) => entry.id == widget.sessionId)
        .firstOrNull;

    return Scaffold(
      backgroundColor: QBColors.bgPage,
      body: SafeArea(
        child: Row(
          children: [
            _Rail(
              tableName: detail.value?.table.title ?? 'Table',
              active: _panel,
              onSelect: (panel) => setState(() => _panel = panel),
              onExit: _exit,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Header(session: session),
                  Expanded(
                    child: !_loaded || session == null
                        ? const Center(child: CircularProgressIndicator())
                        : _panelBody(session),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _panelBody(RemoteGameSession session) => switch (_panel) {
        GameMasterPanel.board => BoardPanel(
            initialTokens: _tokens,
            initialMapId: _mapId,
            onTokensPersisted: _persistTokens,
            onMapPersisted: _persistMap,
          ),
        GameMasterPanel.characters => CharactersPanel(session: session),
        GameMasterPanel.rules => const RulesPanel(),
        GameMasterPanel.scenario => ScenarioPanel(session: session),
        GameMasterPanel.notes => NotesPanel(
            initialValue: _notes,
            onChanged: _onNotesChanged,
          ),
      };
}

class _Rail extends StatelessWidget {
  const _Rail({
    required this.tableName,
    required this.active,
    required this.onSelect,
    required this.onExit,
  });

  final String tableName;
  final GameMasterPanel active;
  final ValueChanged<GameMasterPanel> onSelect;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 196,
      color: QBColors.leather900,
      padding: const EdgeInsets.symmetric(vertical: QBSpace.s5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: QBSpace.s5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mode MJ',
                  style: QBType.game().copyWith(
                    fontWeight: QBType.weightBold,
                    fontSize: 15,
                    letterSpacing: 15 * QBType.trackingWide,
                    color: QBColors.gold500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tableName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: QBType.body().copyWith(
                    fontSize: QBType.xs,
                    color: QBColors.leather300,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: QBSpace.s6),
          for (final panel in GameMasterPanel.values)
            _RailEntry(
              panel: panel,
              selected: panel == active,
              onTap: () => onSelect(panel),
            ),
          const Spacer(),
          _RailExit(onTap: onExit),
        ],
      ),
    );
  }
}

class _RailEntry extends StatelessWidget {
  const _RailEntry({
    required this.panel,
    required this.selected,
    required this.onTap,
  });

  final GameMasterPanel panel;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: const EdgeInsets.fromLTRB(
            QBSpace.s3,
            0,
            QBSpace.s3,
            QBSpace.s2,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: QBSpace.s3,
            vertical: QBSpace.s3,
          ),
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [QBColors.juicyGoldTop, QBColors.juicyGoldBottom],
                  )
                : null,
            borderRadius: BorderRadius.circular(QBRadius.md),
          ),
          child: Row(
            children: [
              Icon(
                panel.icon,
                size: 17,
                color: selected ? QBColors.ink900 : QBColors.paper200,
              ),
              const SizedBox(width: QBSpace.s3),
              Expanded(
                child: Text(
                  panel.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: QBType.game().copyWith(
                    fontWeight: QBType.weightSemibold,
                    fontSize: 12,
                    letterSpacing: 12 * QBType.trackingWide,
                    color: selected ? QBColors.ink900 : QBColors.paper200,
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

class _RailExit extends StatelessWidget {
  const _RailExit({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(QBSpace.s5, QBSpace.s4, QBSpace.s5, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                LucideIcons.logOut,
                size: 16,
                color: QBColors.leather300,
              ),
              const SizedBox(width: QBSpace.s3),
              Expanded(
                child: Text(
                  'Quitter le mode MJ',
                  style: QBType.game().copyWith(
                    fontWeight: QBType.weightSemibold,
                    fontSize: 11,
                    letterSpacing: 11 * QBType.trackingWide,
                    color: QBColors.leather300,
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

class _Header extends StatelessWidget {
  const _Header({required this.session});

  final RemoteGameSession? session;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: QBColors.leather800,
      padding: const EdgeInsets.symmetric(
        horizontal: QBSpace.s6,
        vertical: QBSpace.s4,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session?.title ?? 'Session',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: QBType.game().copyWith(
                    fontWeight: QBType.weightBold,
                    fontSize: 16,
                    letterSpacing: 16 * QBType.trackingWide,
                    color: QBColors.paper100,
                  ),
                ),
                if (session != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${formatSessionDate(session!.startsAt)} · ${session!.location}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: QBType.body().copyWith(
                      fontSize: QBType.xs,
                      color: QBColors.leather300,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Ce que voit un MJ qui a ouvert le mode puis réduit sa fenêtre, ou qui est
/// arrivé ici par une URL depuis un téléphone.
class _Refusal extends StatelessWidget {
  const _Refusal({required this.space, required this.onExit});

  final GameMasterSpace space;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QBColors.bgPage,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(QBSpace.s6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Écran trop petit',
                    textAlign: TextAlign.center,
                    style: QBType.game().copyWith(
                      fontWeight: QBType.weightBold,
                      fontSize: 18,
                      color: QBColors.ink900,
                    ),
                  ),
                  const SizedBox(height: QBSpace.s3),
                  Text(
                    space.message,
                    textAlign: TextAlign.center,
                    style: QBType.body().copyWith(
                      fontSize: QBType.sm,
                      color: QBColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: QBSpace.s6),
                  QBButton(
                    label: 'Revenir à la table',
                    size: QBButtonSize.sm,
                    onPressed: onExit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
