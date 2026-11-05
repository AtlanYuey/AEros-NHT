import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:eros_n/common/enum.dart';
import 'package:eros_n/common/parser/parse_gallery_list.dart'
    show getLanguageCode, getTags;
import 'package:eros_n/component/models/index.dart';

/// nhentai REST API v2 (https://nhentai.net/api/v2/docs).
///
/// Unlike the HTML pages, the API is not behind Cloudflare's browser
/// challenge, so browsing works without the in-app security check. Only
/// account actions need a token (`Authorization: User <access_token>`).
class NhApiV2 {
  NhApiV2._();

  static const String prefix = '/api/v2';
  static const String thumbHost = 'https://t.nhentai.net';
  static const String imageHost = 'https://i.nhentai.net';

  /// Value for the API's requested descriptive User-Agent.
  static const String userAgent =
      'Eros-N/1.1 (+https://github.com/erosTeam/eros_n)';

  static bool isApiPath(String pathOrUrl) => pathOrUrl.contains('$prefix/');

  static String thumbUrl(String path) => '$thumbHost/${_trim(path)}';
  static String imageUrl(String path) => '$imageHost/${_trim(path)}';

  static String _trim(String path) =>
      path.startsWith('/') ? path.substring(1) : path;

  /// The app's sort setting → API `sort` value.
  static String sortValue(SearchSort? sort) {
    switch (sort) {
      case SearchSort.popularMonth:
        return 'popular-month';
      case SearchSort.popularWeek:
        return 'popular-week';
      case SearchSort.popularToday:
        return 'popular-today';
      case SearchSort.popular:
        return 'popular';
      case SearchSort.recent:
      case null:
        return 'date';
    }
  }

  /// API tag types → the display groups used by the gallery page.
  static String tagGroup(String? type) {
    switch (type) {
      case 'parody':
        return 'Parodies';
      case 'character':
        return 'Characters';
      case 'tag':
        return 'Tags';
      case 'artist':
        return 'Artists';
      case 'group':
        return 'Groups';
      case 'language':
        return 'Languages';
      case 'category':
        return 'Categories';
      default:
        return type ?? 'Tags';
    }
  }

  /// Search syntax prefix for a tag (`tag`, `artist`, `parody`...).
  static String searchPrefix(Tag? tag) {
    final fromUrl = RegExp(r'^/(\w+)/').firstMatch(tag?.url ?? '')?.group(1);
    if (fromUrl != null) {
      return fromUrl;
    }
    switch ((tag?.type ?? '').toLowerCase()) {
      case 'parodies':
        return 'parody';
      case 'characters':
        return 'character';
      case 'tags':
        return 'tag';
      case 'artists':
        return 'artist';
      case 'groups':
        return 'group';
      case 'languages':
        return 'language';
      case 'categories':
        return 'category';
      case '':
        return 'tag';
      default:
        return tag!.type!.toLowerCase();
    }
  }

  static String _ext(String path) {
    final match = RegExp(r'\.(\w+)$').firstMatch(path);
    return match?.group(1) ?? 'jpg';
  }

  /// First letter of the extension, as used by the legacy models.
  static String _type(String path) => _ext(path).substring(0, 1);

  static int? _int(Object? v) => v is int ? v : int.tryParse('$v');

  /// Cover / thumbnail images live on the thumbnail servers.
  static GalleryImage _image(Map<String, dynamic>? json) {
    if (json == null) {
      return const GalleryImage();
    }
    final path = json['path'] as String? ?? '';
    return GalleryImage(
      type: _type(path),
      imgWidth: _int(json['width']),
      imgHeight: _int(json['height']),
      imageUrl: path.isEmpty ? null : thumbUrl(path),
    );
  }

  /// `GalleryListItem` → [Gallery].
  static Future<Gallery> galleryFromListItem(Map<String, dynamic> json) async {
    final thumbnail = json['thumbnail'] as String? ?? '';
    final tagIds = ((json['tag_ids'] as List?) ?? const [])
        .map((e) => '$e')
        .toList(growable: false);
    return Gallery(
      gid: _int(json['id']) ?? 0,
      mediaId: '${json['media_id']}',
      title: GalleryTitle(
        englishTitle: json['english_title'] as String?,
        japaneseTitle: json['japanese_title'] as String?,
      ),
      numPages: _int(json['num_pages']),
      numFavorites: _int(json['num_favorites']),
      languageCode: getLanguageCode(tagIds),
      simpleTags: await getTags(tagIds),
      images: GalleryImages(
        thumbnail: GalleryImage(
          type: _type(thumbnail),
          imgWidth: _int(json['thumbnail_width']),
          imgHeight: _int(json['thumbnail_height']),
          imageUrl: thumbnail.isEmpty ? null : thumbUrl(thumbnail),
        ),
      ),
    );
  }

  static Future<List<Gallery>> galleriesFromList(List<dynamic>? list) async {
    final result = <Gallery>[];
    for (final item in list ?? const []) {
      if (item is Map<String, dynamic>) {
        if (item['blacklisted'] == true) {
          continue;
        }
        result.add(await galleryFromListItem(item));
      }
    }
    return result;
  }

