import 'rulebook_models.dart';

/// First chapter: how a roll is asked, read, compared, and later improved.
///
/// Rewritten from the 7th-edition keeper screen — numbers stay, wording does
/// not. Combat, wounds and madness wait for later chapters.
const chapterTests = RulebookChapter(
  id: 'tests',
  title: 'Tests',
  summary:
      'Niveaux de difficulté, dés bonus et malus, comparaison, '
      'développement et niveaux de vie.',
  sections: [
    RulebookSection(
      id: 'difficulte',
      title: 'Niveaux de difficulté',
      blocks: [
        RulebookParagraph(
          'Le gardien fixe le niveau avant le jet. On lance 1D100 : '
          'il faut obtenir un résultat inférieur ou égal au seuil.',
        ),
        RulebookTable(
          headers: ['Niveau', 'Seuil'],
          rows: [
            ['Normal', '≤ la compétence'],
            ['Difficile', '≤ la moitié'],
            ['Extrême', '≤ le cinquième'],
          ],
        ),
        RulebookParagraph(
          'Un succès à un niveau plus dur compte aussi pour les niveaux '
          'plus faciles. Une réussite extrême satisfait donc une demande '
          'normale ou difficile.',
        ),
        RulebookTable(
          headers: ['Résultat', 'Quand'],
          rows: [
            ['Réussite critique', '01'],
            [
              'Échec critique',
              '100, ou 96 à 100 si la compétence est sous 50',
            ],
          ],
        ),
        RulebookCallout(
          'Le lanceur de l’application traite aujourd’hui 01–05 comme '
          'critique et 96–100 comme échec critique, sans regarder la '
          'compétence. À la table, c’est la règle ci-dessus qui fait foi.',
        ),
      ],
    ),
    RulebookSection(
      id: 'des-bonus-malus',
      title: 'Dés bonus et malus',
      blocks: [
        RulebookParagraph(
          'Les circonstances ajoutent un dé des dizaines, pas un modificateur '
          'à la compétence. Le dé des unités reste unique.',
        ),
        RulebookBullets([
          'Dé bonus : on garde la dizaine la plus basse (le meilleur jet).',
          'Dé malus : on garde la dizaine la plus haute (le pire jet).',
          'Un bonus et un malus s’annulent avant le lancer.',
          'Deux dés du même type : on lance les deux dizaines et on garde '
              'la plus utile — ou la plus nuisible.',
        ]),
        RulebookCallout(
          'Au-delà de deux dés bonus ou de deux dés malus, l’écran de '
          'gardien s’arrête : le troisième n’apporte plus rien.',
          tone: RulebookCalloutTone.warning,
        ),
      ],
    ),
    RulebookSection(
      id: 'comparaison',
      title: 'Comparer les résultats',
      blocks: [
        RulebookParagraph(
          'Quand deux jets s’opposent, on compare d’abord le niveau de '
          'réussite, du plus fort au plus faible :',
        ),
        RulebookBullets([
          'critique, puis extrême, puis difficile, puis normal ;',
          'ensuite l’échec, puis l’échec critique.',
        ]),
        RulebookParagraph(
          'À niveau égal, la compétence la plus élevée l’emporte. Si les '
          'deux valeurs sont identiques, chacun relance.',
        ),
        RulebookParagraph(
          'On peut relancer un jet raté une seule fois (la « poussée »), '
          'pour la même action, en acceptant une conséquence plus grave '
          'si ça échoue encore. Pas de relance en combat, ni sur la '
          'Chance, ni sur le Mythe de Cthulhu.',
        ),
      ],
    ),
    RulebookSection(
      id: 'developpement',
      title: 'Phase de développement',
      blocks: [
        RulebookParagraph(
          'En fin de scénario, chaque compétence cochée — utilisée avec '
          'succès pendant l’aventure — a une chance de progresser.',
        ),
        RulebookBullets([
          'Lancer 1D100.',
          'Si le résultat dépasse la valeur actuelle, ou vaut 96 ou plus, '
              'la compétence augmente de 1D10.',
          'Le Mythe de Cthulhu ne progresse pas de cette façon : il ne '
              'monte que par la lecture et les rencontres.',
        ]),
      ],
    ),
    RulebookSection(
      id: 'niveaux-de-vie',
      title: 'Niveaux de vie',
      blocks: [
        RulebookParagraph(
          'Le Crédit décrit le train de vie, pas un compte en banque. '
          'Il fixe ce qu’un investigateur peut dépenser sans discuter, '
          'et le genre de toit qu’il a au-dessus de la tête.',
        ),
        RulebookTable(
          headers: ['Niveau', 'Crédit', 'Ordre d’idée'],
          rows: [
            ['Misérable', '0', 'À la rue, aucune dépense'],
            ['Pauvre', '1–9', 'Chambre meublée, le strict nécessaire'],
            ['Moyen', '10–49', 'Logement correct, vie simple'],
            ['Aisé', '50–89', 'Belle maison, automobile'],
            ['Riche', '90–98', 'Propriété, personnel'],
            ['Super riche', '99', 'Fortune affichée, yacht, avion'],
          ],
        ),
      ],
    ),
  ],
);
