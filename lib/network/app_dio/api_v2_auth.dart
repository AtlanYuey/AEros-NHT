import 'dart:io';

import 'package:dio/dio.dart';
import 'package:eros_n/common/const/const.dart';
import 'package:eros_n/common/global.dart';
import 'package:eros_n/network/api_v2.dart';
import 'package:eros_n/utils/logger.dart';

/// Tokens for the nhentai API v2 (`Authorization: User <access_token>`).
///
/// The tokens come from the website's own login (performed in a WebView,
/// which takes care of Cloudflare Turnstile and the proof of work) and are
/// read from its `access_token` / `refresh_token` cookies.
class ApiV2Auth {
  ApiV2Auth._();

  static const String accessCookie = 'access_token';
  static const String refreshCookie = 'refresh_token';

  static const String _accessKey = 'api_v2_access_token';
  static const String _refreshKey = 'api_v2_refresh_token';

  static String? get accessToken => _read(_accessKey);
  static String? get refreshToken => _read(_refreshKey);

  static bool get isLoggedIn => (accessToken ?? '').isNotEmpty;

  static String? _read(String key) {
    try {
      final value = hiveHelper.getString(key);
      return (value == null || value.isEmpty) ? null : value;
    } catch (_) {
      return null;
    }
  }

  static Future<void> save({required String access, String? refresh}) async {
    await hiveHelper.setString(_accessKey, access);
    if (refresh != null && refresh.isNotEmpty) {
      await hiveHelper.setString(_refreshKey, refresh);
    }
  }

  static Future<void> clear() async {
    await hiveHelper.setString(_accessKey, '');
    await hiveHelper.setString(_refreshKey, '');
  }

  /// Picks the tokens out of cookies (e.g. from the login WebView).
  static Future<bool> saveFromCookies(Iterable<Cookie> cookies) async {
    String? access;
    String? refresh;
    for (final c in cookies) {
      if (c.name == accessCookie) {
        access = Uri.decodeComponent(c.value);
      } else if (c.name == refreshCookie) {
        refresh = Uri.decodeComponent(c.value);
      }
    }
    if (access == null || access.isEmpty) {
      return false;
    }
    await save(access: access, refresh: refresh);
    return true;
  }

  static Future<bool>? _refreshing;

  /// Exchanges the refresh token for a new pair. Concurrent callers share
  /// one request.
  static Future<bool> refresh() {
    return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
  }

  static Future<bool> _doRefresh() async {
    final token = refreshToken;
    if (token == null) {
      return false;
    }
    try {
      final dio = Dio(BaseOptions(
        baseUrl: NHConst.baseUrl,
        headers: {HttpHeaders.userAgentHeader: NhApiV2.userAgent},
        validateStatus: (s) => s != null && s < 500,
      ));
      final response = await dio.post<Map<String, dynamic>>(
        '${NhApiV2.prefix}/auth/refresh',
        data: {'refresh_token': token},
      );
      final data = response.data;
      if (response.statusCode == 200 && data != null) {
        await save(
          access: data['access_token'] as String,
          refresh: data['refresh_token'] as String?,
        );
        return true;
      }
      logger.d('token refresh rejected: ${response.statusCode}');
    } catch (e) {
      logger.e('token refresh failed: $e');
    }
    return false;
  }
}

/// Adds the API token and the descriptive User-Agent the API asks for,
/// and transparently refreshes an expired token once.
class ApiV2AuthInterceptor extends Interceptor {
  ApiV2AuthInterceptor(this.dio);

  final Dio dio;

  static const _retriedKey = '__api_v2_auth_retried';

  bool _isApi(RequestOptions options) =>
      NhApiV2.isApiPath(options.path) || NhApiV2.isApiPath(options.uri.path);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_isApi(options)) {
      options.headers[HttpHeaders.userAgentHeader] = NhApiV2.userAgent;
      options.headers[HttpHeaders.acceptHeader] = 'application/json';
      final token = ApiV2Auth.accessToken;
      if (token != null) {
        options.headers[HttpHeaders.authorizationHeader] = 'User $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    if (err.response?.statusCode != 401 ||
        !_isApi(options) ||
        options.extra[_retriedKey] == true ||
        !await ApiV2Auth.refresh()) {
      return handler.next(err);
    }
    try {
      final retry = options.copyWith(
        headers: {
          ...options.headers,
          HttpHeaders.authorizationHeader: 'User ${ApiV2Auth.accessToken}',
        },
        extra: {...options.extra, _retriedKey: true},
      );
      return handler.resolve(await dio.fetch<dynamic>(retry));
    } on DioException catch (e) {
      return handler.next(e);
    }
  }
}
