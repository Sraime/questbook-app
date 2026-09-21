import 'rulebook_models.dart';

/// Fourth chapter: sanity loss, bouts of madness, and what they leave behind.
///
/// SAN starts at POW, matching the universe config. The 1D10 bout table is
/// the keeper-screen list, rewritten.
const chapterFolie = RulebookChapter(
  id: 'folie',
  title: 'Folie',
  summary: 'Santé mentale, folie passagère, phobies et manies.',
  sections: [
    RulebookSection(
      id: 'san',
      title: 'Santé mentale',
      blocks: [
        RulebookParagraph(
          'La SAN de départ est égale au Pouvoir — c’est le chiffre de '
          'la fiche. Face à l’horreur, on lance 1D100 sous la SAN '
          'actuelle. Le gardien annonce deux pertes : le petit chiffre '
          'si le jet réussit, le grand s’il échoue.',
        ),
        RulebookBullets([
          'La SAN ne peut jamais dépasser 99 − Mythe de Cthulhu.',
          'À 0 SAN, l’investigateur est perdu pour la partie : folie '
              'permanente.',
        ]),
      ],
    ),
    RulebookSection(
      id: 'seuils',
      title: 'Les trois folies',
      blocks: [
        RulebookTable(
          headers: ['Folie', 'Déclencheur', 'Durée'],
          rows: [
            [
              'Passagère',
              '5 SAN ou plus perdus sur un seul jet',
              '1D10 heures',
            ],
            [
              'Indéfinie',
              'Un cinquième de la SAN actuelle perdu dans la même journée',
              'Jusqu’au traitement',
            ],
            [
              'Permanente',
              'SAN à 0',
              'Fin de l’investigateur',
            ],
          ],
        ),
        RulebookParagraph(
          'La folie passagère commence toujours par une crise, puis '
          'laisse un trouble le temps qu’il reste. La folie indéfinie '
          'demande un asile — ou des semaines de Psychanalyse au calme.',
        ),
      ],
    ),
    RulebookSection(
      id: 'crise',
      title: 'Crise de folie',
      blocks: [
        RulebookParagraph(
          'Devant les autres investigateurs, la crise dure 1D10 rounds. '
          'Seul, ou une fois la scène close, elle dure 1D10 heures. '
          'Lancer 1D10 :',
        ),
        RulebookTable(
          headers: ['1D10', 'Crise'],
          rows: [
            ['1', 'Amnésie — plus rien de la dernière heure, ou plus'],
            ['2', 'Infirmité — un membre, la vue ou la voix lâche'],
            ['3', 'Violence — contre la menace, un allié, ou soi'],
            ['4', 'Paranoïa — tout le monde en veut à l’investigateur'],
            ['5', 'Personne chère — il faut la rejoindre, coûte que coûte'],
            ['6', 'Évanouissement — hors combat pour la durée'],
            ['7', 'Fuite — courir, se cacher, ne plus regarder'],
            ['8', 'Hystérie — rires, sanglots, mots sans suite'],
            ['9', 'Phobie nouvelle — voir le trouble ci-dessous'],
            ['10', 'Manie nouvelle — voir le trouble ci-dessous'],
          ],
        ),
        RulebookCallout(
          'Pendant la crise, le gardien joue l’investigateur. Le joueur '
          'reprend la main une fois le décompte fini, avec le trouble '
          'qui reste.',
          tone: RulebookCalloutTone.warning,
        ),
      ],
    ),
    RulebookSection(
      id: 'troubles',
      title: 'Phobies, manies, idées fixes',
      blocks: [
        RulebookParagraph(
          'Après la crise, il reste un trouble adapté au choc — pas une '
          'liste à tirer au hasard. Tant qu’il est actif, croiser le '
          'sujet force un jet de SAN, ou un dé malus sur ce qu’on essaie '
          'de faire.',
        ),
        RulebookBullets([
          'Phobie : on évite. Un cadavre, l’obscurité, l’eau, les '
              'insectes, les espaces clos…',
          'Manie : on ne peut plus s’en passer. Compter, se laver, '
              'collectionner, parler sans s’arrêter…',
          'Idée fixe : une conviction fausse qui tient lieu de vérité '
              '(« le gardien de nuit est un monstre », « je suis déjà '
              'mort »).',
        ]),
        RulebookParagraph(
          'Un succès de Psychanalyse, hors danger, peut atténuer le '
          'trouble. Un échec peut coûter encore 1 SAN.',
        ),
      ],
    ),
    RulebookSection(
      id: 'mythe',
      title: 'Mythe de Cthulhu',
      blocks: [
        RulebookParagraph(
          'Lire un grimoire, subir un sort, voir une créature : la '
          'compétence Mythe monte, et le plafond de SAN baisse d’autant. '
          'Cette compétence ne se développe pas en fin de scénario.',
        ),
        RulebookBullets([
          'Chaque point de Mythe retire 1 au maximum de SAN.',
          'On peut récupérer de la SAN, jamais au-dessus de ce plafond.',
          'En fin d’aventure, le gardien peut rendre 1D6 SAN — ou le '
              'montant annoncé par le scénario — à ceux qui tiennent '
              'encore debout.',
        ]),
      ],
    ),
    RulebookSection(
      id: 'couts',
      title: 'Pertes habituelles',
      blocks: [
        RulebookParagraph(
          'Ordres de grandeur, pas un tarif. Le scénario prime s’il '
          'donne ses propres chiffres.',
        ),
        RulebookTable(
          headers: ['Spectacle', 'Perte (réussite / échec)'],
          rows: [
            ['Cadavre, sang', '0 / 1D4'],
            ['Corps mutilé, ami mort', '0 / 1D6'],
            ['Meurtre sous les yeux', '0 / 1D8'],
            ['Créature du Mythe', 'selon la créature, souvent 1D6 / 1D20'],
            ['Grand Ancien en personne', '1D10 / 1D100'],
            ['Lancer un sort', 'annoncé par le sort'],
          ],
        ),
      ],
    ),
  ],
);
