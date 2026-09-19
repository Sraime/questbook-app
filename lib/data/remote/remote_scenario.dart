/// Wire format of the scenario catalogue. List payloads stay small; the full
/// document is fetched only when the user downloads it for offline reading.
library;

class RemoteScenarioSummary {
  const RemoteScenarioSummary({
    required this.id,
    required this.title,
    required this.description,
    required this.minRecommendedPlayers,
    required this.maxRecommendedPlayers,
    required this.averageDurationMinutes,
  });

  factory RemoteScenarioSummary.fromJson(Map<String, dynamic> json) =>
      RemoteScenarioSummary(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        minRecommendedPlayers: json['minRecommendedPlayers'] as int,
        maxRecommendedPlayers: json['maxRecommendedPlayers'] as int,
        averageDurationMinutes: json['averageDurationMinutes'] as int,
      );

  final String id;
  final String title;
  final String description;
  final int minRecommendedPlayers;
  final int maxRecommendedPlayers;
  final int averageDurationMinutes;

  String get playersLabel =>
      '$minRecommendedPlayers–$maxRecommendedPlayers joueurs';

  String get durationLabel {
    final hours = averageDurationMinutes ~/ 60;
    final minutes = averageDurationMinutes % 60;
    if (hours == 0) return '$minutes min';
    if (minutes == 0) return hours == 1 ? '1 h' : '$hours h';
    return '$hours h $minutes';
  }
}

class RemoteScenarioAnnex {
  const RemoteScenarioAnnex({
    required this.id,
    required this.sortOrder,
    required this.title,
    required this.kind,
    required this.contentMarkdown,
  });

  factory RemoteScenarioAnnex.fromJson(Map<String, dynamic> json) =>
      RemoteScenarioAnnex(
        id: json['id'] as String,
        sortOrder: json['sortOrder'] as int,
        title: json['title'] as String,
        kind: json['kind'] as String,
        contentMarkdown: json['contentMarkdown'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'sortOrder': sortOrder,
        'title': title,
        'kind': kind,
        'contentMarkdown': contentMarkdown,
      };

  final String id;
  final int sortOrder;
  final String title;
  final String kind;
  final String contentMarkdown;
}

class RemoteScenarioDetail extends RemoteScenarioSummary {
  const RemoteScenarioDetail({
    required super.id,
    required super.title,
    required super.description,
    required super.minRecommendedPlayers,
    required super.maxRecommendedPlayers,
    required super.averageDurationMinutes,
    required this.context,
    required this.rundownMarkdown,
    required this.annexes,
  });

  factory RemoteScenarioDetail.fromJson(Map<String, dynamic> json) =>
      RemoteScenarioDetail(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        minRecommendedPlayers: json['minRecommendedPlayers'] as int,
        maxRecommendedPlayers: json['maxRecommendedPlayers'] as int,
        averageDurationMinutes: json['averageDurationMinutes'] as int,
        context: json['context'] as String,
        rundownMarkdown: json['rundownMarkdown'] as String,
        annexes: [
          for (final entry in (json['annexes'] as List? ?? const [])
              .whereType<Map>())
            RemoteScenarioAnnex.fromJson(entry.cast<String, dynamic>()),
        ],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'minRecommendedPlayers': minRecommendedPlayers,
        'maxRecommendedPlayers': maxRecommendedPlayers,
        'averageDurationMinutes': averageDurationMinutes,
        'context': context,
        'rundownMarkdown': rundownMarkdown,
        'annexes': [for (final annex in annexes) annex.toJson()],
      };

  final String context;
  final String rundownMarkdown;
  final List<RemoteScenarioAnnex> annexes;
}

class RemoteSessionScenario {
  const RemoteSessionScenario({required this.id, required this.title});

  factory RemoteSessionScenario.fromJson(Map<String, dynamic> json) =>
      RemoteSessionScenario(
        id: json['id'] as String,
        title: json['title'] as String,
      );

  final String id;
  final String title;
}
