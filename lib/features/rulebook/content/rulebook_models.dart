/// Structured copy for one chapter of the in-app rulebook.
///
/// Kept as plain Dart (no Freezed, no JSON) on purpose: the text is rewritten
/// for the screen, not loaded from a publisher file, and it ships with the
/// app. A later universe can add its own catalog the same way.
class RulebookChapter {
  const RulebookChapter({
    required this.id,
    required this.title,
    required this.summary,
    this.sections = const [],
  });

  final String id;
  final String title;

  /// One line on the table of contents card.
  final String summary;
  final List<RulebookSection> sections;

  bool get isReady => sections.isNotEmpty;
}

class RulebookSection {
  const RulebookSection({
    required this.id,
    required this.title,
    required this.blocks,
  });

  final String id;
  final String title;
  final List<RulebookBlock> blocks;
}

sealed class RulebookBlock {
  const RulebookBlock();
}

final class RulebookParagraph extends RulebookBlock {
  const RulebookParagraph(this.text);

  final String text;
}

final class RulebookBullets extends RulebookBlock {
  const RulebookBullets(this.items);

  final List<String> items;
}

final class RulebookTable extends RulebookBlock {
  const RulebookTable({required this.headers, required this.rows});

  final List<String> headers;
  final List<List<String>> rows;
}

enum RulebookCalloutTone { info, warning }

final class RulebookCallout extends RulebookBlock {
  const RulebookCallout(
    this.text, {
    this.tone = RulebookCalloutTone.info,
  });

  final String text;
  final RulebookCalloutTone tone;
}
