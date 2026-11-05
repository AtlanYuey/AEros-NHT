import 'package:auto_route/auto_route.dart';
import 'package:collection/collection.dart';
import 'package:eros_n/common/const/const.dart';
import 'package:eros_n/component/models/image.dart';
import 'package:eros_n/component/widget/eros_cached_network_image.dart';
import 'package:eros_n/generated/l10n.dart';
import 'package:eros_n/pages/enum.dart';
import 'package:eros_n/pages/gallery/gallery_provider.dart';
import 'package:eros_n/routes/routes.dart';
import 'package:eros_n/utils/get_utils/extensions/context_extensions.dart';
import 'package:eros_n/utils/logger.dart';
import 'package:eros_n/component/theme/theme.dart';
import 'package:eros_n/component/widget/apple.dart';
import 'package:eros_n/pages/list_view/item/item_base.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

@RoutePage()
class ThumbPage extends HookConsumerWidget {
  const ThumbPage({
    Key? key,
    required this.gid,
    this.colorScheme,
  }) : super(key: key);
  final int gid;
  final ColorScheme? colorScheme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ScrollController scrollController = useScrollController();

    return Theme(
      data: colorScheme == null
          ? Theme.of(context)
          : ThemeConfig.buildTheme(colorScheme!),
      child: Builder(builder: (context) {
        return Scaffold(
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          floatingActionButton: Consumer(builder: (context, ref, child) {
            final currentPageIndex = ref
                .watch(galleryProvider(gid).select((g) => g.currentPageIndex));
            final label = currentPageIndex == 0
                ? L10n.of(context).read
                : '${L10n.of(context).resume} · ${currentPageIndex + 1}';
            return DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: CapsuleButton(
                label: label,
                icon: CupertinoIcons.book_fill,
                height: 50,
                onPressed: () {
                  RouteUtil.goRead(context, ref);
                },
              ),
            );
          }),
          body: ThumbBody(
            scrollController: scrollController,
            gid: gid,
            title: L10n.of(context).thumbs,
          ),
        );
      }),
    );
  }
}

class ThumbBody extends StatelessWidget {
  const ThumbBody({
    super.key,
    required this.scrollController,
    required this.gid,
    this.backGround,
    this.title,
  });

  final ScrollController scrollController;
  final int gid;
  final Widget? backGround;

  /// When set, a large-title navigation bar is shown above the grid.
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (backGround != null) backGround!,
        CupertinoScrollbar(
          controller: scrollController,
          child: CustomScrollView(
            controller: scrollController,
            physics: kAppleScrollPhysics,
            slivers: [
              if (title != null)
                AppleSliverNavBar(title: title!, heroTag: 'nav_thumbs_$gid'),
              ThumbsView(
                gid: gid,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ThumbsView extends HookConsumerWidget {
  const ThumbsView({
    Key? key,
    required this.gid,
    this.enableHero = false,
  }) : super(key: key);

  final int gid;
  final bool enableHero;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    logger.t('build thumbs $gid');
    // final pages = ref.watch(galleryProvider(gid).select((g) => g.pages));

    const kHeroTagPrefix = 'thumb_';

    final List<GalleryImage> pages =
        ref.watch(galleryProvider(gid).select((g) => g.images.pages));
    final mediaId = ref.watch(galleryProvider(gid).select((g) => g.mediaId));
    final pageStatus =
        ref.watch(pageStateProvider(gid).select((state) => state.pageStatus));

    if (pageStatus == PageStatus.loading || pages.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: AppleLoading(),
      );
    }

    final minRatio = pages
        .map((image) => (image.imgWidth ?? 300) / (image.imgHeight ?? 400))
        .min;
    // logger.d('minRatio: $minRatio');
    return SliverPadding(
      padding: EdgeInsets.only(
        top: 12,
        bottom: 96 + context.mediaQueryPadding.bottom,
        left: 16,
        right: 16,
      ),
      sliver: SliverGrid(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final thumb = pages[index];
              final imageUrl =
                  'https://t.nhentai.net/galleries/$mediaId/${index + 1}t.${NHConst.extMap[thumb.type]}';
              return PressableScale(
                onTap: () {
                  RouteUtil.goRead(context, ref,
                      index: index, heroTagPrefix: kHeroTagPrefix);
                },
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: (thumb.imgWidth ?? 300) /
                              (thumb.imgHeight ?? 400),
                          child: CoverArtwork(
                            radius: 8,
                            shadow: false,
                            child: Hero(
                              tag: '$kHeroTagPrefix${gid}_$index',
                              child: ErosCachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${index + 1}',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
              );
            },
            childCount: pages.length,
          ),
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 130.0,
            mainAxisSpacing: 12,
            crossAxisSpacing: 10,
            childAspectRatio: minRatio - 0.2,
          )),
    );
  }
}
