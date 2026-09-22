import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/auth_gate.dart';
import 'app/providers.dart';
import 'app/router.dart';
import 'app/theme.dart';
import 'data/universe/universe_assets_loader.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Push is a nice-to-have: the notification history comes from the API, so a
  // device where Firebase cannot start still sees everything.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error) {
    debugPrint('Firebase unavailable, push notifications disabled: $error');
  }

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
      // The UI is written in French throughout, so Material's own widgets —
      // the session date and time pickers above all — follow suit.
      locale: const Locale('fr'),
      supportedLocales: const [Locale('fr')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: appRouter,
      builder: (context, child) {
        return init.when(
          data: (_) => AuthGate(child: child ?? const SizedBox.shrink()),
          loading: () => const SplashScreen(),
          error: (error, stack) => SplashScreen(error: error),
        );
      },
    );
  }
}

