import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:eros_n/common/const/const.dart';
import 'package:eros_n/common/enum.dart';
import 'package:eros_n/common/global.dart';
import 'package:eros_n/component/models/index.dart';
import 'package:flutter/foundation.dart';
import 'package:tuple/tuple.dart';

import '../utils/logger.dart';
import 'api.dart';
import 'api_v2.dart';
import 'app_dio/api_v2_auth.dart';
import 'app_dio/pdio.dart';

Options getOptions({bool forceRefresh = false}) {
  final options = Api.cacheOption
      .copyWith(
        policy: forceRefresh ? CachePolicy.refreshForceCache : null,
      )
      .toOptions();

  return options;
}

// ---------------------------------------------------------------------------
// nhentai API v2. The HTML pages sit behind Cloudflare's browser challenge,
// the JSON API does not, so all browsing goes through it.
// ---------------------------------------------------------------------------

Future<T> _apiGet<T>(
  String path, {
  Map<String, dynamic>? queryParameters,
  bool refresh = false,
  CancelToken? cancelToken,
  required FutureOr<T> Function(dynamic data) parse,
}) async {
  final dioHttpClient = DioHttpClient(dioConfig: globalDioConfig);
  final httpResponse = await dioHttpClient.get(
    path,
    queryParameters: queryParameters,
    options: getOptions(forceRefresh: refresh),
    cancelToken: cancelToken,
    httpTransformer: HttpTransformerBuilder(
      (response) async {
        final data = response.data is String
            ? jsonDecode(response.data as String)
            : response.data;
        return DioHttpResponse<T>.success(await parse(data));
      },
    ),
  );
  if (httpResponse.ok && httpResponse.data is T) {
    return httpResponse.data as T;
  }
  logger.e('$path ${httpResponse.error}');
  throw httpResponse.error ?? HttpException('$path error');
}

Future<T> _apiSend<T>(
  String method,
  String path, {
  Object? data,
  Map<String, dynamic>? queryParameters,
  CancelToken? cancelToken,
  required FutureOr<T> Function(dynamic data) parse,
}) async {
  final dioHttpClient = DioHttpClient(dioConfig: globalDioConfig);
  final options = Options(
    method: method,
    contentType: Headers.jsonContentType,
    responseType: ResponseType.json,
    validateStatus: (status) => status != null && status < 500,
  );
  final httpResponse = await dioHttpClient.request(
    path,
    data: data,
    queryParameters: queryParameters,
    options: options,
    cancelToken: cancelToken,
    httpTransformer: HttpTransformerBuilder(
      (response) async {
        final body =
            response.data is String && (response.data as String).isNotEmpty
                ? jsonDecode(response.data as String)
                : response.data;
        final status = response.statusCode ?? 0;
        if (status >= 400) {
          final message = body is Map
              ? (body['error'] ?? body['detail'] ?? body['message'] ?? '$body')
              : '$body';
          return DioHttpResponse<T>.failure(
              errorMsg: '$message', errorCode: status);
        }
        return DioHttpResponse<T>.success(await parse(body));
      },
    ),
  );
  if (httpResponse.ok && httpResponse.data is T) {
    return httpResponse.data as T;
  }
  logger.e('$method $path ${httpResponse.error}');
  throw httpResponse.error ?? HttpException('$path error');
}

/// Search, or list everything when [query] is empty.
Future<GallerySet> searchGallery({
  bool refresh = false,
  CancelToken? cancelToken,
  int? page,
  String? query,
  SearchSort? sort,
}) async {
  final q = (query ?? '').trim();
  final sortValue = NhApiV2.sortValue(sort);
  if (q.isEmpty && sortValue == 'date') {
    return _apiGet(
      '${NhApiV2.prefix}/galleries',
      queryParameters: {'page': page ?? 1},
      refresh: refresh,
      cancelToken: cancelToken,
      parse: (data) =>
          NhApiV2.gallerySetFromPage(data as Map<String, dynamic>, page: page),
    );
  }
  logger.d('searchGallery q:$q sort:$sortValue page:$page');
  return _apiGet(
    '${NhApiV2.prefix}/search',
    queryParameters: {
      // The API requires a query; "*" matches everything.
      'query': q.isEmpty ? '*' : q,
      'sort': sortValue,
      'page': page ?? 1,
    },
    refresh: refresh,
    cancelToken: cancelToken,
    parse: (data) =>
        NhApiV2.gallerySetFromPage(data as Map<String, dynamic>, page: page),
  );
}

