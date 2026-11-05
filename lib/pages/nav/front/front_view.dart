import 'package:auto_route/auto_route.dart';
import 'package:eros_n/common/enum.dart';
import 'package:eros_n/common/extension.dart';
import 'package:eros_n/common/provider/settings_provider.dart';
import 'package:eros_n/component/models/gallery.dart';
import 'package:eros_n/component/widget/buttons.dart';
import 'package:eros_n/generated/l10n.dart';
import 'package:eros_n/pages/list_view/item/item_base.dart';
import 'package:eros_n/pages/list_view/list_view.dart';
import 'package:eros_n/pages/nav/index/index_provider.dart';
import 'package:eros_n/routes/routes.dart';
import 'package:eros_n/utils/logger.dart';
import 'package:eros_n/component/widget/apple.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:keframe/keframe.dart';
import 'package:sliver_tools/sliver_tools.dart';

import 'front_provider.dart';

@RoutePage()
class FrontPage extends StatefulHookConsumerWidget {
  const FrontPage({super.key});

  @override
  ConsumerState<FrontPage> createState() => _FrontPageState();
}

class _FrontPageState extends ConsumerState<FrontPage>
    with AutomaticKeepAliveClientMixin {
  final ScrollController scrollController = ScrollController();
  ScrollDirection _lastScrollDirection = ScrollDirection.idle;
  double lastScrollOffset = 0;

  IndexNotifier get indexProviderNoti => ref.read(indexProvider.notifier);

  @override
  void initState() {
    super.initState();
    indexProviderNoti.addScrollController(scrollController);
    ref.read(frontProvider.notifier).loadData();
    scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    const double threshold = 100;
    if (scrollController.position.userScrollDirection ==
        ScrollDirection.reverse) {
      if (_lastScrollDirection != ScrollDirection.reverse) {
        lastScrollOffset = scrollController.offset;
      }
      if (scrollController.offset - lastScrollOffset > threshold) {
        indexProviderNoti.hideNavigationBar();
      }
      _lastScrollDirection = ScrollDirection.reverse;
    }
    if (scrollController.position.userScrollDirection ==
        ScrollDirection.forward) {
      if (_lastScrollDirection != ScrollDirection.forward) {
        lastScrollOffset = scrollController.offset;
      }
      if (lastScrollOffset - scrollController.offset > threshold) {
        indexProviderNoti.showNavigationBar();
      }
      _lastScrollDirection = ScrollDirection.forward;
    }
  }

  @override
  Widget build(BuildContext context) {
    logger.t('FrontPage build');

    super.build(context);
    return Scaffold(
      body: SizeCacheWidget(
        child: CustomScrollView(
          controller: scrollController,
          physics: kAppleScrollPhysics,
          slivers: [
            AppleSliverNavBar(
              title: L10n.of(context).home,
              heroTag: 'nav_front',
              trailing: const _FrontFilterButtons(),
            ),
            CupertinoSliverRefreshControl(
              onRefresh: () => ref.read(frontProvider.notifier).reloadData(),
            ),
            const PopularListView(),
            SliverGalleryListView(scrollController: scrollController),
            Consumer(builder: (context, ref, _) {
              final state = ref.watch(frontProvider);
              return EndIndicator(
                loadStatus: state.status,
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    scrollController.dispose();
  }

  @override
  bool get wantKeepAlive => true;
}

/// Language + sort pull-down menus shown in the navigation bar.
class _FrontFilterButtons extends HookConsumerWidget {
  const _FrontFilterButtons();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchSortOnFrontPage =
        ref.watch(settingsProvider.select((s) => s.searchSortOnFrontPage));
    final frontLanguagesFilter =
        ref.watch(settingsProvider.select((s) => s.frontLanguagesFilter));
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        LanguagesFilterPopupButton(
          onSelected: (LanguagesFilter value) async {
            if (value == ref.read(settingsProvider).frontLanguagesFilter) {
              return;
            }
            ref.read(settingsProvider.notifier).setFrontLanguagesFilter(value);
            await ref.read(frontProvider.notifier).reloadData();
          },
          initValue: frontLanguagesFilter,
        ),
        SortPopupButton(
          onSelected: (value) async {
            // if not change, do nothing
            if (value == searchSortOnFrontPage) {
              return;
            }
            ref.read(settingsProvider.notifier).setSearchSortOnFrontPage(value);

            // reload
            await ref.read(frontProvider.notifier).reloadData();
          },
          initValue: searchSortOnFrontPage,
        ),
      ],
    );
  }
}

class SliverGalleryListView extends HookConsumerWidget {
  const SliverGalleryListView({
    super.key,
    required this.scrollController,
  });

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sortMap = <SearchSort, String>{
      SearchSort.recent: L10n.of(context).recent,
      SearchSort.popularToday: L10n.of(context).popular_today,
      SearchSort.popularWeek: L10n.of(context).popular_week,
      SearchSort.popularMonth: L10n.of(context).popular_month,
      SearchSort.popular: L10n.of(context).popular,
    };
    final languagesMap = {
      LanguagesFilter.all: L10n.of(context).all,
      LanguagesFilter.japanese: L10n.of(context).japanese,
      LanguagesFilter.chinese: L10n.of(context).chinese,
      LanguagesFilter.english: L10n.of(context).english,
      LanguagesFilter.translated: L10n.of(context).translated,
    };

    final searchSortOnFrontPage =
        ref.watch(settingsProvider.select((s) => s.searchSortOnFrontPage));
    final frontLanguagesFilter =
        ref.watch(settingsProvider.select((s) => s.frontLanguagesFilter));

    return SliverSafeArea(
      top: false,
      bottom: false,
      sliver: MultiSliver(
        children: [
          AppleSectionHeader(
            title: sortMap[searchSortOnFrontPage] ?? L10n.of(context).recent,
            padding: const EdgeInsets.fromLTRB(20, 24, 16, 2),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: Text(
              languagesMap[frontLanguagesFilter] ?? '',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const GalleryListView(),
        ],
      ),
    );
  }
}

class PopularListView extends ConsumerWidget {
  const PopularListView({
    Key? key,
  }) : super(key: key);

  static const double _coverWidth = 150;
  static const double _coverHeight = _coverWidth * 4 / 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final popularList = ref.watch(popularProvider);
    if (popularList.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    final theme = Theme.of(context);
    return SliverSafeArea(
      top: false,
      bottom: false,
      sliver: MultiSliver(
        children: [
          AppleSectionHeader(
            title: L10n.of(context).popular,
            padding: const EdgeInsets.fromLTRB(20, 8, 16, 10),
          ),
          SizedBox(
            height: _coverHeight + 62,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final gallery = popularList[index];
                return PressableScale(
                  onTap: () {
                    RouteUtil.goGallery(
                      ref,
                      gallery,
                      heroTag: '${NHRoutes.front}_popular',
                    );
                  },
                  child: SizedBox(
                    width: _coverWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: _coverHeight,
                          width: _coverWidth,
                          child: Hero(
                            tag:
                                '${NHRoutes.front}_popular_${gallery.thumbUrl}',
                            child: CoverArtwork(
                              radius: 12,
                              languageCode: gallery.languageCode,
                              child: CoverImg(
                                imgUrl: gallery.thumbUrl ?? '',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          (gallery.title.englishTitle ?? '').prettyTitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                            height: 1.25,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
              itemCount: popularList.length,
            ),
          ),
        ],
      ),
    );
  }
}

class GalleryListView extends HookConsumerWidget {
  const GalleryListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    logger.t('GalleryListView build');
    final List<Gallery> galleryList = ref.watch(gallerysProvider);
    final state = ref.watch(frontProvider);

    if (state.isLoading) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: AppleLoading(),
      );
    }
    return GallerySliverList(
      gallerys: galleryList,
      lastComplete: () => ref.read(frontProvider.notifier).loadNextPage(),
      keepPosition: true,
      maxPage: state.maxPage,
      tabTag: NHRoutes.front,
    );
  }
}
