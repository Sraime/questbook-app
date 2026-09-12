import 'rulebook_models.dart';

/// Third chapter: hit points, dying, first aid, and the other ways to get hurt.
///
/// Madness waits for Folie. The PV formula matches the universe config:
/// (CON + SIZ) / 10, rounded down.
const chapterSante = RulebookChapter(
  id: 'sante',
  title: 'Santé et dégâts',
  summary: 'Points de vie, gravité des blessures, soins et autres dégâts.',
  sections: [
    RulebookSection(
      id: 'pv',
      title: 'Points de vie et blessure grave',
      blocks: [
        RulebookParagraph(
          'Les points de vie valent (Constitution + Taille) ÷ 10, arrondis '
          'à l’entier inférieur — c’est le chiffre affiché sur la fiche.',
        ),
        RulebookBullets([
          'Blessure grave : un seul coup retire au moins la moitié des '
              'PV maximum.',
          'À 0 PV sans blessure grave : inconscient, pas mourant.',
          'À 0 PV avec une blessure grave : agonisant.',
        ]),
        RulebookCallout(
          'On juge chaque coup tout seul. Deux petits coups qui '
          'additionnés dépassent la moitié ne font pas une blessure grave.',
        ),
      ],
    ),
    RulebookSection(
      id: 'agonie',
      title: 'Inconscient et agonisant',
      blocks: [
        RulebookTable(
          headers: ['État', 'Ce qui se passe'],
          rows: [
            [
              'Inconscient',
              'Plus d’action. Un succès de Premiers soins rend 1 PV et réveille.',
            ],
            [
              'Agonisant',
              'Un jet de CON à chaque round : l’échec tue. Un succès de '
                  'Premiers soins ou de Médecine stabilise et rend 1 PV.',
            ],
          ],
        ),
        RulebookParagraph(
          'Une fois stabilisé, l’investigateur reste inconscient jusqu’à '
          'ce qu’on le réveille ou qu’il reprenne 1 PV de plus.',
        ),
      ],
    ),
    RulebookSection(
      id: 'soins',
      title: 'Premiers soins et médecine',
      blocks: [
        RulebookParagraph(
          'Les deux compétences soignent, mais pas au même moment ni '
          'pour le même montant. Chaque blessure n’accepte qu’un passage '
          'de chaque.',
        ),
        RulebookTable(
          headers: ['Compétence', 'Quand', 'Gain'],
          rows: [
            [
              'Premiers soins',
              'Dans l’heure, une fois par blessure',
              '+1 PV',
            ],
            [
              'Médecine',
              'Après les premiers soins, ou le lendemain',
              '+1D3 PV',
            ],
          ],
        ),
        RulebookCallout(
          'Sur un agonisant, le premier succès sert à le stabiliser '
          '(+1 PV). On ne relance pas les dés de médecine par-dessus '
          'dans le même round.',
          tone: RulebookCalloutTone.warning,
        ),
      ],
    ),
    RulebookSection(
      id: 'guerison',
      title: 'Guérison',
      blocks: [
        RulebookParagraph(
          'Le reste se reprend au calme, pas sur le terrain.',
        ),
        RulebookTable(
          headers: ['Situation', 'Récupération'],
          rows: [
            [
              'Sans blessure grave',
              '1 PV par jour de repos',
            ],
            [
              'Blessure grave',
              '1D4 PV par semaine de repos, si un jet de Médecine réussit',
            ],
          ],
        ),
        RulebookParagraph(
          'Un échec de Médecine cette semaine-là : pas de gain, et la '
          'plaie peut s’infecter — au gardien.',
        ),
      ],
    ),
    RulebookSection(
      id: 'autres',
      title: 'Autres formes de dégâts',
      blocks: [
        RulebookParagraph(
          'Quand ce n’est pas une arme, on prend encore les PV, et une '
          'blessure grave reste possible si le coup atteint la moitié.',
        ),
        RulebookTable(
          headers: ['Source', 'Dégâts'],
          rows: [
            ['Chute', '1D6 tous les 3 m'],
            ['Feu (torche, vêtement)', '1D6 / round'],
            ['Brasier, pièce en feu', '2D6 / round'],
            ['Noyade, asphyxie', '1D6 / round après un CON raté'],
            ['Froid, électricité', '1D6 à 2D6 selon l’exposition'],
            ['Poison', 'Virulence contre CON ; dégâts ou effet au gardien'],
          ],
        ),
        RulebookCallout(
          'L’armure aide contre les éclats et les balles. Elle ne fait '
          'rien contre la noyade, le poison ou le manque d’air.',
        ),
      ],
    ),
  ],
);
