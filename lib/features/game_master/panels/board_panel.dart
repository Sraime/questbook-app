import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:uuid/uuid.dart';

import '../../../design_system/components/qb_icon_button.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/effects.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';
import '../models/board_catalog.dart';
import '../models/board_token.dart';
import '../widgets/board_token_view.dart';

/// La carte, les pions posés dessus, et le tiroir d'où on les tire.
///
/// Le plateau est le seul propriétaire de ses pions pendant qu'il est à
/// l'écran. Il ne remonte l'état que lorsqu'il vaut la peine d'être
/// enregistré, jamais pendant un glissement : faire remonter chaque image
/// jusqu'à l'écran MJ reconstruisait le rail et le tiroir soixante fois par
/// seconde, et le pion traînait derrière le doigt.
class BoardPanel extends StatefulWidget {
  const BoardPanel({
    super.key,
    required this.initialTokens,
    required this.initialMapId,
    required this.onTokensPersisted,
    required this.onMapPersisted,
  });

  final List<BoardToken> initialTokens;
  final String? initialMapId;
  final ValueChanged<List<BoardToken>> onTokensPersisted;
  final ValueChanged<String> onMapPersisted;

  @override
  State<BoardPanel> createState() => _BoardPanelState();
}

class _BoardPanelState extends State<BoardPanel> {
  /// Taille de l'aperçu qui suit le doigt, en points.
  static const double _feedbackSide = 60;
  static const _uuid = Uuid();

  final _boardKey = GlobalKey();

  late final _tokens = ValueNotifier<List<BoardToken>>(widget.initialTokens);
  final _selectedId = ValueNotifier<String?>(null);
  final _resizing = ValueNotifier<bool>(false);

  late BoardMap _map = boardMapById(widget.initialMapId);

  @override
  void dispose() {
    _tokens.dispose();
    _selectedId.dispose();
    _resizing.dispose();
    super.dispose();
  }

  void _persist() => widget.onTokensPersisted(_tokens.value);

  void _select(String? id) {
    _selectedId.value = id;
    if (id == null) _resizing.value = false;
  }

  void _drop(BoardAsset asset, Offset globalTopLeft) {
    final box = _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;

    // `details.offset` désigne le coin de l'aperçu, pas le doigt : on vise son
    // centre, sinon le pion se pose en haut à gauche de ce qu'on visait.
    final centre =
        globalTopLeft + const Offset(_feedbackSide / 2, _feedbackSide / 2);
    final local = box.globalToLocal(centre);

    _tokens.value = [
      ..._tokens.value,
      BoardToken(
        id: _uuid.v4(),
        kind: asset.kind,
        color: asset.color,
        x: (local.dx / box.size.width).clamp(0.0, 1.0),
        y: (local.dy / box.size.height).clamp(0.0, 1.0),
      ),
    ];
    _persist();
  }

  void _update(BoardToken token) {
    _tokens.value = [
      for (final existing in _tokens.value)
        existing.id == token.id ? token : existing,
    ];
  }

  void _remove(String id) {
    _select(null);
    _tokens.value = [
      for (final token in _tokens.value)
        if (token.id != id) token,
    ];
    _persist();
  }

