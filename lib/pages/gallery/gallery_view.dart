import 'dart:ui';

import 'package:auto_route/auto_route.dart';
import 'package:dio/dio.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:eros_n/common/const/const.dart';
import 'package:eros_n/common/global.dart';
import 'package:eros_n/common/provider/palette_generator.dart';
import 'package:eros_n/common/provider/settings_provider.dart';
import 'package:eros_n/component/models/index.dart';
import 'package:eros_n/component/theme/theme.dart';
import 'package:eros_n/component/widget/apple.dart';
import 'package:eros_n/component/widget/scroll_edge.dart';
import 'package:eros_n/component/widget/blur_image.dart';
import 'package:eros_n/component/widget/eros_cached_network_image.dart';
import 'package:eros_n/generated/l10n.dart';
import 'package:eros_n/network/request.dart';
import 'package:eros_n/pages/enum.dart';
import 'package:eros_n/pages/list_view/item/item_base.dart';
import 'package:eros_n/pages/user/user_provider.dart';
import 'package:eros_n/routes/routes.dart';
import 'package:eros_n/utils/get_utils/get_utils.dart';
import 'package:eros_n/utils/logger.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:native_liquid_glass/native_liquid_glass.dart';
import 'package:intl/intl.dart';
import 'package:nil/nil.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:path/path.dart' as path;
import 'package:share_plus/share_plus.dart';
import 'package:sliver_tools/sliver_tools.dart';

import 'gallery_provider.dart';
import 'thumb_page.dart';

/// Shows the extracted cover palette under the tags (debug builds only).
const bool _kShowPaletteDebug = false;

/// Height of the floating top bar (below the status bar).
const double _kTopBarHeight = 52;

/// Origin rect for the share sheet (required on iPad).
Rect? shareOriginOf(BuildContext context) {
  final box = context.findRenderObject() as RenderBox?;
  if (box == null || !box.hasSize) {
    return null;
  }
  return box.localToGlobal(Offset.zero) & box.size;
}

@RoutePage()
class GalleryPage extends StatefulHookConsumerWidget {
  const GalleryPage({
    Key? key,
    required this.gid,
    this.heroTag,
  }) : super(key: key);

  final int gid;
  final String? heroTag;

  @override
  ConsumerState<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends ConsumerState<GalleryPage> {
  ColorScheme? tintColorScheme;
  Color? _tintSeed;

  Color? getSeedColors(PaletteGenerator palette) {
    const int threshold = 30;
    if (palette.vibrantColor?.color != null &&
        (palette.vibrantColor?.population ?? 0) > threshold) {
      return palette.vibrantColor?.color;
    } else if (palette.lightVibrantColor?.color != null &&
        (palette.lightVibrantColor?.population ?? 0) > threshold) {
      return palette.lightVibrantColor?.color;
    } else {
      return palette.dominantColor?.color;
    }
  }

  @override
  Widget build(BuildContext context) {
    final useGalleryTint =
        ref.watch(settingsProvider.select((s) => s.useGalleryTint));
    final thumbUrl =
        ref.watch(galleryProvider(widget.gid).select((g) => g.thumbUrl));
    final baseTheme = Theme.of(context);
    final brightness = baseTheme.brightness;

    // Recompute the tint when switching between light and dark mode.
    if (tintColorScheme != null && tintColorScheme!.brightness != brightness) {
      _tintSeed = null;
    }

    if (useGalleryTint) {
      final paletteGenerator =
          ref.watch(paletteGeneratorProvider(thumbUrl ?? ''));
      paletteGenerator.whenData((palette) {
        final seedColor = getSeedColors(palette);
        if (seedColor == null || seedColor == _tintSeed) {
          return;
        }
        final hsvColor = HSVColor.fromColor(seedColor);
        logger.t('$seedColor, $hsvColor');
        if (hsvColor.hue < 0.1) {
          return;
        }
        _tintSeed = seedColor;
        final accent = seedColor.harmonizeWith(baseTheme.colorScheme.primary);
        // Keep the tint readable: use a vivid tone of the cover color.
        final tone = HSLColor.fromColor(accent)
            .withSaturation(
                (HSLColor.fromColor(accent).saturation).clamp(0.45, 0.9))
            .withLightness(brightness == Brightness.dark ? 0.62 : 0.45)
            .toColor();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              tintColorScheme = ThemeConfig.buildColorScheme(tone, brightness);
            });
          }
        });
      });
    }

    final ThemeData themeData =
        useGalleryTint && tintColorScheme?.brightness == brightness
            ? ThemeConfig.buildTheme(tintColorScheme!)
            : baseTheme;

    return AnimatedTheme(
      data: themeData,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      child: GalleryPageBody(gid: widget.gid, heroTag: widget.heroTag),
    );
  }
}

