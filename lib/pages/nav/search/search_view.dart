import 'dart:async';

import 'package:auto_route/auto_route.dart';

import 'package:eros_n/common/enum.dart';
import 'package:eros_n/common/global.dart';
import 'package:eros_n/common/provider/settings_provider.dart';
import 'package:eros_n/component/models/index.dart';
import 'package:eros_n/component/widget/buttons.dart';
import 'package:eros_n/generated/l10n.dart';
import 'package:eros_n/pages/list_view/list_view.dart';
import 'package:eros_n/pages/nav/index/index_provider.dart';
import 'package:eros_n/routes/routes.dart';
import 'package:eros_n/store/db/entity/nh_tag.dart';
import 'package:eros_n/component/theme/theme.dart';
import 'package:eros_n/component/widget/apple.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:keframe/keframe.dart';
import 'package:sliver_tools/sliver_tools.dart';

import '../../../utils/logger.dart';
import 'search_provider.dart';

@RoutePage()
class SearchPage extends StatefulHookConsumerWidget {
  const SearchPage({Key? key, required this.query}) : super(key: key);
  final String query;

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage>
    with AutomaticKeepAliveClientMixin {
  final ScrollController scrollController = ScrollController();
  ScrollDirection _lastScrollDirection = ScrollDirection.idle;
  double lastScrollOffset = 0;
  String query = '';

  late StreamSubscription<bool> keyboardSubscription;

  IndexNotifier get indexProviderNoti => ref.read(indexProvider.notifier);

  SearchNotifier get searchProviderNoti =>
      ref.read(searchProvider(currentSearchDepth).notifier);

  @override
  void initState() {
    super.initState();
    query = widget.query;
    searchProviderNoti.searchController.value = TextEditingValue(
      text: query,
      selection: TextSelection.collapsed(offset: query.length),
    );
    indexProviderNoti.addScrollController(scrollController);
    scrollController.addListener(_scrollListener);

    if (query.trim().isNotEmpty) {
      logger.d('search query: $query');
      searchProviderNoti.search();
    }

    final keyboardVisibilityController = KeyboardVisibilityController();
    // Query
    logger.t(
        'Keyboard visibility direct query: ${keyboardVisibilityController.isVisible}');

    // Subscribe
    keyboardSubscription =
        keyboardVisibilityController.onChange.listen((bool visible) {
      logger.t('Keyboard visibility update. Is visible: $visible');
      if (!visible) {
        searchProviderNoti.searchFocusNode.unfocus();
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    scrollController.removeListener(_scrollListener);
    keyboardSubscription.cancel();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      body: SizeCacheWidget(
        child: CustomScrollView(
          controller: scrollController,
          physics: kAppleScrollPhysics,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            AppleSliverNavBar(
              title: L10n.of(context).search,
              heroTag: 'nav_search_$currentSearchDepth',
              automaticallyImplyLeading: canPop,
              trailing: NavFilterButtons(
                language: ref.watch(
                    settingsProvider.select((s) => s.searchLanguagesFilter)),
                onLanguageSelected: (LanguagesFilter value) async {
                  if (value ==
                      ref.read(settingsProvider).searchLanguagesFilter) {
                    return;
                  }
                  ref
                      .read(settingsProvider.notifier)
                      .setSearchLanguagesFilter(value);
                  await searchProviderNoti.reloadData();
                },
                sort: ref.watch(settingsProvider.select((s) => s.searchSort)),
                onSortSelected: (value) async {
                  if (value == ref.read(settingsProvider).searchSort) {
                    return;
                  }
                  ref.read(settingsProvider.notifier).setSearchSort(value);
                  await searchProviderNoti.reloadData();
                },
              ),
              bottom: PreferredSize(
                preferredSize:
                    const Size.fromHeight(AppleSearchField.height + 12),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: buildSearchBar(),
                ),
              ),
            ),
            CupertinoSliverRefreshControl(
              onRefresh: () => searchProviderNoti.reloadData(),
            ),
            const SearchListView(),
          ],
        ),
      ),
    );
  }

  Widget buildSearchBar() {
    final palette = context.palette;
    final theme = Theme.of(context);
    return TypeAheadField<NhTag>(
      controller: searchProviderNoti.searchController,
      focusNode: searchProviderNoti.searchFocusNode,
      hideOnEmpty: true,
      hideOnError: true,
      hideOnLoading: true,
      debounceDuration: const Duration(milliseconds: 250),
      offset: const Offset(0, 8),
      constraints: const BoxConstraints(maxHeight: 360),
      builder: (context, controller, focusNode) {
        return AppleSearchField(
          controller: controller,
          focusNode: focusNode,
          placeholder: L10n.of(context).search,
          onSubmitted: (value) {
            focusNode.unfocus();
            searchProviderNoti.search();
          },
        );
      },
      decorationBuilder: (context, child) {
        return Material(
          color: palette.menu,
          elevation: 12,
          shadowColor: Colors.black.withValues(alpha: 0.3),
          clipBehavior: Clip.antiAlias,
          shape: const RoundedSuperellipseBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
          ),
          child: child,
        );
      },
      itemSeparatorBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(left: 48),
        child: Divider(color: palette.separator),
      ),
      suggestionsCallback: (pattern) async {
        final currQryText = pattern.split(RegExp(r'[ ;"]')).last;

        if (currQryText.isEmpty) {
          return <NhTag>[];
        }
        logger.d('suggestionsCallback: $currQryText');
        return isarHelper.findNhTagContains(currQryText, 200);
      },
      itemBuilder: (BuildContext context, itemData) {
        return Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Row(
            children: [
              Icon(
                CupertinoIcons.tag,
                size: 18,
                color: palette.secondaryLabel,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${itemData.type}:${itemData.name}',
                        style: theme.textTheme.bodyLarge,
                      ),
                      if (itemData.translateName != null)
                        Text(
                          itemData.translateName ?? '',
                          style: theme.textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
              ),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                onPressed: () {
                  searchProviderNoti.appendNhTagQuery(itemData);
                },
                child: Icon(
                  CupertinoIcons.arrow_up_left,
                  size: 18,
                  color: palette.secondaryLabel,
                ),
              ),
            ],
          ),
        );
      },
      emptyBuilder: (context) {
        return const SizedBox();
      },
      onSelected: (suggestion) {
        searchProviderNoti.appendNhTagQuery(suggestion, search: true);
      },
    );
  }

  @override
  bool get wantKeepAlive => currentSearchDepth == 0;

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
}

