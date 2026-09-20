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

  group('boardAssetSectionsFor', () {
    test('un compte sans achat ne voit que le socle', () {
      expect(boardAssetSectionsFor(const {}), same(boardAssetSections));
    });

    test('ce qui a été acheté rejoint le catalogue, à la suite du socle', () {
      final sections = boardAssetSectionsFor(const {'grand_ancien'});

      expect(sections.length, boardAssetSections.length + 1);
      expect(sections.last.title, 'Ma collection');
      expect(sections.last.assets.single.name, 'Le Grand Ancien');
      // La clé voyage avec le pion : c'est elle que le plateau enregistre.
      expect(sections.last.assets.single.key, 'grand_ancien');
    });

    test('une clé que cette version ne connaît pas est passée sous silence',
        () {
      // Un article ajouté au serveur après la sortie de l'app : le tiroir
      // s'ouvre quand même, sans rubrique vide ni pion sans dessin.
      expect(
        boardAssetSectionsFor(const {'dragon_de_jade'}),
        same(boardAssetSections),
      );
    });

    test('la recherche porte aussi sur la collection', () {
      final sections = filterBoardAssets(
        'ancien',
        sections: boardAssetSectionsFor(const {'grand_ancien'}),
      );

      expect(sections.single.assets.single.name, 'Le Grand Ancien');
    });
  });

  group('boardAssetForKey', () {
    test('rend le pion d’une clé connue', () {
      expect(boardAssetForKey('grand_ancien')?.image, isNotNull);
    });

    test('rend null sur une clé inconnue, à l’affichage de décider', () {
      expect(boardAssetForKey('dragon_de_jade'), isNull);
      expect(boardAssetForKey(null), isNull);
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
