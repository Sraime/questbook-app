import 'package:flutter/material.dart';

import '../../../design_system/components/qb_button.dart';
import '../../../design_system/components/qb_dialog.dart';
import '../../../design_system/components/qb_markdown.dart';
import '../../../design_system/tokens/spacing.dart';

/// Un indice, ouvert pour etre lu.
///
/// La meme fenetre des deux cotes de l'ecran : le MJ relit ce qu'il s'apprete
/// a partager, le joueur lit ce qu'il a trouve. Seuls les gestes du bas
/// changent, et le joueur n'en a aucun.
Future<void> showClueReaderDialog(
  BuildContext context, {
  required String title,
  required String contentMarkdown,
  VoidCallback? onShare,
  VoidCallback? onEdit,
}) {
  return showQBDialog(
    context: context,
    title: title,
    // Comme le formulaire, et pour la meme raison : c'est de la prose, et une
    // colonne de deux mots empeche de la lire.
    width: 560,
    builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // `QBDialog` ne fait pas defiler son contenu, et un indice n'a pas de
        // longueur convenue : sans cette borne, une page arrachee un peu
        // bavarde deborde de l'ecran.
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.6,
          ),
          child: SingleChildScrollView(child: QBMarkdown(contentMarkdown)),
        ),
        if (onShare != null || onEdit != null) ...[
          const SizedBox(height: QBSpace.s4),
          Row(
            children: [
              if (onShare != null)
                QBButton(
                  label: 'Partager',
                  size: QBButtonSize.sm,
                  onPressed: onShare,
                ),
              if (onShare != null && onEdit != null)
                const SizedBox(width: QBSpace.s2),
              if (onEdit != null)
                QBButton(
                  label: 'Modifier',
                  size: QBButtonSize.sm,
                  variant: QBButtonVariant.ghost,
                  onPressed: onEdit,
                ),
            ],
          ),
        ],
      ],
    ),
  );
}
