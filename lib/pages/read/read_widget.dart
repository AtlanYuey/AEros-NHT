import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:auto_route/auto_route.dart';
import 'package:eros_n/common/enum.dart';
import 'package:eros_n/common/provider/settings_provider.dart';
import 'package:eros_n/generated/l10n.dart';
import 'package:eros_n/pages/gallery/gallery_provider.dart';
import 'package:eros_n/pages/read/read_provider.dart';
import 'package:eros_n/utils/get_utils/get_utils.dart';
import 'package:eros_n/utils/logger.dart';
import 'package:eros_n/component/widget/apple.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../setting/read_setting_page.dart';
import 'read_view.dart';

/// Dark frosted chrome used by the reader bars (like Photos).
class _ReaderChrome extends StatelessWidget {
  const _ReaderChrome({required this.child, this.top = true});

  final Widget child;
  final bool top;

  @override
  Widget build(BuildContext context) {
    final side =
        BorderSide(color: Colors.white.withValues(alpha: 0.12), width: 0.5);
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E).withValues(alpha: 0.72),
            border: top ? Border(bottom: side) : Border(top: side),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _ReaderIconButton extends StatelessWidget {
  const _ReaderIconButton({
    required this.icon,
    this.onPressed,
    this.tooltip,
  });

  final Widget icon;
  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    Widget button = CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: const Size(44, 44),
      onPressed: onPressed,
      child: IconTheme.merge(
        data: const IconThemeData(color: Colors.white, size: 24),
        child: icon,
      ),
    );
    if (tooltip != null) {
      button = Tooltip(message: tooltip, child: button);
    }
    return button;
  }
}

class ViewTopBar extends HookConsumerWidget {
  const ViewTopBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: context.mediaQueryPadding.top + kTopBarHeight,
      width: context.mediaQuery.size.width,
      child: _ReaderChrome(
        child: Padding(
          padding: EdgeInsets.only(
            left: context.mediaQueryPadding.left + 4,
            right: context.mediaQueryPadding.right + 4,
            top: context.mediaQueryPadding.top,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _ReaderIconButton(
                    onPressed: () {
                      context.router.maybePop();
                    },
                    tooltip:
                        MaterialLocalizations.of(context).backButtonTooltip,
                    icon: const Icon(CupertinoIcons.chevron_back),
                  ),
                  if (context.isTablet)
                    const ControllerButtonBar(
                      mainAxisSize: MainAxisSize.min,
                    ),
                ],
              ),
              Consumer(builder: (context, ref, child) {
                final gid = currentGalleryGid;
                final currentItemIndex = ref.watch(
                    galleryProvider(gid).select((val) => val.currentPageIndex));
                final totalItem = ref.watch(galleryProvider(gid)
                    .select((val) => val.images.pages.length));
                return Container(
                  alignment: Alignment.center,
                  height: kTopBarButtonHeight,
                  child: Text(
                    '${currentItemIndex + 1} / $totalItem',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.41,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class ViewBottomBar extends HookConsumerWidget {
  const ViewBottomBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottomBarHeight =
        ref.watch(readProvider.select((val) => val.bottomBarHeight));
    final showThumbList =
        ref.watch(readProvider.select((val) => val.showThumbList));

    return AnimatedContainer(
      height: bottomBarHeight,
      width: context.mediaQuery.size.width,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      child: _ReaderChrome(
        top: false,
        child: Column(
          children: [
            // 缩略图栏
            AnimatedContainer(
              height: showThumbList ? kThumbListViewHeight : 0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              child: const ThumbnailListView(),
            ),
            // 控制栏
            const BottomBarControlWidget(),
          ],
        ),
      ),
    );
  }
}

class BottomBarControlWidget extends HookConsumerWidget {
  const BottomBarControlWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gid = currentGalleryGid;
    final currentItemIndex =
        ref.watch(galleryProvider(gid).select((val) => val.currentPageIndex));
    final totNum = ref
        .watch(galleryProvider(gid).select((val) => val.images.pages.length));
    final readModel = ref.watch(settingsProvider.select((s) => s.readModel));
    final readNotifier = ref.read(readProvider.notifier);

    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: context.mediaQueryPadding.horizontal / 2 + 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 滑动控件
          Container(
            height: kSliderBarHeight,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ViewPageSlider(
              key: ValueKey('ViewPageSlider_$currentItemIndex'),
              max: math.max(0, totNum - 1.0),
              initValue: math.max(
                  0, math.min(currentItemIndex.roundToDouble(), totNum - 1.0)),
              reverse: readModel == ReadModel.rightToLeft,
              onChangedEnd: (val) {
                logger.d('onChangedEnd ${val + 1}');
                readNotifier.jumpToPage(val.round());
              },
              onChanged: (_) {},
            ),
          ),
          // 按钮栏
          if (!context.isTablet)
            const ControllerButtonBar(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              mainAxisSize: MainAxisSize.max,
            ),
        ],
      ),
    );
  }
}

/// 页面滑条
class ViewPageSlider extends StatefulWidget {
  const ViewPageSlider({
    Key? key,
    required this.max,
    required this.initValue,
    required this.onChangedEnd,
    required this.onChanged,
    this.reverse = false,
  }) : super(key: key);

