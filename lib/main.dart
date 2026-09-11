import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/providers.dart';
import 'app/push_providers.dart';
import 'app/remote_providers.dart';
import 'app/router.dart';
import 'app/theme.dart';
import 'config/app_config.dart';
import 'data/universe/universe_assets_loader.dart';
import 'features/auth/login_screen.dart';
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
          data: (_) => _AuthGate(child: child ?? const SizedBox.shrink()),
          loading: () => const _SplashScreen(),
          error: (error, stack) => _SplashScreen(error: error),
        );
      },
    );
  }
}

/// Decides whether to show the sign-in screen or the app itself.
///
/// It wraps the router's child rather than living in the route table on
/// purpose: it is an overlay over an app that is otherwise fully navigable,
/// not a navigation step of its own.
///
/// An account is now required. Characters belong to one, tables are shared
/// with other players through one, and a session can only be answered by
/// somebody the server can name — a purely local user had no way to take part
/// in any of it.
class _AuthGate extends ConsumerWidget {
  const _AuthGate({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Builds without an OAuth client id are offline-only: there is nothing to
    // sign in to.
    if (!AppConfig.isRemoteEnabled) return child;

    // Brings the synchronisation controller to life for the whole session: it
    // is what reacts to signing in and to the app returning to the foreground,
    // so it must not wait for a screen that happens to display sync status.
    // Watching the notifier rather than the state keeps the entire app from
    // rebuilding every time a pass starts or finishes.
    ref.watch(syncControllerProvider.notifier);

    // Same reasoning for push: it has to be listening to the session from the
    // moment the app starts, not from the moment a screen happens to need it.
    ref.watch(pushControllerProvider.notifier);

    return ref.watch(authControllerProvider).when(
          data: (user) => user != null ? child : const LoginScreen(),
          loading: () => const _SplashScreen(),
          // Restoring a session never fails for want of a network — the cached
          // profile answers for it — so an error here really is no session.
          error: (error, stack) => const LoginScreen(),
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
