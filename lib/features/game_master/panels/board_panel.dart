import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../design_system/components/qb_icon_button.dart';
import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/effects.dart';
import '../../../design_system/tokens/spacing.dart';
import '../../../design_system/tokens/typography.dart';
import '../models/board_token.dart';
import '../widgets/board_token_view.dart';

/// Le seul fond de carte livré pour l'instant. Le tiroir en annonce d'autres
/// pour que le MJ voie où ils atterriront ; #39 les fera venir du back.
const _mapAsset = 'assets/board/manoir-clairiere.jpg';
const _mapAspectRatio = 1312 / 1199;

/// Ce qu'on attrape dans le tiroir et qu'on lâche sur la carte.
class _PaletteItem {
  const _PaletteItem(this.kind, this.color);

  final BoardTokenKind kind;
  final BoardTokenColor color;
}

/// La carte, les pions posés dessus, et le tiroir d'où on les tire.
class BoardPanel extends StatefulWidget {
  const BoardPanel({
    super.key,
    required this.tokens,
    required this.onAdd,
    required this.onChanged,
    required this.onCommit,
    required this.onRemove,
  });

  final List<BoardToken> tokens;

  /// Position exprimée en fractions de la carte, entre 0 et 1.
  final void Function(BoardTokenKind kind, BoardTokenColor color, Offset at)
      onAdd;

  /// Pendant un glissement : redessiner sans écrire sur le disque.
  final ValueChanged<BoardToken> onChanged;

  /// Fin du geste : c'est maintenant que l'état mérite d'être enregistré.
  final VoidCallback onCommit;
  final ValueChanged<String> onRemove;

  @override
  State<BoardPanel> createState() => _BoardPanelState();
}

class _BoardPanelState extends State<BoardPanel> {
  /// Taille de l'aperçu qui suit le doigt, en points.
  static const double _feedbackSide = 60;

  final _boardKey = GlobalKey();

  String? _selectedId;
  bool _resizing = false;

  void _select(String? id) {
    setState(() {
      _selectedId = id;
      if (id == null) _resizing = false;
    });
  }