/// Front page: latest galleries plus the "popular now" row.
Future<GallerySet> getGalleryList({
  bool refresh = false,
  CancelToken? cancelToken,
  String? referer,
  int? page,
}) async {
  final results = await Future.wait([
    _apiGet<List<Gallery>>(
      '${NhApiV2.prefix}/galleries/popular',
      refresh: refresh,
      cancelToken: cancelToken,
      parse: (data) => NhApiV2.galleriesFromList(data as List?),
    ),
    searchGallery(refresh: refresh, cancelToken: cancelToken, page: page),
  ]);
  final popular = results[0] as List<Gallery>;
  final list = results[1] as GallerySet;
  return list.copyWith(populars: popular);
}

Future<GallerySet> getFavoriteList({
  bool refresh = false,
  CancelToken? cancelToken,
  String? referer,
  int? page,
}) async {
  return _apiGet(
    '${NhApiV2.prefix}/favorites',
    queryParameters: {'page': page ?? 1},
    refresh: refresh,
    cancelToken: cancelToken,
    parse: (data) async {
      final set = await NhApiV2.gallerySetFromPage(data as Map<String, dynamic>,
          page: page);
      return set.copyWith(favorites: set.gallerys);
    },
  );
}

/// [url] may be a gallery URL (`/g/123/`) or a gallery id.
Future<Gallery> getGalleryDetail({
  required String url,
  bool refresh = false,
  CancelToken? cancelToken,
}) async {
  final gid = NhApiV2.gidFromUrl(url);
  if (gid == null) {
    throw HttpException('invalid gallery url: $url');
  }
  return _apiGet(
    '${NhApiV2.prefix}/galleries/$gid',
    queryParameters: {
      'include': ApiV2Auth.isLoggedIn ? 'related,favorite' : 'related',
    },
    refresh: refresh,
    cancelToken: cancelToken,
    parse: (data) => NhApiV2.galleryFromDetail(data as Map<String, dynamic>),
  );
}

Future<List<Comment>> getGalleryComments({
  required int? gid,
  String? token,
  bool refresh = false,
  CancelToken? cancelToken,
}) async {
  return _apiGet(
    '${NhApiV2.prefix}/galleries/$gid/comments',
    queryParameters: {'page': 1, 'per_page': 50},
    refresh: refresh,
    cancelToken: cancelToken,
    parse: (data) => NhApiV2.commentsFromList(
        (data as Map<String, dynamic>)['result'] as List?),
  );
}

/// The signed-in user (needs a token).
Future<User> getCurrentUser() async {
  return _apiGet(
    '${NhApiV2.prefix}/user',
    refresh: true,
    parse: (data) {
      final json = data as Map<String, dynamic>;
      final avatar = json['avatar_url'] as String? ?? '';
      return User(
        userName: json['username'] as String?,
        userId: '${json['id']}',
        userUrl: '${NHConst.baseUrl}/users/${json['id']}/${json['slug']}/',
        avatarUrl: avatar.isEmpty
            ? null
            : (avatar.startsWith('http')
                ? avatar
                : '${NhApiV2.imageHost}/$avatar'),
      );
    },
  );
}

