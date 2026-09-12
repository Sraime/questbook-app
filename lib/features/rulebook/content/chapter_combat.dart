import 'rulebook_models.dart';

/// Second chapter: a fight round, from DEX order to armor.
///
/// Same deal as Tests — keeper-screen numbers, our wording. Wounds and
/// healing stay in Santé.
const chapterCombat = RulebookChapter(
  id: 'combat',
  title: 'Combat',
  summary: 'Corps à corps, à distance, feu automatique et armure.',
  sections: [
    RulebookSection(
      id: 'ordre',
      title: 'Ordre et surprise',
      blocks: [
        RulebookParagraph(
          'Un round, chacun agit une fois. On résout dans l’ordre de '
          'DEX décroissante. À DEX égale, l’arme la plus longue — ou le '
          'plus haut score d’arme — passe devant.',
        ),
        RulebookBullets([
          'Surprise : les attaquants jouent avant tout le monde. Les '
              'surpris ne peuvent ni esquiver ni rendre le coup à cette '
              'première salve.',
          'Après avoir attaqué, on peut encore choisir une réaction '
              '(esquive ou coup rendu) contre chaque attaque reçue.',
        ]),
      ],
    ),
    RulebookSection(
      id: 'melee',
      title: 'Résoudre une attaque',
      blocks: [
        RulebookParagraph(
          'Le défenseur choisit sa réaction avant le jet. On compare '
          'ensuite les niveaux de réussite, comme pour n’importe quel '
          'jet opposé.',
        ),
        RulebookTable(
          headers: ['Réaction', 'Jets', 'Qui blesse'],
          rows: [
            [
              'Aucune',
              'Attaque simple',
              'L’attaquant, s’il réussit',
            ],
            [
              'Esquive',
              'Combat vs Esquive',
              'L’attaquant, s’il fait mieux',
            ],
            [
              'Coup rendu',
              'Combat vs Combat',
              'Celui qui fait mieux',
            ],
          ],
        ),
        RulebookParagraph(
          'À niveau égal, la compétence la plus élevée l’emporte. Les '
          'dégâts se lancent tout de suite, moins l’armure.',
        ),
      ],
    ),
    RulebookSection(
      id: 'manoeuvres',
      title: 'Manœuvres et surnombre',
      blocks: [
        RulebookParagraph(
          'Désarmer, plaquer, bousculer : un jet de Combat dont la '
          'difficulté dépend de la Carrure (attaquant moins défenseur).',
        ),
        RulebookTable(
          headers: ['Écart de Carrure', 'Effet'],
          rows: [
            ['+3 ou plus', 'Réussite automatique'],
            ['+2', '1 dé bonus'],
            ['+1 ou 0', 'Normal'],
            ['−1', '1 dé malus'],
            ['−2', '2 dés malus'],
            ['−3 ou moins', 'Impossible'],
          ],
        ),
        RulebookBullets([
          'Face à plus d’un adversaire, 1 dé malus sur les jets de Combat '
              '(y compris le coup rendu).',
          'On ne rend le coup qu’à une attaque par round ; les suivantes '
              'ne peuvent plus qu’être esquivées — ou encaissées.',
        ]),
      ],
    ),
    RulebookSection(
      id: 'empale',
      title: 'Réussite extrême et empale',
      blocks: [
        RulebookParagraph(
          'Une arme perforante (la plupart des armes à feu, une lame '
          'en estoc) empale sur une réussite extrême — et donc aussi '
          'sur un 01.',
        ),
        RulebookBullets([
          'Dégâts : le maximum de l’arme, plus un jet normal des dés '
              'de l’arme, plus le bonus aux dégâts s’il s’applique.',
          'Une arme sans qualité « empale » inflige simplement le '
              'maximum de ses dés.',
        ]),
      ],
    ),
    RulebookSection(
      id: 'distance',
      title: 'Combat à distance',
      blocks: [
        RulebookParagraph(
          'La portée fixe le niveau de difficulté. Les circonstances '
          'ajoutent des dés bonus ou malus, elles ne changent pas le '
          'seuil.',
        ),
        RulebookTable(
          headers: ['Portée', 'Difficulté'],
          rows: [
            ['Bout portant (≤ 1/5 de la base)', '1 dé bonus'],
            ['Portée de base', 'Normal'],
            ['Longue (×2)', 'Difficile'],
            ['Extrême (×4)', 'Extrême'],
          ],
        ),
        RulebookTable(
          headers: ['Circonstance', 'Dé'],
          rows: [
            ['Visée (un round à viser)', '1 bonus'],
            ['Cible petite ou rapide', '1 malus'],
            ['Cible minuscule', '2 malus'],
            ['Couvert partiel / obscurité', '1 malus'],
            ['Couvert / nuit noire', '2 malus'],
            ['Tirer dans une mêlée', '1 malus'],
            ['Tireur ou cible en mouvement', '1 malus'],
          ],
        ),
      ],
    ),
    RulebookSection(
      id: 'auto',
      title: 'Feu automatique',
      blocks: [
        RulebookParagraph(
          'On annonce le nombre de balles, groupées par salves de 3. '
          'Chaque salve est un jet d’Arme à feu, à la difficulté de la '
          'portée.',
        ),
        RulebookTable(
          headers: ['Réussite', 'Touchés (par salve)'],
          rows: [
            ['Normale', '1'],
            ['Difficile', '2'],
            ['Extrême ou critique', '3'],
          ],
        ),
        RulebookCallout(
          'Si le jet est supérieur ou égal au seuil d’enrayement de '
          'l’arme, elle s’enraye — même quand le jet était une réussite. '
          'Il faudra un round et un jet de mécanique ou d’arme pour '
          'la remettre en batterie.',
          tone: RulebookCalloutTone.warning,
        ),
      ],
    ),
    RulebookSection(
      id: 'armure',
      title: 'Armure et bonus aux dégâts',
      blocks: [
        RulebookParagraph(
          'L’armure se retranche à chaque blessure, pas au total du '
          'round. Le bonus aux dégâts et la Carrure viennent de '
          'FOR + TAI.',
        ),
        RulebookTable(
          headers: ['Protection', 'Armure'],
          rows: [
            ['Manteau lourd, cuir', '1'],
            ['Casque', '2 (tête)'],
            ['Porte, carrosserie légère', '3'],
            ['Gilet pare-balles d’époque', '5'],
            ['Pare-balles moderne', '8'],
          ],
        ),
        RulebookTable(
          headers: ['FOR + TAI', 'Bonus', 'Carrure'],
          rows: [
            ['2–64', '−2', '−2'],
            ['65–84', '−1', '−1'],
            ['85–124', 'aucun', '0'],
            ['125–164', '+1D4', '+1'],
            ['165–204', '+1D6', '+2'],
            ['205–284', '+2D6', '+3'],
            ['puis +80', '+1D6', '+1'],
          ],
        ),
      ],
    ),
  ],
);
