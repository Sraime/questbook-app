import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/login_screen.dart';
import '../features/auth/terms_screen.dart';
import 'push_providers.dart';
import 'remote_providers.dart';

/// Decides whether to show the sign-in screen, the terms, or the app itself.
///
/// It wraps the router's child rather than living in the route table on
/// purpose: it is an overlay over an app that is otherwise fully navigable,
/// not a navigation step of its own.
///
/// An account is now required. Characters belong to one, tables are shared
/// with other players through one, and a session can only be answered by
/// somebody the server can name — a purely local user had no way to take part
/// in any of it.
class AuthGate extends ConsumerWidget {
  const AuthGate({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Builds without an OAuth client id are offline-only: there is nothing to
    // sign in to.
    if (!ref.watch(remoteEnabledProvider)) return child;

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
          data: (user) => switch (user) {
            null => const LoginScreen(),
            // Barred at every launch, not only at sign-up: accounts that
            // predate the terms meet this screen on their next start, since
            // nobody consented on their behalf.
            final account when !account.hasAcceptedTerms => const TermsScreen(),
            _ => child,
          },
          loading: () => const SplashScreen(),
          // Restoring a session never fails for want of a network — the cached
          // profile answers for it — so an error here really is no session.
          error: (error, stack) => const LoginScreen(),
        );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({this.error, super.key});

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