  final double max;
  final double initValue;
  final ValueChanged<double> onChangedEnd;
  final ValueChanged<double> onChanged;
  final bool reverse;

  @override
  State<ViewPageSlider> createState() => _ViewPageSliderState();
}

class _ViewPageSliderState extends State<ViewPageSlider> {
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initValue;
  }

  @override
  Widget build(BuildContext context) {
    const labelStyle = TextStyle(
      color: Colors.white,
      fontSize: 15,
      fontWeight: FontWeight.w500,
      fontFeatures: [FontFeature.tabularFigures()],
    );
    final minText = Text('${_value.round() + 1}', style: labelStyle);

    final maxText = Text(
      '${widget.max.round() + 1}',
      style: labelStyle.copyWith(color: Colors.white.withValues(alpha: 0.6)),
    );

    return Row(
      children: <Widget>[
        Container(
          constraints: const BoxConstraints(minWidth: 36),
          alignment: Alignment.center,
          child: widget.reverse ? maxText : minText,
        ),
        Expanded(
          child: Transform.flip(
            flipX: widget.reverse,
            child: CupertinoSlider(
              min: 0,
              max: widget.max > 0 ? widget.max : 1,
              value: _value.clamp(0, widget.max > 0 ? widget.max : 1),
              divisions: widget.max > 0 ? widget.max.round() : null,
              activeColor: Colors.white,
              thumbColor: Colors.white,
              onChanged: widget.max > 0
                  ? (double newValue) {
                      if (newValue.round() != _value.round()) {
                        HapticFeedback.selectionClick();
                      }
                      setState(() {
                        _value = newValue;
                      });
                      widget.onChanged(newValue);
                    }
                  : null,
              onChangeEnd: (double newValue) {
                widget.onChangedEnd(newValue);
              },
            ),
          ),
        ),
        Container(
          constraints: const BoxConstraints(minWidth: 36),
          alignment: Alignment.center,
          child: widget.reverse ? minText : maxText,
        ),
      ],
    );
  }
}

// 阅读控制按钮栏
class ControllerButtonBar extends HookConsumerWidget {
  const ControllerButtonBar({
    Key? key,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.max,
    this.showLabel = true,
  }) : super(key: key);

  final MainAxisAlignment mainAxisAlignment;
  final MainAxisSize mainAxisSize;
  final bool showLabel;

  static const buttonWidth = 44.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: mainAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: [
        const ReadModelButton(),
        const AutoReadButton(),
        _ReaderIconButton(
          tooltip: L10n.of(context).settings,
          onPressed: () async {
            // now auto read
            final nowAutoRead =
                ref.read(readProvider.select((s) => s.autoRead));

            // stop auto read
            if (nowAutoRead) {
              ref.read(readProvider.notifier).stopAutoRead();
            }

            await showAppleSheet<void>(
              context: context,
              builder: (context) => const ReadSettings(),
            );

            // restart auto read
            if (nowAutoRead) {
              ref.read(readProvider.notifier).startAutoRead();
            }
          },
          icon: const Icon(CupertinoIcons.slider_horizontal_3),
        ),
      ],
    );
  }
}

class AutoReadButton extends HookConsumerWidget {
  const AutoReadButton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final autoRead = ref.watch(readProvider.select((r) => r.autoRead));
    return _ReaderIconButton(
      tooltip: L10n.of(context).auto_read_interval,
      onPressed: () {
        HapticFeedback.lightImpact();
        ref.read(readProvider.notifier).toggleAutoRead();
      },
      icon: autoRead
          ? const Icon(CupertinoIcons.pause_circle_fill)
          : const Icon(CupertinoIcons.play_circle),
    );
  }
}

