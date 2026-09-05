/// The token pair issued by `POST /api/v1/auth/google` and rotated by
/// `POST /api/v1/auth/refresh`.
class AuthTokens {
  const AuthTokens({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;
}

/// The authenticated account, as returned alongside the tokens.
class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    this.displayName,
    this.pictureUrl,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as String,
        email: json['email'] as String,
        displayName: json['displayName'] as String?,
        pictureUrl: json['pictureUrl'] as String?,
      );

  final String id;
  final String email;
  final String? displayName;
  final String? pictureUrl;

  /// What the UI shows: the Google display name, falling back to the part of
  /// the email before the `@`.
  String get label =>
      displayName?.trim().isNotEmpty == true ? displayName! : email.split('@').first;
}

class AuthSession {
  const AuthSession({required this.tokens, required this.user});

  final AuthTokens tokens;
  final AuthUser user;
}
