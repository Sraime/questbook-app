/// Decouper un document markdown la ou ses titres le decoupent deja.
///
/// Sert au sommaire de l'ecran d'un scenario : un deroule de quinze pages se
/// parcourt mal au pouce, et l'auteur a deja dit ou commencent ses scenes.
/// Rien ici ne rend quoi que ce soit — c'est du texte qui entre et du texte
/// qui sort, ce qui rend la chose verifiable sans arbre de widgets.
library;

class MarkdownSection {
  const MarkdownSection({
    required this.title,
    required this.level,
    required this.markdown,
  });

  /// Nul pour ce qui precede le premier titre : une mise en bouche sans
  /// intitule, qui appartient a la section d'accueil plutot qu'au sommaire.
  final String? title;
  final int level;

  /// La ligne de titre comprise, pour que le rendu reste exactement celui du
  /// document entier : c'est `QBMarkdown` qui met en forme les titres, et lui
  /// seul doit decider a quoi ils ressemblent.
  final String markdown;
}

final _heading = RegExp(r'^(#{1,6})\s+(.*)$');
final _fence = RegExp(r'^\s*(```|~~~)');

/// Coupe a chaque titre de niveau au plus [maxLevel]. Les titres plus fins
/// restent dans le corps de leur section : un sommaire qui descend a tous les
/// etages n'aide plus personne a viser.
List<MarkdownSection> splitByHeadings(String markdown, {int maxLevel = 2}) {
  final sections = <MarkdownSection>[];
  final buffer = <String>[];
  String? title;
  var level = 0;
  var inFence = false;

  void flush() {
    final body = buffer.join('\n').trim();
    if (title == null && body.isEmpty) return;
    sections.add(
      MarkdownSection(title: title, level: level, markdown: body),
    );
  }

  for (final line in markdown.split('\n')) {
    // Un `#` dans un bloc de code est un commentaire, pas un titre. Le cas ne
    // s'est pas encore presente dans le catalogue, et il coute trois lignes.
    if (_fence.hasMatch(line)) inFence = !inFence;

    final match = inFence ? null : _heading.firstMatch(line);
    final foundLevel = match == null ? 0 : match.group(1)!.length;

    if (match != null && foundLevel <= maxLevel) {
      flush();
      buffer.clear();
      title = match.group(2)!.replaceAll(RegExp(r'\s*#+\s*$'), '').trim();
      level = foundLevel;
    }

    buffer.add(line);
  }

  flush();

  return sections;
}
