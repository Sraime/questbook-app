import 'package:flutter_test/flutter_test.dart';
import 'package:questbook/features/scenarios/scenario_outline.dart';

void main() {
  test('coupe a chaque titre, et garde la ligne de titre dans le corps', () {
    final sections = splitByHeadings(
      '## Mise en place\n\nDonner le télégramme.\n\n## 1. Le village\n\nLes rumeurs se contredisent.',
    );

    expect(sections.map((s) => s.title), ['Mise en place', '1. Le village']);
    expect(sections.first.markdown, startsWith('## Mise en place'));
    expect(sections.last.markdown, contains('Les rumeurs'));
  });

  /// Ce qui précède le premier titre appartient à la section d'accueil : il
  /// n'a pas d'intitulé à mettre au sommaire.
  test('garde le texte d’avant le premier titre, sans le nommer', () {
    final sections = splitByHeadings('Une phrase seule.\n\n## Suite\n\nEncore.');

    expect(sections.first.title, isNull);
    expect(sections.first.markdown, 'Une phrase seule.');
    expect(sections.last.title, 'Suite');
  });

  /// Un sommaire qui descend à tous les étages n'aide plus à viser.
  test('laisse les titres plus fins dans le corps de leur section', () {
    final sections = splitByHeadings('## Le phare\n\n### La lanterne\n\nChaude.');

    expect(sections, hasLength(1));
    expect(sections.single.markdown, contains('### La lanterne'));
  });

  test('ignore un dièse pris dans un bloc de code', () {
    final sections = splitByHeadings('## Vrai\n\n```\n## Faux\n```\n');

    expect(sections.map((s) => s.title), ['Vrai']);
  });

  test('ne rend rien d’un document vide', () {
    expect(splitByHeadings('   \n\n'), isEmpty);
  });
}
