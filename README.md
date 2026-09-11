# Questbook

Questbook est une application Flutter de compagnon de jeu de rôle sur table : création et suivi de personnages, gestion des jets de dés, et organisation de tables de jeu. Le premier système supporté (« seedé ») est **L'Appel de Cthulhu, 7e édition**, mais l'architecture est pensée pour accueillir d'autres systèmes sans réécrire l'app.

## Sommaire

- [Aperçu fonctionnel](#aperçu-fonctionnel)
- [Stack technique](#stack-technique)
- [Architecture](#architecture)
  - [Arborescence](#arborescence)
  - [Couches applicatives](#couches-applicatives)
  - [Modèle de données](#modèle-de-données)
  - [Univers et mode de création](#univers-et-mode-de-création)
  - [Configuration d'un univers (`assets/universes/universe_*.json`)](#configuration-dun-univers-assetsuniversesuniverse_json)
  - [Configuration d'un mode de création (`assets/universes/*.json`)](#configuration-dun-mode-de-création-assetsuniversesjson)
  - [Extensibilité multi-système](#extensibilité-multi-système)
- [Prérequis](#prérequis)
- [Installation](#installation)
- [Génération de code](#génération-de-code)
- [Exécution](#exécution)
- [Compte Google et synchronisation](#compte-google-et-synchronisation)
  - [Configuration de build (`--dart-define`)](#configuration-de-build---dart-define)
  - [Lancer contre le backend local](#lancer-contre-le-backend-local)
  - [Comment la synchronisation fonctionne](#comment-la-synchronisation-fonctionne)
- [Tests](#tests)
- [Workflow git (branches)](#workflow-git-branches)
- [Distribution Android (signature, Firebase, CI/CD)](#distribution-android-signature-firebase-cicd)
  - [Vue d'ensemble](#vue-densemble)
  - [Numéro de version](#numéro-de-version)
  - [Signature de release](#signature-de-release)
  - [Firebase App Distribution](#firebase-app-distribution)
  - [CI GitHub Actions](#ci-github-actions)
  - [Déployer manuellement (sans la CI)](#déployer-manuellement-sans-la-ci)
  - [Reprendre ce setup sur une nouvelle machine](#reprendre-ce-setup-sur-une-nouvelle-machine)
- [Limitations connues](#limitations-connues)

## Aperçu fonctionnel

- **Accueil (`/perso`)** : liste des personnages créés, avec un badge de points de vie et un accès rapide à la fiche.
- **Création de personnage (`/perso/create`)** : choix de l'univers et du mode de création, nom/occupation/description, tirage des caractéristiques (3d6 × 5, façon CdC v7), répartition des points de compétence personnels et — si l'occupation choisie en définit — de son propre budget de points de compétence d'occupation.
- **Fiche de personnage (`/perso/:id`)** : caractéristiques, compétences, ressources (PV/SAN/PM), inventaire, jets de compétence (1d100) et édition rapide des ressources.
- **Tables (`/tables`)** : liste des tables de jeu dont on est membre, invitations reçues à accepter ou décliner, et création d'une table (titre + univers). Le créateur en devient le maître du jeu.
- **Détail d'une table (`/tables/:id`)** : joueurs, invitations en attente, sessions à venir et passées. Le MJ y invite par adresse Google, propose et modifie les sessions, et peut confier la table à un joueur. Chaque joueur y confirme ou décline sa participation, et peut changer d'avis à tout moment.
- **Participer avec un personnage** : après avoir confirmé, un joueur dit avec qui il vient — ou le renseigne plus tard, les deux gestes étant séparés. Les autres membres peuvent alors consulter sa fiche en lecture seule, depuis la liste des présents.

> Le MJ n'est pas un participant : il anime la séance, il n'a donc rien à confirmer et n'apparaît pas parmi les joueurs attendus.
- **Notifications (`/tables/notifications`)** : historique des invitations, sessions et réponses, avec pastille de non-lus sur la barre de navigation. Doublé de notifications push (Firebase Cloud Messaging).

> Contrairement aux personnages, **les tables sont strictement en ligne** : elles sont partagées entre plusieurs comptes, il n'y a donc rien à stocker localement et l'onglet demande une connexion.

Toute l'interface utilise un design system interne « juicy » (boutons/cartes/dés avec relief, ombres et dégradés) inspiré d'une maquette produit, situé dans `lib/design_system/`.

## Stack technique

| Domaine | Choix |
| --- | --- |
| Framework | Flutter (SDK Dart `^3.12.2`, canal stable) |
| État / DI | [`flutter_riverpod`](https://pub.dev/packages/flutter_riverpod) (`Notifier`, `Provider`, `FutureProvider`) |
| Navigation | [`go_router`](https://pub.dev/packages/go_router) (`StatefulShellRoute` pour la barre de navigation basse) |
| Persistance locale | [`drift`](https://pub.dev/packages/drift) + [`drift_flutter`](https://pub.dev/packages/drift_flutter) (SQLite embarqué) |
| Modèles immuables | [`freezed`](https://pub.dev/packages/freezed) / `freezed_annotation` |
| Sérialisation | `json_annotation` / `json_serializable` |
| UI | Design system maison (`qb_*` widgets), `google_fonts`, `lucide_icons_flutter` |
| Génération de code | `build_runner` (`drift_dev`, `freezed`, `json_serializable`) |

## Architecture

Le projet suit une architecture en couches façon *clean architecture* simplifiée : `domain` ne dépend de rien d'autre dans `lib/`, `data` implémente les interfaces de `domain`, et `features`/`design_system` consomment le tout via Riverpod.

### Arborescence

```
assets/
└── universes/                  # Un fichier universe_<id>.json par univers (métadonnées +
                                 # tronc commun general_configuration + index des modes)
                                 # et un fichier de surcharges par mode de création qu'il
                                 # référence (ex. call_of_cthulhu_classique.json…)
lib/
├── app/                       # Bootstrap : router, thème, providers racine
│   ├── router.dart            # Déclaration des routes go_router
│   ├── providers.dart         # DB, repositories, moteur de règles (DI)
│   └── theme.dart             # ThemeData Material basé sur les tokens du design system
├── domain/                    # Cœur métier, indépendant de Flutter/Drift
│   ├── models/                # Character, CharacterStat, CharacterResource,
│   │                          # GameSystem, InventoryItem, Tone,
│   │                          # CreationModeConfig (parsing des configs de
│   │                          # mode de création), UniverseConfig (parsing
│   │                          # des métadonnées d'univers)
│   ├── repositories/          # Interfaces abstraites (Character/GameSystem)
│   └── rules/                 # RulesEngine (interface) + ConfigRulesEngine
│                               # (implémentation générique) + FormulaEvaluator
├── data/
│   ├── universe/               # Découverte + chargement des configs de mode
│   │                            # de création et d'univers (assets JSON)
│   ├── local/
│   │   ├── database.dart      # Schéma Drift (tables SQLite) + AppDatabase
│   │   ├── local_*_repository.dart  # Implémentations locales des repositories
│   │   └── seed/               # seedDatabase() — insère le GameSystem de
│   │                            # chaque mode de création bundlé
│   ├── remote/                 # DTO et clients HTTP de l'API (auth, personnages,
│   │                            # tables, sessions, notifications)
│   ├── sync/                   # SyncService : push/pull des personnages
│   └── push/                   # PushMessaging : jeton FCM et messages entrants
├── design_system/
│   ├── tokens/                # colors, spacing, typography, effects (constantes de design)
│   └── components/            # Widgets réutilisables préfixés qb_ (bouton, carte, dés, etc.)
├── features/                   # Un dossier par écran/flux, avec ses providers Riverpod locaux
│   ├── home/                   # Écran « Mes personnages »
│   ├── character_creation/     # Création de personnage + modale de jet de caractéristique
│   ├── character_sheet/        # Fiche de personnage + modales (jet de compétence, ressource)
│   ├── tables/                  # « Mes tables », détail d'une table, notifications
│   ├── auth/                    # Écran de connexion Google et barre de compte
│   └── shell/                   # AppShell : bottom nav bar persistante (StatefulShellRoute)
├── services/
│   └── dice_service.dart       # Primitives de lancer de dés (dNombre, dPourcent), testable isolément
└── main.dart                    # Point d'entrée : ProviderScope + MaterialApp.router
```

### Couches applicatives

1. **`domain`** définit *quoi* (modèles + contrats de repository) et *comment calculer* (interface `RulesEngine`), sans savoir comment c'est stocké ni affiché.
2. **`data/local`** persiste ces modèles dans SQLite via Drift (`AppDatabase`), et traduit entre les lignes Drift générées (`*Row`) et les modèles `domain` dans les `Local*Repository`. **`data/universe`** découvre et parse tous les fichiers JSON sous `assets/universes/` en deux listes distinctes (par préfixe de nom de fichier) : les modes de création (`CreationModeConfig`) et les univers (`UniverseConfig`).
3. **`app/providers.dart`** est le point de câblage (DI) : il expose `appDatabaseProvider`, `availableCreationModesProvider`/`availableUniversesProvider` (les listes complètes, injectées depuis `main.dart` au démarrage), `selectedCreationModeProvider`/`selectedCreationModeIdProvider`/`selectedUniverseProvider` (le mode de création — et l'univers qui va avec — choisi par le joueur en cours de création de personnage), un provider par repository, et `rulesEngineProvider`. C'est le seul endroit à modifier pour brancher un futur backend distant (`Remote*Repository`) à la place du local.
4. **`features/*`** contient un `Notifier`/`AsyncNotifier` Riverpod par écran (ex. `CharacterCreationNotifier`, `CharacterListProvider`) qui lit les repositories/le rules engine, et les widgets d'écran qui les consomment via `ConsumerWidget`/`ConsumerStatefulWidget`.
5. **`design_system`** ne connaît ni Riverpod ni le domaine métier : ce sont des widgets purs paramétrés par variant/label/callback, réutilisés à l'identique entre les écrans.

### Modèle de données

Schéma Drift (`lib/data/local/database.dart`), modélisant un système de jeu générique :

- `GameSystems` — un mode de création (ex. `call_of_cthulhu_classique`) avec ses suggestions d'occupation.
- `Characters` — rattaché à un `GameSystem`, avec nom/occupation/description.
- `CharacterStats` — caractéristiques **et** compétences d'un personnage (`kind` distingue les deux), génériques sur `key`/`label`/`value` pour rester agnostiques du système.
- `CharacterResources` — ressources consommables (PV, SAN, PM…) avec valeur courante/max et un `tone` d'affichage.
- `InventoryItems` — objets possédés par un personnage.
- `SyncMetadata` — curseur de synchronisation et identifiant du compte auquel appartiennent les données locales.

Les tables de jeu **n'apparaissent pas ici** : elles sont partagées entre plusieurs comptes et vivent uniquement sur le serveur. La table Drift `GameTables` de la maquette locale a été supprimée par la migration v2 → v3.

Ce schéma générique (`kind`/`key`/`label`/`value`) permet d'ajouter un nouveau système de jeu sans migration : seul un nouveau fichier de config JSON de mode de création (voir ci-dessous) change.

### Univers et mode de création

Un **univers** (ex. "Call of Cthulhu") peut avoir plusieurs **modes de création** : des variantes de règles pour construire un personnage dans cet univers. Aujourd'hui, Call of Cthulhu en a deux : "Classique" (jets de dés) et "Simplifié" (caractéristiques choisies dans une liste de valeurs proposées plutôt que tirées aux dés) — un futur mode suivrait le même schéma. Un univers **structure** tout ce qui est commun à ses modes (caractéristiques, compétences, occupations, ressources, attributs globaux — voir [Configuration d'un univers](#configuration-dun-univers-assetsuniversesuniverse_json) juste après) ; chaque mode de création est un second fichier JSON qui ne porte que ce qui *diffère* réellement de ce tronc commun (voir [Configuration d'un mode de création](#configuration-dun-mode-de-création-assetsuniverses) ensuite).

Au démarrage, `main.dart` charge d'abord tous les univers (`loadAllUniverseConfigs()`), puis résout chaque mode de création qu'ils indexent (`loadAllCreationModeConfigs(universes)`) en fusionnant le tronc commun de son univers avec son propre fichier de surcharge (voir `lib/data/universe/universe_assets_loader.dart`, basé sur `AssetManifest` pour la découverte des `universe_*.json` — pas de liste codée en dur), puis les injecte via `availableCreationModesProvider`/`availableUniversesProvider`. Dans l'écran de création (`CharacterCreationScreen`), le joueur choisit son "Univers", puis (dans la même section, avec le nom et la description du personnage) son "Mode de création" ; ce choix pilote `selectedCreationModeIdProvider`/`selectedCreationModeProvider`/`selectedUniverseProvider`, dont dépend tout le reste du formulaire (occupations, caractéristiques, compétences…) — changer de sélection réinitialise le brouillon en cours. Chaque personnage garde une référence immuable vers le mode de création qui l'a vu naître via `Character.systemId` (voir `creationModeByIdProvider`, utilisé par la fiche de personnage pour toujours l'interpréter avec le bon jeu de règles, même si d'autres modes sont ajoutés plus tard).

### Configuration d'un univers (`assets/universes/universe_*.json`)

Un fichier `assets/universes/universe_<id>.json` porte trois choses :

1. Les **métadonnées/constantes** partagées par tous les modes de création de cet univers — nom, description, lien vers le livre de règles, seuils de réussite/échec critique.
2. L'**index `creation_modes`** : la liste des modes de création de cet univers, chacun avec son identité (`id`/`name`/`description`) et le nom du fichier JSON (`configuration_file`, relatif au même dossier) qui porte ses propres règles.
3. Le **`general_configuration`** : le tronc commun — même forme qu'un `character_sheet` de mode de création (`global_attributes`/`characteristics`/`resources`/`skills`/`occupations`) — que chaque mode de création vient ensuite compléter/surcharger.

```jsonc
{
  "id": "call_of_cthulhu",
  "name": "Call of Cthulhu",
  "description": "L'Appel de Cthulhu est un jeu de rôle d'horreur basé sur les récits de H. P. Lovecraft…",
  "rulebook_pdf_url": "https://www.chaosium.com/wp-content/uploads/2023/04/Call-of-Cthulhu-7th-Edition-Rulebook.pdf",
  "critical_success_max": 5,
  "critical_failure_min": 96,
  "creation_modes": [
    { "id": "call_of_cthulhu_classique", "name": "Classique",
      "description": "Lancez vos dés pour déterminer les valeurs de vos caractéristiques.",
      "configuration_file": "call_of_cthulhu_classique.json" },
    { "id": "call_of_cthulhu_simplifie", "name": "Simplifié",
      "description": "Affectez les valeurs 40, 50, 50, 50, 60, 60, 70 et 80 aux huit caractéristiques dans l'ordre de votre choix.",
      "configuration_file": "call_of_cthulhu_simplifie.json" }
  ],
  "general_configuration": {
    "global_attributes": [
      { "key": "age", "name": "Âge", "type": "integer" },
      { "key": "fortune", "name": "Fortune", "type": "choice",
        "choices": ["Indigent", "Pauvre", "Moyen", "Aisé", "Riche", "Richissime"] }
    ],
    "characteristics": [
      { "key": "FOR", "name": "Force", "description": "Puissance physique brute…", "type": "integer", "min": 0, "max": 100 }
    ],
    "skills": [
      { "key": "bibliotheque", "name": "Bibliothèque", "description": "Trouver une information…", "base_value": 20, "max": 100 }
    ],
    "occupations": [
      { "key": "medecin", "name": "Médecin", "description": "Praticien de la médecine…",
        "occupation_skill_points_formula": "EDU * 4",
        "occupation_skills": ["medecine", "premiers_soins", "psychologie", "sciences", "bibliotheque", "persuasion"],
        "occupation_skill_choices": 1 }
    ],
    "resources": [
      { "key": "PV", "label": "PV", "description": "Points de vie…", "type": "integer", "min": 0, "max": 100, "tone": "danger" }
    ]
  }
}
```

Le champ `name` est ce que `CreationModeConfig.universe_name` doit matcher exactement pour rattacher un mode de création à cet univers (voir `universeByNameProvider`). `critical_success_max`/`critical_failure_min` sont lus par `ConfigRulesEngine.rollSkillCheck` — un jet ≤ au premier est toujours une réussite critique, un jet ≥ au second toujours un échec critique, quelle que soit la compétence visée. Notez ce qui *manque* volontairement au `general_configuration` ci-dessus : ni `calculation_method`/`calculation_formula` sur une caractéristique, ni `formula` sur une ressource — c'est justement ce qui varie entre "Classique" et "Simplifié", donc ça vit dans les fichiers de mode plutôt qu'ici. `type`/`min`/`max` (sur les caractéristiques, ressources, attributs globaux) documentent le format attendu de la valeur ; ils ne sont pour l'instant pas exploités par le code Dart (pas de validation de saisie), c'est une réserve pour un usage futur.

### Configuration d'un mode de création (`assets/universes/*.json`)

Un fichier de mode de création (celui référencé par `configuration_file` dans l'index `creation_modes` de son univers) ne porte **que** les différences avec le `general_configuration` de son univers — pas d'`id`/`name`/`description` (déjà dans l'index), juste un `character_sheet` :

```jsonc
{
  "character_sheet": {
    "personal_skill_points": "INT * 2",
    "global_attributes": [],
    "characteristics": [
      { "key": "FOR", "calculation_method": "roll", "calculation_formula": "3D6*5" },
      { "key": "ESQ", "calculation_method": "derived", "calculation_formula": "DEX / 2" },
      { "key": "MVT", "calculation_method": "derived",
        "condition_table": [
          { "condition": "FOR > TAI && DEX > TAI", "value": 9 },
          { "condition": "true", "value": 8 }
        ] }
    ],
    "resources": [
      { "key": "PV", "formula": "(CON + TAI) / 10" }
    ],
    "skills": [
      { "key": "mythe_de_cthulhu", "name": "Mythe de Cthulhu", "description": "Connaissance interdite du Mythe…", "base_value": 0 }
    ],
    "occupations": []
  }
}
```

`CharacterSheetConfig.merge` (`lib/domain/models/creation_mode_config.dart`) combine ce fichier avec le `general_configuration` de son univers, liste par liste, **fusionnées par `key`** (`_mergeEntriesByKey`) :
- une entrée présente des deux côtés (ex. `FOR` ci-dessus) est fusionnée champ par champ — le mode ne redéfinit que ce qui change (`calculation_method`/`calculation_formula`) et hérite le reste (`name`, `description`, `type`…) du `general_configuration` ;
- une entrée présente seulement dans le fichier de mode (ex. `mythe_de_cthulhu`, une compétence propre à "Classique") s'ajoute au catalogue commun, sans toucher aux autres modes ;
- une entrée présente seulement dans le `general_configuration` (l'immense majorité des compétences/occupations) est héritée sans changement.

`personal_skill_points` est un simple scalaire : la valeur du fichier de mode si elle existe, sinon celle du `general_configuration`, sinon `"0"`. Voir `buildCreationModeConfig` (`lib/data/universe/universe_assets_loader.dart`) pour l'assemblage complet id/nom/description (venant de l'entrée `creation_modes` de l'univers) + `character_sheet` fusionné, et les tests `test/domain/models/creation_mode_config_test.dart`/`call_of_cthulhu_simplifie_test.dart` qui exercent cette fusion sur les vrais fichiers shippés (ex. "Classique" surcharge la base de Baratin à 10 alors que le tronc commun la fixe à 5).

Les chaînes `calculation_formula`/`condition_table[].condition`/`condition_table[].value`/`personal_skill_points`/`occupations[].occupation_skill_points_formula`/`resources[].formula`/`skills[].base_formula` sont interprétées par un petit évaluateur (`lib/domain/rules/formula_evaluator.dart`) qui supporte les dés (`3D6`, `d6`), l'arithmétique (`+ - * /`, parenthèses, `Floor()`, `Max(a, b, ...)`), et les conditions (`>= <= == != > <`, `&& ||`). C'est ce même évaluateur — pas de code Dart spécifique à Cthulhu — qui calcule les jets, les stats dérivées, les budgets de points de compétence et les ressources.

**Points de compétence personnels (`personal_skill_points`)** : chaque jeu définit sa propre règle pour le nombre de points que le joueur répartit librement sur *n'importe quelle* compétence à la création (CdC v7 : `INT * 2`, les « points d'intérêt personnel », ex. Nager).

Le schéma prévoit aussi `occupations[].skills_bonus` : un bonus fixe, automatique et non réparti par le joueur, qu'une occupation accorderait à des compétences précises (en pourcentage). CdC v7 n'en donne plus aucun exemple depuis l'introduction des points de compétence d'occupation ci-dessous, qui couvrent le même besoin de façon plus flexible — le champ reste disponible dans le schéma pour un futur système qui en aurait besoin.

**Points de compétence d'occupation (`occupations[].occupation_skill_points_formula`)** : en plus du crédit personnel ci-dessus, chaque occupation a son propre budget de points (CdC v7 : ex. `EDU * 4`, ou `EDU * 2 + Max(FOR, DEX) * 2` pour une occupation physique), dépensable **uniquement** sur la liste de compétences listées dans `occupations[].occupation_skills` (typiquement 5-7 compétences). `occupation_skill_choices` (souvent `1`) donne au joueur un nombre de créneaux « Compétence d'occupation bonus » : il choisit alors lui-même quelle compétence supplémentaire devient éligible à ce budget. Ce crédit est totalement séparé du pool `personal_skill_points` — les deux se cumulent sur une même compétence si le joueur le souhaite. Voir `CharacterCreationState.occupationSkillAllocated`/`occupationSkillChoiceSelections` (`lib/features/character_creation/providers/character_creation_provider.dart`) pour la logique, et la carte « Compétences » de l'écran de création pour l'UI.

**Caractéristique à choix (`calculation_method: "choice"`)** : pour une caractéristique qui n'est ni tirée aux dés ni calculée, mais choisie par le joueur dans une liste fixe d'options numériques (`choices`, ex. `["40", "50", "60", "70", "80"]`). Le mode "Simplifié" de CdC v7 assigne ainsi FOR/DEX/CON/POU/APP/ÉDU/INT/TAI — ce sont des caractéristiques primaires comme les autres, donc elles apparaissent comme un cercle tap-to-open dans la carte « Caractéristiques » de l'écran de création, au même endroit et avec le même style que les caractéristiques tirées aux dés. Le cercle ouvre `CharacteristicChoiceDialog` (`lib/features/character_creation/widgets/characteristic_choice_dialog.dart`) — la même coquille de popup que `CharacteristicRollDialog`, mais avec une liste de valeurs à choisir plutôt que des dés à lancer ; sélectionner une valeur met à jour le cercle immédiatement, avant même de valider. Elles alimentent normalement toutes les formules (stats dérivées, bases de compétence, ressources, budgets de points…) via `CharacteristicConfig.choiceValueAt`/`CharacterCreationState.resolvedCharacteristics`. La valeur stockée/persistée est la vraie valeur numérique choisie (pas son index), donc elles s'affichent sur la fiche comme un cadran numérique classique. (`choice` accepte aussi des options textuelles en théorie — voir `CharacteristicConfig.isNumericChoice` — mais CdC v7 n'en a plus d'exemple depuis que Fortune a été déplacée vers `global_attributes` ci-dessous ; à réserver à une caractéristique qui reste alimentée par des formules malgré des options textuelles.)

**Attributs globaux (`global_attributes`)** : informations propres à cet univers mais qui ne sont ni tirées, ni calculées, ni jamais lues par une formule — juste enregistrées et affichées (contrairement à une caractéristique à choix numérique, qui peut nourrir des formules). C'est la différence avec le nom/la description du personnage, communs à tout univers et donc gérés hors de ce fichier : un attribut global est spécifique à *cet* univers-ci. CdC v7 en a deux : l'âge (`"type": "integer"`, saisi en texte libre) et Fortune (`"type": "choice"`, paliers "Indigent" à "Richissime", remplaçant l'ancienne compétence Crédit). `GlobalAttributeConfig` (`lib/domain/models/creation_mode_config.dart`) porte `key`/`name`/`description`/`type`/`choices` ; pour un attribut `choice`, la valeur stockée/persistée est l'index dans `choices` (même convention qu'un choix de caractéristique), pour un `integer` c'est le nombre saisi tel quel. Persisté comme `CharacterStat` avec `kind: StatKind.attribute` (troisième valeur de l'enum, à côté de `characteristic`/`skill`) — d'où une lecture par `Character.attributes`. Dans l'écran de création, ces champs apparaissent dans la carte « Occupation », juste après le sélecteur d'occupation (un `QBSelect` pour `choice`, un `QBInput` numérique pour `integer` — pas de popup, contrairement aux caractéristiques à choix numérique ci-dessus). Sur la fiche de personnage, ils s'affichent en badge texte sous les cadrans de caractéristiques (`_attributeValueLabel` mappe l'index vers son libellé pour un `choice`).

### Extensibilité multi-système

`RulesEngine` (`lib/domain/rules/rules_engine.dart`) isole toute la mécanique spécifique à un système :

```dart
abstract interface class RulesEngine {
  String get systemId;
  CharacteristicRoll rollCharacteristic(String characteristicKey, {int bonus = 0, Random? random});
  Map<String, int> computeDerivedCharacteristics(Map<String, int> primary);
  SkillCheckResult rollSkillCheck(int targetValue, {Random? random});
}
```

`ConfigRulesEngine` (`lib/domain/rules/config_rules_engine.dart`) en est l'implémentation : générique, elle interprète n'importe quel `CreationModeConfig` (plus le `UniverseConfig` de son univers, pour les seuils de critique) plutôt que de coder en dur les règles d'un seul système. Ajouter un système (D&D 5e, Vampire…) ou une variante de règles (un futur mode "Débutant"…) qui reste décrivable par le schéma JSON ci-dessus consiste simplement à :
1. si c'est un nouvel univers, écrire son fichier `assets/universes/universe_<id>.json` avec son `general_configuration` (voir [Configuration d'un univers](#configuration-dun-univers-assetsuniversesuniverse_json)) ;
2. écrire un nouveau fichier de surcharges pour ce mode (juste ce qui diffère du `general_configuration`) et l'ajouter à l'index `creation_modes` de son univers (voir [Configuration d'un mode de création](#configuration-dun-mode-de-création-assetsuniverses)) ;
3. rien de plus — le dossier `assets/universes/` entier est déjà déclaré dans `pubspec.yaml`, `loadAllUniverseConfigs()` découvre tout `universe_*.json` qui y apparaît sans changement de code, et `loadAllCreationModeConfigs()` résout chaque entrée de leurs `creation_modes` en suivant `configuration_file`. Le nouveau mode apparaît alors automatiquement dans les menus "Univers"/"Mode de création" de l'écran de création.

Seul un système avec une mécanique réellement inédite (non descriptible en dés/arithmétique/conditions) nécessiterait une nouvelle implémentation de `RulesEngine`, câblée dans `rulesEngineProvider`.

## Prérequis

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (canal stable — projet testé avec Flutter 3.44.x / Dart 3.12.x).
- Un IDE avec plugin Flutter/Dart (VS Code, Android Studio…) ou juste la CLI.
- Pour lancer sur mobile :
  - **Android** : Android SDK + un émulateur configuré, ou un appareil physique en mode debug USB.
  - **iOS** (macOS uniquement) : Xcode + CocoaPods, ou un simulateur iOS.
- Vérifier l'environnement :
  ```bash
  flutter doctor
  ```

> ℹ️ Seuls les dossiers `android/` et `ios/` sont présents dans ce dépôt : il n'y a pas de support desktop (`windows/`) ni web (`web/`) configuré nativement. Voir [Limitations connues](#limitations-connues).

## Installation

```bash
git clone <url-du-dépôt>
cd questbook
flutter pub get
```

## Génération de code

Le projet utilise `build_runner` pour générer :
- les classes Drift (`*.g.dart`) à partir du schéma dans `database.dart` ;
- les classes `freezed`/`json_serializable` (`*.freezed.dart`, `*.g.dart`) pour les modèles du dossier `domain/models/`.

Les fichiers générés sont déjà commités, mais après toute modification d'un modèle `@freezed` ou du schéma Drift, régénérez-les avec :

```bash
dart run build_runner build --delete-conflicting-outputs
```

(ou `dart run build_runner watch --delete-conflicting-outputs` pendant le développement actif des modèles).

## Exécution

1. Lister les appareils/émulateurs disponibles :
   ```bash
   flutter devices
   flutter emulators
   ```
2. Démarrer un émulateur Android si besoin (remplacez l'id par celui listé ci-dessus, par ex. `questbook_test`) :
   ```bash
   flutter emulators --launch <id_emulateur>
   ```
3. Lancer l'application :
   ```bash
   flutter run -d <id_appareil>
   # ex. flutter run -d emulator-5554
   ```

Au premier lancement, `databaseInitProvider` (voir `lib/app/providers.dart`) crée la base SQLite locale et insère le système « Appel de Cthulhu v7 » (`seedDatabase`) — aucun personnage ni table de démo n'est pré-créé.

### Recharge à chaud

Une fois `flutter run` actif dans un terminal interactif, les commandes clavier standard fonctionnent :
- `r` → hot reload
- `R` → hot restart
- `q` → quitter

### Web / Desktop

Ce dépôt ne contient pas les dossiers `web/` ni `windows/`/`linux/`/`macos/`. `flutter run -d chrome` peut fonctionner en apparence, mais **la persistance Drift (SQLite via IndexedDB/OPFS) nécessite des fichiers `sqlite3.wasm` + un worker JS** qui ne sont générés qu'après `flutter create .` (ce qui ajoute les dossiers de plateforme manquants). Sans cette étape, l'appli peut rester bloquée sur l'écran de chargement/erreur. Si vous avez besoin d'une cible web ou desktop :
```bash
flutter create .
flutter run -d chrome     # ou -d windows / -d linux / -d macos
```

## Compte Google et synchronisation

L'app peut sauvegarder les personnages sur un compte Google, via l'API Questbook
qui vit dans un dépôt séparé : [`questbook-back`](https://github.com/Sraime/questbook-back)
(Fastify + Prisma + PostgreSQL). Son README couvre l'installation, les variables
d'environnement et le déploiement.

**La connexion reste facultative.** Sans compte, l'app fonctionne exactement
comme avant : tout est stocké en local par Drift. L'écran de connexion propose
toujours « Continuer hors ligne ».

### Configuration de build (`--dart-define`)

Rien n'est codé en dur : `lib/config/app_config.dart` lit deux valeurs injectées
au build.

| Define | Rôle | Défaut |
| --- | --- | --- |
| `QUESTBOOK_API_URL` | Base URL de l'API. | `http://10.0.2.2:3000` (le `localhost` de la machine hôte, vu depuis l'émulateur Android) |
| `QUESTBOOK_GOOGLE_SERVER_CLIENT_ID` | Client OAuth **Web** de Google Cloud — c'est l'audience des jetons d'identité que l'API vérifie, pas le client Android. | *(vide)* |

Si `QUESTBOOK_GOOGLE_SERVER_CLIENT_ID` est vide, le build est purement hors
ligne : ni écran de connexion, ni bandeau de compte, plutôt qu'un bouton qui ne
peut pas marcher.

Côté Google Cloud, il faut **deux** clients OAuth dans le même projet : un client
Web (dont l'id est le define ci-dessus, et le seul que l'API accepte) et un
client Android déclarant le `applicationId` et l'empreinte SHA-1 de la clé de
signature — celle de debug pour `flutter run`, celle du keystore de release
(voir [Signature de release](#signature-de-release)) pour les builds distribués.
Un SHA-1 manquant est la cause la plus fréquente d'une connexion qui échoue avec
« Google n'a pas renvoyé de jeton d'identité ».

### Lancer contre le backend local

Démarrer l'API dans `questbook-back` (`docker compose -f docker-compose.dev.yml up`
puis `npm run dev`), puis :

```bash
flutter run -d emulator-5554 \
  --dart-define=QUESTBOOK_API_URL=http://10.0.2.2:3000 \
  --dart-define=QUESTBOOK_GOOGLE_SERVER_CLIENT_ID=<client-web>.apps.googleusercontent.com
```

Sur un **appareil physique**, `10.0.2.2` ne veut rien dire : utiliser l'adresse
LAN de la machine (`http://192.168.x.x:3000`) et vérifier que le pare-feu Windows
laisse passer le port.

### Comment la synchronisation fonctionne

Drift reste la source de vérité de l'UI : tous les écrans lisent les mêmes
streams locaux, connecté ou non. La synchronisation ne fait que refléter ces
lignes vers le serveur et rapatrier ce que les autres appareils ont changé.

- Chaque écriture locale marque le personnage `needsSync` et avance son
  `updatedAt` ; une suppression laisse une **pierre tombale** (`deletedAt`) pour
  que l'effacement se propage au lieu de disparaître silencieusement.
- Une passe fait d'abord un *push* puis un *pull*, dans cet ordre — sinon un
  personnage créé hors ligne ressemblerait, vu du pull, à quelque chose à
  supprimer.
- Les conflits se résolvent en **last-write-wins sur le personnage entier**,
  la règle qu'applique aussi l'API, donc les deux côtés désignent toujours le
  même gagnant.
- Une passe se déclenche à la connexion, au retour au premier plan, et via le
  bouton ↻ du bandeau de compte.
- Si un **autre compte** se connecte sur l'appareil, les données locales sont
  effacées : les personnages du compte précédent ne doivent pas fuiter dans la
  nouvelle session.

Les personnages créés avant cette fonctionnalité sont poussés tels quels à la
première connexion (migration Drift v1 → v2, voir `lib/data/local/database.dart`).

### Tables : le choix inverse

Les tables ne suivent **pas** ce modèle. Une table est partagée entre plusieurs
comptes qui la modifient en même temps ; la stocker localement obligerait à
résoudre des conflits sur des données que l'utilisateur ne contrôle pas seul,
pour un gain nul — sans réseau, il n'y a de toute façon pas de partie à
organiser. L'onglet Tables lit donc l'API directement (`FutureProvider` dans
`lib/features/tables/providers/`) et affiche un état « connexion requise » à
défaut. La maquette locale est supprimée par la migration Drift v2 → v3.

Un cas se tient à la frontière des deux modèles : le personnage qu'un joueur
inscrit à une session. Le choix se fait dans une liste lue en local, mais c'est
l'identifiant qui part au serveur, lequel ne connaît que les personnages déjà
synchronisés. Un personnage créé hors-ligne et jamais poussé revient donc en
404, et la boîte de dialogue invite explicitement à synchroniser.

La fiche d'un autre participant, elle, est lue en ligne et n'est jamais écrite
sur l'appareil : elle appartient à quelqu'un d'autre, et c'est à lui de la
changer.

### Notifications push (Firebase Cloud Messaging)

`lib/data/push/push_messaging.dart` enregistre le jeton FCM de l'appareil à la
connexion (`PUT /devices`) et le retire à la déconnexion, pour qu'un téléphone
partagé cesse de recevoir les notifications du compte précédent. Un message
reçu app ouverte rafraîchit la pastille ; un message ouvert depuis la barre
système ouvre la table concernée.

Le push n'est qu'un canal de livraison : **l'historique consultable vient de
l'API**, où chaque ligne est écrite dans la transaction de la modification qui
la justifie. Un appareil sans Play Services, ou un build sans Firebase, voit
donc tout — simplement plus tard. C'est pourquoi `Firebase.initializeApp` est
enveloppé dans un `try` au démarrage.

`android/app/google-services.json` et `lib/firebase_options.dart` sont
**versionnés volontairement** : ils ne contiennent pas de secret (ils sont de
toute façon embarqués dans l'APK) et la CI en a besoin pour construire le
release. Pour les régénérer :

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=questbook-48540 --platforms=android \
  --android-package-name=com.questbook.questbook
```

Côté serveur, l'envoi demande une clé de compte de service Firebase
(`FIREBASE_PROJECT_ID`, `FIREBASE_CLIENT_EMAIL`, `FIREBASE_PRIVATE_KEY`) — voir
le README du backend.

## Tests

```bash
flutter test
```

`.github/workflows/ci.yml` rejoue `flutter analyze` puis `flutter test` sur
chaque pull request et sur les pushes de `dev`. Les deux sont bloquants : le
projet est à zéro avertissement et il s'agit de le garder ainsi. Le job installe
`libsqlite3-dev`, dont les tests de migration Drift ont besoin pour ouvrir une
vraie base sur le runner.

Ce garde-fou est ce qui sépare une PR rouge de la distribution aux testeurs,
puisque celle-ci part dès qu'une PR tombe dans `main`.

Tests actuellement présents (`test/`) :
- `domain/rules/formula_evaluator_test.dart` — l'évaluateur de formules/dés/conditions lui-même.
- `domain/rules/config_rules_engine_test.dart` — mécaniques de jet (caractéristiques, dérivées, jets de compétence) sur une config de test.
- `domain/models/creation_mode_config_test.dart` — smoke-test du mode "Classique" tel que réellement résolu à l'exécution (`universe_call_of_cthulhu.json`'s `general_configuration` fusionné avec `call_of_cthulhu_classique.json`, via `buildCreationModeConfig`).
- `domain/models/call_of_cthulhu_simplifie_test.dart` — même chose pour "Simplifié" (`call_of_cthulhu_simplifie.json`), notamment ses caractéristiques à choix numérique et le fait qu'il hérite du même catalogue de compétences/occupations que "Classique".
- `domain/models/universe_config_test.dart` — smoke-test du fichier `assets/universes/universe_call_of_cthulhu.json` : métadonnées, index `creation_modes`, contenu du `general_configuration`.
- `services/dice_service_test.dart` — primitives de lancer de dés.
- `data/local/local_character_repository_test.dart` — la comptabilité de synchronisation du dépôt local : chaque écriture marque le personnage à pousser, une suppression laisse une pierre tombale invisible dans la liste.
- `data/local/migration_test.dart` — les migrations sur un vrai fichier SQLite ramené aux schémas v1 puis v2, pour vérifier qu'aucun personnage existant n'est perdu, que `updatedAt` est bien rempli et que la maquette locale des tables est bien supprimée en v3.
- `data/sync/sync_service_test.dart` — les règles de synchronisation (push, pull, conflits, changement de compte) contre une fausse API et une vraie base en mémoire.
- `data/remote/api_client_test.dart` — le rafraîchissement du jeton contre un vrai serveur HTTP local : un 401 déclenche un refresh puis un seul rejeu, plusieurs requêtes simultanées ne brûlent qu'un seul refresh token, et un refresh refusé termine la session au lieu de boucler.

## Workflow git (branches)

Le dépôt suit un git-flow simplifié à deux branches :

- **`dev`** — branche de travail. Toutes les modifications (features, fixes,
  docs…) sont commitées ici (directement ou via des branches
  `feature/xxx` ouvertes depuis `dev`, selon la taille du changement).
  Pousser sur `dev` déclenche l'analyse et les tests, mais **aucun build ni
  aucune distribution**.
- **`main`** — branche de release, protégée. Elle ne doit être mise à jour
  que via une **Pull Request `dev` → `main`**, jamais par un push direct.
  C'est le *merge* de cette PR qui déclenche automatiquement la CI (build +
  distribution Firebase App Distribution — voir section suivante).

En pratique :

```bash
git checkout dev
# ... commits de travail ...
git push origin dev
# Puis, une fois prêt à livrer une version aux testeurs :
# ouvrir une Pull Request "dev → main" sur GitHub et la merger.
```

> ℹ️ Pour que `main` reste vraiment protégée, active sur GitHub
> `Settings → Branches → Branch protection rules` une règle sur `main`
> exigeant une Pull Request avant tout merge (« Require a pull request
> before merging »). Sans ça, rien n'empêche techniquement un push direct
> sur `main`, qui ne déclencherait d'ailleurs pas la CI non plus (le
> workflow n'écoute que l'événement « Pull Request fermée en tant que
> merged », pas les push) — mais court-circuiterait la revue de code.

## Distribution Android (signature, Firebase, CI/CD)

### Vue d'ensemble

Le projet est connecté à un projet Firebase (**`questbook-48540`**) pour deux
usages distincts : distribuer des builds de test aux beta-testeurs via **Firebase
App Distribution**, et envoyer les notifications push via **Cloud Messaging**
(`firebase_core` et `firebase_messaging` côté app). Aucun autre SDK Firebase
n'est intégré : ni Auth, ni Analytics, ni Firestore. Le flux de distribution,
une fois poussé sur `main` :

```
Pull Request "dev → main" mergée sur GitHub
   └─▶ GitHub Actions (.github/workflows/firebase-distribution.yml)
          ├─ flutter build apk --release   (signé avec la clé "upload")
          └─ firebase appdistribution:distribute
                 └─▶ groupe de testeurs "testeurs" sur Firebase App Distribution
                        └─▶ email + lien de téléchargement pour chaque testeur
```

Trois briques composent ce dispositif, détaillées ci-dessous : la **signature
release**, le **projet Firebase**, et le **workflow CI**.

### Numéro de version

**Monter `version` dans `pubspec.yaml` fait partie de la PR, pas de l'après.**
Deux distributions sous le même numéro sont indiscernables pour un testeur, qui
ne peut plus savoir laquelle il a installée, et le `versionCode` Android figé
interdit toute publication ultérieure sur le Play Store.

Le workflow refuse donc de distribuer une version déjà livrée. Chaque
distribution réussie pose un tag `v<version>` — `v1.3.0+5`, par exemple — et le
job échoue d'emblée si ce tag existe déjà. Les tags font office de registre : ce
sont eux qui disent ce qui est réellement parti chez les testeurs.

Le tag est posé **après** la distribution, pour qu'un build en échec ne brûle pas
son numéro.

> C'est arrivé le 11 septembre : la feature « Tables de jeu » est partie en
> `1.2.0+4`, le numéro exact de la release du 5 septembre, sans que rien ne le
> signale. D'où ce garde-fou.

### Signature de release

Par défaut, un projet Flutter fraîchement créé signe ses builds `release`
avec la clé de debug (`android/app/build.gradle.kts` originel) — ce qui
fonctionne mais n'est pas une vraie release signée. Ce repo utilise une
vraie clé de signature dédiée (« clé upload »), stockée **hors du dépôt
git** :

- La clé elle-même (`upload-keystore.jks`, RSA 2048, alias `upload`) et ses
  mots de passe ne sont **jamais commités** — ils vivent uniquement dans un
  dossier local `.secrets/` (gitignoré) et dans les secrets GitHub Actions
  (voir plus bas).
- `android/app/build.gradle.kts` lit un fichier `android/key.properties`
  (également gitignoré) au moment du build :

  ```properties
  storePassword=...
  keyPassword=...
  keyAlias=upload
  storeFile=/chemin/vers/upload-keystore.jks
  ```

  Si `android/key.properties` n'existe pas (ex. sur un checkout tout frais
  sans accès au keystore), le build `release` **retombe automatiquement sur
  la signature debug** — `flutter run --release` continue donc de fonctionner
  sans configuration supplémentaire, seule la distribution vers de vrais
  testeurs nécessite la vraie clé.
- Pourquoi un seul mot de passe (`storePassword` == `keyPassword`) ? Les
  keystores `PKCS12` (format par défaut des JDK récents) ne supportent pas
  des mots de passe distincts pour le keystore et l'alias — `keytool` ignore
  silencieusement `-keypass` si différent de `-storepass`.

> ⚠️ **Ne perds pas ce keystore.** Pour l'instant l'app n'est distribuée que
> via Firebase App Distribution donc ce n'est pas critique, mais le jour où
> l'app est publiée sur le Play Store *sans* Play App Signing, perdre cette
> clé signifie ne plus jamais pouvoir publier de mise à jour sous le même
> `applicationId`. Sauvegarde `.secrets/upload-keystore.jks` dans un
> gestionnaire de mots de passe/coffre-fort d'équipe.

### Firebase App Distribution

- **Projet Firebase** : `questbook-48540` (console :
  [console.firebase.google.com/project/questbook-48540](https://console.firebase.google.com/project/questbook-48540)).
- **App Android enregistrée** : package `com.questbook.questbook`, App ID
  Firebase `1:56734402863:android:8f12f08f8eff13a8e2b9da` (visible dans
  Project settings → General, ou via `firebase apps:list`).
- **Groupe de testeurs** : alias `testeurs` (affiché « Testeurs Questbook »
  dans la console). Ajouter un testeur :
  ```bash
  firebase appdistribution:testers:add nouveau.testeur@example.com --group-alias testeurs --project questbook-48540
  ```
- Chaque testeur reçoit un email d'invitation avec un lien de téléchargement
  direct (aucun compte Google Play/bêta-test public requis).

### CI GitHub Actions

Le workflow [`.github/workflows/firebase-distribution.yml`](.github/workflows/firebase-distribution.yml)
se déclenche :
- automatiquement quand une **Pull Request vers `main` est mergée**
  (événement `pull_request` de type `closed`, filtré par
  `github.event.pull_request.merged == true` pour ignorer les PR fermées
  sans être mergées) — voir [Workflow git](#workflow-git-branches) ;
- ou manuellement depuis l'onglet **Actions** du repo GitHub (bouton
  « Run workflow »), avec des notes de version personnalisées en option.

Volontairement, un simple `push` sur `main` (ou sur toute autre branche) ne
déclenche **rien** : ça évite de redéployer un build de test à chaque petit
commit (doc, refactor…) qui n'apporte aucune évolution fonctionnelle.

Il enchaîne : checkout → setup Flutter/JDK → `flutter pub get` → décodage du
keystore + écriture de `key.properties` à partir des secrets → 
`flutter build apk --release` → installation de `firebase-tools` →
`firebase appdistribution:distribute` vers le groupe `testeurs` → nettoyage
des fichiers de signature sur le runner.

Il a besoin de **5 secrets** définis dans
`Settings → Secrets and variables → Actions` du repo GitHub :

| Secret                      | Contenu                                                              |
| ---------------------------- | --------------------------------------------------------------------- |
| `ANDROID_KEYSTORE_BASE64`   | Le fichier `upload-keystore.jks` encodé en base64 (une seule ligne)   |
| `ANDROID_KEYSTORE_PASSWORD` | Mot de passe du keystore (`storePassword`)                            |
| `ANDROID_KEY_PASSWORD`      | Idem (même valeur, voir note PKCS12 ci-dessus)                        |
| `ANDROID_KEY_ALIAS`         | `upload`                                                               |
| `FIREBASE_TOKEN`            | Token CI généré via `firebase login:ci` (voir note de dépréciation ci-dessous) |

L'App ID Firebase et le Project ID ne sont *pas* secrets — ils sont en dur
dans le workflow (`env:` en tête de fichier).

> ⚠️ `firebase login:ci` / l'option `--token` de `firebase-tools` sont
> marquées comme dépréciées par Google au profit de l'authentification par
> compte de service. Elles fonctionnent encore avec `firebase-tools` 15.x
> (utilisé ici), mais si Google les retire dans une future version majeure,
> il faudra migrer l'étape « Distribute » du workflow vers un compte de
> service GCP (rôle *Firebase App Distribution Admin*) exposé via
> `GOOGLE_APPLICATION_CREDENTIALS`, en remplacement de `--token`.

### Déployer manuellement (sans la CI)

Utile en local si tu as le keystore et que tu veux tester une distribution
avant de pousser :

```bash
flutter build apk --release
firebase appdistribution:distribute build/app/outputs/flutter-apk/app-release.apk \
  --app 1:56734402863:android:8f12f08f8eff13a8e2b9da \
  --project questbook-48540 \
  --groups "testeurs" \
  --release-notes "Description de ce build"
```

(nécessite `firebase login` préalable — sur Windows/PowerShell, utiliser
`firebase.cmd` si l'exécution de scripts `.ps1` est bloquée par la
politique d'exécution).

### Reprendre ce setup sur une nouvelle machine

Un `git clone` frais **n'inclut ni le keystore ni les mots de passe**
(volontairement, ils sont gitignorés). Deux cas :

- **Tu veux juste lancer/développer l'app** : rien à faire, les builds
  `debug` et même `release` fonctionnent (signature debug de repli — voir
  [Signature de release](#signature-de-release)).
- **Tu veux publier/distribuer un vrai build** : il te faut le fichier
  `upload-keystore.jks` existant (demande-le à un mainteneur ayant accès à
  `.secrets/`, ne le régénère surtout pas — un nouveau keystore ne
  correspondrait plus à ce qui a déjà été distribué) et recréer localement
  un `android/key.properties` qui pointe dessus, avec les mêmes valeurs que
  celles utilisées dans les secrets GitHub `ANDROID_KEYSTORE_*`.

## Limitations connues

- Un seul univers est embarqué aujourd'hui (Call of Cthulhu, avec ses modes "Classique" et "Simplifié") : le menu "Univers" de l'écran de création n'a donc qu'une option pour l'instant, même si le mécanisme sous-jacent (découverte dynamique + sélection) supporte déjà d'en ajouter d'autres sans changement de code — voir [Univers et mode de création](#univers-et-mode-de-création).
- Le mode "Simplifié" ne fait qu'assigner librement une valeur à chaque caractéristique (`calculation_method: "choice"`) : il n'empêche pas de choisir deux fois la même valeur, alors que la règle CdC7 d'origine impose de répartir un jeu fixe de 8 valeurs (40, 50, 50, 50, 60, 60, 70, 80) sans répétition au-delà de ce que ce jeu autorise. Ajouter cette contrainte demanderait un nouveau mécanisme de "pool partagé sans répétition", pas juste une liste de choix par caractéristique.
- Le palier de "Bonus aux dégâts" (IMP) est simplifié en indice de palier (-2 à 5+) plutôt qu'en expression de dés (`+1D4`, `+2D6`…) : le schéma stocke les stats en entier, pas en expression. Voir le champ `description` de `IMP` dans le fichier de config pour la correspondance réelle.
- Pas de support desktop/web packagé nativement (voir ci-dessus).
- La synchronisation hors-ligne ne couvre que les personnages (stats, ressources, inventaire). Les tables, sessions et notifications sont lues et écrites en ligne : sans réseau, l'onglet Tables est vide.
- La connexion Google n'est câblée que pour Android : `ios/Runner/Info.plist` n'a pas encore de `CFBundleURLTypes`, et il manque un client OAuth iOS. Un build iOS lancé sans `QUESTBOOK_GOOGLE_SERVER_CLIENT_ID` reste utilisable, mais hors ligne. Voir [Compte Google et synchronisation](#compte-google-et-synchronisation).
- Les notifications push ne sont câblées que pour Android : le projet Firebase n'a pas d'app iOS, et l'envoi APNs demanderait une clé Apple. Sur iOS, seul l'historique in-app fonctionne.
- Pas de relance en cas d'échec d'envoi d'un e-mail ou d'un push : les deux partent au mieux après le commit. La ligne de notification, elle, est écrite dans la transaction, donc l'historique in-app reste juste. Une table d'outbox avec relance reste un ajout simple si le besoin apparaît.
- Distribution actuelle limitée à Firebase App Distribution (bêta-testeurs) ; pas encore de publication Play Store, ni de Play App Signing (la clé de signature `upload` est gérée manuellement — voir [Distribution Android](#distribution-android-signature-firebase-cicd)).
- L'authentification CI Firebase (`firebase login:ci` / `--token`) repose sur un mécanisme déprécié par Google ; à migrer vers un compte de service GCP si `firebase-tools` le retire dans une future version majeure.
