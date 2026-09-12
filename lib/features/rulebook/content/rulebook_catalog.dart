import 'chapter_combat.dart';
import 'chapter_folie.dart';
import 'chapter_poursuites.dart';
import 'chapter_sante.dart';
import 'chapter_tests.dart';
import 'rulebook_models.dart';

/// The five keeper-screen chapters, in the order the sommaire shows them.
const rulebookChapters = <RulebookChapter>[
  chapterTests,
  chapterCombat,
  chapterSante,
  chapterFolie,
  chapterPoursuites,
];

RulebookChapter? rulebookChapterById(String id) {
  for (final chapter in rulebookChapters) {
    if (chapter.id == id) return chapter;
  }
  return null;
}