  /// `PaginatedResponse[GalleryListItem]` → [GallerySet].
  static Future<GallerySet> gallerySetFromPage(
    Map<String, dynamic> json, {
    int? page,
  }) async {
    return GallerySet(
      gallerys: await galleriesFromList(json['result'] as List?),
      maxPage: _int(json['num_pages']) ?? 1,
      currentPage: page,
    );
  }

  /// `GalleryDetailResponse` → [Gallery].
  static Future<Gallery> galleryFromDetail(Map<String, dynamic> json) async {
    final title = (json['title'] as Map?)?.cast<String, dynamic>() ?? const {};
    final tags = <Tag>[];
    for (final item in (json['tags'] as List?) ?? const []) {
      if (item is! Map) {
        continue;
      }
      final type = item['type'] as String?;
      final name = item['name'] as String?;
      final translated = await getTags(['${item['id']}']);
      tags.add(Tag(
        id: _int(item['id']),
        type: tagGroup(type),
        name: name,
        url: item['url'] as String?,
        count: _int(item['count']),
        translatedName: translated.isNotEmpty &&
                (translated.first.translatedName ?? '').isNotEmpty
            ? translated.first.translatedName
            : name,
      ));
    }
    final tagIds = tags.map((e) => '${e.id}').toList(growable: false);

    final pages = <GalleryImage>[];
    for (final p in (json['pages'] as List?) ?? const []) {
      if (p is! Map) {
        continue;
      }
      final path = p['path'] as String? ?? '';
      final thumb = p['thumbnail'] as String? ?? '';
      pages.add(GalleryImage(
        type: _type(path),
        imgWidth: _int(p['width']),
        imgHeight: _int(p['height']),
        // Full size page and its thumbnail, as given by the API.
        imageUrl: path.isEmpty ? null : imageUrl(path),
        href: thumb.isEmpty ? null : thumbUrl(thumb),
      ));
    }

    final uploadDate = _int(json['upload_date']);
    final related = await galleriesFromList(json['related'] as List?);
    final comments = commentsFromList(json['comments'] as List?);

    return Gallery(
      gid: _int(json['id']) ?? 0,
      mediaId: '${json['media_id']}',
      title: GalleryTitle(
        englishTitle: title['english'] as String?,
        japaneseTitle: title['japanese'] as String?,
        prettyTitle: title['pretty'] as String?,
      ),
      scanlator: json['scanlator'] as String?,
      uploadDate: uploadDate,
      uploadedDateTime: uploadDate == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(uploadDate * 1000, isUtc: true)
              .toIso8601String(),
      numPages: _int(json['num_pages']),
      numFavorites: _int(json['num_favorites']),
      isFavorited: json['is_favorited'] as bool?,
      tags: tags,
      simpleTags: tags.where((t) => t.type == 'Tags').take(10).toList(),
      languageCode: getLanguageCode(tagIds),
      moreLikeGallerys: related,
      comments: comments,
      images: GalleryImages(
        cover: _image((json['cover'] as Map?)?.cast<String, dynamic>()),
        thumbnail: _image((json['thumbnail'] as Map?)?.cast<String, dynamic>()),
        pages: pages,
      ),
    );
  }

  /// `CommentResponse` → [Comment].
  static Comment commentFromJson(Map<String, dynamic> json) {
    final poster = (json['poster'] as Map?)?.cast<String, dynamic>();
    return Comment(
      commentId: _int(json['id']),
      gid: _int(json['gallery_id']),
      postDate: _int(json['post_date']),
      commentText: json['body'] as String?,
      poster: poster == null
          ? null
          : CommentPoster(
              posterId: _int(poster['id']),
              username: poster['username'] as String?,
              avatarUrl: poster['avatar_url'] as String?,
              isSuperuser: poster['is_superuser'] as bool?,
              isStaff: poster['is_staff'] as bool?,
            ),
    );
  }

  static List<Comment> commentsFromList(List<dynamic>? list) => [
        for (final item in list ?? const [])
          if (item is Map<String, dynamic>) commentFromJson(item),
      ];

  /// Gallery id from a gallery URL (`https://nhentai.net/g/123/`) or id.
  static int? gidFromUrl(String url) {
    final match = RegExp(r'/g/(\d+)').firstMatch(url);
    return int.tryParse(match?.group(1) ?? url);
  }

  /// Solve the API's proof-of-work: find a nonce so that
  /// sha256(challenge + nonce) starts with [difficulty] zero bits.
  static String solvePow(String challenge, int difficulty) {
    if (difficulty <= 0) {
      return '';
    }
    final fullBytes = difficulty ~/ 8;
    final remBits = difficulty % 8;
    final mask = remBits == 0 ? 0 : (0xFF << (8 - remBits)) & 0xFF;
    for (var nonce = 0; nonce < 1 << 30; nonce++) {
      final digest = sha256.convert(utf8.encode('$challenge$nonce')).bytes;
      var ok = true;
      for (var i = 0; i < fullBytes; i++) {
        if (digest[i] != 0) {
          ok = false;
          break;
        }
      }
      if (ok && (mask == 0 || (digest[fullBytes] & mask) == 0)) {
        return '$nonce';
      }
    }
    return '';
  }
}
