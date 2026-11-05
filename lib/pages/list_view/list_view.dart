import 'dart:math' as math;

import 'package:eros_n/common/const/const.dart';
import 'package:eros_n/common/enum.dart';
import 'package:eros_n/common/provider/card_size_provider.dart';
import 'package:eros_n/common/provider/settings_provider.dart';
import 'package:eros_n/component/models/gallery.dart';
import 'package:eros_n/pages/enum.dart';
import 'package:eros_n/pages/list_view/item/item_list_card.dart';
import 'package:eros_n/pages/list_view/item/item_waterfall_flow_card.dart';
import 'package:eros_n/utils/get_utils/get_utils.dart';
import 'package:eros_n/component/theme/theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_list_view/flutter_list_view.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:keframe/keframe.dart';
import 'package:waterfall_flow/waterfall_flow.dart';

import 'item/item_grid_card.dart';

class GallerySliverList extends HookConsumerWidget {
  const GallerySliverList({
    Key? key,
    required this.gallerys,
    this.tabTag,
    this.lastComplete,
    this.keepPosition = false,
    this.maxPage = 1,
    this.currentPage = 1,
  }) : super(key: key);

  final List<Gallery> gallerys;
  final String? tabTag;
  final VoidCallback? lastComplete;
  final bool keepPosition;
  final int maxPage;
  final int currentPage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listMode = ref.watch(settingsProvider.select((s) => s.listModel));
    switch (listMode) {
      case ListModel.waterfall:
        return GalleryWaterfallFlowView(
          gallerys: gallerys,
          tabTag: tabTag,
          lastComplete: lastComplete,
          keepPosition: keepPosition,
          maxPage: maxPage,
          currentPage: currentPage,
        );
      case ListModel.waterfallCompact:
        return GalleryWaterfallFlowView(
          gallerys: gallerys,
          tabTag: tabTag,
          lastComplete: lastComplete,
          keepPosition: keepPosition,
          maxPage: maxPage,
          currentPage: currentPage,
          compact: true,
        );
      case ListModel.grid:
        return GalleryCardSliverGridView(
          gallerys: gallerys,
          tabTag: tabTag,
          lastComplete: lastComplete,
          keepPosition: keepPosition,
          maxPage: maxPage,
          currentPage: currentPage,
        );
      case ListModel.list:
      default:
        return GalleryCardSliverListView(
          gallerys: gallerys,
          tabTag: tabTag,
          lastComplete: lastComplete,
          keepPosition: keepPosition,
          maxPage: maxPage,
          currentPage: currentPage,
        );
    }
  }
}

class GalleryCardSliverGridView extends ConsumerWidget {
  const GalleryCardSliverGridView({
    Key? key,
    required this.gallerys,
    this.tabTag,
    this.lastComplete,
    this.keepPosition = false,
    this.maxPage = 1,
    this.currentPage = 1,
  }) : super(key: key);

  final List<Gallery> gallerys;
  final String? tabTag;
  final VoidCallback? lastComplete;
  final bool keepPosition;
  final int maxPage;
  final int currentPage;

  Widget itemCardBuilder(BuildContext context, int index) {
    if (gallerys.length - 1 < index) {
      return const SizedBox.shrink();
    }

    if (index == gallerys.length - 1 && currentPage < maxPage) {
      // 加载完成最后一项的回调
      SchedulerBinding.instance
          .addPostFrameCallback((_) => lastComplete?.call());
    }

    final Gallery gallery = gallerys[index];

    return ItemGridCard(
      gallery: gallery,
      index: index,
      tabTag: tabTag,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardSize = ref
        .watch(cardSizeProvider)
        .of(MediaQuery.orientationOf(context));
    final titleStyle = Theme.of(context).textTheme.bodySmall;
    // Two lines of the title below the cover.
    final titleExtent = MediaQuery.textScalerOf(context)
            .scale((titleStyle?.fontSize ?? 12) * 1.25) *
        2;
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      sliver: SliverGrid(
        gridDelegate: CardSizeGridDelegate(
          cardSize: cardSize,
          titleExtent: titleExtent + 2,
        ),
        delegate: SliverChildBuilderDelegate(
          itemCardBuilder,
          childCount: gallerys.length,
        ),
      ),
    );
  }
}

class GalleryCardSliverListView extends StatelessWidget {
  const GalleryCardSliverListView({
    Key? key,
    required this.gallerys,
    this.tabTag,
    this.lastComplete,
    this.keepPosition = false,
    this.maxPage = 1,
    this.currentPage = 1,
  }) : super(key: key);

  final List<Gallery> gallerys;
  final String? tabTag;
  final VoidCallback? lastComplete;
  final bool keepPosition;
  final int maxPage;
  final int currentPage;

  Widget itemCardBuilder(BuildContext context, int index) {
    if (gallerys.length - 1 < index) {
      return const SizedBox.shrink();
    }

    if (index == gallerys.length - 1 && currentPage < maxPage) {
      // 加载完成最后一项的回调
      SchedulerBinding.instance
          .addPostFrameCallback((_) => lastComplete?.call());
    }

    final Gallery gallery = gallerys[index];

    return ItemListCard(
      gallery: gallery,
      index: index,
      tabTag: tabTag,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FlutterSliverList(
      delegate: FlutterListViewDelegate(
        itemCardBuilder,
        onItemKey: (index) => '${gallerys[index].gid}',
        childCount: gallerys.length,
        keepPosition: keepPosition,
        // onItemHeight: (index) => 180,
        preferItemHeight: kItemHeight,
      ),
    );
  }
}

class GalleryWaterfallFlowView extends ConsumerWidget {
  const GalleryWaterfallFlowView({
    Key? key,
    required this.gallerys,
    this.tabTag,
    this.lastComplete,
    this.keepPosition = false,
    this.maxPage = 1,
    this.currentPage = 1,
    this.compact = false,
  }) : super(key: key);

