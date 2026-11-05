import 'package:auto_route/auto_route.dart';
import 'package:eros_n/component/models/index.dart';
import 'package:eros_n/generated/l10n.dart';
import 'package:eros_n/pages/list_view/list_view.dart';
import 'package:eros_n/pages/user/user_provider.dart';
import 'package:eros_n/routes/routes.dart';
import 'package:eros_n/utils/logger.dart';
import 'package:eros_n/common/global.dart';
import 'package:eros_n/component/widget/apple.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:keframe/keframe.dart';
import 'package:sliver_tools/sliver_tools.dart';

import '../index/index_provider.dart';
import 'favorite_provider.dart';

@RoutePage()
class FavoritePage extends StatefulHookConsumerWidget {
  const FavoritePage({
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends ConsumerState<FavoritePage>
    with AutomaticKeepAliveClientMixin {
  final ScrollController scrollController = ScrollController();
  ScrollDirection _lastScrollDirection = ScrollDirection.idle;
  double lastScrollOffset = 0;

  IndexNotifier get indexProviderNoti => ref.read(indexProvider.notifier);

  @override
  void initState() {
    super.initState();
    indexProviderNoti.addScrollController(scrollController);
    ref.read(favoriteProvider.notifier).loadData();
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
    final isUserLoggedIn =
        ref.watch(userProvider.select((user) => user.isLogin));
    super.build(context);
    return Scaffold(
      body: SizeCacheWidget(
        child: CustomScrollView(
          controller: scrollController,
          physics: kAppleScrollPhysics,
          slivers: [
            AppleSliverNavBar(
              title: L10n.of(context).favorites,
              heroTag: 'nav_favorite',
            ),
            if (isUserLoggedIn) ...[
              CupertinoSliverRefreshControl(
                onRefresh: ref.read(favoriteProvider.notifier).reloadData,
              ),
              SliverSafeArea(
                top: false,
                bottom: false,
                sliver: MultiSliver(
                  children: [
                    const FavoriteListView(),
                    Consumer(builder: (context, ref, _) {
                      final state = ref.watch(favoriteProvider);
                      return EndIndicator(
                        loadStatus: state.status,
                      );
                    }),
                  ],
                ),
              ),
            ] else
              SliverFillRemaining(
                hasScrollBody: false,
                child: AppleEmptyState(
                  icon: CupertinoIcons.heart,
                  title: L10n.of(context).favorites,
                  message: L10n.of(context).please_login_first,
                  action: CapsuleButton(
                    label: L10n.of(context).login,
                    icon: CupertinoIcons.person_crop_circle,
                    onPressed: () => erosRouter.pushNamed(NHRoutes.login),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class FavoriteListView extends HookConsumerWidget {
  const FavoriteListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Gallery> galleryList = ref.watch(favoriteGallerysProvider);
    final state = ref.watch(favoriteProvider);
    logger
        .t('FavoriteListView build ,galleryList.length: ${galleryList.length}');

    if (state.isLoading) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: AppleLoading(),
      );
    }
    return GallerySliverList(
      gallerys: galleryList,
      lastComplete: () => ref.read(favoriteProvider.notifier).loadNextPage(),
      keepPosition: true,
      maxPage: state.maxPage,
      tabTag: NHRoutes.favorite,
    );
  }
}
