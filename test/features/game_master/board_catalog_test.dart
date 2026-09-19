import 'package:flutter_test/flutter_test.dart';
import 'package:questbook/features/game_master/models/board_catalog.dart';

void main() {
  group('boardMapById', () {
    test('falls back to the first map when nothing was chosen yet', () {
      expect(boardMapById(null).id, boardMaps.first.id);
    });

    test('falls back rather than leaving an empty board on a stale id', () {
      expect(boardMapById('carte-supprimee').id, boardMaps.first.id);
    });

    test('gives back the chosen map', () {
      expect(boardMapById('grille').label, 'Grille vierge');
    });
  });

  group('filterBoardAssets', () {
    test('an empty search leaves the whole drawer alone', () {
      expect(filterBoardAssets('   '), same(boardAssetSections));
    });

    test('finds a piece by name, dropping the sections that have none', () {
      final sections = filterBoardAssets('jaune');

      // Les zones sont jaunes elles aussi, mais ne s'appellent pas ainsi :
      // c'est le nom qui est cherché, pas la teinte.
      expect(sections.map((s) => s.title), [
        'Personnages',
        'Environnement',
        'Effets',
      ]);
      expect(
        sections.first.assets.map((a) => a.name),
        ['Joueur jaune'],
      );
    });

    test('a section title brings back its whole shelf', () {
      final sections = filterBoardAssets('personnages');

      expect(sections, hasLength(1));
      expect(sections.single.assets, hasLength(4));
    });

    test('ignores case and accents', () {
      final sections = filterBoardAssets('CARREE');

      expect(sections.single.assets.single.name, 'Zone carrée');
    });

    test('says nothing rather than everything when nothing matches', () {
      expect(filterBoardAssets('dragon'), isEmpty);
    });
  });

  test('every piece carries a name, since the search relies on it', () {
    for (final section in boardAssetSections) {
      for (final asset in section.assets) {
        expect(asset.name, isNotEmpty);
      }
    }
  });
}
