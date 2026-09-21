import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Les volets de l'écran de session, dans l'ordre où ils s'affichent.
enum GameMasterPanel {
  details('Détails', LucideIcons.settings),
  board('Plateau', LucideIcons.map),
  characters('Personnages', LucideIcons.users),
  rules('Règles', LucideIcons.bookOpen),
  scenario('Scénario', LucideIcons.scroll),
  notes('Notes', LucideIcons.notebookPen);

  const GameMasterPanel(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// À quel titre on est entré dans l'écran de session.
///
/// **Lu sur la table, pas sur la route.** Les deux rôles partagent l'adresse,
/// et c'est délibéré : une restriction posée sur le chemin se contourne en
/// tapant l'autre, alors qu'un rôle déduit de l'appartenance à la table ne se
/// contourne pas. Tant qu'on ne sait pas encore, on est joueur — on n'ouvre
/// pas les volets du MJ par défaut pour les refermer ensuite.
enum SessionSeat {
  /// Il anime : il dispose le plateau, corrige la séance, lit les PNJ qu'il a
  /// préparés et ses propres notes.
  gameMaster,

  /// Il joue : il regarde le plateau bouger et les investigateurs de la
  /// table. Rien d'autre, et rien qu'il puisse changer.
  player;

  bool get isGameMaster => this == SessionSeat.gameMaster;

  /// Ce que chacun voit. Le joueur n'a que deux volets, si bien que la barre
  /// d'onglets tient sans se serrer là où celle du MJ en porte six.
  ///
  /// Ni **Détails** — la séance ne se corrige pas depuis sa chaise, et
  /// l'entête en dit déjà l'heure et le lieu — ni **Scénario**, que le MJ
  /// raconte et ne montre pas, ni **Notes**, qui sont les siennes. Les
  /// **Règles** restent à `/regles` pour tout le monde.
  List<GameMasterPanel> get panels => switch (this) {
        SessionSeat.gameMaster => GameMasterPanel.values,
        SessionSeat.player => const [
            GameMasterPanel.board,
            GameMasterPanel.characters,
          ],
      };

  /// Le volet d'accueil. Le MJ arrive ici avant la partie, pour vérifier
  /// l'heure et le lieu ; le joueur, lui, n'entre qu'une fois la séance
  /// commencée et vient voir le plateau.
  GameMasterPanel get landing => switch (this) {
        SessionSeat.gameMaster => GameMasterPanel.details,
        SessionSeat.player => GameMasterPanel.board,
      };

  /// Le nom d'un volet, qui dépend de ce qu'on y trouve.
  ///
  /// Un seul écart : **Personnages** réunit les investigateurs et les PNJ chez
  /// le MJ, et ce mot-là les couvre tous les deux. Le joueur n'y voit que les
  /// investigateurs, et c'est ainsi qu'ils s'appellent partout ailleurs dans
  /// l'app.
  String labelFor(GameMasterPanel panel) =>
      panel == GameMasterPanel.characters && !isGameMaster
          ? 'Investigateurs'
          : panel.label;
}
