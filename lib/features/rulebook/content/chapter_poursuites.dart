import 'rulebook_models.dart';

/// Last chapter: chases, vehicles, hazards and wrecks.
///
/// The 7th-edition chase is a line of locations, not a battle map. Numbers
/// stay close to the keeper screen; the prose does not.
const chapterPoursuites = RulebookChapter(
  id: 'poursuites',
  title: 'Poursuites',
  summary: 'Courses, véhicules, obstacles et collisions.',
  sections: [
    RulebookSection(
      id: 'piste',
      title: 'Mise en place',
      blocks: [
        RulebookParagraph(
          'Le gardien pose une ligne de cases — rues, toits, virages. '
          'Chaque participant occupe une case. L’avance, c’est le nombre '
          'de cases entre le poursuivi et le plus proche poursuivant.',
        ),
        RulebookBullets([
          'Un humain marche à MOV 7–9. Un cheval tourne autour de 12. '
              'Une automobile des années 20 dépasse souvent 12.',
          'Si l’avance tombe à 0, on est au contact : bagarre, embarquement '
              'ou nouvelle fuite.',
          'On sort de la poursuite en prenant 5 cases d’avance, ou quand '
              'plus personne ne peut suivre.',
        ]),
      ],
    ),
    RulebookSection(
      id: 'round',
      title: 'Un round de poursuite',
      blocks: [
        RulebookParagraph(
          'On joue dans l’ordre de DEX. Chacun se déplace, puis peut '
          'tenter une action sur sa case.',
        ),
        RulebookTable(
          headers: ['MOV par rapport au plus lent', 'Déplacement'],
          rows: [
            ['Égal', '1 case'],
            ['+1 ou +2', '2 cases'],
            ['+3 ou plus', '3 cases'],
          ],
        ),
        RulebookBullets([
          'Action typique : attaquer au passage, jeter un obstacle, '
              'forcer un véhicule, se cacher au prochain virage.',
          'Attaquer pendant la course se fait avec 1 dé malus, sauf à '
              'bout portant sur la même case.',
          'Un CON raté en sprint : on perd 1 case ce round, et le '
              'suivant se joue avec 1 dé malus.',
        ]),
      ],
    ),
    RulebookSection(
      id: 'obstacles',
      title: 'Obstacles et barrières',
      blocks: [
        RulebookParagraph(
          'Une case peut demander un jet pour la traverser. L’échec '
          'n’arrête pas toujours la poursuite — il coûte.',
        ),
        RulebookTable(
          headers: ['Type', 'Jet', 'Échec'],
          rows: [
            [
              'Obstacle',
              'Sauter, Grimper, Conduire…',
              'Perdre 1 case, parfois 1D6',
            ],
            [
              'Barrière',
              'Le même, souvent difficile',
              'On reste bloqué jusqu’à un succès',
            ],
            [
              'Raccourci',
              'Idée, Occultisme, Conduire…',
              'On rate le gain ; le succès fait gagner 1 case',
            ],
          ],
        ),
        RulebookCallout(
          'Un échec critique sur un obstacle de véhicule, c’est une '
          'collision. Voir plus bas.',
          tone: RulebookCalloutTone.warning,
        ),
      ],
    ),
    RulebookSection(
      id: 'vehicules',
      title: 'Véhicules',
      blocks: [
        RulebookParagraph(
          'Le conducteur utilise Conduire (auto), Pilotage ou Équitation. '
          'Les passagers peuvent tirer, jeter, ou se préparer à sauter. '
          'Les chiffres ci-dessous sont des ordres de grandeur d’époque.',
        ),
        RulebookTable(
          headers: ['Véhicule', 'MOV', 'Carrure', 'Armure'],
          rows: [
            ['Bicyclette', '10', '0', '0'],
            ['Cheval', '12', '+3', '0'],
            ['Moto', '14', '+1', '0'],
            ['Automobile', '13', '+4', '3'],
            ['Camion, autobus', '11', '+6', '4'],
          ],
        ),
        RulebookParagraph(
          'La Carrure du véhicule sert aux collisions et aux manœuvres '
          'pour éjecter quelqu’un. L’armure se retranche aux dégâts '
          'faits à la carcasse, pas aux passagers.',
        ),
      ],
    ),
    RulebookSection(
      id: 'collisions',
      title: 'Collisions et casse',
      blocks: [
        RulebookParagraph(
          'Quand deux véhicules se percutent, ou qu’un obstacle gagne, '
          'on compare les Carrures et on lance les dégâts sur chaque '
          'carcasse.',
        ),
        RulebookTable(
          headers: ['Situation', 'Dégâts à la carcasse'],
          rows: [
            ['Écart de Carrure 0 ou 1', '1D10 chacun'],
            ['Écart de 2 ou 3', '2D10 au plus léger, 1D10 à l’autre'],
            ['Écart de 4 ou plus', '3D10 au plus léger, 1D10 à l’autre'],
            ['Mur, arbre, fossé', '2D10, +1D10 si MOV 12 ou plus'],
          ],
        ),
        RulebookBullets([
          'Chaque passager lance Chance : succès = la moitié des dégâts '
              'du véhicule (arrondie au-dessus) ; échec = la totalité. '
              'L’armure personnelle compte, pas celle de la carcasse.',
          'À la moitié de ses PV, le véhicule prend 1 dé malus aux jets '
              'de conduite et perd 2 MOV.',
          'À 0 PV, il s’arrête — épave. Un 01 sur Conduire peut encore '
              'le poser sans tuer tout le monde.',
        ]),
      ],
    ),
  ],
);
