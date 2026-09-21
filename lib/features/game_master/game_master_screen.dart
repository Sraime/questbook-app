import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/remote_providers.dart';
import '../../data/remote/remote_table.dart';
import '../../design_system/components/qb_icon_button.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/spacing.dart';
import '../../design_system/tokens/typography.dart';
import '../tables/providers/table_providers.dart';
import '../tables/table_formatting.dart';
import 'game_master_layout.dart';
import 'models/board_token.dart';
import 'models/session_seat.dart';
import 'panels/board_panel.dart';
import 'panels/characters_panel.dart';
import 'panels/details_panel.dart';
import 'panels/notes_panel.dart';
import 'panels/rules_panel.dart';
import 'panels/scenario_panel.dart';
import 'panels/watched_board_panel.dart';
import 'providers/game_master_providers.dart';

export 'models/session_seat.dart' show GameMasterPanel, SessionSeat;

/// L'écran depuis lequel le MJ anime sa session : le plateau et ses pions, les
/// fiches des joueurs, l'aide-mémoire des règles, le scénario et ses notes.
///
/// Vit hors du shell à onglets — c'est le seul écran de l'app dans ce cas. Une
/// partie occupe l'appareil entier ; la barre du bas et le tiroir n'y ont rien
/// à faire.
///
/// Deux dispositions pour un même contenu, choisies par
/// [measureGameMasterLayout] : le rail de gauche quand l'écran est assez
/// large, une barre d'onglets sous l'entête sinon.
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

  /// Le mode MJ s'ouvre sur ce qu'est la séance, pas sur le plateau : on
  /// arrive ici avant la partie, pour vérifier l'heure et le lieu, bien plus
  /// souvent qu'on n'y arrive une carte à la main.
  GameMasterPanel _panel = GameMasterPanel.details;

  /// Plateau et notes ne s'affichent que dans leur propre volet, qui en est
  /// le seul manipulateur. Les garder hors de l'état de cet écran évite de
  /// reconstruire le rail et le tiroir à chaque image d'un glissement.
  List<BoardToken> _tokens = const [];
  String _notes = '';
  String? _mapId;
  String? _accountId;
  bool _loaded = false;
  Timer? _notesTimer;

  /// Une poussée que le serveur a refusée, faute de réseau le plus souvent.
  /// Le plateau est intact sur l'appareil ; ce sont les joueurs qui regardent
  /// une copie périmée, et c'est ce qu'on répare au retour de la connexion.
  bool _pendingPush = false;

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

    // Le réseau qui revient doit rattraper ce qui s'est joué sans lui. Sans
    // cela, un MJ ayant déplacé ses pions hors couverture les verrait figés
    // chez ses joueurs jusqu'à son geste suivant — qui peut ne jamais venir
    // si la partie se termine sur ce plateau.
    ref.listenManual(connectivityProvider, (was, isNow) {
      if (isNow && was == false && _pendingPush) _push();
    });
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
    _push();
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
    _push();
  }

  /// Montre le plateau aux joueurs qui le regardent, après l'avoir écrit sur
  /// l'appareil et jamais avant : le local est la vérité, le serveur la copie.
  ///
  /// Sans attendre la réponse. Le MJ vient de déposer un pion et n'a pas à
  /// patienter le temps d'un aller-retour ; en cas d'échec on retient
  /// seulement qu'il reste quelque chose à pousser.
  void _push() {
    unawaited(
      pushSessionBoard(
        ref,
        sessionId: widget.sessionId,
        tokens: BoardToken.encode(_tokens),
        mapId: _mapId,
      ).then((pushed) => _pendingPush = !pushed),
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
    // Mesuré à chaque build : pivoter l'appareil en pleine partie change la
    // disposition, jamais ce qu'on est en train de faire.
    final layout = measureGameMasterLayout(MediaQuery.sizeOf(context));
    final detail = ref.watch(tableDetailProvider(widget.tableId));
    final session = detail.value?.sessions
        .where((entry) => entry.id == widget.sessionId)
        .firstOrNull;
    final tableName = detail.value?.table.title ?? 'Table';

    // Tant que la table n'a pas répondu, on est joueur : ouvrir les volets du
    // MJ pour les refermer ensuite montrerait une seconde ce qui ne le
    // regarde pas.
    final seat = detail.value?.table.isGameMaster ?? false
        ? SessionSeat.gameMaster
        : SessionSeat.player;

    // Un joueur qui atterrirait sur le volet d'un MJ — en pivotant l'appareil
    // après un changement de rôle, ou parce qu'on a confié la table en pleine
    // partie — retombe sur le sien.
    final panel = seat.panels.contains(_panel) ? _panel : seat.landing;

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(
          session: session,
          seat: seat,
          // L'entête ne porte le nom de la table et la sortie que faute de
          // rail pour les accueillir.
          tableName: layout.isCompact ? tableName : null,
          onExit: layout.isCompact ? _exit : null,
        ),
        if (layout.isCompact)
          _PanelTabs(
            seat: seat,
            active: panel,
            onSelect: (next) => setState(() => _panel = next),
          ),
        Expanded(
          child: !_loaded || session == null
              ? const Center(child: CircularProgressIndicator())
              : _panelBody(
                  session,
                  panel: panel,
                  seat: seat,
                  compact: layout.isCompact,
                ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: QBColors.bgPage,
      body: SafeArea(
        child: layout.isCompact
            ? body
            : Row(
                children: [
                  _Rail(
                    tableName: tableName,
                    seat: seat,
                    active: panel,
                    onSelect: (next) => setState(() => _panel = next),
                    onExit: _exit,
                  ),
                  Expanded(child: body),
                ],
              ),
      ),
    );
  }

  Widget _panelBody(
    RemoteGameSession session, {
    required GameMasterPanel panel,
    required SessionSeat seat,
    required bool compact,
  }) =>
      switch (panel) {
        GameMasterPanel.details => DetailsPanel(
            tableId: widget.tableId,
            session: session,
            onCancelled: _exit,
          ),
        // Deux plateaux pour un seul volet : celui que le MJ dispose, rangé
        // sur son appareil, et celui que le joueur regarde, qui arrive du
        // serveur. Le même widget les dessine.
        GameMasterPanel.board => seat.isGameMaster
            ? BoardPanel(
                initialTokens: _tokens,
                initialMapId: _mapId,
                compact: compact,
                onTokensPersisted: _persistTokens,
                onMapPersisted: _persistMap,
              )
            : WatchedBoardPanel(
                sessionId: widget.sessionId,
                compact: compact,
              ),
        GameMasterPanel.characters => CharactersPanel(
            session: session,
            seat: seat,
            compact: compact,
          ),
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
    required this.seat,
    required this.active,
    required this.onSelect,
    required this.onExit,
  });

  final String tableName;
  final SessionSeat seat;
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
                  seat.isGameMaster ? 'Mode MJ' : 'À table',
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
          for (final panel in seat.panels)
            _RailEntry(
              panel: panel,
              label: seat.labelFor(panel),
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
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final GameMasterPanel panel;
  final String label;
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
                  label,
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
                  'Quitter',
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
  const _Header({
    required this.session,
    required this.seat,
    this.tableName,
    this.onExit,
  });

  final RemoteGameSession? session;
  final SessionSeat seat;

  /// Renseignés en disposition compacte seulement : sans rail, c'est l'entête
  /// qui dit où l'on est et par où l'on sort.
  final String? tableName;
  final VoidCallback? onExit;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: QBColors.leather800,
      padding: EdgeInsets.symmetric(
        horizontal: onExit == null ? QBSpace.s6 : QBSpace.s4,
        vertical: QBSpace.s4,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (tableName case final name?) ...[
                  Text(
                    seat.isGameMaster ? 'Mode MJ · $name' : 'À table · $name',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: QBType.game().copyWith(
                      fontWeight: QBType.weightBold,
                      fontSize: 11,
                      letterSpacing: 11 * QBType.trackingWide,
                      color: QBColors.gold500,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
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
          if (onExit case final exit?) ...[
            const SizedBox(width: QBSpace.s3),
            QBIconButton(
              icon: const Icon(
                LucideIcons.logOut,
                size: 16,
                color: QBColors.paper100,
              ),
              label: seat.isGameMaster ? 'Quitter le mode MJ' : 'Quitter',
              size: 36,
              variant: QBIconButtonVariant.solid,
              onPressed: exit,
            ),
          ],
        ],
      ),
    );
  }
}

/// Les volets en une ligne, quand il n'y a pas la place d'un rail.
///
/// Icônes seules : six libellés dans la largeur d'un téléphone seraient
/// illisibles. Seul le volet actif est nommé, et il prend pour cela toute la
/// place que les cinq autres ne réclament pas.
class _PanelTabs extends StatelessWidget {
  const _PanelTabs({
    required this.seat,
    required this.active,
    required this.onSelect,
  });

  final SessionSeat seat;
  final GameMasterPanel active;
  final ValueChanged<GameMasterPanel> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: QBColors.leather900,
      padding: const EdgeInsets.symmetric(
        horizontal: QBSpace.s2,
        vertical: QBSpace.s2,
      ),
      child: Row(
        children: [
          // Les deux volets d'un joueur méritent chacun leur nom : ce qui
          // forçait l'icône seule, c'est six volets sur la largeur d'un
          // téléphone, pas deux.
          for (final panel in seat.panels)
            if (panel == active || seat.panels.length <= 2)
              Expanded(
                child: _PanelTab(
                  panel: panel,
                  label: seat.labelFor(panel),
                  selected: panel == active,
                  named: true,
                  onTap: panel == active ? null : () => onSelect(panel),
                ),
              )
            else
              _PanelTab(
                panel: panel,
                label: seat.labelFor(panel),
                onTap: () => onSelect(panel),
              ),
        ],
      ),
    );
  }
}

class _PanelTab extends StatelessWidget {
  const _PanelTab({
    required this.panel,
    required this.label,
    this.selected = false,
    this.named = false,
    this.onTap,
  });

  /// Largeur d'un onglet au repos : de quoi viser l'icône sans plus. Six
  /// volets sur la largeur d'un téléphone ne laissent pas de quoi être plus
  /// généreux sans rogner le libellé de l'actif.
  static const double _restingWidth = 46;

  final GameMasterPanel panel;
  final String label;
  final bool selected;

  /// Nommé même au repos. Vrai pour les deux volets d'un joueur, qui ont la
  /// place ; faux chez le MJ, où seul l'actif se paie son libellé.
  final bool named;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? QBColors.ink900 : QBColors.paper200;

    return Semantics(
      selected: selected,
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: selected || named ? null : _restingWidth,
          height: 40,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: EdgeInsets.symmetric(
            horizontal: selected || named ? QBSpace.s3 : 0,
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(panel.icon, size: 17, color: foreground),
              if (selected || named) ...[
                const SizedBox(width: QBSpace.s2),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: QBType.game().copyWith(
                      fontWeight: QBType.weightSemibold,
                      fontSize: 12,
                      letterSpacing: 12 * QBType.trackingWide,
                      color: foreground,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
