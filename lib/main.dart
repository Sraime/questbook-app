import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/providers.dart';
import 'app/router.dart';
import 'app/theme.dart';
import 'data/universe/universe_assets_loader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final universes = await loadAllUniverseConfigs();
  if (universes.isEmpty) {
    throw StateError('No universe config found under assets/universes/universe_*.json.');
  }
  final creationModes = await loadAllCreationModeConfigs(universes);
  if (creationModes.isEmpty) {
    throw StateError('No creation mode config found under assets/universes/.');
  }

  runApp(
    ProviderScope(
      overrides: [
        availableCreationModesProvider.overrideWithValue(creationModes),
        selectedCreationModeIdProvider.overrideWith(
          () => SelectedCreationModeIdNotifier(creationModes.first.id),
        ),
        availableUniversesProvider.overrideWithValue(universes),
      ],
      child: const QuestbookApp(),
    ),
  );
}

class QuestbookApp extends ConsumerWidget {
  const QuestbookApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final init = ref.watch(databaseInitProvider);

    return MaterialApp.router(
      title: 'Questbook',
      debugShowCheckedModeBanner: false,
      theme: buildQuestbookTheme(),
      routerConfig: appRouter,
      builder: (context, child) {
        return init.when(
          data: (_) => child ?? const SizedBox.shrink(),
          loading: () => const _SplashScreen(),
          error: (error, stack) => _SplashScreen(error: error),
        );
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen({this.error});

  final Object? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: error == null
            ? const CircularProgressIndicator()
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Erreur au démarrage : $error'),
              ),
      ),
    );
  }
}
