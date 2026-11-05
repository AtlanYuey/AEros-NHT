import 'dart:io';

import 'package:dio/dio.dart';
import 'package:eros_n/utils/logger.dart';

/// Retries requests blocked by Cloudflare once the security check passed.
class DioThroughInterceptor extends Interceptor {
  DioThroughInterceptor({required this.dio, required this.throughHandler});

  Dio dio;
  Future<bool> Function(DioException err) throughHandler;

  /// Only Cloudflare's browser challenge — not every 403/503 (the API
  /// answers 403 for its own reasons, e.g. retired endpoints).
  static bool _isChallenge(DioException err) {
    final response = err.response;
    final status = response?.statusCode;
    if (status != 403 && status != 503) {
      return false;
    }
    final mitigated = response?.headers.value('cf-mitigated');
    if (mitigated != null && mitigated.toLowerCase() == 'challenge') {
      return true;
    }
    final server = response?.headers.value('server') ?? '';
    final body = response?.data;
    if (server.toLowerCase().contains('cloudflare') && body is String) {
      const markers = [
        'cf_chl_opt',
        '/cdn-cgi/challenge-platform/',
        'Just a moment...',
        'cf-browser-verification',
      ];
      return markers.any(body.contains);
    }
    return false;
  }

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    // A request that was already retried after a check is not challenged
    // again, otherwise a rejected clearance would loop forever.
    if (options.disableThrough ||
        options.throughRetried ||
        !_isChallenge(err)) {
      return handler.next(err);
    }

    logger
        .d('DioThroughInterceptor: ${err.response?.statusCode} ${options.uri}');
    bool ok;
    try {
      ok = await throughHandler(err);
    } catch (e) {
      logger.d('Security check aborted: $e');
      return handler.next(err);
    }
    if (!ok) {
      return handler.next(err);
    }

    final headers = Map<String, dynamic>.of(options.headers)
      ..remove(HttpHeaders.cookieHeader);
    final request = options.copyWith(
      headers: headers,
      extra: {...options.extra, _throughRetriedKey: true},
    );
    try {
      final response = await dio.fetch<dynamic>(request);
      return handler.resolve(response);
    } on DioException catch (e) {
      return handler.next(e);
    }
  }
}

const _disableThroughKey = '__dio_through_disable';
const _throughRetriedKey = '__dio_through_retried';

extension RequestOptionsThrough on RequestOptions {
  bool get disableThrough => (extra[_disableThroughKey] as bool?) ?? false;

  set disableThrough(bool value) => extra[_disableThroughKey] = value;

  bool get throughRetried => (extra[_throughRetriedKey] as bool?) ?? false;
}

extension OptionsThrough on Options {
  bool get disableRetry => (extra?[_disableThroughKey] as bool?) ?? false;

  set disableRetry(bool value) => extra?[_disableThroughKey] = value;
}
