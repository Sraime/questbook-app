import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';

/// Du texte que quelqu'un a ecrit en markdown, rendu sur le parchemin.
///
/// Ne du scenario, ou l'auteur met en forme ce qu'il publie ; le MJ compose
/// ses indices dans la meme langue, et le joueur les lit dans le meme rendu.
/// Un troisieme consommateur, c'est le moment de quitter l'ecran ou il etait
/// ne : le markdown de l'app ne doit avoir qu'une apparence.
class QBMarkdown extends StatelessWidget {
  const QBMarkdown(this.data, {super.key});

  final String data;

  @override
  Widget build(BuildContext context) {
    final body = QBType.body().copyWith(
      fontSize: QBType.sm,
      color: QBColors.ink800,
      height: 1.45,
    );

    return MarkdownBody(
      data: data,
      selectable: true,
      styleSheet: MarkdownStyleSheet(
        p: body,
        h2: QBType.game().copyWith(
          fontWeight: QBType.weightSemibold,
          fontSize: 16,
          color: QBColors.ink900,
        ),
        h3: QBType.game().copyWith(
          fontWeight: QBType.weightSemibold,
          fontSize: 14,
          color: QBColors.ink900,
        ),
        listBullet: body,
        blockquote: body.copyWith(fontStyle: FontStyle.italic),
        // Le bleu que `flutter_markdown` pose par defaut sur une citation
        // tache le parchemin. Un filet de cuir a gauche dit la meme chose et
        // se tait.
        blockquoteDecoration: const BoxDecoration(
          color: QBColors.paper100,
          border: Border(
            left: BorderSide(color: QBColors.leather300, width: 3),
          ),
        ),
        blockquotePadding: const EdgeInsets.fromLTRB(
          QBSpace.s3,
          QBSpace.s2,
          QBSpace.s3,
          QBSpace.s2,
        ),
        strong: body.copyWith(fontWeight: QBType.weightSemibold),
      ),
    );
  }
}