class GalleryPageBody extends HookConsumerWidget {
  const GalleryPageBody({
    super.key,
    required this.gid,
    this.heroTag,
  });

  final int gid;
  final String? heroTag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thumbUrl = ref.watch(galleryProvider(gid).select((g) => g.thumbUrl));
    final title = ref.watch(galleryProvider(gid).select((g) => g.title));
    final url = ref.watch(galleryProvider(gid).select((g) => g.url));
    final images = ref.watch(galleryProvider(gid).select((g) => g.images));

    final ScrollController scrollController = useScrollController();
    final ScrollController thumbScrollController = useScrollController();

    // `collapsed` = the header has scrolled under the top bar.
    final collapsed = useMemoized(() => ValueNotifier<bool>(false));
    useEffect(() {
      void listener() {
        final threshold = _GalleryHeader.height(context) -
            MediaQuery.paddingOf(context).top -
            _kTopBarHeight +
            40;
        final value =
            scrollController.hasClients && scrollController.offset > threshold;
        if (collapsed.value != value) {
          collapsed.value = value;
        }
      }

      scrollController.addListener(listener);
      return () {
        scrollController.removeListener(listener);
        collapsed.dispose();
      };
    }, [scrollController]);

    final large = context.isTablet;

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: _GalleryTopBar(
        title: title.englishTitle ?? '',
        collapsed: collapsed,
        alwaysShowTitle: false,
        onShare: (shareContext) {
          final shareText = 'title:${title.englishTitle}\n$url';
          logger.d(shareText);
          Share.share(
            shareText,
            sharePositionOrigin: shareOriginOf(shareContext),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: large
          ? null
          : ValueListenableBuilder<bool>(
              valueListenable: collapsed,
              builder: (context, isCollapsed, child) {
                return IgnorePointer(
                  ignoring: !isCollapsed,
                  child: AnimatedSlide(
                    offset: isCollapsed ? Offset.zero : const Offset(0, 1.5),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    child: AnimatedOpacity(
                      opacity: isCollapsed ? 1 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: child,
                    ),
                  ),
                );
              },
              child: GalleryReadButton(gid: gid, floating: true),
            ),
      body: LayoutBuilder(builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;

        const kMinWidget = 386.0;

        final width =
            maxWidth / 2 - kMinWidget > 50 ? kMinWidget : maxWidth / 2;

        return Row(
          children: [
            AnimatedContainer(
              width: large ? width : maxWidth,
              duration: const Duration(milliseconds: 400),
              child: GalleryDetailBody(
                gid: gid,
                scrollController: scrollController,
                title: title,
                heroTag: heroTag,
                thumbUrl: thumbUrl,
                images: images,
                backGround: _BackGround(thumbUrl: thumbUrl),
                large: large,
              ),
            ),
            if (large)
              Expanded(
                child: Stack(
                  children: [
                    SizedBox(
                      height: _GalleryHeader.height(context),
                      child: _BackGround(thumbUrl: thumbUrl),
                    ),
                    SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.only(top: _kTopBarHeight),
                        child: ThumbBody(
                          gid: gid,
                          scrollController: thumbScrollController,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      }),
    );
  }
}

/// Transparent top bar with glass buttons; frosts and shows the title once
/// the header scrolls away (iOS 26 style).
class _GalleryTopBar extends StatelessWidget implements PreferredSizeWidget {
  const _GalleryTopBar({
    required this.title,
    required this.collapsed,
    required this.onShare,
    this.alwaysShowTitle = false,
  });

  final String title;
  final ValueListenable<bool> collapsed;
  final void Function(BuildContext context) onShare;
  final bool alwaysShowTitle;

  @override
  Size get preferredSize => const Size.fromHeight(_kTopBarHeight);

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return ValueListenableBuilder<bool>(
      valueListenable: collapsed,
      builder: (context, isCollapsed, _) {
        final dark = Theme.of(context).brightness == Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
          child: SizedBox(
            height: topInset + _kTopBarHeight,
            child: Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.none,
              children: [
                // iOS 26 soft scroll edge: blur and fade the content under
                // the bar progressively, reaching a little past it.
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: topInset + _kTopBarHeight + 6,
                  child: IgnorePointer(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(end: isCollapsed ? 1 : 0),
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      builder: (context, value, _) => ScrollEdgeEffect(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        visibility: value,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(
                    top: topInset,
                    left: MediaQuery.paddingOf(context).left + 12,
                    right: MediaQuery.paddingOf(context).right + 12,
                  ),
                  child: Row(
                    children: [
                      GlassIconButton(
                        icon: CupertinoIcons.chevron_back,
                        sfSymbol: 'chevron.backward',
                        tooltip:
                            MaterialLocalizations.of(context).backButtonTooltip,
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                      Expanded(
                        child: AnimatedOpacity(
                          opacity: isCollapsed || alwaysShowTitle ? 1 : 0,
                          duration: const Duration(milliseconds: 220),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        ),
                      ),
                      Builder(builder: (context) {
                        return GlassIconButton(
                          icon: CupertinoIcons.share,
                          sfSymbol: 'square.and.arrow.up',
                          tooltip: L10n.of(context).share,
                          onPressed: () => onShare(context),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BackGround extends StatelessWidget {
  const _BackGround({
    required this.thumbUrl,
  });

  final String? thumbUrl;

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).scaffoldBackgroundColor;
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRect(
          child: BlurImage(
            sigma: 36,
            color: bg.withValues(alpha: 0.35),
            child: thumbUrl != null
                ? ErosCachedNetworkImage(
                    imageUrl: thumbUrl!,
                    filterQuality: FilterQuality.low,
                    fit: BoxFit.cover,
                  )
                : const SizedBox(),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.55, 1.0],
              colors: [
                bg.withValues(alpha: 0.0),
                bg.withValues(alpha: 0.35),
                bg,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class GalleryDetailBody extends HookConsumerWidget {
  const GalleryDetailBody({
    super.key,
    required this.gid,
    required this.scrollController,
    required this.title,
    required this.heroTag,
    required this.thumbUrl,
    required this.images,
    this.backGround,
    this.large = false,
  });

  final int gid;
  final ScrollController scrollController;
  final GalleryTitle title;
  final String? heroTag;
  final String? thumbUrl;
  final GalleryImages images;
  final Widget? backGround;
  final bool large;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScrollView(
      physics: kAppleScrollPhysics,
      controller: scrollController,
      slivers: [
        SliverToBoxAdapter(
          child: _GalleryHeader(
            gid: gid,
            title: title,
            heroTag: heroTag,
            thumbUrl: thumbUrl,
            images: images,
            backGround: backGround,
          ),
        ),
        CupertinoSliverRefreshControl(
          onRefresh: ref.read(galleryProvider(gid).notifier).reloadData,
        ),
        DetailView(
          gid: gid,
          showThumbs: !large,
        ),
      ],
    );
  }
}

class _GalleryHeader extends StatelessWidget {
  const _GalleryHeader({
    required this.gid,
    required this.title,
    required this.heroTag,
    required this.thumbUrl,
    required this.images,
    this.backGround,
  });

  final int gid;
  final GalleryTitle title;
  final String? heroTag;
  final String? thumbUrl;
  final GalleryImages images;
  final Widget? backGround;

  static const double _coverWidth = 132;

  static double height(BuildContext context) =>
      MediaQuery.paddingOf(context).top + _kTopBarHeight + 246;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = MediaQuery.paddingOf(context);
    final aspectRatio = (images.thumbnail.imgWidth ?? 300) /
        (images.thumbnail.imgHeight ?? 400);
    final coverHeight = (_coverWidth / aspectRatio).clamp(120.0, 200.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: height(context),
          child: Stack(
            fit: StackFit.expand,
            children: [
              backGround ?? const SizedBox(),
              Padding(
                padding: EdgeInsets.only(
                  left: padding.left + 20,
                  right: padding.right + 20,
                  top: padding.top + _kTopBarHeight + 8,
                  bottom: 4,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SizedBox(
                      width: _coverWidth,
                      height: coverHeight,
                      child: Hero(
                        tag: '${heroTag ?? ''}_$thumbUrl',
                        child: CoverArtwork(
                          radius: 12,
                          child: thumbUrl == null
                              ? nil
                              : ErosCachedNetworkImage(
                                  imageUrl: thumbUrl!,
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Flexible(
                            child: SelectableText(
                              title.englishTitle ?? '',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                              maxLines: 5,
                              minLines: 1,
                            ),
                          ),
                          HeadInfoView(gid: gid, context: context),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.only(
            left: padding.left + 20,
            right: padding.right + 20,
            top: 16,
          ),
          child: ToolBarView(gid: gid),
        ),
        _StatsRow(gid: gid),
      ],
    );
  }
}

/// Japanese title and artists beneath the main title.
class HeadInfoView extends StatelessWidget {
  const HeadInfoView({
    super.key,
    required this.gid,
    required this.context,
  });

  final int gid;
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Consumer(
          builder: (context, ref, child) {
            final japaneseTitle =
                ref.watch(galleryProvider(gid)).title.japaneseTitle;
            if (japaneseTitle == null || japaneseTitle.isEmpty) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: SelectableText(
                japaneseTitle,
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.start,
                minLines: 1,
                maxLines: 2,
              ),
            );
          },
        ),
        Consumer(builder: (context, ref, child) {
          final isTagTranslate = ref
              .watch(settingsProvider.select((value) => value.isTagTranslate));

          final artistTags = ref
              .watch(galleryProvider(gid))
              .tags
              .where((e) => e.type == 'Artists')
              .toList();

          if (artistTags.isEmpty) {
            return const SizedBox.shrink();
          }

          final textStyle = theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          );

          final children = <Widget>[];
          for (var i = 0; i < artistTags.length; i++) {
            final tag = artistTags[i];
            children.add(GestureDetector(
              onTap: () => RouteUtil.goSearch(tag: tag),
              child: Text(
                isTagTranslate
                    ? tag.translatedName ?? tag.name ?? ''
                    : tag.name ?? '',
                style: textStyle,
              ),
            ));
            if (i != artistTags.length - 1) {
              children.add(Text(', ', style: textStyle));
            }
          }

          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(children: children),
          );
        }),
      ],
    );
  }
}

/// App Store style metadata strip (pages · favorites · date · id).
class _StatsRow extends HookConsumerWidget {
  const _StatsRow({required this.gid});

  final int gid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final theme = Theme.of(context);
    final pages =
        ref.watch(galleryProvider(gid).select((g) => g.images.pages.length));
    final numFavorites =
        ref.watch(galleryProvider(gid).select((g) => g.numFavorites));
    final uploadedDate =
        ref.watch(galleryProvider(gid).select((g) => g.uploadedDate));

    Widget item(String label, String value, {IconData? icon}) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 15, color: palette.secondaryLabel),
                  const SizedBox(width: 3),
                ],
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: palette.secondaryLabel,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    Widget separator() =>
        Container(width: 0.5, height: 30, color: palette.separator);

    final items = <Widget>[
      item(L10n.of(context).pages, pages > 0 ? '$pages' : '··'),
      separator(),
      item(
        L10n.of(context).favorites,
        numFavorites == null
            ? '··'
            : NumberFormat.compact().format(numFavorites),
        icon: CupertinoIcons.heart_fill,
      ),
      separator(),
      item(
        L10n.of(context).uploaded,
        uploadedDate != null
            ? DateFormat('yyyy-MM-dd').format(uploadedDate)
            : '··',
      ),
      separator(),
      item('ID', '#$gid'),
    ];

    return Column(
      children: [
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Divider(color: palette.separator),
        ),
        SizedBox(
          height: 66,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            children:
                items.map((e) => Center(child: e)).toList(growable: false),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Divider(color: palette.separator),
        ),
      ],
    );
  }
}

class DetailView extends HookConsumerWidget {
  const DetailView({
    Key? key,
    required this.gid,
    this.showThumbs = true,
  }) : super(key: key);

  final int gid;
  final bool showThumbs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageStatus =
        ref.watch(pageStateProvider(gid).select((state) => state.pageStatus));
    logger.t('DetailView build $pageStatus');
    if (pageStatus == PageStatus.loading) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: 80),
          child: AppleLoading(),
        ),
      );
    } else {
      return SliverSafeArea(
        top: false,
        bottom: false,
        sliver: MultiSliver(children: [
          const SizedBox(height: 8),
          TagsView(gid: gid),
          if (kDebugMode && _kShowPaletteDebug)
            PaletteGeneratorWidget(gid: gid),
          if (showThumbs) ThumbListView(gid: gid),
          MoreLikeListView(gid: gid),
          CommentsListView(gid: gid),
          SizedBox(height: 120 + MediaQuery.paddingOf(context).bottom),
        ]),
      );
    }
  }
}

class PaletteGeneratorWidget extends HookConsumerWidget {
  const PaletteGeneratorWidget({
    Key? key,
    required this.gid,
  }) : super(key: key);
  final int gid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thumbUrl = ref.watch(galleryProvider(gid).select((g) => g.thumbUrl));
    final paletteGenerator =
        ref.watch(paletteGeneratorProvider(thumbUrl ?? ''));
    return MultiSliver(children: [
      ListTile(
        title: const Text('PaletteGenerator (debug)'),
        subtitle: SizedBox(
          height: 100,
          child: paletteGenerator.when(
              data: (pg) => Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Expanded(
                              child: Container(
                                color: pg.dominantColor?.color,
                              ),
                            ),
                            Text(
                              'dm',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              '${pg.dominantColor?.population}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      // vibrantColor
                      Expanded(
                        child: Column(
                          children: [
                            Expanded(
                              child: Container(
                                color: pg.vibrantColor?.color,
                              ),
                            ),
                            Text(
                              'vibrant',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              '${pg.vibrantColor?.population}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      // lightVibrantColor
                      Expanded(
                        child: Column(
                          children: [
                            Expanded(
                              child: Container(
                                color: pg.lightVibrantColor?.color,
                              ),
                            ),
                            Text(
                              'lightV',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              '${pg.lightVibrantColor?.population}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      // darkVibrantColor
                      Expanded(
                        child: Column(
                          children: [
                            Expanded(
                              child: Container(
                                color: pg.darkVibrantColor?.color,
                              ),
                            ),
                            Text(
                              'darkV',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              '${pg.darkVibrantColor?.population}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      // mutedColor
                      Expanded(
                        child: Column(
                          children: [
                            Expanded(
                              child: Container(
                                color: pg.mutedColor?.color,
                              ),
                            ),
                            Text(
                              'muted',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              '${pg.mutedColor?.population}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      // lightMutedColor
                      Expanded(
                        child: Column(
                          children: [
                            Expanded(
                              child: Container(
                                color: pg.lightMutedColor?.color,
                              ),
                            ),
                            Text(
                              'lightM',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              '${pg.lightMutedColor?.population}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      // darkMutedColor
                      Expanded(
                        child: Column(
                          children: [
                            Expanded(
                              child: Container(
                                color: pg.darkMutedColor?.color,
                              ),
                            ),
                            Text(
                              'darkM',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              '${pg.darkMutedColor?.population}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
              error: (_, __) => nil,
              loading: () => nil),
        ),
      ),
    ]);
  }
}

String _getTagTypeTranslate(BuildContext context, String tagType) {
  switch (tagType) {
    case 'Parodies':
      return L10n.of(context).tag_type_parodies;
    case 'Characters':
      return L10n.of(context).tag_type_characters;
    case 'Tags':
      return L10n.of(context).tag_type_tags;
    case 'Artists':
      return L10n.of(context).tag_type_artists;
    case 'Groups':
      return L10n.of(context).tag_type_groups;
    case 'Languages':
      return L10n.of(context).tag_type_languages;
    case 'Categories':
      return L10n.of(context).tag_type_categories;
    default:
      return tagType;
  }
}

class TagsView extends HookConsumerWidget {
  const TagsView({
    Key? key,
    required this.gid,
  }) : super(key: key);

  final int gid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tags = ref.watch(galleryProvider(gid)).tags;
    final isTagTranslate =
        ref.watch(settingsProvider.select((value) => value.isTagTranslate));
    final theme = Theme.of(context);

    // tags group by type
    final tagsGroupByType = <String, List<Tag>>{};
    for (final tag in tags) {
      if (tag.type == 'Artists' || tag.type == null) {
        continue;
      }
      tagsGroupByType.putIfAbsent(tag.type!, () => <Tag>[]).add(tag);
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: MultiSliver(
        children: tagsGroupByType.entries.map((entry) {
          final type = entry.key;
          final tags = entry.value;
          return Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getTagTypeTranslate(context, type),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tags.map((Tag tag) {
                    return AppleTagChip(
                      label: isTagTranslate
                          ? tag.translatedName ?? tag.name ?? ''
                          : tag.name ?? '',
                      onTap: () {
                        RouteUtil.goSearch(tag: tag);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Primary "Read / Resume" capsule.
class GalleryReadButton extends HookConsumerWidget {
  const GalleryReadButton({required this.gid, this.floating = false});

  final int gid;
  final bool floating;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPageIndex =
        ref.watch(galleryProvider(gid).select((g) => g.currentPageIndex));
    final label = currentPageIndex == 0
        ? L10n.of(context).read
        : '${L10n.of(context).resume} · ${currentPageIndex + 1}';

    final button = CapsuleButton(
      label: label,
      icon: currentPageIndex == 0
          ? CupertinoIcons.book_fill
          : CupertinoIcons.play_fill,
      height: floating ? 50 : 46,
      expand: !floating,
      onPressed: () {
        HapticFeedback.lightImpact();
        RouteUtil.goRead(context, ref);
      },
    );

    if (!floating) {
      return button;
    }
    if (useNativeLiquidGlass) {
      // Floating over content: Apple's prominent (tinted) glass button.
      return SizedBox(
        height: 50,
        child: LiquidGlassButton(
          label: label,
          icon: NativeLiquidGlassIcon.sfSymbol(
              currentPageIndex == 0 ? 'book.fill' : 'play.fill'),
          style: LiquidGlassButtonStyle.prominentGlass,
          tint: Theme.of(context).colorScheme.primary,
          height: 50,
          shrinkWrap: true,
          onPressed: () {
            HapticFeedback.lightImpact();
            RouteUtil.goRead(context, ref);
          },
        ),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: button,
      ),
    );
  }
}

/// Circular tinted action (favorite / torrent).
class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.icon,
    required this.label,
    this.onPressed,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = context.palette;
    return Tooltip(
      message: label,
      child: PressableScale(
        onTap: onPressed,
        scale: 0.9,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? scheme.primary : palette.tertiaryFill,
          ),
          child: Icon(
            icon,
            size: 21,
            color: active ? scheme.onPrimary : scheme.primary,
          ),
        ),
      ),
    );
  }
}

class ToolBarView extends HookConsumerWidget {
  const ToolBarView({Key? key, required this.gid}) : super(key: key);

  final int gid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gallery = ref.watch(galleryProvider(gid));
    final isUserLogin = ref.watch(userProvider.select((user) => user.isLogin));
    final isFavorited = gallery.isFavorited ?? false;
    final downloading = useState(false);

    return Row(
      children: [
        Expanded(child: GalleryReadButton(gid: gid)),
        const SizedBox(width: 12),
        _CircleAction(
          icon: isFavorited ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
          label: isFavorited
              ? L10n.of(context).favorited
              : L10n.of(context).favorite,
          active: isFavorited,
          onPressed: isUserLogin
              ? () {
                  HapticFeedback.mediumImpact();
                  ref.read(galleryProvider(gid).notifier).toggleFavorite();
                }
              : null,
        ),
        const SizedBox(width: 12),
        Builder(builder: (buttonContext) {
          return _CircleAction(
            icon: downloading.value
                ? CupertinoIcons.hourglass
                : CupertinoIcons.arrow_down_doc,
            label: L10n.of(context).torrent,
            onPressed: isUserLogin && !downloading.value
                ? () async {
                    late String savePath;
                    final origin = shareOriginOf(buttonContext);
                    downloading.value = true;
                    try {
                      await nhDownload(
                          url: '/g/${gallery.gid}/download',
                          savePath: (Headers headers) {
                            logger.d(headers);
                            final contentDisposition =
                                headers.value('content-disposition');
                            final filename = contentDisposition
                                    ?.split(RegExp(r"filename(=|\*=UTF-8'')"))
                                    .last ??
                                '';
                            final fileNameDecode =
                                Uri.decodeFull(filename).replaceAll('/', '_');
                            logger.d(fileNameDecode);
                            savePath = path.joinAll([
                              Global.tempPath,
                              'torrent',
                              '${gallery.gid}',
                              fileNameDecode
                            ]);
                            return savePath;
                          });
                    } finally {
                      downloading.value = false;
                    }
                    await Share.shareXFiles(
                      [XFile(savePath)],
                      sharePositionOrigin: origin,
                    );
                  }
                : null,
          );
        }),
      ],
    );
  }
}

class ThumbListView extends HookConsumerWidget {
  const ThumbListView({
    Key? key,
    required this.gid,
  }) : super(key: key);

  final int gid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    logger.t('ThumbListView build');
    final pages = ref
        .watch(galleryProvider(gid).select((gallery) => gallery.images.pages));
    final mediaId =
        ref.watch(galleryProvider(gid).select((gallery) => gallery.mediaId));
    if (pages.isEmpty) {
      return const SizedBox.shrink();
    }
    return MultiSliver(
      children: [
        AppleSectionHeader(
          title: L10n.of(context).thumbs,
          actionLabel: L10n.of(context).see_all,
          onAction: () {
            erosRouter.push(ThumbRoute(
              gid: gid,
              colorScheme: Theme.of(context).colorScheme,
            ));
          },
        ),
        SizedBox(
          height: 186,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: pages.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final GalleryImage image = pages[index];
              return PressableScale(
                onTap: () async {
                  RouteUtil.goRead(context, ref, index: index);
                },
                child: Column(
                  children: [
                    Expanded(
                      child: AspectRatio(
                        aspectRatio:
                            (image.imgWidth ?? 300) / (image.imgHeight ?? 400),
                        child: CoverArtwork(
                          radius: 8,
                          shadow: false,
                          child: Hero(
                            tag: '${gid}_$index',
                            child: mediaId == null
                                ? nil
                                : ErosCachedNetworkImage(
                                    imageUrl: image.href ??
                                        'https://t.nhentai.net/galleries/$mediaId/${index + 1}t.${NHConst.extMap[image.type]}',
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${index + 1}',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class MoreLikeListView extends HookConsumerWidget {
  const MoreLikeListView({
    Key? key,
    required this.gid,
  }) : super(key: key);

  final int gid;

  static const double _coverWidth = 120;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moreLikeGallerys = ref.watch(galleryProvider(gid)).moreLikeGallerys;
    final heroTag = useMemoized(() => 'more_like_$gid');
    final theme = Theme.of(context);
    if (moreLikeGallerys.isEmpty) {
      return const SizedBox.shrink();
    }
    return MultiSliver(
      children: [
        AppleSectionHeader(title: L10n.of(context).more_like_this),
        SizedBox(
          height: _coverWidth * 4 / 3 + 52,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: moreLikeGallerys.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final likeGallery = moreLikeGallerys[index];
              return PressableScale(
                onTap: () {
                  RouteUtil.goGallery(ref, likeGallery, heroTag: heroTag);
                },
                child: SizedBox(
                  width: _coverWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: _coverWidth,
                        height: _coverWidth * 4 / 3,
                        child: Hero(
                          tag: '${heroTag}_${likeGallery.thumbUrl}',
                          child: CoverArtwork(
                            languageCode: likeGallery.languageCode,
                            child: ErosCachedNetworkImage(
                              imageUrl: likeGallery.thumbUrl ?? '',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        likeGallery.title.englishTitle ?? '',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                          height: 1.25,
                        ),
                        textAlign: TextAlign.start,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class CommentsListView extends HookConsumerWidget {
  const CommentsListView({
    Key? key,
    required this.gid,
  }) : super(key: key);

  final int gid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comments = ref.watch(galleryProvider(gid)).comments;
    final palette = context.palette;
    final theme = Theme.of(context);

    void openComments() {
      erosRouter.push(CommentsRoute(
        gid: gid,
        colorScheme: Theme.of(context).colorScheme,
      ));
    }

    return MultiSliver(
      children: [
        AppleSectionHeader(
          title: L10n.of(context).comments,
          actionLabel: comments.isEmpty
              ? null
              : '${L10n.of(context).see_all} (${comments.length})',
          onAction: openComments,
        ),
        if (comments.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: PressableScale(
              onTap: openComments,
              child: Container(
                height: 64,
                alignment: Alignment.center,
                decoration: ShapeDecoration(
                  color: palette.secondaryBackground,
                  shape: const RoundedSuperellipseBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                ),
                child: Text(
                  L10n.of(context).write_comment,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: palette.secondaryLabel),
                ),
              ),
            ),
          )
        else
          SizedBox(
            height: 168,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: comments.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final Comment comment = comments[index];
                final date = DateTime.fromMillisecondsSinceEpoch(
                    (comment.postDate ?? 0) * 1000);
                final dateFormatted =
                    DateFormat('yyyy-MM-dd HH:mm').format(date.toLocal());
                return PressableScale(
                  scale: 0.98,
                  onTap: openComments,
                  child: Container(
                    width: 290,
                    padding: const EdgeInsets.all(14),
                    decoration: ShapeDecoration(
                      color: palette.secondaryBackground,
                      shape: const RoundedSuperellipseBorder(
                        borderRadius: BorderRadius.all(Radius.circular(18)),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CommentAvatar(
                              avatarUrl: comment.poster?.avatarUrl,
                              size: 34,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    comment.poster?.username ?? '',
                                    style: theme.textTheme.titleSmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    dateFormatted,
                                    style: theme.textTheme.labelMedium,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: Text(
                            comment.commentText ?? '',
                            style: theme.textTheme.bodyMedium,
                            softWrap: true,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

/// Round avatar for comment posters.
class CommentAvatar extends StatelessWidget {
  const CommentAvatar({super.key, required this.avatarUrl, this.size = 40});

  final String? avatarUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      color: CupertinoColors.systemGrey3.resolveFrom(context),
      child: Icon(
        CupertinoIcons.person_fill,
        size: size * 0.6,
        color: Colors.white,
      ),
    );
    return ClipOval(
      child: SizedBox(
        height: size,
        width: size,
        child: (avatarUrl ?? '').isEmpty
            ? placeholder
            : ErosCachedNetworkImage(
                imageUrl: 'https://i.${NHConst.baseHost}/$avatarUrl',
                fit: BoxFit.cover,
                placeholder: (_, __) => placeholder,
                errorWidget: (_, __, ___) => placeholder,
              ),
      ),
    );
  }
}
