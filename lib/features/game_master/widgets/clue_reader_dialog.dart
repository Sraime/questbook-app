import 'package:flutter/material.dart';

import '../../../design_system/components/qb_dialog.dart';
import '../../../design_system/components/qb_markdown.dart';
import '../../../design_system/tokens/spacing.dart';

/// Un indice, ouvert pour etre lu.
///
/// La meme fenetre des deux cotes de l'ecran : le MJ relit ce qu'il s'apprete
/// a partager, le joueur lit ce qu'il a trouve. Seul le bas change — c'est de
/// la que le MJ prend tous les gestes qui concernent l'indice, et le joueur
/// n'en a aucun, donc [actions] reste nul chez lui.
Future<void> showClueReaderDialog(
  BuildContext context, {
  required String title,
  required String contentMarkdown,
  Widget? actions,
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
        if (actions != null) ...[
          const SizedBox(height: QBSpace.s4),
          actions,
        ],
      ],
    ),
  );
}
