import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../remote/api_exception.dart';
import '../remote/notification_api.dart';

/// Registers this device with the API so the server can push to it, and
/// reports incoming messages back to the app.
///
/// Firebase is a delivery channel, nothing more: the authoritative history is
/// the `Notification` rows the API writes inside the same transaction as the
/// change. That is why every failure here is logged and swallowed — a device
/// with no push still sees everything, just later.
class PushMessaging {
  PushMessaging(this._api);

  final NotificationApi _api;

  String? _registeredToken;
  StreamSubscription<String>? _tokenRefresh;
  StreamSubscription<RemoteMessage>? _foreground;
  StreamSubscription<RemoteMessage>? _opened;

  /// Fired whenever a message arrives while the app is in use, so the badge,
  /// the notification list and the table it concerns can refresh without
  /// waiting for a manual pull. The table id is null for messages that are not
  /// about one.
  void Function(String? tableId)? onMessageReceived;

  /// Fired with the table id when the user taps a notification from outside
  /// the app.
  void Function(String tableId)? onNotificationOpened;

  /// Called once the user is signed in: there is no point holding a device
  /// token for nobody.
  Future<void> start() async {
    try {
      final messaging = FirebaseMessaging.instance;

      // On Android 13+ this shows the runtime permission prompt; below that it
      // resolves immediately as granted.
      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return;
      }

      await _register(await messaging.getToken());

      _tokenRefresh ??= messaging.onTokenRefresh.listen(_register);
      _foreground ??= FirebaseMessaging.onMessage.listen((message) {
        onMessageReceived?.call(_tableIdOf(message));
      });
      _opened ??= FirebaseMessaging.onMessageOpenedApp.listen(_handleOpened);

      // A notification tapped while the app was not running is delivered here
      // instead, once, at startup.
      final initial = await messaging.getInitialMessage();
      if (initial != null) _handleOpened(initial);
    } catch (error, stack) {
      // A build without Firebase configured, or a device without Play
      // Services, must not stop the app from working.
      debugPrint('Push unavailable: $error\n$stack');
    }
  }

  /// Called on sign-out so a shared device stops receiving the previous
  /// player's notifications.
  Future<void> stop() async {
    final token = _registeredToken;
    _registeredToken = null;

    if (token == null) return;

    try {
      await _api.unregisterDevice(token);
    } on ApiException catch (error) {
      debugPrint('Could not unregister the device token: ${error.message}');
    }
  }

  Future<void> dispose() async {
    await _tokenRefresh?.cancel();
    await _foreground?.cancel();
    await _opened?.cancel();
  }

  Future<void> _register(String? token) async {
    if (token == null || token == _registeredToken) return;

    try {
      await _api.registerDevice(
        token: token,
        platform: defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
      );
      _registeredToken = token;
    } on ApiException catch (error) {
      debugPrint('Could not register the device token: ${error.message}');
    }
  }

  void _handleOpened(RemoteMessage message) {
    final tableId = _tableIdOf(message);
    if (tableId != null) {
      onNotificationOpened?.call(tableId);
    }
  }

  static String? _tableIdOf(RemoteMessage message) {
    final tableId = message.data['tableId'];
    return tableId is String && tableId.isNotEmpty ? tableId : null;
  }
}
