import 'dart:async';

import 'package:dio/dio.dart';

import 'api_exception.dart';
import 'auth_tokens.dart';
import 'token_store.dart';

/// HTTP access to the Questbook API.
///
/// Owns the token lifecycle so callers never think about it: requests are
/// signed automatically, and a 401 transparently triggers a refresh followed by
/// a single retry.
class ApiClient {
  ApiClient(String baseUrl, this._tokenStore)
      : _dio = Dio(_optionsFor(baseUrl)),
        _plain = Dio(_optionsFor(baseUrl)) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final tokens = await _tokens();
          if (tokens != null) {
            options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode != 401 || _hasBeenRetried(error)) {
            return handler.next(error);
          }

          final refreshed = await _refreshTokens();
          if (!refreshed) {
            return handler.next(error);
          }

          try {
            handler.resolve(await _retry(error.requestOptions));
          } on DioException catch (retryError) {
            handler.next(retryError);
          }
        },
      ),
    );
  }

  static BaseOptions _optionsFor(String baseUrl) => BaseOptions(
        baseUrl: '$baseUrl/api/v1',
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 20),
        contentType: Headers.jsonContentType,
        // 4xx bodies carry the error envelope and are handled explicitly, so
        // Dio must not reject them before we get a chance to read it.
        validateStatus: (status) => status != null && status < 500,
      );

  static const _retriedMarker = 'questbook-retried';

  final Dio _dio;

  /// A second client without the auth interceptor, used for sign-in, token
  /// refresh and post-refresh retries. Without it, a failing refresh would
  /// recurse into itself.
  final Dio _plain;

  final TokenStore _tokenStore;

  AuthTokens? _cached;
  Future<bool>? _inFlightRefresh;

  /// Called when the refresh token is rejected and the session cannot be
  /// recovered, so the app can send the user back to the sign-in screen.
  void Function()? onSessionExpired;

  Future<AuthTokens?> _tokens() async => _cached ??= await _tokenStore.read();

  Future<void> setTokens(AuthTokens tokens) async {
    _cached = tokens;
    await _tokenStore.write(tokens);
  }

  Future<void> clearTokens() async {
    _cached = null;
    await _tokenStore.clear();
  }

  bool _hasBeenRetried(DioException error) =>
      error.requestOptions.extra[_retriedMarker] == true;

  Future<Response<dynamic>> _retry(RequestOptions options) async {
    final tokens = await _tokens();
    return _plain.request<dynamic>(
      options.path,
      data: options.data,
      queryParameters: options.queryParameters,
      options: Options(
        method: options.method,
        headers: {
          ...options.headers,
          if (tokens != null) 'Authorization': 'Bearer ${tokens.accessToken}',
        },
        extra: {...options.extra, _retriedMarker: true},
        validateStatus: options.validateStatus,
      ),
    );
  }

  /// Refreshes the token pair, collapsing concurrent callers onto a single
  /// request: several requests failing with 401 at once must not each burn a
  /// refresh token, which rotation would immediately invalidate.
  Future<bool> _refreshTokens() {
    return _inFlightRefresh ??=
        _performRefresh().whenComplete(() => _inFlightRefresh = null);
  }

  Future<bool> _performRefresh() async {
    final tokens = await _tokens();
    if (tokens == null) return false;

    try {
      final response = await _plain.post<dynamic>(
        '/auth/refresh',
        data: {'refreshToken': tokens.refreshToken},
      );

      if (response.statusCode != 200 || response.data is! Map) {
        await clearTokens();
        onSessionExpired?.call();
        return false;
      }

      final body = (response.data as Map).cast<String, dynamic>();
      await setTokens(AuthTokens(
        accessToken: body['accessToken'] as String,
        refreshToken: body['refreshToken'] as String,
      ));
      return true;
    } on DioException {
      // A transport failure is not proof the session is dead, so the tokens
      // are kept and the caller simply sees the original error.
      return false;
    }
  }

  /// Runs a request and turns every failure into an [ApiException], so callers
  /// never have to know Dio exists.
  Future<T> send<T>(Future<Response<dynamic>> Function(Dio dio) request, {
    bool authenticated = true,
    required T Function(dynamic data) parse,
  }) async {
    try {
      final response = await request(authenticated ? _dio : _plain);
      final status = response.statusCode ?? 0;

      if (status >= 400) {
        throw ApiException.from(DioException.badResponse(
          statusCode: status,
          requestOptions: response.requestOptions,
          response: response,
        ));
      }

      return parse(response.data);
    } on DioException catch (error) {
      throw ApiException.from(error);
    }
  }
}