// 阅读模式按钮
class ReadModelButton extends HookConsumerWidget {
  const ReadModelButton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readModel =
        ref.watch(settingsProvider.select((setting) => setting.readModel));

    final readModelIconMap = <ReadModel, Widget>{
      ReadModel.leftToRight: const Icon(CupertinoIcons.arrow_right_square),
      ReadModel.rightToLeft: const Icon(CupertinoIcons.arrow_left_square),
      ReadModel.webtoon: const Icon(CupertinoIcons.rectangle_stack),
      ReadModel.vertical: const Icon(CupertinoIcons.arrow_down_square),
      ReadModel.curlVertical:
          const Icon(CupertinoIcons.square_stack_3d_down_right),
    };

    return _ReaderIconButton(
      tooltip: L10n.of(context).read_model,
      icon: readModelIconMap[readModel]!,
      onPressed: () async {
        final result = await showAppleOptionsSheet<ReadModel>(
          context: context,
          title: L10n.of(context).read_model,
          options: readModelOptions(context),
          selected: readModel,
        );
        if (result != null) {
          ref.read(settingsProvider.notifier).setReadModel(result);
        }
      },
    );
  }
}

// 阅读设置
class ReadSettings extends HookConsumerWidget {
  const ReadSettings({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppleSheet(
      title: L10n.of(context).read,
      child: AppleSection(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        header: null,
        children: [
          const FullScreenListTile(onReadView: true),
          if (Platform.isAndroid)
            const VolumeKeyTurnPageListTile(onReadView: true),
          const AutoReadIntervalListTile(),
          const PreloadPagesCountListTile(),
        ],
      ),
    );
  }
}

class ThumbnailListView extends HookConsumerWidget {
  const ThumbnailListView({Key? key}) : super(key: key);

  static const kBorderWidth = 2.0;
  static const kRadius = 4.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const SizedBox(height: kThumbListViewHeight);
  }
}

class ReadScaffold extends HookConsumerWidget {
  const ReadScaffold({
    Key? key,
    required this.child,
    required this.topBar,
    required this.bottomBar,
  }) : super(key: key);

  final Widget child;
  final Widget topBar;
  final Widget bottomBar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ref.read(readProvider.notifier).init(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(readProvider.notifier).resetBottomBarHeight(context);
    });
    return Stack(
      children: [
        child,
        Consumer(builder: (context, ref, child) {
          final topBarOffset =
              ref.watch(readProvider.select((state) => state.topBarOffset));
          final bottomBarOffset =
              ref.watch(readProvider.select((state) => state.bottomBarOffset));
          logger.v(
              'topBarOffset: $topBarOffset bottomBarOffset: $bottomBarOffset');

          return Stack(
            children: [
              AnimatedPositioned(
                curve: Curves.fastOutSlowIn,
                duration: const Duration(milliseconds: 300),
                top: topBarOffset,
                child: topBar,
              ),
              AnimatedPositioned(
                curve: Curves.fastOutSlowIn,
                duration: const Duration(milliseconds: 300),
                bottom: bottomBarOffset,
                child: bottomBar,
              ),
            ],
          );
        }),
      ],
    );
  }
}

/// 控制触摸手势事件
class ImageGestureDetector extends HookConsumerWidget {
  const ImageGestureDetector({
    Key? key,
    required this.child,
  }) : super(key: key);
  final Widget child;

  static const lrRatio = 1 / 3;
  static const tbRatio = 1 / 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readNoti = ref.read(readProvider.notifier);
    return GestureDetector(
      behavior: HitTestBehavior.deferToChild,
      onTapUp: (details) {
        // logger.d('${details.globalPosition} ${details.localPosition}');

        final globalPosition = details.globalPosition;
        if (globalPosition.dx < context.width * (1 - lrRatio) &&
            globalPosition.dx > context.width * lrRatio) {
          if (globalPosition.dy < context.height * tbRatio) {
            readNoti.toPrev();
          } else if (globalPosition.dy > context.height * (1 - tbRatio)) {
            readNoti.toNext();
          } else {
            readNoti.handOnTapCenter(context);
          }
        }

        if (globalPosition.dx < context.width * lrRatio) {
          readNoti.tapLeft();
        }

        if (globalPosition.dx > context.width * (1 - lrRatio)) {
          readNoti.tapRight();
        }
      },
      child: child,
    );
  }
}
