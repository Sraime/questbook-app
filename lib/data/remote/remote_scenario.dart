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

/// Un PNJ que l'aventure livre avec elle, et que le MJ retrouve dans sa
/// séance à côté de ceux qu'il a écrits.
class RemoteScenarioNpc {
  const RemoteScenarioNpc({
    required this.id,
    required this.sortOrder,
    required this.name,
    required this.description,
  });

  factory RemoteScenarioNpc.fromJson(Map<String, dynamic> json) =>
      RemoteScenarioNpc(
        id: json['id'] as String,
        sortOrder: json['sortOrder'] as int,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'sortOrder': sortOrder,
        'name': name,
        'description': description,
      };

  final String id;
  final int sortOrder;
  final String name;
  final String description;
}

/// Ce que l'aventure destine à passer de l'autre côté de l'écran : un
/// télégramme, un carnet trempé, une page arrachée.
///
/// S'appelait une annexe et ne se lisait que dans l'écran du scénario. C'est
/// désormais la même chose que le MJ transmet pendant la séance, donc le mot
/// du produit s'applique.
class RemoteScenarioClue {
  const RemoteScenarioClue({
    required this.id,
    required this.sortOrder,
    required this.title,
    required this.contentMarkdown,
  });

  factory RemoteScenarioClue.fromJson(Map<String, dynamic> json) =>
      RemoteScenarioClue(
        id: json['id'] as String,
        sortOrder: json['sortOrder'] as int,
        title: json['title'] as String,
        contentMarkdown: json['contentMarkdown'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'sortOrder': sortOrder,
        'title': title,
        'contentMarkdown': contentMarkdown,
      };

  final String id;
  final int sortOrder;
  final String title;
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
    required this.npcs,
    required this.clues,
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
        npcs: [
          for (final entry
              in (json['npcs'] as List? ?? const []).whereType<Map>())
            RemoteScenarioNpc.fromJson(entry.cast<String, dynamic>()),
        ],
        // `annexes` est l'ancien nom du même contenu. Un scénario téléchargé
        // avant cette version dort dans la base locale sous cette clé, et il
        // se lit hors ligne : le relire ainsi coûte une ligne, le refuser
        // coûterait sa soirée à quelqu'un.
        clues: [
          for (final entry in (json['clues'] as List? ??
                  json['annexes'] as List? ??
                  const [])
              .whereType<Map>())
            RemoteScenarioClue.fromJson(entry.cast<String, dynamic>()),
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
        'npcs': [for (final npc in npcs) npc.toJson()],
        'clues': [for (final clue in clues) clue.toJson()],
      };

  final String context;
  final String rundownMarkdown;
  final List<RemoteScenarioNpc> npcs;
  final List<RemoteScenarioClue> clues;
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