Future<Tuple2<bool?, int?>> setFavorite({
  required int? gid,
  String? csrfToken,
  bool unfavorite = false,
  bool refresh = true,
  CancelToken? cancelToken,
}) async {
  if (gid == null) {
    return const Tuple2(null, null);
  }
  return _apiSend(
    unfavorite ? 'DELETE' : 'POST',
    '${NhApiV2.prefix}/galleries/$gid/favorite',
    cancelToken: cancelToken,
    parse: (data) {
      final json = data as Map<String, dynamic>;
      return Tuple2<bool?, int?>(
        json['favorited'] as bool?,
        json['num_favorites'] as int?,
      );
    },
  );
}

Future<void> nhDownload({
  required String url,
  required savePath,
  CancelToken? cancelToken,
  bool? errToast,
  bool deleteOnError = true,
  VoidCallback? onDownloadComplete,
  ProgressCallback? progressCallback,
}) async {
  late final String downloadUrl;
  DioHttpClient dioHttpClient = DioHttpClient(dioConfig: globalDioConfig);
  if (!url.startsWith(RegExp(r'https?://'))) {
    downloadUrl = '${NHConst.baseUrl}$url';
  } else {
    downloadUrl = url;
  }
  logger.v('downloadUrl $downloadUrl');
  try {
    final response = await dioHttpClient.download(
      downloadUrl,
      savePath,
      deleteOnError: deleteOnError,
      onReceiveProgress: (int count, int total) {
        progressCallback?.call(count, total);
        if (count == total) {
          onDownloadComplete?.call();
        }
      },
      cancelToken: cancelToken,
    );

    // logger.d('response.runtimeType ${response.runtimeType}');
    // logger.d('response.statusCode ${response.headers}');
  } on CancelException catch (e) {
    logger.d('cancel');
  } on Exception catch (e) {
    rethrow;
  }
}

Future<Map> getGithubApi(String url) async {
  DioHttpClient dioHttpClient = DioHttpClient(dioConfig: globalDioConfig);
  DioHttpResponse httpResponse =
      await dioHttpClient.get(url, options: getOptions(forceRefresh: true));
  if (httpResponse.ok && httpResponse.data is Map) {
    return httpResponse.data as Map;
  } else {
    throw httpResponse.error ?? HttpException('getGithubApi error');
  }
}

Future<Tuple2<bool, Comment?>> postComment({
  required int gid,
  required String comment,
  String? csrfToken,
  CancelToken? cancelToken,
}) async {
  // Posting needs a proof of work.
  final pow = await _apiGet<Map<String, dynamic>>(
    '${NhApiV2.prefix}/pow',
    queryParameters: {'action': 'comment'},
    refresh: true,
    parse: (data) => data as Map<String, dynamic>,
  );
  final challenge = pow['challenge'] as String? ?? '';
  final difficulty = pow['difficulty'] as int? ?? 0;
  final nonce = await compute(
    (List<Object> args) => NhApiV2.solvePow(args[0] as String, args[1] as int),
    <Object>[challenge, difficulty],
  );

  final created = await _apiSend<Comment>(
    'POST',
    '${NhApiV2.prefix}/galleries/$gid/comments',
    data: {
      'body': comment,
      'pow_challenge': challenge,
      'pow_nonce': nonce,
    },
    cancelToken: cancelToken,
    parse: (data) => NhApiV2.commentFromJson(data as Map<String, dynamic>),
  );
  return Tuple2(true, created);
}

Future<List<Tag>> nhAutocomplete({
  String? name,
  TagCategory? type,
  CancelToken? cancelToken,
}) async {
  return _apiSend(
    'POST',
    '${NhApiV2.prefix}/tags/search',
    data: {
      'query': name,
      if (type != null && type.value.isNotEmpty) 'type': type.value,
      'limit': 20,
    },
    cancelToken: cancelToken,
    parse: (data) => [
      for (final e in (data as List?) ?? const [])
        if (e is Map)
          Tag(
            id: e['id'] as int?,
            type: e['type'] as String?,
            name: e['name'] as String?,
            url: e['url'] as String?,
            count: e['count'] as int?,
          ),
    ],
  );
}
