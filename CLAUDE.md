# CLAUDE.md

Contexte projet pour les agents IA (Claude Code, Cursor, etc.). Pour la
documentation fonctionnelle/architecture complète, voir **`README.md`** —
ce fichier ne duplique pas ce qui y est déjà bien expliqué, il se concentre
sur ce qu'un agent doit savoir *avant d'agir* : pièges connus, conventions,
et état actuel du projet.

## En une phrase

Questbook = app Flutter de compagnon de jeu de rôle sur table (perso,
compétences, dés, tables de jeu), seedée avec L'Appel de Cthulhu v7.
Riverpod + go_router + Drift (SQLite local). UI et textes en **français**,
code/commentaires en **anglais**.

## Avant de coder : lire le README

`README.md` documente en détail : architecture en couches (`domain` →
`data` → `app/providers.dart` → `features`), schéma Drift, le pattern
`RulesEngine` pour l'extensibilité multi-système, et toute la chaîne de
signature/distribution/CI. Le lire d'abord évite de redécouvrir tout ça à
chaque session.

## Environnement de dev (Windows)

Ce projet est développé sur **Windows / PowerShell**. Pièges rencontrés :

- **PowerShell bloque les scripts `.ps1`** installés par npm (politique
  d'exécution par défaut). Pour `firebase-tools`, utiliser `firebase.cmd`
  au lieu de `firebase` (le `.cmd` contourne le blocage sans toucher à la
  politique système).
- **`git push`/`firebase login` sont interactifs** (ouvrent un navigateur
  via Git Credential Manager / OAuth) — ça ne fonctionne **pas** depuis un
  shell non-interactif automatisé. Il faut soit laisser l'utilisateur
  lancer la commande lui-même dans son propre terminal, soit utiliser une
  méthode non-interactive (token, `--with-token`, etc.).
- **`keytool` n'est pas dans le PATH** mais existe dans le JDK embarqué
  d'Android Studio : `C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe`.
- **Fichiers `.properties` Java** (ex. `android/key.properties`) : un
  backslash Windows dans une valeur (`storeFile=C:\Users\...`) casse le
  parsing (`Malformed \uxxxx encoding`). Toujours utiliser des slashs `/`
  dans ces fichiers.
- Un émulateur Android est déjà configuré : `questbook_test` (voir
  `flutter emulators`). Le web (`flutter run -d chrome`) et le desktop ne
  sont **pas** configurés nativement dans ce repo (pas de dossier `web/`
  ni `windows/`) — voir la section Web/Desktop du README avant d'essayer.

## Secrets — ne jamais committer, ne jamais afficher en clair

- `.secrets/` (keystore de release, mots de passe, tokens) et
  `android/key.properties` sont gitignorés. Ne pas les recréer à la légère
  ni en afficher le contenu dans une réponse — les lire/écrire via des
  commandes qui ne les impriment pas en sortie.
- Le keystore de release (`upload-keystore.jks`, alias `upload`) ne doit
  **jamais être régénéré** une fois des builds distribués avec — ça
  casserait la continuité des mises à jour. Voir README →
  [Signature de release](README.md#signature-de-release).

## Git flow — important pour toute future contribution

- **`dev`** = branche de travail (tout se commit ici, ou sur des branches
  `feature/*` ouvertes depuis `dev`).
- **`main`** = branche de release, protégée. Mise à jour **uniquement**
  via Pull Request `dev → main`, jamais de push direct.
- La CI (`.github/workflows/firebase-distribution.yml`) ne se déclenche
  **que** quand une PR vers `main` est mergée (ou manuellement via
  `workflow_dispatch`) — surtout pas à chaque push, pour ne pas spammer les
  testeurs Firebase avec des builds sans évolution fonctionnelle.
- Avant de proposer un `git push origin main` direct : s'arrêter et
  proposer une PR depuis `dev` à la place.

## Commandes utiles

```bash
flutter pub get                                              # dépendances
dart run build_runner build --delete-conflicting-outputs     # régénère Drift/freezed/json_serializable
flutter test                                                 # tests unitaires
flutter run -d <device_id>                                   # lancer (voir `flutter devices`)
flutter build apk --release                                  # build release (signé si android/key.properties existe, sinon fallback debug)
```

## Pièges Riverpod/Flutter déjà rencontrés dans ce code

- **Ne jamais muter un provider Riverpod de façon synchrone dans
  `initState()`** d'un widget affiché pendant un build (ex. une modale
  ouverte depuis `onTap`). Ça lève `Tried to modify a provider while the
  widget tree was building`. Solution appliquée : différer l'appel via
  `WidgetsBinding.instance.addPostFrameCallback`. Voir
  `lib/features/character_creation/widgets/characteristic_roll_dialog.dart`
  pour l'exemple corrigé.
- **`QBButton`** (`lib/design_system/components/qb_button.dart`) enveloppe
  son contenu dans un `FittedBox` pour éviter les `RenderFlex overflowed`
  quand un label français long est utilisé dans une rangée de boutons
  serrée (ex. deux `QBButton` côte à côte dans une modale de 320px). Si un
  nouveau label déborde encore, c'est probablement un cas plus extrême du
  même problème — pas la peine de rajouter un `FittedBox` ad hoc ailleurs,
  le composant le gère déjà.
- Les captures d'écran/diagnostics sur cette machine passent par **`adb`**
  directement (`$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe`) —
  utiliser `adb shell screencap -p /sdcard/x.png` + `adb pull`, jamais
  `adb exec-out ... > fichier` en PowerShell (corrompt le PNG binaire à
  cause de la traduction de fin de ligne).

## Fiche de personnage pilotée par config JSON (`assets/universes/`)

Les caractéristiques, compétences, occupations (+ bonus) et ressources
(PV/SAN/PM) ne sont **pas** codées en dur : elles viennent des fichiers
`assets/universes/`, interprétés en `CreationModeConfig`
(`lib/domain/models/creation_mode_config.dart`) par
`ConfigRulesEngine`/`FormulaEvaluator`
(`lib/domain/rules/config_rules_engine.dart` et `formula_evaluator.dart`) —
un petit interpréteur qui gère dés (`3D6`), arithmétique
(`+ - * / Floor() Max(a, b, ...)`) et conditions (`>= <= && ||`) à partir de
simples chaînes du JSON. Voir la section
[Univers et mode de création](README.md#univers-et-mode-de-création)
du README pour le détail.

- **Deux types de fichiers cohabitent** dans `assets/universes/`,
 distingués par préfixe de nom : `universe_<id>.json` = un **univers**
 (`UniverseConfig` — nom, description, url du pdf de règles, seuils de
 critique, **et** un `general_configuration` : le tronc commun
 characteristics/skills/occupations/resources/global_attributes partagé
 par tous ses modes) ; tout le reste = un fichier de **surcharges** pour un
 mode de création précis, référencé par le `configuration_file` de
 l'entrée correspondante dans `creation_modes` de son univers — pas
 d'`id`/`name`/`description` dans ce fichier, juste un `character_sheet`
 qui ne porte que ce qui *diffère* du `general_configuration` (ex. le
 `calculation_method` d'une caractéristique, alors que son `name`/
 `description` restent hérités). `UniverseConfig.generalConfigurationJson`
 reste volontairement **non parsé** (`Map<String, dynamic>` brut) — la
 fusion doit se faire au niveau JSON, champ par champ, avant que
 `CharacterSheetConfig.fromJson` ne s'exécute une seule fois sur le
 résultat.
- `CharacterSheetConfig.merge({general, overrides})`
 (`lib/domain/models/creation_mode_config.dart`) fait cette fusion, liste
 par liste, **par `key`** (`_mergeEntriesByKey`) : une entrée des deux
 côtés est fusionnée champ par champ (`overrides` gagne) ; une entrée
 seulement côté `overrides` est un ajout propre à ce mode (ex. la
 compétence `mythe_de_cthulhu`, propre à "Classique") ; une entrée
 seulement côté `general` est héritée sans y toucher. `buildCreationModeConfig`
 (`lib/data/universe/universe_assets_loader.dart`) assemble ensuite
 id/nom/description (venant de l'entrée `creation_modes` de l'univers,
 **pas** du fichier de mode) + ce `character_sheet` fusionné — exposé
 séparément du chargement `rootBundle` pour que les tests puissent
 l'exercer directement sur les fichiers réels via `dart:io` (voir
 `test/domain/models/creation_mode_config_test.dart`).
 `loadAllUniverseConfigs()`/`loadAllCreationModeConfigs(universes)` (cette
 dernière prend désormais la liste d'univers déjà chargée, pour résoudre
 les `configuration_file` qu'ils indexent) restent basés sur
 `AssetManifest` — pas de liste d'ids codée en dur — et sont exposés via
 `availableUniversesProvider`/`availableCreationModesProvider`. Si tu
 cherches encore `critical_success_max` dans un `character_sheet` (fichier
 de mode ou `general_configuration`), c'est normal qu'il n'y soit lu que
 depuis le **niveau univers** (top-level du fichier `universe_*.json`, pas
 depuis `general_configuration` qui en porte une copie non lue/inerte) —
 `ConfigRulesEngine` prend `(CreationModeConfig, UniverseConfig)` en
 constructeur.
- Le joueur choisit "Univers" puis (même carte, avec nom/description du
 personnage) "Mode de création" en haut de l'écran de création
 (`CharacterCreationScreen`), ce qui pilote
 `selectedCreationModeIdProvider`/`selectedCreationModeProvider`/
 `selectedUniverseProvider` — dont dépend tout le reste du formulaire.
 Ajouter un mode de création (ex. un futur "Débutant") = un nouveau
 fichier de surcharges + une entrée dans `creation_modes` de son univers,
 aucun changement Dart. Chaque personnage garde son `systemId` d'origine
 (`Character.systemId`) ; la fiche le relit via `creationModeByIdProvider`
 plutôt que la sélection courante, pour rester correcte même si d'autres
 modes sont ajoutés après.
- Call of Cthulhu a deux modes, tous deux définis par surcharge du même
 `general_configuration` : "Classique" (`call_of_cthulhu_classique.json`,
 dés) et "Simplifié" (`call_of_cthulhu_simplifie.json`) où FOR/DEX/CON/
 POU/APP/ÉDU/INT/TAI sont choisies dans `["40","50","60","70","80"]` au
 lieu d'être lancées — leur `name`/`description` restent identiques dans
 les deux (hérités), seul `calculation_method`/`calculation_formula`/
 `choices` change. Ce sont des `calculation_method: "choice"`
 **numériques** — voir `CharacteristicConfig.isNumericChoice`/
 `choiceValueAt` et `CharacterSheetConfig.numericChoiceCharacteristics`. Un
 choix numérique alimente `CharacterCreationState.resolvedCharacteristics`
 avec sa **vraie valeur** (pas son index) : sinon `ConfigRulesEngine`
 planterait sur les formules dérivées/compétences/ressources qui
 référencent ces clés (`DEX / 2`, `(CON + TAI) / 10`…), puisque
 `FormulaEvaluator` lève une erreur sur un identifiant inconnu.
- Pour changer une règle de calcul (formule de caractéristique, seuil de
  palier, bonus d'occupation…), éditer le JSON, **pas** le code Dart — sauf
  mécanique réellement nouvelle que l'évaluateur ne sait pas exprimer.
- Il y a **deux** budgets de points de compétence distincts, cumulables sur
  une même compétence :
  - `character_sheet.personal_skill_points` (une seule formule par univers,
    ex. `"INT * 2"` pour CdC v7 —
    `CharacterSheetConfig.personalSkillPointsFormula`,
    `CharacterCreationState.skillPointsTotal`/`skillAllocated`) : dépensable
    sur n'importe quelle compétence.
  - `occupations[].occupation_skill_points_formula` (une formule par
    occupation, ex. `"EDU * 4"` ou `"EDU * 2 + Max(FOR, DEX) * 2"` —
    `OccupationConfig.occupationSkillPointsFormula`,
    `CharacterCreationState.occupationSkillPointsTotal`/
    `occupationSkillAllocated`) : dépensable **uniquement** sur
    `occupations[].occupation_skills` (+ les créneaux
    `occupation_skill_choices` où le joueur choisit lui-même une compétence
    supplémentaire éligible — `occupationSkillChoiceSelections`,
    `setOccupationSkillChoice`). Changer d'occupation réinitialise ce
    budget (les compétences éligibles changent).
  - Les deux sont distincts de `occupations[].skills_bonus`, un bonus fixe
    et non réparti par le joueur que le schéma permet d'accorder
    automatiquement à des compétences précises — aucune occupation de
    CdC v7 ne s'en sert plus depuis l'introduction des points d'occupation
    ci-dessus, mais le champ reste dans le modèle
    (`OccupationConfig.skillsBonus`/`skillBonusFor`) pour un futur système.
- Les infos propres à un univers mais qui ne sont **jamais lues par une
  formule** (juste enregistrées/affichées) vivent dans
  `character_sheet.global_attributes`, pas dans `characteristics` — c'est
  la différence avec une caractéristique à choix numérique ci-dessus.
  `GlobalAttributeConfig` (`lib/domain/models/creation_mode_config.dart`)
  a un `type` : `"integer"` (nombre libre, ex. l'âge) ou `"choice"` (liste
  fixe `choices: [...]`, stockée comme l'index dans cette liste — CdC v7
  s'en sert pour Fortune : "Indigent" → "Richissime", qui a remplacé
  l'ancienne compétence Crédit). Voir
  `CharacterCreationState.globalAttributeValues`/
  `globalAttributeChoiceLabel`/`setGlobalAttributeValue` — les champs
  apparaissent dans l'écran de création juste après le choix de
  l'occupation (`QBSelect` pour `choice`, `QBInput` numérique pour
  `integer`). Persisté comme `CharacterStat` avec `kind:
  StatKind.attribute` (3e valeur de l'enum, à côté de
  `characteristic`/`skill` — voir `Character.attributes`). Sur la fiche,
  ces attributs sont affichés en badge texte (pas dans un `QBStatDial`,
  pensé pour un nombre de caractéristique) — voir `_OverviewTab` dans
  `character_sheet_screen.dart`. Ne pas confondre avec le nom/la
  description du personnage : ceux-ci sont communs à tout univers et
  restent hors de ce fichier de config.
- `main.dart` charge tous ces fichiers une fois avant `runApp` et injecte la
  liste via `availableCreationModesProvider.overrideWithValue(...)` (plus
  un id par défaut pour `selectedCreationModeIdProvider`) : c'est pour ça
  que ces providers lèvent une erreur s'ils ne sont jamais overridés (ne
  pas essayer de les lire depuis un test sans leur fournir une valeur, cf.
  `test/domain/rules/config_rules_engine_test.dart` pour construire un
  `CreationModeConfig` minimal à la main).
- Les regex de `FormulaEvaluator` utilisent `matchAsPrefix(string, start)`
  **sans** ancre `^` : en Dart, `^` vise le tout début de la chaîne, pas le
  paramètre `start` — un piège déjà rencontré en écrivant ce fichier.

## Firebase (App Distribution uniquement, pas de SDK dans l'app)

- Projet `questbook-48540`, app Android
  `1:56734402863:android:8f12f08f8eff13a8e2b9da`, groupe de testeurs
  `testeurs`. Détails complets dans README →
  [Distribution Android](README.md#distribution-android-signature-firebase-cicd).
