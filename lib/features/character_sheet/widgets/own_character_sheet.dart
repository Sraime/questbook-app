import 'package:flutter/material.dart';

import '../../../design_system/tokens/colors.dart';
import '../../../design_system/tokens/spacing.dart';
import '../character_sheet_screen.dart';

/// Sa propre fiche, ouverte en pleine séance, et modifiable comme partout
/// ailleurs.
///
/// Une partie fait perdre des points de vie, dépenser de la magie et ramasser
/// des objets, et rien de tout cela n'attend la fin de la soirée. Quitter la
/// séance pour aller bouger une jauge, puis y revenir, se paie pendant que la
/// table attend — la fiche vient donc à la table.
///
/// Une feuille et non un écran : l'écran de séance est plein cadre, hors du
/// shell, et y naviguer par-dessus ferait perdre le volet, l'onglet et le
/// plateau qu'on regardait. On la referme et la partie est toujours là.
///
/// C'est [CharacterSheetBody], la même que sous `/perso/:id` — le lecteur
/// d'une jauge n'a pas à se demander laquelle des deux fiches il regarde.
/// Pour celle d'un camarade, voir `showAttendeeCharacterSheet`, qui ne montre
/// que ce que le serveur en dit et ne modifie rien.
Future<void> showOwnCharacterSheet(
  BuildContext context, {
  required String characterId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _OwnSheet(characterId: characterId),
  );
}

class _OwnSheet extends StatelessWidget {
  const _OwnSheet({required this.characterId});

  final String characterId;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, controller) => Container(
        decoration: const BoxDecoration(
          color: QBColors.paper100,
          borderRadius: BorderRadius.vertical(top: Radius.circular(QBRadius.lg)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: QBColors.borderHairline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: CharacterSheetBody(
                characterId: characterId,
                controller: controller,
                // Le clavier de l'inventaire monte par-dessus la feuille :
                // sans cette marge, le champ où l'on tape finit dessous.
                padding: EdgeInsets.fromLTRB(
                  18,
                  QBSpace.s4,
                  18,
                  24 + MediaQuery.viewInsetsOf(context).bottom,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
