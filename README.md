# Questbook

Questbook est une application Flutter de compagnon de jeu de rôle sur table : création et suivi de personnages, gestion des jets de dés, et organisation de tables de jeu. Le premier système supporté (« seedé ») est **L'Appel de Cthulhu, 7e édition**, mais l'architecture est pensée pour accueillir d'autres systèmes sans réécrire l'app.

> Ce que désignent **table**, **session**, **scénario**, **plateau**, **asset** ou **boutique** est défini une fois pour toutes dans le [lexique](../questbook-ia/LEXIQUE.md), commun à l'app et à l'API. Ce README décrit comment c'est fait ; le lexique dit ce que c'est.

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
  - [Navigation](#navigation)
- [Prérequis](#prérequis)
- [Installation](#installation)
- [Génération de code](#génération-de-code)
- [Exécution](#exécution)
- [Compte Google et synchronisation](#compte-google-et-synchronisation)
  - [Supprimer son compte](#supprimer-son-compte)
  - [Configuration de build (`--dart-define`)](#configuration-de-build---dart-define)
  - [Lancer contre le backend local](#lancer-contre-le-backend-local)
  - [Comment la synchronisation fonctionne](#comment-la-synchronisation-fonctionne)
  - [Tables : le choix inverse](#tables--le-choix-inverse)
  - [Consultation seule (hors ligne)](#consultation-seule-hors-ligne)
- [Tests](#tests)
- [Workflow git (branches)](#workflow-git-branches)
- [Distribution (signature, Firebase, CI/CD)](#distribution-signature-firebase-cicd)
  - [Vue d'ensemble](#vue-densemble)
  - [Icône de l'application](#icône-de-lapplication)
  - [Numéro de version](#numéro-de-version)
  - [Signature de release Android](#signature-de-release-android)
  - [Signature de release iOS](#signature-de-release-ios)
  - [Firebase App Distribution](#firebase-app-distribution)
  - [CI GitHub Actions](#ci-github-actions)
  - [Publication sur les stores](#publication-sur-les-stores)
  - [Déployer manuellement (sans la CI)](#déployer-manuellement-sans-la-ci)
  - [Reprendre ce setup sur une nouvelle machine](#reprendre-ce-setup-sur-une-nouvelle-machine)
- [Limitations connues](#limitations-connues)

## Aperçu fonctionnel

- **Accueil (`/perso`)** : liste des personnages créés, avec un badge de points de vie et un accès rapide à la fiche.
- **Création de personnage (`/perso/create`)** : choix du mode de création, nom/occupation/description, tirage des caractéristiques (3d6 × 5, façon CdC v7), répartition des points de compétence personnels et — si l'occupation choisie en définit — de son propre budget de points de compétence d'occupation.
- **Fiche de personnage (`/perso/:id`)** : caractéristiques, compétences, ressources (PV/SAN/PM), inventaire, jets de compétence (1d100) et édition rapide des ressources.
- **Tables (`/tables`)** : liste des tables de jeu dont on est membre, invitations reçues à accepter ou décliner, et création d'une table (un titre, rien d'autre). Le créateur en devient le maître du jeu.
- **Scénarios (`/scenarios`, depuis le menu du burger)** : aventures possédées, listées par titre et description. Le contenu complet (contexte, déroulé markdown, annexes) se télécharge sur l'appareil pour la lecture hors ligne. Un utilisateur ne crée pas de scénario : le catalogue vient du serveur. Quelques-uns sont donnés à la connexion pour que la liste ne soit pas vide, les autres s'achètent à la boutique.
- **Détail d'une table (`/tables/:id`)** : joueurs, invitations en attente, sessions à venir et passées. Le MJ y invite par adresse Google, propose les sessions — et peut y rattacher un scénario déjà téléchargé — et peut confier la table à un joueur. Chaque joueur y confirme ou décline sa participation, et peut changer d'avis à tout moment.
- **Carte d'une session** : pour le MJ, la carte entière mène au mode MJ ; corriger la session ou l'annuler s'y fait ensuite, dans le volet Détails. Elle ne porte donc plus rien dans l'angle de son titre — ni boutons, ni picto — trois cibles de 32 points côte à côte se visaient mal, et le geste le plus fréquent, animer, était le plus petit. Pour un joueur, la carte reste informative : ses boutons à lui sont « Je viens » et « Je passe ».
- **Nouvelle session (`/tables/:id/sessions/new`)** : titre, lieu, date et heure, puis description. Une page plutôt qu'une fenêtre modale — cinq champs et un clavier virtuel ne tiennent pas dans une fenêtre centrée sur un téléphone, et faire défiler à l'intérieur d'une modale est un mauvais compromis. Les mêmes champs servent à la corriger depuis le mode MJ : c'est un seul widget, `tables/widgets/session_form.dart`, que ses deux hôtes se partagent.
- **Participer avec un personnage** : après avoir confirmé, un joueur dit avec qui il vient — ou le renseigne plus tard, les deux gestes étant séparés. Les autres membres peuvent alors consulter sa fiche en lecture seule, depuis la liste des présents.

> Le MJ n'est pas un participant : il anime la séance, il n'a donc rien à confirmer et n'apparaît pas parmi les joueurs attendus.
- **Mode MJ (`/tables/:id/sessions/:sessionId/mj`)** : l'écran depuis lequel le maître du jeu anime sa séance, ouvert d'un doigt sur la carte d'une session à venir. Six volets, dans un rail à gauche sur tablette et dans une barre d'onglets sur téléphone, **ouvert sur le premier** : **Détails** (les champs de la session, un bouton pour enregistrer, un autre pour l'annuler), **Plateau** (un fond de carte à choisir, un tiroir de pions nommés — repliables par rayon et cherchables — à faire glisser dessus, puis à déplacer, redimensionner ou retirer), **Personnages** (les fiches des joueurs qui viennent, puis les personnages non-joueurs que le MJ prépare pour cette séance), **Règles** (le même contenu que `/regles`, déplié), **Scénario** (le document téléchargé, rattaché à la session) et **Notes** (un carnet libre). Voir [Mode MJ](#mode-mj-tablette-et-téléphone).
- **Assets (`/assets`, depuis le menu du burger)** : la vitrine des pions qu'un MJ peut poser sur un plateau, rangés par rayon (Personnages, Environnement, Effets, Zones) — les pions achetés en boutique s'y rangent avec les autres, d'après leur nature, et non dans une rubrique à part. Le tiroir du mode MJ montre exactement les mêmes, mais seulement une fois la session ouverte : on ne pouvait pas savoir avant de s'asseoir à la table ce qu'on aurait sous la main. Les deux écrans lisent `boardCatalogueProvider` (`features/assets/providers/owned_assets_provider.dart`) et ne redéclarent rien — un pion ajouté au socle ou acheté en boutique apparaît des deux côtés sans qu'on y pense, et des tests l'exigent. Voir [Les pions achetés](#les-pions-achetés).
- **Boutique (`/boutique`)** : le catalogue en entier, possédé ou non — une boutique qui cacherait ce qu'on n'a pas acheté n'aurait rien à vendre. Une carte ne dit que l'image, le titre, le type et le prix ; la description attend la page de l'article (`/boutique/:id`), où « Obtenir » l'accorde. Un article déjà détenu porte « Possédé » à la place de son prix — ce qu'il coûtait n'intéresse plus personne une fois qu'il est à vous. Acheter un scénario le fait apparaître dans `/scenarios` sans autre geste.
- **Notifications (`/notifications`)** : historique des invitations, sessions et réponses. Doublé de notifications push (Firebase Cloud Messaging).
- **Profil (`/profil`)** : le compte connecté, son pseudo et l'état de la synchronisation. Le pseudo est la seule chose qui s'y modifie — l'adresse et la photo appartiennent à Google, et le serveur a cessé de recopier le nom Google à chaque connexion pour ne pas défaire ce choix. Tout en bas, et nulle part ailleurs, la suppression du compte : voir [Supprimer son compte](#supprimer-son-compte).
- **Livre de règle (`/regles`)** : les cinq chapitres de l'écran du gardien (Tests, Combat, Santé, Folie, Poursuites), en sommaire puis en chapitre.

- **Connexion (obligatoire)** : l'app démarre sur l'écran de connexion Google tant qu'aucun compte n'a été utilisé sur l'appareil. Il n'y a plus de « Continuer hors ligne ».

> **Sans réseau, l'app passe en consultation seule.** Personnages et tables restent lisibles — les seconds depuis la dernière réponse du serveur, datée à l'écran — mais rien ne peut être modifié tant que le serveur ne répond pas. Voir [Consultation seule](#consultation-seule-hors-ligne).

Toute l'interface utilise un design system interne « juicy » (boutons/cartes/dés avec relief, ombres et dégradés) inspiré d'une maquette produit, situé dans `lib/design_system/`.

### Navigation

Deux barres de chrome cuir encadrent chaque écran une fois connecté, et une seule règle les départage : **le bas est pour les endroits où l'on travaille, le haut pour tout le reste.**

- **En bas**, les trois onglets persistants : Perso, Tables et Boutique. Chacun garde sa pile — revenir à Tables retrouve la table qu'on lisait, pas la liste.
- **En haut**, le burger à gauche, le sigle au centre, la cloche des notifications à droite avec son sceau de non-lus.

Le volet du burger tient ce qui ne mérite pas un onglet : le compte connecté, Scénarios, Assets, Livre de règle, Profil, et la déconnexion en bas du panneau.

**Scénarios a quitté la barre du bas** pour ce volet. On y va préparer une partie avant qu'elle existe, pas pendant qu'on joue : ce n'est pas un endroit où l'on travaille en allers-retours, et lui garder un tiers de la barre disait le contraire. Le voisinage du Livre de règle est plus juste — deux lectures qu'on ouvre, pas deux chantiers qu'on reprend.

**La Boutique a pris la place laissée libre.** On la parcourt par allers-retours — une carte, son article, retour au rayon — et ce qu'on y obtient doit rester à portée sans rouvrir un menu. C'est bien un endroit où l'on travaille, au sens de la règle ci-dessus.

Trois conséquences valent d'être notées, parce que ce sont elles qui ont dicté la structure du routeur :

- **Les notifications ne sont plus rangées sous `/tables`.** La cloche est visible depuis partout ; ouvrir l'historique depuis une fiche de personnage allumait l'onglet Tables et faisait perdre sa place au lecteur. Une invitation arrive d'ailleurs avant qu'aucune table n'existe.
- Notifications, Scénarios, Assets, Profil et Livre de règle vivent donc dans une **branche sans onglet** (`StatefulShellBranch`), la dernière : aucun onglet ne s'allume pendant qu'elles sont à l'écran, ce qui est la vérité — elles n'appartiennent à aucun. Son index n'est pas écrit en dur dans `AppShell` mais lu sur `qbNavTabs.length`, pour que déplacer une destination dans la barre ou l'en sortir ne puisse pas laisser les deux en désaccord.
- Le « Retour » des notifications ramène à **l'onglet qu'on a quitté** (`lastTabProvider`), pas à un écran choisi d'avance. Renvoyer tout le monde vers les personnages aurait égaré celui qui venait d'une table.
- Le compteur de non-lus a quitté l'onglet Tables : la cloche le porte désormais, et l'afficher aux deux bouts de l'écran ne disait rien de plus.

L'`AccountBar` qui coiffait la liste des personnages a disparu : le compte est passé dans le volet, son état de synchronisation dans Profil. Le bouton « Synchroniser » n'a pas été déplacé, il a été **supprimé** — une passe part déjà à la connexion et à chaque retour au premier plan, si bien que le bouton n'offrait qu'une illusion de contrôle, et laissait croire que ce qu'on n'avait pas pressé n'était pas enregistré.

## Stack technique

| Domaine | Choix |
| --- | --- |
| Framework | Flutter (SDK Dart `^3.12.2`, canal stable) |
| État / DI | [`flutter_riverpod`](https://pub.dev/packages/flutter_riverpod) (`Notifier`, `Provider`, `FutureProvider`) |
| Navigation | [`go_router`](https://pub.dev/packages/go_router) (`StatefulShellRoute` : trois onglets, plus une branche sans onglet pour ce qu'ouvre la barre haute) |
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
├── board/                      # Fonds de carte du mode MJ (JPEG : l'illustration est
│                               # photographique, le PNG d'origine pesait huit fois plus)
├── brand/                      # logo-mark.png (le sigle découpé, porté par la barre
│                               # haute et la carte de connexion) et app-icon.png
│                               # (le badge opaque, lu uniquement par
│                               # flutter_launcher_icons)
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
│   ├── tables/                  # « Mes tables », détail d'une table, formulaire de
│   │                            # session, notifications
│   ├── game_master/             # Mode MJ : plein écran hors du shell, six
│   │                            # volets (détails, plateau, personnages,
│   │                            # règles, scénario, notes) en rail ou onglets
│   ├── assets/                  # Vitrine des pions du plateau, hors partie ;
│   │                            # lit le catalogue de game_master
│   ├── shop/                    # Boutique : catalogue, page d'un article,
│   │                            # achat ; les clés d'image se résolvent ici
│   ├── profile/                 # Compte connecté et état de la synchronisation
│   ├── rulebook/                # Livre de règle : sommaire + chapitres
│   │                            # (7e éd. Cthulhu : Tests, Combat, Santé,
│   │                            # Folie, Poursuites)
│   ├── auth/                    # Écran de connexion Google
│   └── shell/                   # AppShell : les deux barres de chrome (haut et bas)
│                                # (StatefulShellRoute), le volet du burger,
│                                # le bandeau hors ligne et l'onglet d'où l'on vient
├── services/
│   └── dice_service.dart       # Primitives de lancer de dés (dNombre, dPourcent), testable isolément
└── main.dart                    # Point d'entrée : ProviderScope + MaterialApp.router
```

### Couches applicatives

1. **`domain`** définit *quoi* (modèles + contrats de repository) et *comment calculer* (interface `RulesEngine`), sans savoir comment c'est stocké ni affiché.
2. **`data/local`** persiste ces modèles dans SQLite via Drift (`AppDatabase`), et traduit entre les lignes Drift générées (`*Row`) et les modèles `domain` dans les `Local*Repository`. **`data/universe`** découvre et parse tous les fichiers JSON sous `assets/universes/` en deux listes distinctes (par préfixe de nom de fichier) : les modes de création (`CreationModeConfig`) et les univers (`UniverseConfig`).
3. **`app/providers.dart`** est le point de câblage (DI) : il expose `appDatabaseProvider`, `availableCreationModesProvider`/`availableUniversesProvider` (les listes complètes, injectées depuis `main.dart` au démarrage), `selectedCreationModeProvider`/`selectedCreationModeIdProvider`/`selectedUniverseProvider` (le mode de création choisi par le joueur en cours de création de personnage, et l'univers qui va avec — que le joueur, lui, ne choisit pas), un provider par repository, et `rulesEngineProvider`. C'est le seul endroit à modifier pour brancher un futur backend distant (`Remote*Repository`) à la place du local.
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
- `RemoteCache` — la dernière réponse de l'API pour quelques lectures (tables, sessions), conservée telle quelle pour que l'onglet Tables reste lisible sans réseau. Voir [Consultation seule](#consultation-seule-hors-ligne).

Les tables de jeu **ne sont pas modélisées ici** : elles sont partagées entre plusieurs comptes et le serveur en reste la source de vérité. La table Drift `GameTables` de la maquette locale a été supprimée par la migration v2 → v3 ; ce que la v4 réintroduit est une copie en lecture seule, pas un modèle.

Ce schéma générique (`kind`/`key`/`label`/`value`) permet d'ajouter un nouveau système de jeu sans migration : seul un nouveau fichier de config JSON de mode de création (voir ci-dessous) change.

### Univers et mode de création

**L'univers ne se choisit plus : l'application est dédiée à l'Appel de Cthulhu.** Le multi-JDR dans une seule appli est trop coûteux pour le moment, donc aucun écran ne demande ni n'affiche d'univers — ni la création de personnage, ni celle d'une table. Ce qui suit décrit la mécanique interne, qui elle n'a pas bougé : le jour où un second univers arrive, il suffira de remettre un sélecteur dans `CharacterCreationScreen`.

Un **univers** (ex. "Call of Cthulhu") peut avoir plusieurs **modes de création** : des variantes de règles pour construire un personnage dans cet univers. Aujourd'hui, Call of Cthulhu en a deux : "Classique" (jets de dés) et "Simplifié" (caractéristiques choisies dans une liste de valeurs proposées plutôt que tirées aux dés) — un futur mode suivrait le même schéma. Un univers **structure** tout ce qui est commun à ses modes (caractéristiques, compétences, occupations, ressources, attributs globaux — voir [Configuration d'un univers](#configuration-dun-univers-assetsuniversesuniverse_json) juste après) ; chaque mode de création est un second fichier JSON qui ne porte que ce qui *diffère* réellement de ce tronc commun (voir [Configuration d'un mode de création](#configuration-dun-mode-de-création-assetsuniverses) ensuite).

Au démarrage, `main.dart` charge d'abord tous les univers (`loadAllUniverseConfigs()`), puis résout chaque mode de création qu'ils indexent (`loadAllCreationModeConfigs(universes)`) en fusionnant le tronc commun de son univers avec son propre fichier de surcharge (voir `lib/data/universe/universe_assets_loader.dart`, basé sur `AssetManifest` pour la découverte des `universe_*.json` — pas de liste codée en dur), puis les injecte via `availableCreationModesProvider`/`availableUniversesProvider`. Dans l'écran de création (`CharacterCreationScreen`), le joueur ne choisit que son "Mode de création", en bas de la même section que le nom et la description du personnage ; l'univers, lui, est celui du mode retenu. Ce choix pilote `selectedCreationModeIdProvider`/`selectedCreationModeProvider`/`selectedUniverseProvider`, dont dépend tout le reste du formulaire (occupations, caractéristiques, compétences…) — changer de sélection réinitialise le brouillon en cours. Chaque personnage garde une référence immuable vers le mode de création qui l'a vu naître via `Character.systemId` (voir `creationModeByIdProvider`, utilisé par la fiche de personnage pour toujours l'interpréter avec le bon jeu de règles, même si d'autres modes sont ajoutés plus tard).

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
3. rien de plus — le dossier `assets/universes/` entier est déjà déclaré dans `pubspec.yaml`, `loadAllUniverseConfigs()` découvre tout `universe_*.json` qui y apparaît sans changement de code, et `loadAllCreationModeConfigs()` résout chaque entrée de leurs `creation_modes` en suivant `configuration_file`. Un nouveau mode du même univers apparaît alors automatiquement dans le menu "Mode de création". Un nouvel **univers**, lui, demanderait en plus de rendre au joueur le sélecteur d'univers retiré de `CharacterCreationScreen` : sans lui, ses modes resteraient hors d'atteinte.

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

**La connexion est obligatoire.** Elle a longtemps été facultative, et l'écran
de connexion proposait « Continuer hors ligne ». Ce n'était plus tenable : les
tables sont partagées avec d'autres joueurs, et confirmer sa présence à une
séance suppose d'être quelqu'un que le serveur sait nommer. Un utilisateur
purement local n'avait accès à rien de tout cela.

**Ne pas confondre avec le réseau.** Une fois connecté, perdre le réseau ne
déconnecte pas : l'app bascule en **consultation seule**, décrite plus bas.

### Supprimer son compte

Tout en bas de `/profil`, dans une carte à part. Le dialogue de confirmation
énumère ce qui disparaît, et **compte les tables que le joueur anime** : elles
seront dissoutes, et disparaîtront aussi pour leurs joueurs. Dire « tes tables
seront supprimées » ne veut rien dire tant qu'on ne sait pas lesquelles.

C'est le serveur qui fait le travail, en une cascade (`DELETE /auth/me`).
L'appareil n'agit qu'ensuite, et seulement si le serveur a accepté : jetons
effacés, puis les personnages, les scénarios téléchargés et les plateaux de
session. La déconnexion, elle, épargne les personnages — ils remonteront à la
prochaine connexion. Ici il n'y a plus rien où les remonter, et les garder
serait conserver ce qu'on a demandé d'effacer.

Si le serveur refuse, rien n'est touché localement et le message s'affiche dans
le dialogue : l'appareil reste connecté à un compte qui existe toujours, ce qui
est la vérité.

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

Côté Google Cloud, il faut **trois** clients OAuth dans le même projet :

- un client **Web** (dont l'id est le define ci-dessus, et le seul que l'API
  accepte) ;
- un client **Android** déclarant le `applicationId` et l'empreinte SHA-1 de la
  clé de signature — celle de debug pour `flutter run`, celle du keystore de
  release (voir [Signature de release Android](#signature-de-release-android))
  pour les builds distribués ;
- un client **iOS** déclarant le bundle `com.questbook.questbook`. Son
  identifiant inversé est le schéma d'URL dans `ios/Runner/Info.plist`
  (`GIDClientID` / `CFBundleURLTypes`).

Un SHA-1 Android manquant, ou un schéma d'URL iOS absent, est la cause la plus
fréquente d'une connexion qui échoue avec « Google n'a pas renvoyé de jeton
d'identité ».

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
  effacées : les personnages **et** le cache des tables du compte précédent
  ne doivent pas fuiter dans la nouvelle session.

Les personnages créés avant cette fonctionnalité sont poussés tels quels à la
première connexion (migration Drift v1 → v2, voir `lib/data/local/database.dart`).

### Tables : le choix inverse

Les tables ne suivent **pas** ce modèle. Une table est partagée entre plusieurs
comptes qui la modifient en même temps ; en faire une source de vérité locale
obligerait à résoudre des conflits sur des données que l'utilisateur ne
contrôle pas seul. L'onglet Tables lit donc l'API directement (`FutureProvider`
dans `lib/features/tables/providers/`). La maquette locale des débuts a été
supprimée par la migration Drift v2 → v3.

Ce que le téléphone garde, depuis la v4, c'est la **dernière réponse** du
serveur (table `RemoteCache`), et rien de plus : jamais un brouillon, jamais
une modification en attente. Sans réseau, l'onglet rejoue cette copie en
annonçant sa date plutôt que d'afficher une erreur — voir ci-dessous.

L'entrée est volontairement opaque : elle stocke l'enveloppe JSON brute, qui
repasse par le `fromJson` du chemin normal. Recopier la forme du serveur en
colonnes imposerait une migration à chaque champ ajouté à l'API, pour un cache
qu'on ne fait que relire.

### Consultation seule (hors ligne)

Ce que voit un utilisateur déjà connecté mais sans réseau :

- ses personnages et ses tables, **en lecture** ;
- un bandeau « Hors ligne — consultation seule » en haut de l'app, avec un
  « Réessayer » ;
- la date de la copie affichée sur l'onglet Tables et sur le détail d'une
  table ;
- **aucun bouton d'écriture** : ni création de personnage ou de table, ni
  réponse à une session, ni invitation, ni transmission du MJ. Ils sont retirés
  plutôt que désactivés, et le bandeau dit pourquoi — un bouton grisé sans
  explication se lit comme une panne.

La connectivité est **mesurée, pas déclarée** (`connectivityProvider` dans
`lib/app/remote_providers.dart`) : un téléphone peut afficher quatre barres
derrière un portail captif, donc ce qui compte est de savoir si le serveur
répond. Chaque requête rend son verdict à l'`ApiClient`, et tant que la réponse
est non, une sonde légère (`GET /health`, toutes les 20 s, plus au retour au
premier plan) continue de demander — sinon un utilisateur qui retrouve la 4G
resterait bloqué sur sa copie sans rien pour l'en sortir. Dès que le réseau
revient, les tables sont rechargées.

Un refus du serveur (403, 404…) n'est **pas** un motif de repli sur le cache :
c'est une nouvelle réelle à propos du compte, et afficher les tables d'hier
par-dessus l'enterrerait. Seule une panne réseau déclenche le repli.

Le cache est rattaché à un compte et effacé à la déconnexion : sur un téléphone
partagé, personne ne doit tomber sur les tables du joueur précédent. Android
désactive les sauvegardes (`allowBackup=false`) ; iOS exclut Application
Support d'iCloud. Les jetons et l'email du compte connecté restent dans le
Keystore / Keychain de l'appareil, sans synchronisation iCloud.

Un cas se tient à la frontière des deux modèles : le personnage qu'un joueur
inscrit à une session. Le choix se fait dans une liste lue en local, mais c'est
l'identifiant qui part au serveur, lequel ne connaît que les personnages déjà
synchronisés. Un personnage créé hors-ligne et jamais poussé revient donc en
404, et la boîte de dialogue invite explicitement à synchroniser.

La fiche d'un autre participant, elle, est lue en ligne et n'est jamais écrite
sur l'appareil : elle appartient à quelqu'un d'autre, et c'est à lui de la
changer.

### Mode MJ (tablette et téléphone)

Le mode MJ (`lib/features/game_master/`) est le seul écran déclaré **hors du
`StatefulShellRoute`** : une partie prend l'appareil entier, et la barre
d'onglets n'y mène nulle part. « Quitter le mode MJ » ramène au détail de la
table.

**Aucun écran n'est refusé** : c'est la disposition qui s'adapte, pas l'accès.
`game_master_layout.dart` (`measureGameMasterLayout`) tranche entre deux
présentations du même contenu, à partir de la place disponible — 900 × 560
points, ce qu'il faut pour étaler le rail, la carte et le tiroir de front :

| Disposition | Quand | Ce que ça donne |
| --- | --- | --- |
| `rail` | Tablette en paysage | Rail de six volets à gauche, tiroir d'assets ouvert à droite de la carte |
| `tabs` | Téléphone, tablette en portrait, fenêtre réduite | Onglets sous l'entête, tiroir en surimpression |

En disposition compacte, les six volets tiennent dans une barre d'onglets
**en icônes seules** : six libellés dans la largeur d'un téléphone seraient
illisibles. Seul le volet actif est nommé, et il prend pour cela la place que
les cinq autres ne réclament pas. Faute de rail, l'entête accueille le nom
de la table et le bouton de sortie. Un volet de plus rogne cette place :
ajouter un septième demanderait autre chose qu'une rangée fixe.

**Le mode MJ s'ouvre sur le volet Détails**, et non sur le plateau : on y
arrive surtout avant la partie, pour vérifier l'heure, le lieu ou le scénario.
Poser des pions est le geste d'un soir ; relire ce qu'est la séance, celui de
tous les jours qui précèdent.

Le volet **Détails** est celui par lequel une session se corrige. Il réutilise
le formulaire de création (`tables/widgets/session_form.dart`) et n'envoie que
les champs qui ont bougé — une date renvoyée telle quelle ressemblerait, vue
du serveur, à un report, et réveillerait toute la table. Enregistrer laisse le
MJ sur place, avec un toast pour toute confirmation : on corrige une heure
sans sortir de la partie en cours. Annuler la session, en revanche, referme le
mode MJ — il n'y a plus rien à y animer.

Le plateau, lui, est le seul volet à ne pas tenir tel quel : la carte et un
tiroir de 280 points ne cohabitent pas sur un téléphone. Le tiroir y **recouvre
la carte** au lieu de la pousser, démarre rangé, et **se range de lui-même dès
qu'on tire un pion** — le garder ouvert reviendrait à viser derrière lui. Une
languette et une bande de carte restent visibles : on voit toujours ce qu'on
recouvre.

La disposition est remesurée à chaque `build` : pivoter l'appareil en pleine
partie bascule du rail aux onglets sans quitter la session.

**L'état du plateau reste sur l'appareil**, dans la table Drift
`session_boards` (clé primaire `{sessionId, accountId}`, voir
`data/local/session_board_dao.dart`). Deux raisons : le plateau se manipule
pion par pion pendant la partie, souvent loin d'un réseau fiable, et il ne
regarde que le MJ. Les pions y sont rangés en JSON opaque — même parti pris que
`remote_cache` : la forme d'un pion peut changer sans migration. Les positions
et les tailles sont des **fractions de la carte**, jamais des pixels, pour que
le plateau se retrouve identique d'un écran à l'autre. Comme le cache et les
scénarios téléchargés, la table est vidée à la déconnexion.

**Le plateau se reconstruit seul.** Pions, sélection et poignées vivent dans
des `ValueNotifier` détenus par le volet, et seule la pile du plateau les
écoute. Un glissement ne repasse donc ni par l'écran MJ ni par le tiroir :
les faire remonter reconstruisait le rail, l'entête et les vignettes à chaque
image, et le pion traînait derrière le doigt. La carte, elle, est isolée dans
un `RepaintBoundary` pour ne pas être repeinte pendant qu'un pion bouge.

Les pions restent des enfants directs de la pile du plateau. Les regrouper
dans une pile à eux, si tentant que ce soit pour la lisibilité, leur fait
perdre le toucher.

Le tiroir tient son catalogue dans `models/board_catalog.dart` : les cartes
d'un côté, les pions rangés par rayon de l'autre, chacun avec un nom. Ajouter
une carte, c'est une image sous `assets/board/` et une entrée dans la liste.
La recherche porte sur ce nom et sur le titre du rayon, sans casse ni accents,
et déplie au passage les rayons repliés.

#### Les pions achetés

Le catalogue n'est plus une constante : c'est la somme d'un socle commun et de
ce que le compte a acheté, assemblée par `boardAssetSectionsFor` et servie par
`boardCatalogueProvider` (`features/assets/providers/owned_assets_provider.dart`)
au tiroir comme à `/assets`.

**Un pion acheté se range dans les rayons existants, d'après sa nature** — le
Grand Ancien est un personnage, il se trouve avec les personnages — et non dans
une vitrine « ma collection » à part. Deux endroits où regarder pour une même
question (« qu'est-ce que je peux poser comme PNJ ? ») se seraient écartés un
peu plus à chaque achat. `boardSectionTitleFor` fait ce rangement à partir du
`BoardTokenKind`, et un test vérifie que le socle lui-même s'y conforme, ce qui
interdit à un rayon de dériver de la nature qu'il affiche. Les achats arrivent
en fin de rayon : repérables, sans déplacer ce que le MJ a l'habitude de
trouver en tête.

Le serveur ne décrit pas à quoi ressemble un pion : la boutique n'envoie qu'une
`assetKey`, et le dessin qui lui correspond vit dans `purchasableBoardAssets`,
du côté qui peint. Une clé qu'une version de l'app ne connaît pas encore est
donc simplement ignorée — le tiroir s'ouvre sans rubrique vide ni pion sans
visage.

Un pion posé garde cette clé (`BoardToken.assetKey`, absente des plateaux
enregistrés avant la boutique, et c'est très bien : le socle se décrit
entièrement par sa forme et sa couleur). **Un pion dont le lecteur ne possède
pas l'asset se rend en rond rouge** plutôt que de disparaître : perdre une
position en silence serait pire que l'afficher au mauvais visage. Ce repli est
aujourd'hui inatteignable — le plateau ne quitte pas l'appareil, donc personne
d'autre ne le lit — et il est là pour le jour où les plateaux se partageront.

Les clés possédées viennent de `/shop/items`, dont le résumé porte déjà `owned`
et `assetKey`. Elles sont gardées dans `remote_cache` comme les tables et les
scénarios, alors que la boutique elle-même ne se lit pas hors ligne : il n'y a
rien à acheter sans réseau, mais une partie se joue parfois sans couverture, et
un MJ dont les pions payés disparaîtraient du tiroir à ce moment-là n'aurait
aucun moyen de les retrouver.

L'écriture suit le geste : pendant un glissement l'état ne vit qu'en mémoire,
et il part sur le disque à la fin du geste. Les notes, elles, s'enregistrent
500 ms après la dernière frappe — une transaction SQLite par caractère serait
absurde.

Deux limites assumées pour l'instant : les fiches des joueurs viennent de l'API
une par une (`GET /sessions/:id/attendances/:userId/character` est le seul
appel qui les autorise) — le volet Personnages en montre le résumé et ouvre
la fiche entière, la même qu'à la table, en lecture seule — et ne sont donc
**pas lisibles hors ligne**, et le
plateau ne quitte pas l'appareil — un MJ qui change d'appareil repart d'une
carte vierge.

#### Les personnages non-joueurs

Sous les fiches des joueurs, dans le même volet : créatures, indicateurs,
esprits. Un nom, une description libre, et rien d'autre — ce ne sont pas des
fiches de personnage, et leur donner des caractéristiques serait une autre
fonctionnalité. Le MJ en ajoute, en corrige et en retire ; toucher une carte
rouvre le formulaire rempli, pour qu'une coquille ne force pas à tout retaper.

Ils vivent **sur le serveur**, contrairement au plateau et aux notes, et sont
attachés à la **session** : ce qu'on prépare pour une veillée n'est pas ce
qu'on prépare pour la suivante. Le revers est qu'ils ne se lisent pas hors
ligne, et le volet le dit plutôt que d'afficher une liste vide.

Les routes sont réservées au MJ, lectures comprises : ce qu'il a écrit est
exactement ce que ses joueurs ne doivent pas savoir. `GET /sessions/:id` ne les
renvoie pas, il faut les demander — il n'y a donc pas de vue joueur à concevoir
ni à oublier de protéger.

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

`android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist` et
`lib/firebase_options.dart` sont **versionnés volontairement** : ils ne
contiennent pas de secret (ils sont de toute façon embarqués dans l'APK/IPA)
et la CI en a besoin pour construire le release. Pour les régénérer :

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=questbook-48540 --platforms=android,ios \
  --android-package-name=com.questbook.questbook \
  --ios-bundle-id=com.questbook.questbook
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
- `data/local/migration_test.dart` — les migrations sur un vrai fichier SQLite ramené aux schémas v1, v2 puis v3, pour vérifier qu'aucun personnage existant n'est perdu, que `updatedAt` est bien rempli, que la maquette locale des tables est bien supprimée en v3 et que le cache s'ouvre en v4.
- `data/local/remote_cache_dao_test.dart` — le cache rend ce qu'on lui a confié, remplace une entrée au lieu d'en empiler, et refuse de montrer celle d'un autre compte.
- `features/tables/offline_tables_test.dart` — le repli hors ligne bout en bout : la copie est rejouée quand le serveur est injoignable et datée, un refus du serveur passe au travers sans être masqué, et l'écriture est refusée tant que le réseau n'est pas revenu.
- `data/sync/sync_service_test.dart` — les règles de synchronisation (push, pull, conflits, changement de compte) contre une fausse API et une vraie base en mémoire.
- `data/remote/api_client_test.dart` — le rafraîchissement du jeton contre un vrai serveur HTTP local : un 401 déclenche un refresh puis un seul rejeu, plusieurs requêtes simultanées ne brûlent qu'un seul refresh token, et un refresh refusé termine la session au lieu de boucler. Vérifie aussi qu'une requête sans corps ne déclare pas de type de média : Dio estampille tout `application/json`, ce qu'un serveur strict lit comme la promesse d'un corps qui ne vient jamais.

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

## Distribution (signature, Firebase, CI/CD)

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
          ├─ ubuntu : flutter build apk --release   (keystore "upload")
          ├─ macos  : flutter build ipa --release    (certificat Ad Hoc)
          └─ ubuntu : firebase appdistribution:distribute des deux binaires
                 └─▶ groupe de testeurs "testeurs"
                        └─▶ email + lien de téléchargement pour chaque testeur
```

Android et iOS partent **ensemble**. Si l'IPA ne se signe pas, l'APK n'est pas
envoyé non plus, et le tag de version n'est pas posé : un retry peut
repartir sur le même numéro.

Quatre briques composent ce dispositif, détaillées ci-dessous : la **signature
Android**, la **signature iOS**, le **projet Firebase**, et le **workflow CI**.

### Icône de l'application

Les mipmaps Android et l'`AppIcon.appiconset` iOS sont **générés puis
versionnés** :

```bash
dart run flutter_launcher_icons
```

La commande se lance à la main, quand la marque change ; la CI n'a rien à
refaire. Sa configuration vit dans `pubspec.yaml`, et elle lit deux fichiers
plutôt qu'un, parce qu'Android compose sa propre icône : `app-icon.png` est le
badge arrondi et opaque que servent les lanceurs anciens tel quel, tandis que
`logo-mark.png` — le sigle découpé, sur fond `#001712` — est la couche qu'un
lanceur moderne masque et fait bouger en parallaxe.

Ce sigle est inséré de 20 % : Android ne garantit que les **66 % centraux**
d'une couche adaptative, et sans cet inset les ailes et les tentacules du bas
se font couper par tout masque rond ou en squircle.

### Numéro de version

**Monter `version` dans `pubspec.yaml` fait partie de la PR, pas de l'après.**
Deux distributions sous le même numéro sont indiscernables pour un testeur, qui
ne peut plus savoir laquelle il a installée, et le `versionCode` Android figé
interdit toute publication ultérieure sur le Play Store.

Le workflow refuse donc de **reconstruire** une version déjà livrée : le job
de version réussit en sautant le build, pour qu'un merge docs/CI vers `main`
ne casse pas la release en cours. Pour envoyer un nouveau binaire aux
testeurs, monter `version` dans `pubspec.yaml`.

Le tag est posé **après** la distribution, pour qu'un build en échec ne brûle pas
son numéro.

> C'est arrivé le 11 septembre : la feature « Tables de jeu » est partie en
> `1.2.0+4`, le numéro exact de la release du 5 septembre, sans que rien ne le
> signale. D'où ce garde-fou.

### Signature de release Android

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

### Signature de release iOS

Firebase App Distribution n'accepte pas un IPA « App Store » : il faut un
export **Ad Hoc**, signé avec un certificat Apple Distribution et un profil
de provisioning qui liste les UDID des appareils testeurs.

Rien de tout ça n'est dans git. La CI importe le `.p12` depuis un secret,
régénère le profil Ad Hoc à chaque build avec `fastlane` (voir
[UDID des testeurs iOS](#udid-des-testeurs-ios)), en extrait toute seule le
Team ID et le nom du profil, et lance :

```bash
flutter build ipa --release --export-options-plist=ExportOptions.plist
```

#### Créer le certificat et le profil (une fois)

1. Dans [developer.apple.com](https://developer.apple.com/account) →
   Identifiers : un App ID **explicit** `com.questbook.questbook`.
2. Certificates : **Apple Distribution**. Apple demande un CSR :
   - **Sur Mac** : Keychain Access → Certificate Assistant → Request a
     Certificate From a Certificate Authority, puis uploader le `.certSigningRequest`.
   - **Sans Mac** (OpenSSL) :

     ```bash
     openssl genrsa -out ios-distribution.key 2048
     openssl req -new -key ios-distribution.key -out ios-distribution.csr \
       -subj "/CN=Questbook Distribution/O=Questbook/C=FR"
     ```

     Uploader le `.csr`, télécharger le `.cer`, puis :

     ```bash
     openssl x509 -in ios_distribution.cer -inform DER -out ios_distribution.pem
     openssl pkcs12 -export -inkey ios-distribution.key -in ios_distribution.pem \
       -out ios-distribution.p12
     ```

     Garder la clé `.key` et le `.p12` dans le coffre-fort d'équipe, jamais
     dans git. Sans la clé privée, le `.cer` Apple ne sert à rien.
3. Devices : rien à enregistrer à la main, la CI s'en charge — voir
   [UDID des testeurs iOS](#udid-des-testeurs-ios).
4. Profiles : rien à créer non plus. `fastlane` génère le profil **Ad Hoc**
   au premier build, puis le régénère à chaque fois avec le certificat
   Distribution et tous les appareils connus du compte.

#### Secrets GitHub

Sur une machine qui a les fichiers (PowerShell) :

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("ios-distribution.p12")) | Set-Clipboard
```

Sur macOS : `base64 -i ios-distribution.p12 | pbcopy`.

Coller dans `Settings → Secrets and variables → Actions` :

| Secret                              | Contenu                                      |
| ----------------------------------- | -------------------------------------------- |
| `IOS_BUILD_CERTIFICATE_BASE64`      | Le `.p12` en une seule ligne base64          |
| `IOS_P12_PASSWORD`                  | Mot de passe choisi à l'export du `.p12`     |

S'y ajoute la clé App Store Connect (`APP_STORE_CONNECT_ISSUER_ID`,
`APP_STORE_CONNECT_KEY_ID`, `APP_STORE_CONNECT_API_KEY`), partagée avec la
publication sur les stores. Elle doit avoir le rôle **App Manager** : le job
s'en sert pour enregistrer des appareils et régénérer le profil, ce qui
demande plus de droits qu'un simple envoi vers TestFlight.

Le Team ID n'est pas un secret : le job le lit dans le profil.

> ⚠️ **Ne perds pas la clé privée du certificat Distribution.** Un nouveau
> certificat se crée, mais il faudra régénérer le profil et mettre à jour
> les secrets. Sauvegarde `ios-distribution.key` / `.p12` dans le même
> coffre-fort que le keystore Android.

#### UDID des testeurs iOS

Un IPA Ad Hoc n'installe que sur les appareils listés dans son profil de
provisioning. Firebase collecte bien l'UDID quand un testeur enregistre son
appareil, mais il s'arrête là : c'est au projet de déclarer l'appareil chez
Apple et de rediffuser un build signé avec un profil à jour.

Le job `ios` de `firebase-distribution.yml` fait cet aller-retour tout seul,
via la lane `refresh_adhoc_profile` (`ios/fastlane/Fastfile`) :

1. `firebase_app_distribution_get_udids` récupère les UDID connus de Firebase.
2. `register_devices` les déclare sur le portail Apple.
3. `get_provisioning_profile(adhoc: true, force: true)` régénère le profil ;
   `force` est ce qui y réinjecte tous les appareils du compte.

Côté testeur, il reste donc **un seul geste** : ouvrir le lien Firebase et
enregistrer son appareil. Son UDID sera pris en compte au build suivant.
Aucun profil n'a plus besoin d'être stocké en secret.

Deux limites à garder en tête :

- Un appareil enregistré ne rattrape pas les builds déjà publiés. Il faut
  attendre la prochaine distribution.
- Apple plafonne le nombre d'appareils enregistrables par an (100 par type).
  Le compteur ne se remet à zéro qu'au renouvellement de l'adhésion.

Android n'a pas cet aller-retour : n'importe quel testeur du groupe
télécharge l'APK. iOS, si — mais il est désormais automatique.

#### Mode développeur sur l'appareil du testeur

Une fois l'app installée, iOS 16 et plus refuse de l'ouvrir tant que le
**mode développeur** n'est pas activé : « Developer Mode Required ». C'est une
contrainte d'Apple sur toute distribution **Ad Hoc**, même signée avec un
certificat Apple Distribution, et
[documentée par Firebase](https://firebase.google.com/docs/app-distribution/troubleshooting).
Aucun réglage de certificat ou de profil ne l'enlève.

C'est une condition qui **s'ajoute** à l'enregistrement de l'UDID, elle ne le
remplace pas : sans UDID l'app ne s'installe pas, sans mode développeur elle
ne s'ouvre pas.

Sur l'appareil, une seule fois :

1. **Réglages → Confidentialité et sécurité**, section **Sécurité**.
2. **Mode développeur** → activer l'interrupteur.
3. Redémarrer quand l'iPhone/iPad le demande.
4. Après le redémarrage, déverrouiller et confirmer **Activer**.

> Le piège : avant que l'app ne soit installée, l'entrée **Mode développeur**
> **n'existe pas** dans les Réglages — on n'y voit que « Mode isolement ». Elle
> n'apparaît qu'une fois présente sur l'appareil une app qui l'exige. Inutile
> donc de demander à un testeur de l'activer en amont : il ne trouvera rien.

Seuls TestFlight, l'App Store et la distribution Enterprise échappent à cette
contrainte. Si un jour la manipulation devient un frein pour les testeurs, la
sortie est de basculer les tests iOS sur TestFlight — que
[`store-publish.yml`](.github/workflows/store-publish.yml) sait déjà
alimenter — ce qui supprimerait au passage toute la mécanique des UDID.

### Firebase App Distribution

- **Projet Firebase** : `questbook-48540` (console :
  [console.firebase.google.com/project/questbook-48540](https://console.firebase.google.com/project/questbook-48540)).
- **App Android enregistrée** : package `com.questbook.questbook`, App ID
  Firebase `1:56734402863:android:8f12f08f8eff13a8e2b9da` (visible dans
  Project settings → General, ou via `firebase apps:list`).
- **App iOS enregistrée** : bundle `com.questbook.questbook`, App ID
  Firebase `1:56734402863:ios:b0ba4650fb4476f3e2b9da`.
- **Groupe de testeurs** : alias `testeurs` (affiché « Testeurs Questbook »
  dans la console). Le même groupe reçoit l'APK et l'IPA. Ajouter un testeur :
  ```bash
  firebase appdistribution:testers:add nouveau.testeur@example.com --group-alias testeurs --project questbook-48540
  ```
- Chaque testeur reçoit un email d'invitation avec un lien de téléchargement
  direct (aucun compte Google Play / TestFlight requis). Sur iOS, l'appareil
  doit figurer dans le profil Ad Hoc — voir
  [Signature de release iOS](#signature-de-release-ios).

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

Il enchaîne quatre jobs : vérification du numéro de version → build Android
(ubuntu) et build iOS (macos) **en parallèle** → distribution des deux
binaires vers le groupe `testeurs` puis pose du tag. L'APK n'est envoyé
qu'une fois l'IPA signé, pour qu'un échec iOS ne brûle pas le numéro.

Il a besoin de **10 secrets** définis dans
`Settings → Secrets and variables → Actions` du repo GitHub :

| Secret                               | Contenu                                                              |
| ------------------------------------ | --------------------------------------------------------------------- |
| `ANDROID_KEYSTORE_BASE64`            | Le fichier `upload-keystore.jks` encodé en base64 (une seule ligne)   |
| `ANDROID_KEYSTORE_PASSWORD`          | Mot de passe du keystore (`storePassword`)                            |
| `ANDROID_KEY_PASSWORD`               | Idem (même valeur, voir note PKCS12 ci-dessus)                        |
| `ANDROID_KEY_ALIAS`                  | `upload`                                                               |
| `IOS_BUILD_CERTIFICATE_BASE64`       | Certificat Apple Distribution (`.p12`) en base64                      |
| `IOS_P12_PASSWORD`                   | Mot de passe du `.p12`                                                |
| `APP_STORE_CONNECT_ISSUER_ID`        | Issuer ID de la clé App Store Connect (rôle App Manager)              |
| `APP_STORE_CONNECT_KEY_ID`           | Identifiant de cette clé                                              |
| `APP_STORE_CONNECT_API_KEY`          | Contenu du `.p8` de cette clé                                         |
| `FIREBASE_TOKEN`                     | Token CI généré via `firebase login:ci` (voir note de dépréciation ci-dessous) |

Le profil Ad Hoc n'est plus un secret : il est régénéré à chaque build à
partir de la clé App Store Connect, en même temps que les appareils des
nouveaux testeurs sont enregistrés chez Apple.

Les App ID Firebase et le Project ID ne sont *pas* secrets — ils sont en dur
dans le workflow (`env:` en tête de fichier).

> ⚠️ `firebase login:ci` / l'option `--token` de `firebase-tools` sont
> marquées comme dépréciées par Google au profit de l'authentification par
> compte de service. Elles fonctionnent encore avec `firebase-tools` 15.x
> (utilisé ici), mais si Google les retire dans une future version majeure,
> il faudra migrer l'étape « Distribute » du workflow vers un compte de
> service GCP (rôle *Firebase App Distribution Admin*) exposé via
> `GOOGLE_APPLICATION_CREDENTIALS`, en remplacement de `--token`.

### Publication sur les stores

Deux pistes, volontairement séparées :

| Piste | Déclencheur | Destinataires | Artefact |
| --- | --- | --- | --- |
| Testeurs | Merge **`dev` → `main`** | Groupe Firebase `testeurs` | APK + IPA Ad Hoc, tag `vX.Y.Z+N` |
| Stores | **GitHub Release** créée sur ce tag | Play Console (piste interne) + TestFlight | AAB + IPA App Store |

Pas de branche `release/*`. Le tag posé par la distribution testeurs *est* la
release : en faire une GitHub Release est le geste humain « ça a été validé,
envoie-le aux stores ». C'est le modèle GitHub standard (un tag, une Release,
un workflow `release: published`).

```
1. Merger dev → main          → testeurs, tag v1.6.0+8
2. Valider sur un appareil
3. gh release create v1.6.0+8 → Play internal (brouillon) + TestFlight
4. Dans les consoles, promouvoir vers prod / soumettre la review
```

Étape 3, une fois le tag posé :

```bash
gh release create v1.6.0+8 --title "1.6.0" --notes "Invitations sans compte, boutons MJ, emails privés."
```

Un retry sans recréer la Release : onglet Actions → **Publish to Play Store
and TestFlight** → Run workflow (il refuse si le tag testeurs n'existe pas).

Le workflow [`.github/workflows/store-publish.yml`](.github/workflows/store-publish.yml)
ne construit **pas** le même binaire que Firebase : Play exige un `.aab`,
TestFlight un IPA signé **App Store** (le profil Ad Hoc des testeurs est
refusé). Le certificat Apple Distribution, lui, est le même.

#### Secrets supplémentaires

En plus des 8 secrets de la distribution testeurs :

| Secret | Contenu |
| --- | --- |
| `PLAY_SERVICE_ACCOUNT_JSON` | JSON du compte de service Play Console (une seule ligne ou le fichier entier) |
| `IOS_APPSTORE_PROVISION_PROFILE_BASE64` | Profil **App Store** (pas Ad Hoc) en base64 |
| `APP_STORE_CONNECT_ISSUER_ID` | UUID issuer de la clé API App Store Connect |
| `APP_STORE_CONNECT_KEY_ID` | Identifiant de la clé (10 caractères) |
| `APP_STORE_CONNECT_API_KEY` | Contenu du fichier `.p8` (AuthKey_XXXX.p8) |

#### À faire une fois dans les consoles (Robin)

Ces gestes ne passent pas par le code. Sans eux le workflow échoue, et c'est
voulu : un upload vers un store qui n'existe pas encore n'aiderait personne.

**Google Play**

1. Créer l'application `com.questbook.questbook` dans Play Console.
2. Activer la **signature d'application Play** en lui donnant la clé upload
   déjà utilisée par Firebase (`.secrets/upload-keystore.jks`).
3. Google Cloud → compte de service avec le rôle *Service Account User*,
   puis Play Console → *Utilisateurs et droits* → inviter ce compte
   (permissions *Versions* sur l'app).
4. Télécharger la clé JSON, la coller dans `PLAY_SERVICE_ACCOUNT_JSON`.
5. Remplir la fiche (politique de confidentialité, captures, questionnaire
   contenu). La CI dépose un **brouillon** sur la piste interne
   (`changesNotSentForReview`) : rien n'est envoyé en review tout seul.

**App Store Connect**

1. Créer l'app iOS bundle `com.questbook.questbook`.
2. Portail développeur : profil de provisioning **App Store** pour ce bundle
   (le certificat Distribution déjà dans `IOS_BUILD_CERTIFICATE_BASE64`
   suffit). Encoder le `.mobileprovision` en base64 comme pour l'Ad Hoc.
3. App Store Connect → *Intégrations* → *Clés API* : clé *App Manager*,
   noter Issuer ID + Key ID, garder le `.p8`.
4. Coller le tout dans les trois secrets `APP_STORE_CONNECT_*`.

La promotion piste interne → production (Play) et TestFlight → App Store
reste manuelle dans les consoles : c'est là que vivent la review, les
captures, et le texte de version.

### Déployer manuellement (sans la CI)

Utile en local si tu as le keystore / le certificat et que tu veux tester une
distribution avant de pousser.

Android (Windows compris) :

```bash
flutter build apk --release
firebase appdistribution:distribute build/app/outputs/flutter-apk/app-release.apk \
  --app 1:56734402863:android:8f12f08f8eff13a8e2b9da \
  --project questbook-48540 \
  --groups "testeurs" \
  --release-notes "Description de ce build"
```

iOS (macOS uniquement, Xcode + le profil Ad Hoc installé) :

```bash
flutter build ipa --release --export-method=ad-hoc
firebase appdistribution:distribute build/ios/ipa/*.ipa \
  --app 1:56734402863:ios:b0ba4650fb4476f3e2b9da \
  --project questbook-48540 \
  --groups "testeurs" \
  --release-notes "Description de ce build"
```

(nécessite `firebase login` préalable — sur Windows/PowerShell, utiliser
`firebase.cmd` si l'exécution de scripts `.ps1` est bloquée par la
politique d'exécution).

### Reprendre ce setup sur une nouvelle machine

Un `git clone` frais **n'inclut ni le keystore Android, ni le certificat iOS,
ni les mots de passe** (volontairement, ils sont gitignorés). Deux cas :

- **Tu veux juste lancer/développer l'app** : rien à faire côté Android, les
  builds `debug` et même `release` fonctionnent (signature debug de repli —
  voir [Signature de release Android](#signature-de-release-android)). Sur
  iOS, Xcode demandera le Team ID du compte Apple pour signer en automatique.
- **Tu veux publier/distribuer un vrai build** :
  - Android : le fichier `upload-keystore.jks` existant (demande-le à un
    mainteneur ayant accès à `.secrets/`, ne le régénère surtout pas — un
    nouveau keystore ne correspondrait plus à ce qui a déjà été distribué)
    et un `android/key.properties` qui pointe dessus, avec les mêmes valeurs
    que les secrets GitHub `ANDROID_KEYSTORE_*`.
  - iOS : le `.p12` Distribution et le profil Ad Hoc déjà utilisés par la CI,
    pas un nouveau certificat. Les secrets `IOS_*` du dépôt font foi.

## Limitations connues

- L'application ne connaît qu'un univers, l'Appel de Cthulhu, et ne le dit nulle part : le joueur ne choisit que le mode de création ("Classique" ou "Simplifié"). Le mécanisme de config par JSON supporte toujours plusieurs univers, mais y revenir demanderait de réafficher un sélecteur — voir [Univers et mode de création](#univers-et-mode-de-création).
- Le mode "Simplifié" ne fait qu'assigner librement une valeur à chaque caractéristique (`calculation_method: "choice"`) : il n'empêche pas de choisir deux fois la même valeur, alors que la règle CdC7 d'origine impose de répartir un jeu fixe de 8 valeurs (40, 50, 50, 50, 60, 60, 70, 80) sans répétition au-delà de ce que ce jeu autorise. Ajouter cette contrainte demanderait un nouveau mécanisme de "pool partagé sans répétition", pas juste une liste de choix par caractéristique.
- Le palier de "Bonus aux dégâts" (IMP) est simplifié en indice de palier (-2 à 5+) plutôt qu'en expression de dés (`+1D4`, `+2D6`…) : le schéma stocke les stats en entier, pas en expression. Voir le champ `description` de `IMP` dans le fichier de config pour la correspondance réelle.
- Pas de support desktop/web packagé nativement (voir ci-dessus).
- Le **Livre de règle** ne couvre que les cinq chapitres de l'écran du gardien (Tests, Combat, Santé, Folie, Poursuites), rédigés en dur dans `features/rulebook/content/`. Compétences et occupations n'y sont pas, et un second univers devrait apporter son propre catalogue.
- Le **mode MJ** tourne sur téléphone comme sur tablette, mais ne quitte pas l'appareil : ni plateau ni notes ne remontent au serveur, donc changer d'appareil repart d'une carte vierge. Sur un écran étroit, le plateau reste le volet le plus à l'étroit — la carte y est petite, et les poignées de redimensionnement sont d'autant plus serrées que le pion l'est. Les fiches des joueurs, elles, viennent de l'API une par une et ne sont pas lisibles hors ligne. Deux fonds de carte seulement, écrits en dur dans `board_catalog.dart` ; le catalogue viendra du back avec les scénarios. Les pions sont des formes colorées nommées, sans illustration.
- L'écriture hors ligne ne couvre que les personnages (stats, ressources, inventaire), et encore : elle est bloquée par la consultation seule tant que le serveur ne répond pas. Les tables et les sessions ne s'écrivent qu'en ligne.
- Hors ligne, l'onglet Tables ne montre que ce qui a déjà été ouvert au moins une fois avec du réseau : le détail d'une table jamais consultée n'a pas de copie à rejouer. Les notifications ne sont pas mises en cache du tout.
- La sonde de retour réseau tourne toutes les 20 s tant qu'on est hors ligne. Le retour peut donc mettre jusqu'à 20 s à être remarqué si l'utilisateur ne touche à rien, un compromis assumé face à une dépendance à `connectivity_plus` qui, elle, ne dirait rien de la joignabilité réelle du serveur.
- Les notifications push iOS s'initialisent (Firebase a une app iOS) mais
  l'envoi APNs demande une clé Apple déposée dans la console Firebase. Sans
  elle, seul l'historique in-app fonctionne sur iPhone.
- Pas de relance en cas d'échec d'envoi d'un e-mail ou d'un push : les deux partent au mieux après le commit. La ligne de notification, elle, est écrite dans la transaction, donc l'historique in-app reste juste. Une table d'outbox avec relance reste un ajout simple si le besoin apparaît.
- Distribution actuelle limitée à Firebase App Distribution (bêta-testeurs) ; pas encore de publication Play Store ni App Store, ni de Play App Signing (la clé de signature `upload` est gérée manuellement — voir [Distribution](#distribution-signature-firebase-cicd)).
- L'authentification CI Firebase (`firebase login:ci` / `--token`) repose sur un mécanisme déprécié par Google ; à migrer vers un compte de service GCP si `firebase-tools` le retire dans une future version majeure.