  void _selectMap(BoardMap map) {
    setState(() => _map = map);
    widget.onMapPersisted(map.id);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(QBSpace.s5),
            child: LayoutBuilder(
              builder: (context, constraints) {
                var width = constraints.maxWidth;
                var height = width / _map.aspectRatio;
                if (height > constraints.maxHeight) {
                  height = constraints.maxHeight;
                  width = height * _map.aspectRatio;
                }
                return Center(
                  child: SizedBox(
                    key: _boardKey,
                    width: width,
                    height: height,
                    child: _Board(
                      map: _map,
                      tokens: _tokens,
                      selectedId: _selectedId,
                      resizing: _resizing,
                      onSelect: _select,
                      onChanged: _update,
                      onCommit: _persist,
                      onRemove: _remove,
                      onToggleResize: () => _resizing.value = !_resizing.value,
                      onDrop: _drop,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        _AssetDrawer(
          feedbackSide: _feedbackSide,
          selectedMapId: _map.id,
          onSelectMap: _selectMap,
        ),
      ],
    );
  }
}

class _Board extends StatelessWidget {
  const _Board({
    required this.map,
    required this.tokens,
    required this.selectedId,
    required this.resizing,
    required this.onSelect,
    required this.onChanged,
    required this.onCommit,
    required this.onRemove,
    required this.onToggleResize,
    required this.onDrop,
  });

  final BoardMap map;
  final ValueListenable<List<BoardToken>> tokens;
  final ValueListenable<String?> selectedId;
  final ValueListenable<bool> resizing;
  final ValueChanged<String?> onSelect;
  final ValueChanged<BoardToken> onChanged;
  final VoidCallback onCommit;
  final ValueChanged<String> onRemove;
  final VoidCallback onToggleResize;
  final void Function(BoardAsset asset, Offset globalTopLeft) onDrop;

  @override
  Widget build(BuildContext context) {
    return DragTarget<BoardAsset>(
      onAcceptWithDetails: (details) => onDrop(details.data, details.offset),
      builder: (context, candidate, rejected) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            final reference = math.min(width, height);

            return DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                  color:
                      candidate.isEmpty ? QBColors.leather800 : QBColors.gold500,
                  width: 3,
                ),
                boxShadow: QBShadows.paperLg,
              ),
              // Le seul morceau de l'écran reconstruit pendant un geste. Les
              // pions restent des enfants directs de cette pile : les isoler
              // dans une pile à eux leur faisait perdre le toucher.
              child: ListenableBuilder(
                listenable: Listenable.merge([tokens, selectedId, resizing]),
                builder: (context, _) {
                  final selected = selectedId.value;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Isolée des pions : sans cette barrière, déplacer un
                      // pion repeindrait aussi la carte à chaque image.
                      Positioned.fill(
                        child: RepaintBoundary(child: _MapSurface(map: map)),
                      ),
                      // Toucher la carte à côté d'un pion le désélectionne :
                      // sans cela, l'encadré doré reste et le MJ croit à un
                      // blocage.
                      Positioned.fill(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => onSelect(null),
                        ),
                      ),
                      for (final token in tokens.value)
                        _PlacedToken(
                          token: token,
                          boardWidth: width,
                          boardHeight: height,
                          reference: reference,
                          selected: token.id == selected,
                          resizing: resizing.value && token.id == selected,
                          onSelect: () => onSelect(token.id),
                          onChanged: onChanged,
                          onCommit: onCommit,
                          onRemove: () => onRemove(token.id),
                          onToggleResize: onToggleResize,
                        ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

class _MapSurface extends StatelessWidget {
  const _MapSurface({required this.map});

  final BoardMap map;

  @override
  Widget build(BuildContext context) {
    final asset = map.asset;
    if (asset != null) return Image.asset(asset, fit: BoxFit.fill);
    return const ColoredBox(
      color: QBColors.paper100,
      child: CustomPaint(painter: _GridPainter()),
    );
  }
}

/// La grille de la carte vierge. Douze cases dans la largeur : assez pour
/// situer des personnages les uns par rapport aux autres, pas assez pour
/// transformer le plateau en damier illisible.
class _GridPainter extends CustomPainter {
  const _GridPainter();

  static const _columns = 12;

  @override
  void paint(Canvas canvas, Size size) {
    final step = size.width / _columns;
    final line = Paint()
      ..color = QBColors.borderHairline
      ..strokeWidth = 1;

    for (var x = step; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
    for (var y = step; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => false;
}

class _PlacedToken extends StatelessWidget {
  const _PlacedToken({
    required this.token,
    required this.boardWidth,
    required this.boardHeight,
    required this.reference,
    required this.selected,
    required this.resizing,
    required this.onSelect,
    required this.onChanged,
    required this.onCommit,
    required this.onRemove,
    required this.onToggleResize,
  });

  static const double _handleSide = 18;
  static const double _actionsHeight = 40;

  final BoardToken token;
  final double boardWidth;
  final double boardHeight;

  /// Le plus petit côté de la carte : la taille d'un pion s'y rapporte pour
  /// qu'il garde ses proportions quelle que soit la fenêtre.
  final double reference;
  final bool selected;
  final bool resizing;
  final VoidCallback onSelect;
  final ValueChanged<BoardToken> onChanged;
  final VoidCallback onCommit;
  final VoidCallback onRemove;
  final VoidCallback onToggleResize;

  @override
  Widget build(BuildContext context) {
    final side = token.size * reference;
    final left = token.x * boardWidth - side / 2;
    final top = token.y * boardHeight - side / 2;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: left,
          top: top,
          width: side,
          height: side,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onSelect,
            onPanStart: (_) => onSelect(),
            onPanUpdate: (details) => onChanged(
              token.copyWith(
                x: (token.x + details.delta.dx / boardWidth).clamp(0.0, 1.0),
                y: (token.y + details.delta.dy / boardHeight).clamp(0.0, 1.0),
              ),
            ),
            onPanEnd: (_) => onCommit(),
            child: BoardTokenView.of(token, selected: selected),
          ),
        ),
        if (selected) ..._actions(side, left, top),
        if (resizing) ..._handles(side, left, top),
      ],
    );
  }

  List<Widget> _actions(double side, double left, double top) {
    // Au-dessus du pion, sauf s'il touche le haut de la carte : la barre
    // passe alors dessous plutôt que de sortir du cadre.
    final above = top - _actionsHeight - 6;
    final y = above >= 0 ? above : top + side + 6;

    return [
      Positioned(
        left: (left + side / 2 - 40).clamp(0.0, boardWidth - 80),
        top: y,
        child: Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: QBColors.leather900,
            borderRadius: BorderRadius.circular(QBRadius.md),
            border: Border.all(color: QBColors.gold500, width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              QBIconButton(
                icon: Icon(
                  LucideIcons.scaling,
                  size: 14,
                  color: resizing ? QBColors.ink900 : QBColors.paper100,
                ),
                label: 'Redimensionner le pion',
                size: 28,
                variant: resizing
                    ? QBIconButtonVariant.outline
                    : QBIconButtonVariant.solid,
                onPressed: onToggleResize,
              ),
              const SizedBox(width: 4),
              QBIconButton(
                icon: const Icon(
                  LucideIcons.trash2,
                  size: 14,
                  color: QBColors.paper100,
                ),
                label: 'Retirer le pion du plateau',
                size: 28,
                variant: QBIconButtonVariant.solid,
                onPressed: onRemove,
              ),
            ],
          ),
        ),
      ),
    ];
  }

  List<Widget> _handles(double side, double left, double top) {
    const corners = [
      Offset(-1, -1),
      Offset(1, -1),
      Offset(-1, 1),
      Offset(1, 1),
    ];

    return [
      for (final corner in corners)
        Positioned(
          left: left + (corner.dx > 0 ? side : 0) - _handleSide / 2,
          top: top + (corner.dy > 0 ? side : 0) - _handleSide / 2,
          width: _handleSide,
          height: _handleSide,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanUpdate: (details) {
              // Le pion grandit depuis son centre : tirer une poignée d'un
              // point en ajoute deux au côté.
              final growth =
                  details.delta.dx * corner.dx + details.delta.dy * corner.dy;
              final next = (token.size + 2 * growth / reference)
                  .clamp(BoardToken.minSize, BoardToken.maxSize);
              onChanged(token.copyWith(size: next));
            },
            onPanEnd: (_) => onCommit(),
            child: Container(
              decoration: BoxDecoration(
                color: QBColors.gold500,
                border: Border.all(color: QBColors.leather900, width: 2),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
    ];
  }
}

/// Le tiroir : la carte à afficher, un champ de recherche, puis les rayons
/// de pions.
class _AssetDrawer extends StatefulWidget {
  const _AssetDrawer({
    required this.feedbackSide,
    required this.selectedMapId,
    required this.onSelectMap,
  });

  final double feedbackSide;
  final String selectedMapId;
  final ValueChanged<BoardMap> onSelectMap;

  @override
  State<_AssetDrawer> createState() => _AssetDrawerState();
}

class _AssetDrawerState extends State<_AssetDrawer> {
  final _search = TextEditingController();

  /// Les rayons repliés. Tout est ouvert au départ ; c'est en grandissant que
  /// le catalogue rendra le pliage utile.
  final _collapsed = <String>{};

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text;
    final sections = filterBoardAssets(query);
    // Une recherche déplie : chercher pour tomber sur un rayon fermé serait
    // une deuxième énigme.
    final searching = foldForSearch(query).isNotEmpty;

    return Container(
      width: 280,
      decoration: const BoxDecoration(
        color: QBColors.paper200,
        border: Border(left: BorderSide(color: QBColors.borderStrong, width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              QBSpace.s3,
              QBSpace.s4,
              QBSpace.s3,
              QBSpace.s3,
            ),
            child: _SearchField(
              controller: _search,
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                QBSpace.s3,
                0,
                QBSpace.s3,
                QBSpace.s6,
              ),
              children: [
                if (!searching) ...[
                  _DrawerSection(
                    title: 'Carte',
                    collapsed: _collapsed.contains('Carte'),
                    onToggle: () => _toggle('Carte'),
                    children: [
                      for (final map in boardMaps)
                        _MapTile(
                          map: map,
                          selected: map.id == widget.selectedMapId,
                          onTap: () => widget.onSelectMap(map),
                        ),
                    ],
                  ),
                  const _Hint(
                    'Fais glisser un pion sur la carte. Touche-le ensuite '
                    'pour le redimensionner ou le retirer.',
                  ),
                ],
                if (sections.isEmpty)
                  const _Hint('Aucun pion ne porte ce nom.')
                else
                  for (final section in sections)
                    _DrawerSection(
                      title: section.title,
                      collapsed:
                          !searching && _collapsed.contains(section.title),
                      onToggle: () => _toggle(section.title),
                      children: [
                        for (final asset in section.assets)
                          _AssetTile(
                            asset: asset,
                            feedbackSide: widget.feedbackSide,
                          ),
                      ],
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _toggle(String title) {
    setState(() {
      if (!_collapsed.remove(title)) _collapsed.add(title);
    });
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: QBType.body().copyWith(
        fontSize: QBType.sm,
        color: QBColors.ink900,
      ),
      cursorColor: QBColors.ink900,
      decoration: InputDecoration(
        isDense: true,
        hintText: 'Rechercher un pion…',
        hintStyle: QBType.body().copyWith(
          fontSize: QBType.sm,
          color: QBColors.textMuted,
        ),
        prefixIcon: const Icon(
          LucideIcons.search,
          size: 16,
          color: QBColors.ink500,
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 34),
        suffixIcon: controller.text.isEmpty
            ? null
            : GestureDetector(
                onTap: () {
                  controller.clear();
                  onChanged('');
                },
                child: const Icon(
                  LucideIcons.x,
                  size: 16,
                  color: QBColors.ink500,
                ),
              ),
        suffixIconConstraints: const BoxConstraints(minWidth: 30),
        filled: true,
        fillColor: QBColors.surfaceRaised,
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(QBRadius.sm),
          borderSide: const BorderSide(color: QBColors.borderStrong, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(QBRadius.sm),
          borderSide: const BorderSide(color: QBColors.borderStrong, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(QBRadius.sm),
          borderSide: const BorderSide(color: QBColors.accentFocus, width: 2),
        ),
      ),
    );
  }
}

class _DrawerSection extends StatelessWidget {
  const _DrawerSection({
    required this.title,
    required this.collapsed,
    required this.onToggle,
    required this.children,
  });

  final String title;
  final bool collapsed;
  final VoidCallback onToggle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: QBSpace.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            expanded: !collapsed,
            button: true,
            // Sinon le rayon entier se lit d'un bloc : « Personnages, Joueur
            // rouge, Joueur rouge… » au lieu d'un titre qu'on peut replier.
            container: true,
            child: GestureDetector(
              onTap: onToggle,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: QBSpace.s2),
                child: Row(
                  children: [
                    Icon(
                      collapsed
                          ? LucideIcons.chevronRight
                          : LucideIcons.chevronDown,
                      size: 15,
                      color: QBColors.leather800,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        title,
                        style: QBType.game().copyWith(
                          fontWeight: QBType.weightSemibold,
                          fontSize: 11,
                          letterSpacing: 11 * QBType.trackingWide,
                          color: QBColors.leather800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (!collapsed)
            LayoutBuilder(
              builder: (context, constraints) {
                // Deux vignettes par ligne au minimum : une seule obligeait à
                // dérouler tout le tiroir pour voir quatre pions.
                const gap = QBSpace.s2;
                final columns =
                    math.max(2, (constraints.maxWidth / 150).floor());
                final side =
                    (constraints.maxWidth - gap * (columns - 1)) / columns;

                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final child in children)
                      SizedBox(width: side, child: child),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: QBSpace.s4),
      child: Text(
        text,
        style: QBType.body().copyWith(
          fontSize: QBType.xs,
          color: QBColors.ink600,
        ),
      ),
    );
  }
}

class _MapTile extends StatelessWidget {
  const _MapTile({
    required this.map,
    required this.selected,
    required this.onTap,
  });

  final BoardMap map;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final asset = map.asset;

    return Semantics(
      selected: selected,
      button: true,
      container: true,
      excludeSemantics: true,
      label: 'Carte ${map.label}',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: QBColors.paper50,
            border: Border.all(
              color: selected ? QBColors.gold500 : QBColors.borderDefault,
              width: selected ? 3 : 1,
            ),
            borderRadius: BorderRadius.circular(QBRadius.md),
          ),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(QBRadius.xs),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: asset == null
                      ? const ColoredBox(
                          color: QBColors.paper200,
                          child: CustomPaint(painter: _GridPainter()),
                        )
                      : Image.asset(asset, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                map.label,
                textAlign: TextAlign.center,
                style: QBType.body().copyWith(
                  fontSize: QBType.xs,
                  color: QBColors.ink700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssetTile extends StatelessWidget {
  const _AssetTile({required this.asset, required this.feedbackSide});

  final BoardAsset asset;
  final double feedbackSide;

  @override
  Widget build(BuildContext context) {
    final preview = BoardTokenView(kind: asset.kind, color: asset.color);

    return Draggable<BoardAsset>(
      data: asset,
      // L'aperçu se centre sous le doigt, sinon le MJ vise un endroit et le
      // pion se pose à côté.
      dragAnchorStrategy: (_, _, _) =>
          Offset(feedbackSide / 2, feedbackSide / 2),
      feedback: SizedBox(
        width: feedbackSide,
        height: feedbackSide,
        child: Opacity(opacity: 0.85, child: preview),
      ),
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
              SizedBox(width: 34, height: 34, child: preview),
              const SizedBox(height: QBSpace.s2),
              Text(
                asset.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: QBType.body().copyWith(
                  fontSize: QBType.xs,
                  color: QBColors.ink700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