  void _drop(_PaletteItem item, Offset globalTopLeft) {
    final box = _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;

    // `details.offset` désigne le coin de l'aperçu, pas le doigt : on vise son
    // centre, sinon le pion se pose en haut à gauche de ce qu'on visait.
    final centre = globalTopLeft +
        const Offset(_feedbackSide / 2, _feedbackSide / 2);
    final local = box.globalToLocal(centre);

    widget.onAdd(
      item.kind,
      item.color,
      Offset(
        (local.dx / box.size.width).clamp(0.0, 1.0),
        (local.dy / box.size.height).clamp(0.0, 1.0),
      ),
    );
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
                var height = width / _mapAspectRatio;
                if (height > constraints.maxHeight) {
                  height = constraints.maxHeight;
                  width = height * _mapAspectRatio;
                }
                return Center(
                  child: SizedBox(
                    key: _boardKey,
                    width: width,
                    height: height,
                    child: _Board(
                      tokens: widget.tokens,
                      selectedId: _selectedId,
                      resizing: _resizing,
                      onSelect: _select,
                      onChanged: widget.onChanged,
                      onCommit: widget.onCommit,
                      onRemove: (id) {
                        _select(null);
                        widget.onRemove(id);
                      },
                      onToggleResize: () =>
                          setState(() => _resizing = !_resizing),
                      onDrop: _drop,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const _Palette(feedbackSide: _feedbackSide),
      ],
    );
  }
}

class _Board extends StatelessWidget {
  const _Board({
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

  final List<BoardToken> tokens;
  final String? selectedId;
  final bool resizing;
  final ValueChanged<String?> onSelect;
  final ValueChanged<BoardToken> onChanged;
  final VoidCallback onCommit;
  final ValueChanged<String> onRemove;
  final VoidCallback onToggleResize;
  final void Function(_PaletteItem item, Offset globalTopLeft) onDrop;

  @override
  Widget build(BuildContext context) {
    return DragTarget<_PaletteItem>(
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
                  color: candidate.isEmpty
                      ? QBColors.leather800
                      : QBColors.gold500,
                  width: 3,
                ),
                boxShadow: QBShadows.paperLg,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: Image.asset(_mapAsset, fit: BoxFit.fill),
                  ),
                  // Toucher la carte à côté d'un pion le désélectionne : sans
                  // cela, l'encadré doré reste et le MJ croit à un blocage.
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onSelect(null),
                    ),
                  ),
                  for (final token in tokens)
                    _PlacedToken(
                      token: token,
                      boardWidth: width,
                      boardHeight: height,
                      reference: reference,
                      selected: token.id == selectedId,
                      resizing: resizing && token.id == selectedId,
                      onSelect: () => onSelect(token.id),
                      onChanged: onChanged,
                      onCommit: onCommit,
                      onRemove: () => onRemove(token.id),
                      onToggleResize: onToggleResize,
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
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

class _Palette extends StatelessWidget {
  const _Palette({required this.feedbackSide});

  final double feedbackSide;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 236,
      decoration: const BoxDecoration(
        color: QBColors.paper200,
        border: Border(left: BorderSide(color: QBColors.borderStrong, width: 2)),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          QBSpace.s3,
          QBSpace.s4,
          QBSpace.s3,
          QBSpace.s6,
        ),
        children: [
          const _PaletteHint(),
          const SizedBox(height: QBSpace.s4),
          _section('Personnages', [
            for (final color in BoardTokenColor.values)
              _PaletteItem(BoardTokenKind.character, color),
          ]),
          _section('Environnement', [
            for (final color in BoardTokenColor.values)
              _PaletteItem(BoardTokenKind.environment, color),
          ]),
          _section('Effets', [
            for (final color in BoardTokenColor.values)
              _PaletteItem(BoardTokenKind.effect, color),
          ]),
          _section('Zones', const [
            _PaletteItem(BoardTokenKind.zoneDisc, BoardTokenColor.yellow),
            _PaletteItem(BoardTokenKind.zoneSquare, BoardTokenColor.yellow),
          ]),
        ],
      ),
    );
  }

  Widget _section(String title, List<_PaletteItem> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: QBSpace.s5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: QBSpace.s2),
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
          Wrap(
            spacing: QBSpace.s2,
            runSpacing: QBSpace.s2,
            children: [
              for (final item in items)
                _PaletteTile(item: item, feedbackSide: feedbackSide),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaletteHint extends StatelessWidget {
  const _PaletteHint();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Fais glisser un pion sur la carte. Touche-le ensuite pour le '
      'redimensionner ou le retirer.',
      style: QBType.body().copyWith(
        fontSize: QBType.xs,
        color: QBColors.ink600,
      ),
    );
  }
}

class _PaletteTile extends StatelessWidget {
  const _PaletteTile({required this.item, required this.feedbackSide});

  static const double _tileSide = 100;

  final _PaletteItem item;
  final double feedbackSide;

  @override
  Widget build(BuildContext context) {
    final preview = BoardTokenView(kind: item.kind, color: item.color);

    return Draggable<_PaletteItem>(
      data: item,
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
        label: '${_kindLabel(item.kind)} ${_colorLabel(item.color)}',
        child: Container(
          width: _tileSide,
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
                _label(item),
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

  static String _label(_PaletteItem item) => item.kind.isZone
      ? _kindLabel(item.kind)
      : _colorLabel(item.color);

  static String _kindLabel(BoardTokenKind kind) => switch (kind) {
        BoardTokenKind.character => 'Personnage',
        BoardTokenKind.environment => 'Décor',
        BoardTokenKind.effect => 'Effet',
        BoardTokenKind.zoneDisc => 'Disque',
        BoardTokenKind.zoneSquare => 'Carré',
      };

  static String _colorLabel(BoardTokenColor color) => switch (color) {
        BoardTokenColor.red => 'Rouge',
        BoardTokenColor.green => 'Vert',
        BoardTokenColor.blue => 'Bleu',
        BoardTokenColor.yellow => 'Jaune',
      };
}
