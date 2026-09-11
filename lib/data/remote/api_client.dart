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
      ),
    );

    // A request with no body has no media type to declare, and saying
    // `application/json` anyway makes a strict server look for a payload that
    // was never coming. Dio sets the header from [BaseOptions] whatever the
    // body, so dropping it here is the only place the distinction can be made.
    for (final dio in [_dio, _plain]) {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.data == null) {
              options.headers.remove(Headers.contentTypeHeader);
            }
            handler.next(options);
          },
        ),
      );
    }
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

  final Dio _dio;

  /// A second client without the auth interceptor, used for sign-in and token
  /// refresh. Without it, a failing refresh would recurse into itself.
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
  ///
  /// An expired access token is refreshed here rather than in an error
  /// interceptor: [_optionsFor] deliberately lets Dio resolve 4xx responses so
  /// the error envelope can be read, which means a 401 never reaches
  /// `onError`.
  Future<T> send<T>(Future<Response<dynamic>> Function(Dio dio) request, {
    bool authenticated = true,
    required T Function(dynamic data) parse,
  }) async {
    try {
      var response = await request(authenticated ? _dio : _plain);

      if (authenticated &&
          response.statusCode == 401 &&
          await _refreshTokens()) {
        // Exactly one retry: the second answer is final, whatever it says.
        response = await request(_dio);
      }

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
