import 'dart:convert';
import 'dart:io';

import 'package:eros_n/common/enum.dart';
import 'package:eros_n/component/models/index.dart';
import 'package:eros_n/network/api_v2.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _json(String name) =>
    jsonDecode(File('test/fixtures/$name').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  test('gallery list maps ids, titles and webp thumbnails', () async {
    final set =
        await NhApiV2.gallerySetFromPage(_json('galleries.json'), page: 1);
    expect(set.gallerys, isNotEmpty);
    expect(set.maxPage, greaterThan(1));
    final g = set.gallerys!.first;
    expect(g.gid, greaterThan(0));
    expect(g.title.englishTitle, isNotEmpty);
    expect(g.thumbUrl, startsWith('https://t.nhentai.net/galleries/'));
    expect(g.thumbUrl, isNot(contains('null')));
    expect(g.images.thumbnail.imgWidth, greaterThan(0));
  });

  test('popular list', () async {
    final list =
        jsonDecode(File('test/fixtures/popular.json').readAsStringSync());
    final galleries = await NhApiV2.galleriesFromList(list as List);
    expect(galleries, isNotEmpty);
  });

  test('gallery detail maps pages, tags, related', () async {
    final g = await NhApiV2.galleryFromDetail(_json('detail.json'));
    expect(g.images.pages, isNotEmpty);
    final page = g.images.pages.first;
    expect(page.imageUrl, startsWith('https://i.nhentai.net/galleries/'));
    expect(page.href, startsWith('https://t.nhentai.net/galleries/'));
    expect(page.imgWidth, greaterThan(0));
    expect(
        g.tags.map((t) => t.type).toSet(),
        everyElement(isIn([
          'Parodies',
          'Characters',
          'Tags',
          'Artists',
          'Groups',
          'Languages',
          'Categories'
        ])));
    expect(g.uploadedDate, isNotNull);
    expect(g.coverUrl, startsWith('https://t.nhentai.net/'));
    expect(g.moreLikeGallerys, isNotEmpty);
    expect(g.languageCode, isNotNull);
    final tag = g.tags.firstWhere((t) => t.type == 'Tags');
    expect(NhApiV2.searchPrefix(tag), 'tag');
  });

  test('comments', () {
    final comments =
        NhApiV2.commentsFromList(_json('comments.json')['result'] as List);
    expect(comments, isNotEmpty);
    expect(comments.first.poster?.username, isNotEmpty);
    expect(comments.first.postDate, greaterThan(0));
  });

  test('search page', () async {
    final set = await NhApiV2.gallerySetFromPage(_json('search.json'));
    expect(set.gallerys, isNotEmpty);
  });

  test('sort mapping and url parsing', () {
    expect(NhApiV2.sortValue(SearchSort.recent), 'date');
    expect(NhApiV2.sortValue(SearchSort.popularWeek), 'popular-week');
    expect(NhApiV2.gidFromUrl('https://nhentai.net/g/694331/'), 694331);
    expect(
        NhApiV2.searchPrefix(const Tag(type: 'Artists', name: 'x')), 'artist');
  });

  test('proof of work finds a nonce with leading zero bits', () {
    final nonce = NhApiV2.solvePow('abc', 12);
    expect(nonce, isNotEmpty);
  });
}
