import 'package:dio/dio.dart';

/// A failure surfaced by the Questbook API, already decoded from the
/// `{ "error": { "code", "message", "details" } }` envelope the server uses.
class ApiException implements Exception {
  const ApiException({
    required this.code,
    required this.message,
    this.statusCode,
    this.details,
  });

  /// Builds an [ApiException] from whatever Dio threw, whether that is an HTTP
  /// error carrying the server envelope or a connectivity problem.
  factory ApiException.from(DioException error) {
    final response = error.response;
    final body = response?.data;

    if (body is Map && body['error'] is Map) {
      final envelope = (body['error'] as Map).cast<String, dynamic>();
      return ApiException(
        code: envelope['code'] as String? ?? 'UNKNOWN',
        message: envelope['message'] as String? ?? 'Erreur inconnue',
        statusCode: response?.statusCode,
        details: envelope['details'],
      );
    }

    final message = switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        'Le serveur met trop de temps à répondre.',
      DioExceptionType.connectionError =>
        'Impossible de joindre le serveur Questbook.',
      DioExceptionType.badCertificate => 'Certificat du serveur invalide.',
      DioExceptionType.cancel => 'Requête annulée.',
      _ => 'Erreur réseau inattendue.',
    };

    return ApiException(
      code: 'NETWORK_ERROR',
      message: message,
      statusCode: response?.statusCode,
    );
  }

  final String code;
  final String message;
  final int? statusCode;
  final Object? details;

  /// A stale synchronisation push: the server holds a newer version and sent
  /// it back in [details] so the client can adopt it directly.
  bool get isStaleWrite => code == 'CONFLICT';

  /// True when retrying later could plausibly succeed.
  bool get isRetryable =>
      code == 'NETWORK_ERROR' || (statusCode != null && statusCode! >= 500);

  Map<String, dynamic>? get conflictingCharacter {
    final data = details;
    if (data is Map && data['character'] is Map) {
      return (data['character'] as Map).cast<String, dynamic>();
    }
    return null;
  }

  @override
  String toString() => 'ApiException($code): $message';
}
