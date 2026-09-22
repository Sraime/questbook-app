import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';

/// Une ligne de menu : son picto, ce qu'elle fait, et si elle est de celles
/// qu'on regrette.
class QBMenuEntry {
  const QBMenuEntry({
    required this.icon,
    required this.label,
    required this.onSelected,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onSelected;

  /// Écrite en rouge : retirer quelqu'un, signaler, dissoudre.
  final bool danger;
}

/// Les trois points d'un élément de liste. Replier deux gestes voisins
/// derrière un seul point d'entrée vaut mieux que les poser côte à côte :
/// des cibles de trente points qui se ressemblent se pressent l'une pour
/// l'autre.
class QBMenu extends StatelessWidget {
  const QBMenu({
    super.key,
    required this.tooltip,
    required this.entries,
    this.iconSize = 18,
  });

  /// Ce que lit une synthèse vocale, et ce par quoi un test trouve le menu.
  final String tooltip;

  final List<QBMenuEntry> entries;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<VoidCallback>(
      tooltip: tooltip,
      icon: Icon(
        LucideIcons.ellipsisVertical,
        size: iconSize,
        color: QBColors.ink500,
      ),
      padding: EdgeInsets.zero,
      color: QBColors.paper50,
      // Les libellés par défaut plafonnent à 280 points, et « Désigner comme
      // MJ » y tient de justesse selon la police chargée.
      constraints: const BoxConstraints(minWidth: 180, maxWidth: 320),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(QBRadius.md),
        side: const BorderSide(color: QBColors.borderStrong, width: 2),
      ),
      onSelected: (action) => action(),
      itemBuilder: (context) => [
        for (final entry in entries)
          PopupMenuItem(
            value: entry.onSelected,
            child: _Line(entry: entry),
          ),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.entry});

  final QBMenuEntry entry;

  @override
  Widget build(BuildContext context) {
    final color = entry.danger ? QBColors.semanticDanger : QBColors.ink800;

    return Row(
      children: [
        Icon(entry.icon, size: 16, color: color),
        const SizedBox(width: QBSpace.s2),
        Flexible(
          child: Text(
            entry.label,
            style: QBType.body().copyWith(fontSize: QBType.sm, color: color),
          ),
        ),
      ],
    );
  }
}
