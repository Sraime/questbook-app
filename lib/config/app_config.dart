/// Build-time configuration, injected with `--dart-define`.
///
/// ```bash
/// flutter run \
///   --dart-define=QUESTBOOK_API_URL=http://10.0.2.2:3000 \
///   --dart-define=QUESTBOOK_GOOGLE_SERVER_CLIENT_ID=xxx.apps.googleusercontent.com
/// ```
abstract final class AppConfig {
  /// Base URL of the Questbook API.
  ///
  /// The default targets a server running on the development machine:
  /// `10.0.2.2` is how the Android emulator reaches the host's `localhost`.
  /// A physical device needs the machine's LAN address instead, and release
  /// builds need the production URL.
  static const String apiBaseUrl = String.fromEnvironment(
    'QUESTBOOK_API_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );

  /// The **Web** OAuth client id from Google Cloud, not the Android one.
  /// Google mints ID tokens whose audience is this id, which is exactly what
  /// the API verifies.
  static const String googleServerClientId = String.fromEnvironment(
    'QUESTBOOK_GOOGLE_SERVER_CLIENT_ID',
  );

  /// Without a client id there is no way to obtain an ID token, so the app
  /// stays fully offline instead of showing a sign-in button that cannot work.
  static bool get isRemoteEnabled => googleServerClientId.isNotEmpty;
}