  final List<Gallery> gallerys;
  final String? tabTag;
  final VoidCallback? lastComplete;
  final bool keepPosition;
  final int maxPage;
  final int currentPage;
  final bool compact;

  Widget itemCardBuilder(BuildContext context, int index) {
    if (gallerys.length - 1 < index) {
      return const SizedBox.shrink();
    }

    if (index == gallerys.length - 1 && currentPage < maxPage) {
      // 加载完成最后一项的回调
      SchedulerBinding.instance
          .addPostFrameCallback((_) => lastComplete?.call());
    }

    final Gallery gallery = gallerys[index];

    Widget item = ItemWaterfallFlowCard(
      gallery: gallery,
      index: index,
      tabTag: tabTag,
      compact: compact,
    );

    if (!GetPlatform.isDesktop) {
      item = FrameSeparateWidget(
        index: index,
        child: item,
      );
    }

    return item;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardSize = ref
        .watch(cardSizeProvider)
        .of(MediaQuery.orientationOf(context));
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        16,
        8,
        16,
        NHConst.waterfallFlowLargeMainAxisSpacing,
      ),
      sliver: SliverWaterfallFlow(
        delegate: SliverChildBuilderDelegate(
          itemCardBuilder,
          childCount: gallerys.length,
        ),
        gridDelegate: CardSizeWaterfallFlowDelegate(
          cardSize: cardSize,
          lastChildLayoutTypeBuilder: (int index) => index == gallerys.length
              ? LastChildLayoutType.foot
              : LastChildLayoutType.none,
        ),
      ),
    );
  }
}

/// Grid layout whose column count follows the card size setting and the
/// width of the pane; each tile is a 3:4 cover plus two title lines.
class CardSizeGridDelegate extends SliverGridDelegate {
  const CardSizeGridDelegate({
    required this.cardSize,
    required this.titleExtent,
  });

  final CardSize cardSize;
  final double titleExtent;

  /// Gap between the cover and the title (see ItemGridCard).
  static const double _titleGap = 7;

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    final columns = cardSize.columnsFor(
      crossAxisExtent: constraints.crossAxisExtent,
      maxCrossAxisExtent: gridMaxCrossAxisExtent,
      crossAxisSpacing: gridCrossAxisSpacing,
    );
    final usable = math.max(
      0.0,
      constraints.crossAxisExtent - gridCrossAxisSpacing * (columns - 1),
    );
    final tileWidth = usable / columns;
    final tileHeight = tileWidth * 4 / 3 + _titleGap + titleExtent;
    return SliverGridRegularTileLayout(
      crossAxisCount: columns,
      mainAxisStride: tileHeight + gridMainAxisSpacing,
      crossAxisStride: tileWidth + gridCrossAxisSpacing,
      childMainAxisExtent: tileHeight,
      childCrossAxisExtent: tileWidth,
      reverseCrossAxis: axisDirectionIsReversed(constraints.crossAxisDirection),
    );
  }

  @override
  bool shouldRelayout(CardSizeGridDelegate oldDelegate) {
    return oldDelegate.cardSize != cardSize ||
        oldDelegate.titleExtent != titleExtent;
  }
}

/// Waterfall layout whose column count follows the card size setting and
/// the width of the pane ("standard" equals the original automatic count).
class CardSizeWaterfallFlowDelegate
    extends SliverWaterfallFlowDelegateWithMaxCrossAxisExtent {
  const CardSizeWaterfallFlowDelegate({
    required this.cardSize,
    super.lastChildLayoutTypeBuilder,
  }) : super(
          maxCrossAxisExtent: NHConst.waterfallFlowLargeMaxCrossAxisExtent,
          crossAxisSpacing: NHConst.waterfallFlowLargeCrossAxisSpacing,
          mainAxisSpacing: NHConst.waterfallFlowLargeMainAxisSpacing,
        );

  final CardSize cardSize;

  @override
  int getCrossAxisCount(SliverConstraints constraints) {
    return cardSize.columnsFor(
      crossAxisExtent: constraints.crossAxisExtent,
      maxCrossAxisExtent: maxCrossAxisExtent,
      crossAxisSpacing: crossAxisSpacing,
    );
  }

  @override
  bool shouldRelayout(SliverWaterfallFlowDelegate oldDelegate) {
    return super.shouldRelayout(oldDelegate) ||
        (oldDelegate is CardSizeWaterfallFlowDelegate &&
            oldDelegate.cardSize != cardSize);
  }
}

class EndIndicator extends StatelessWidget {
  const EndIndicator({Key? key, required this.loadStatus, this.loadDataMore})
      : super(key: key);

  final LoadStatus loadStatus;
  final VoidCallback? loadDataMore;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
          alignment: Alignment.center,
          padding: EdgeInsets.only(
              top: 32, bottom: 40.0 + context.mediaQueryPadding.bottom),
          child: () {
            switch (loadStatus) {
              case LoadStatus.none:
              case LoadStatus.success:
                return const SizedBox.shrink();
              case LoadStatus.loadingMore:
                return const CupertinoActivityIndicator();
              case LoadStatus.error:
                return CupertinoButton(
                  onPressed: loadDataMore,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.exclamationmark_circle,
                        size: 32,
                        color: context.palette.secondaryLabel,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Load more fail',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                );
              default:
                return const SizedBox.shrink();
            }
          }()),
    );
  }
}
