import 'dart:async';
import 'dart:ui';

import 'package:auto_route/auto_route.dart';

import 'package:eros_n/common/extension.dart';
import 'package:eros_n/component/models/index.dart';
import 'package:eros_n/component/widget/eros_cached_network_image.dart';
import 'package:eros_n/generated/l10n.dart';
import 'package:eros_n/pages/nav/history/history_provider.dart';
import 'package:eros_n/pages/nav/index/index_provider.dart';
import 'package:eros_n/routes/routes.dart';
import 'package:eros_n/store/db/entity/gallery_history.dart';
import 'package:eros_n/utils/logger.dart';
import 'package:eros_n/component/theme/theme.dart';
import 'package:eros_n/component/widget/apple.dart';
import 'package:eros_n/pages/list_view/item/item_base.dart';
import 'package:eros_n/utils/get_utils/extensions/context_extensions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:sliver_tools/sliver_tools.dart';

@RoutePage()
class HistoryPage extends StatefulHookConsumerWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage>
    with AutomaticKeepAliveClientMixin {
  final ScrollController scrollController = ScrollController();
  ScrollDirection _lastScrollDirection = ScrollDirection.idle;
  double lastScrollOffset = 0;
  IndexNotifier get indexProviderNoti => ref.read(indexProvider.notifier);
  late StreamSubscription<bool> keyboardSubscription;

  @override
  void initState() {
    super.initState();
    indexProviderNoti.addScrollController(scrollController);
    scrollController.addListener(_scrollListener);

    final keyboardVisibilityController = KeyboardVisibilityController();
    keyboardSubscription =
        keyboardVisibilityController.onChange.listen((bool visible) {
      if (!visible) {
        // unfocus
        FocusScope.of(context).unfocus();
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    scrollController.removeListener(_scrollListener);
    keyboardSubscription.cancel();
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
    logger.t('build HistoryPage');
    super.build(context);
    final palette = context.palette;
    return Scaffold(
      body: CupertinoScrollbar(
        controller: scrollController,
        child: CustomScrollView(
          controller: scrollController,
          physics: kAppleScrollPhysics,
          slivers: [
            AppleSliverNavBar(
              title: L10n.of(context).history,
              heroTag: 'nav_history',
              trailing: GlassIconButton(
                icon: CupertinoIcons.trash,
                sfSymbol: 'trash',
                iconSize: 18,
                tooltip: L10n.of(context).clear_history,
                onPressed: () {
                  showAppleAlert<void>(
                    context: context,
                    title: L10n.of(context).clear_history,
                    message: L10n.of(context).clear_history_tip,
                    actions: [
                      AppleAlertAction(
                        label: L10n.of(context).cancel,
                        isDefault: true,
                      ),
                      AppleAlertAction(
                        label: L10n.of(context).ok,
                        isDestructive: true,
                        onPressed: () {
                          ref.read(historyProvider.notifier).clearHistory();
                        },
                      ),
                    ],
                  );
                },
              ),
              bottom: PreferredSize(
                preferredSize:
                    const Size.fromHeight(AppleSearchField.height + 12),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: AppleSearchField(
                    placeholder: L10n.of(context).search,
                    onChanged: (value) {
                      ref
                          .read(searchKeyProvider.notifier)
                          .update((state) => state = value);
                    },
                  ),
                ),
              ),
            ),
            Consumer(
              builder: (context, ref, child) {
                final historys = ref.watch(filteredHistoryGallerysProvider);
                if (historys.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: AppleEmptyState(
                      icon: CupertinoIcons.clock,
                      title: L10n.of(context).history,
                    ),
                  );
                }
                final historysGroupByDate = groupByDate(historys);
                return SliverSafeArea(
                  top: false,
                  sliver: MultiSliver(
                      children: historysGroupByDate.entries.map(
                    (e) {
                      final DateTime date = e.key;
                      // if date is today
                      final String dateStr = date.isToday()
                          ? L10n.of(context).today
                          : date.isYesterday()
                              ? L10n.of(context).yesterday
                              : date.toLocal().toString().split(' ')[0];
                      final historysInDate = e.value;
                      return MultiSliver(
                        pushPinnedChildren: true,
                        children: [
                          SliverPinnedHeader(
                            child: ClipRect(
                              child: BackdropFilter(
                                filter:
                                    ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                                child: Container(
                                  color: palette.bar,
                                  padding:
                                      const EdgeInsets.fromLTRB(20, 10, 20, 6),
                                  child: Text(
                                    dateStr,
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final history = historysInDate[index];
                                return HistoryItem(
                                  history: history,
                                  showDivider:
                                      index != historysInDate.length - 1,
                                );
                              },
                              childCount: historysInDate.length,
                            ),
                          ),
                        ],
                      );
                    },
                  ).toList()),
                );
              },
            ),
            SliverToBoxAdapter(
              child: SizedBox(height: context.mediaQueryPadding.bottom + 24),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class HistoryItem extends HookConsumerWidget {
  const HistoryItem({
    Key? key,
    required this.history,
    this.showDivider = true,
  }) : super(key: key);

  final GalleryHistory history;
  final bool showDivider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final theme = Theme.of(context);
    // last view hour and minute
    final lastReadTime =
        DateTime.fromMillisecondsSinceEpoch(history.lastReadTime ?? 0);
    final String lastReadTimeStr =
        lastReadTime.toLocal().toString().split(' ')[1].substring(0, 5);

    return Dismissible(
      key: ValueKey('history_${history.gid}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: CupertinoColors.systemRed.resolveFrom(context),
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: const Icon(CupertinoIcons.trash, color: Colors.white),
      ),
      onDismissed: (_) {
        ref.read(historyProvider.notifier).removeHistory(history.gid);
      },
      child: InkWell(
        onTap: () {
          final gallery = Gallery(
            gid: history.gid,
            mediaId: history.mediaId,
            title: GalleryTitle(
              englishTitle: history.title,
              japaneseTitle: history.japaneseTitle,
            ),
            images: GalleryImages(
              cover: GalleryImage(
                imgHeight: history.coverImgHeight,
                imgWidth: history.coverImgWidth,
              ),
            ),
          );

          RouteUtil.goGallery(ref, gallery);
        },
        child: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Row(
            children: [
              SizedBox(
                width: 58,
                height: 78,
                child: CoverArtwork(
                  radius: 8,
                  shadow: false,
                  child: ErosCachedNetworkImage(
                    imageUrl: history.thumbUrl ?? '',
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const SizedBox.expand(),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Container(
                  height: 98,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    border: showDivider
                        ? Border(
                            bottom: BorderSide(
                                color: palette.separator, width: 0.5),
                          )
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        history.title ?? '',
                        style: theme.textTheme.titleSmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            CupertinoIcons.clock,
                            size: 13,
                            color: palette.secondaryLabel,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            lastReadTimeStr,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Map<DateTime, List<GalleryHistory>> groupByDate(List<GalleryHistory> historys) {
  final Map<DateTime, List<GalleryHistory>> map = {};
  for (final history in historys) {
    final date = DateTime.fromMillisecondsSinceEpoch(history.lastReadTime ?? 0);
    final key = DateTime(date.year, date.month, date.day);
    if (map.containsKey(key)) {
      map[key]!.add(history);
    } else {
      map[key] = [history];
    }
  }
  return map;
}
