import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/push/push_messaging.dart';
import '../features/tables/providers/table_providers.dart';
import 'remote_providers.dart';
import 'router.dart';

/// Ties push delivery to the session: a device token is registered when
/// someone signs in and dropped when they sign out.
///
/// Kept out of `remote_providers.dart` so that file stays free of any feature
/// import, and — more importantly — so nothing here is ever read from
/// `AuthController`, which would reopen the circular dependency that
/// `test/app/sync_trigger_test.dart` guards against.

final pushMessagingProvider = Provider<PushMessaging>((ref) {
  final push = PushMessaging(ref.watch(notificationApiProvider));

  // A message arriving while the app is open should move the badge, not wait
  // for the user to pull to refresh.
  push.onMessageReceived = () => ref.invalidate(notificationsProvider);

  // Tapping a notification from the system tray lands on the table it is
  // about, which is where the session, the invitation or the answer lives.
  push.onNotificationOpened = (tableId) => appRouter.go('/tables/$tableId');

  ref.onDispose(push.dispose);
  return push;
});

class PushController extends Notifier<void> {
  @override
  void build() {
    ref.listen<AsyncValue<Object?>>(authControllerProvider, (previous, next) {
      final user = next.value;
      final push = ref.read(pushMessagingProvider);

      if (user != null) {
        unawaited(push.start());
      } else if (previous?.value != null) {
        unawaited(push.stop());
      }
    }, fireImmediately: true);
  }
}

final pushControllerProvider =
    NotifierProvider<PushController, void>(PushController.new);
