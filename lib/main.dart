import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/providers.dart';
import 'app/router.dart';
import 'app/theme.dart';
import 'data/universe/universe_config_loader.dart';

/// Only one universe is bundled today (Cthulhu v7) — its config is loaded
/// once here and injected as a provider override, so the rest of the app
/// can read `universeConfigProvider` synchronously. Once a second universe
/// exists, this hardcoded id becomes a user choice (e.g. a "new table"
/// screen) instead.
const _defaultSystemId = 'cthulhu-v7';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final universeConfig = await loadUniverseConfig(_defaultSystemId);

  runApp(
    ProviderScope(
      overrides: [universeConfigProvider.overrideWithValue(universeConfig)],
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
