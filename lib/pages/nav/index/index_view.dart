import 'dart:math' as math;

import 'package:auto_route/auto_route.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:eros_n/common/provider/receive_sharing_provider.dart';
import 'package:eros_n/generated/l10n.dart';
import 'package:eros_n/pages/nav/favorite/favorite_view.dart';
import 'package:eros_n/pages/nav/front/front_view.dart';
import 'package:eros_n/pages/nav/history/history_view.dart';
import 'package:eros_n/pages/nav/more/more_view.dart';
import 'package:eros_n/pages/nav/search/search_view.dart';
import 'package:eros_n/component/theme/theme.dart';
import 'package:eros_n/component/widget/apple.dart';
import 'package:eros_n/utils/get_utils/extensions/export.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../utils/logger.dart';
import 'index_provider.dart';

@RoutePage()
class IndexPage extends StatefulHookConsumerWidget {
  const IndexPage({super.key});

  @override
  ConsumerState<IndexPage> createState() => _IndexPageState();
}

class _IndexPageState extends ConsumerState<IndexPage> {
  final pages = <Widget>[
    const FrontPage(),
    const FavoritePage(),
    const SearchPage(query: ''),
    const HistoryPage(),
    const MorePage(),
  ];

  @override
  void initState() {
    logger.d('initState');
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      EasyDebounce.debounce(
        'listenReceiveSharing',
        const Duration(milliseconds: 500),
        () =>
            ref.read(receiveSharingProvider.notifier).listenReceiveSharing(ref),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(indexProvider);

    return Scaffold(
      extendBody: true,
      body: PageView(
        controller: state.pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: pages,
        onPageChanged: (index) {
          ref.read(indexProvider.notifier).setIndex(index, context: context);
        },
      ),
      bottomNavigationBar: AnimatedSlide(
        offset: state.hideNavigationBar ? const Offset(0, 1.6) : Offset.zero,
        duration: 320.milliseconds,
        curve: Curves.easeOutCubic,
        child: Builder(builder: (context) {
          return GlassTabBar(
            currentIndex: state.selectedIndex,
            items: [
              GlassTabItem(
                icon: CupertinoIcons.house,
                activeIcon: CupertinoIcons.house_fill,
                label: L10n.of(context).home,
              ),
              GlassTabItem(
                icon: CupertinoIcons.heart,
                activeIcon: CupertinoIcons.heart_fill,
                label: L10n.of(context).favorites,
              ),
              GlassTabItem(
                icon: CupertinoIcons.search,
                activeIcon: CupertinoIcons.search,
                label: L10n.of(context).search,
              ),
              GlassTabItem(
                icon: CupertinoIcons.clock,
                activeIcon: CupertinoIcons.clock_fill,
                label: L10n.of(context).history,
              ),
              GlassTabItem(
                icon: CupertinoIcons.ellipsis_circle,
                activeIcon: CupertinoIcons.ellipsis_circle_fill,
                label: L10n.of(context).more,
              ),
            ],
            onTap: (index) {
              HapticFeedback.selectionClick();
              ref
                  .read(indexProvider.notifier)
                  .setIndex(index, context: context, jumpToPage: true);
            },
          );
        }),
      ),
    );
  }
}

class GlassTabItem {
  const GlassTabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

/// Floating "liquid glass" tab bar in the style of iOS 26.
class GlassTabBar extends StatelessWidget {
  const GlassTabBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<GlassTabItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  static const double barHeight = 62;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final accent = Theme.of(context).colorScheme.primary;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        math.max(12.0, bottomInset - 12),
      ),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: GlassContainer(
            borderRadius: barHeight / 2,
            padding: const EdgeInsets.all(4),
            style: (palette.brightness == Brightness.dark
                    ? LiquidGlassStyle.dark
                    : LiquidGlassStyle.light)
                .copyWith(refraction: 14, bevel: 20, blur: 3),
            child: SizedBox(
              height: barHeight - 8,
              child: LayoutBuilder(builder: (context, constraints) {
                final itemWidth = constraints.maxWidth / items.length;
                return Stack(
                  children: [
                    AnimatedPositioned(
                      duration: 380.milliseconds,
                      curve: Curves.easeOutBack,
                      left: itemWidth * currentIndex,
                      top: 0,
                      bottom: 0,
                      width: itemWidth,
                      child: DecoratedBox(
                        decoration: ShapeDecoration(
                          color: palette.label.withValues(
                              alpha: palette.brightness == Brightness.dark
                                  ? 0.14
                                  : 0.07),
                          shape: const StadiumBorder(),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        for (var i = 0; i < items.length; i++)
                          Expanded(
                            child: _GlassTabButton(
                              item: items[i],
                              selected: i == currentIndex,
                              color: i == currentIndex
                                  ? accent
                                  : palette.label.withValues(alpha: 0.75),
                              onTap: () => onTap(i),
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassTabButton extends StatelessWidget {
  const _GlassTabButton({
    required this.item,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final GlassTabItem item;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      label: item.label,
      child: PressableScale(
        onTap: onTap,
        scale: 0.9,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: 200.milliseconds,
              child: Icon(
                selected ? item.activeIcon : item.icon,
                key: ValueKey(selected),
                size: 23,
                color: color,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.fade,
              softWrap: false,
              style: TextStyle(
                fontSize: 10,
                height: 1.1,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
