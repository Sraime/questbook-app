import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../domain/models/universe_config.dart';

/// Loads and parses one universe's character-sheet config from
/// `assets/universes/<systemId>.json` (declared as a Flutter asset in
/// `pubspec.yaml`). Called once in `main()`, before `runApp` — see
/// `universeConfigProvider` in `app/providers.dart` for how the parsed
/// result is then threaded through the app as a provider override.
Future<UniverseConfig> loadUniverseConfig(String systemId) async {
  final raw = await rootBundle.loadString('assets/universes/$systemId.json');
  final json = jsonDecode(raw) as Map<String, dynamic>;
  return UniverseConfig.fromJson(json);
}