class SearchListView extends HookConsumerWidget {
  const SearchListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Gallery> galleryList =
        ref.watch(searchGallerysProvider(currentSearchDepth));
    final state = ref.watch(searchProvider(currentSearchDepth));

    if (state.isLoading) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: AppleLoading(),
      );
    }

    if (state.isLoadError) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: AppleEmptyState(
          icon: CupertinoIcons.wifi_exclamationmark,
          title: state.errorMessage ?? 'Error',
          action: CapsuleButton(
            label: '',
            icon: CupertinoIcons.arrow_clockwise,
            filled: false,
            onPressed: () {
              ref
                  .read(searchProvider(currentSearchDepth).notifier)
                  .reloadData();
            },
          ),
        ),
      );
    }

    if (galleryList.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: AppleEmptyState(
          icon: CupertinoIcons.search,
          title: L10n.of(context).search,
        ),
      );
    }

    return SliverSafeArea(
      top: false,
      bottom: false,
      sliver: MultiSliver(
        children: [
          GallerySliverList(
            gallerys: galleryList,
            lastComplete: () => ref
                .read(searchProvider(currentSearchDepth).notifier)
                .loadNextPage(),
            keepPosition: true,
            maxPage: state.maxPage,
            tabTag: '${NHRoutes.search}_$currentSearchDepth',
          ),
          Consumer(builder: (context, ref, _) {
            final state = ref.watch(searchProvider(currentSearchDepth));
            return EndIndicator(
              loadStatus: state.status,
            );
          }),
        ],
      ),
    );
  }
}
