import 'package:eros_n/component/theme/theme.dart';
import 'package:eros_n/component/widget/apple_controls.dart';
import 'package:eros_n/component/widget/apple_menu.dart';
import 'package:eros_n/component/widget/liquid_glass.dart';
import 'package:eros_n/component/widget/scroll_edge.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:native_liquid_glass/native_liquid_glass.dart';

export 'apple_controls.dart';
export 'apple_menu.dart' show showAppleMenu, globalRectOf, glassPanelStyle;
export 'liquid_glass.dart' show LiquidGlassStyle;

/// A small kit of widgets that follow Apple's Human Interface Guidelines.
///
/// Everything here is built on top of the Material/Cupertino primitives
/// already used by the app so pages can adopt the iOS look incrementally.

const kAppleScrollPhysics =
    BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());

/// Apple "Liquid Glass" surface.
///
/// On Impeller (iOS) the backdrop is refracted through a lens-shaped rim
/// with a specular highlight, while the centre stays clear. Elsewhere it
/// falls back to a light frosted look.
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 28,
    this.padding,
    this.style,
    this.shadow = true,
  });

  final Widget child;

  /// Corner radius in logical pixels (capped at half the shortest side).
  final double borderRadius;
  final EdgeInsetsGeometry? padding;

  /// Override the default light/dark glass.
  final LiquidGlassStyle? style;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final dark = context.palette.brightness == Brightness.dark;
    var effective =
        style ?? (dark ? LiquidGlassStyle.dark : LiquidGlassStyle.light);
    if (!shadow) {
      effective = effective.copyWith(shadowBlur: 0);
    }
    return LiquidGlass(
      borderRadius: borderRadius,
      style: effective,
      child: padding == null ? child : Padding(padding: padding!, child: child),
    );
  }
}

/// Leading / trailing content inset used by bars and lists: 20pt on large
/// iPhones (414pt and wider), 16pt otherwise, as UIKit's layout margins.
double appleContentInset(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= 414 ? 20 : 16;

/// Whether Apple's own Liquid Glass (UIKit, iOS 26+) is available. When it
/// is, glass chrome is drawn by real UIKit controls instead of Flutter.
bool get useNativeLiquidGlass => NativeLiquidGlassUtils.supportsLiquidGlass;

/// Circular glass button, used for floating toolbar actions over content
/// (e.g. back / share buttons above a cover image).
///
/// On iOS 26+ this is a native `UIButton` with the system glass
/// configuration; elsewhere a Flutter approximation.
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    this.sfSymbol,
    this.onPressed,
    this.size = 44,
    this.iconSize = 20,
    this.color,
    this.tooltip,
  });

  final IconData icon;

  /// SF Symbol used by the native button (e.g. `chevron.backward`).
  final String? sfSymbol;
  final VoidCallback? onPressed;
  final double size;
  final double iconSize;
  final Color? color;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    if (useNativeLiquidGlass && sfSymbol != null) {
      return SizedBox(
        width: size,
        height: size,
        child: LiquidGlassButton.icon(
          onPressed: onPressed ?? () {},
          icon: NativeLiquidGlassIcon.sfSymbol(sfSymbol!),
          size: size,
          iconSize: iconSize,
          iconColor: color ?? context.palette.label,
          tooltip: tooltip,
        ),
      );
    }
    Widget button = GlassContainer(
      borderRadius: size / 2,
      style: (context.palette.brightness == Brightness.dark
              ? LiquidGlassStyle.dark
              : LiquidGlassStyle.light)
          .copyWith(
        refraction: 6,
        bevel: 10,
        blur: 6,
        tint: context.palette.brightness == Brightness.dark
            ? const Color(0x4D000000)
            : const Color(0x4DFFFFFF),
        shadowBlur: 10,
        shadowOffset: const Offset(0, 3),
      ),
      child: SizedBox(
        width: size,
        height: size,
        child: Icon(
          icon,
          size: iconSize,
          color: color ?? context.palette.label,
        ),
      ),
    );
    button = PressableScale(onTap: onPressed, child: button);
    if (tooltip != null) {
      button = Tooltip(message: tooltip, child: button);
    }
    return button;
  }
}

/// Gives a child the soft "press down" feedback used across iOS.
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale = 0.96,
    this.behavior = HitTestBehavior.opaque,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;
  final HitTestBehavior behavior;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  void _set(bool v) {
    if (_pressed != v) {
      setState(() => _pressed = v);
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null || widget.onLongPress != null;
    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: enabled ? (_) => _set(true) : null,
      onTapUp: enabled ? (_) => _set(false) : null,
      onTapCancel: enabled ? () => _set(false) : null,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: !enabled ? 0.4 : (_pressed ? 0.8 : 1),
          duration: const Duration(milliseconds: 140),
          child: widget.child,
        ),
      ),
    );
  }
}

/// iOS large-title navigation bar for scroll views (iOS 26 style).
///
/// The bar itself has no background: while content scrolls beneath it,
/// a soft scroll edge effect ([ScrollEdgeEffect]) progressively blurs and
/// fades that content into the page colour, extending a little past the
/// bar so there is no hard edge. The large title collapses into the inline
/// title as the page scrolls, and the back button is a glass circle.
class AppleSliverNavBar extends StatelessWidget {
  const AppleSliverNavBar({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
    this.bottom,
    this.previousPageTitle,
    this.heroTag,
    this.automaticallyImplyLeading = true,
    this.backgroundColor,
    this.pageBackgroundColor,
    this.largeTitle,
  });

  final String title;
  final Widget? leading;
  final Widget? trailing;
  final PreferredSizeWidget? bottom;

  /// Whether to show a large title. Defaults to true only for root pages:
  /// pages with a back button use a standard (inline) centred title, as
  /// the iOS 26 Settings sub pages do.
  final bool? largeTitle;

  /// Kept for API compatibility; iOS 26 back buttons show only a chevron.
  final String? previousPageTitle;

  /// Kept for API compatibility (no hero transition between bars).
  final Object? heroTag;
  final bool automaticallyImplyLeading;

  /// Colour content is washed into under the bar; defaults to
  /// [pageBackgroundColor].
  final Color? backgroundColor;

  /// Colour of the page behind the bar.
  final Color? pageBackgroundColor;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final pageColor =
        pageBackgroundColor ?? Theme.of(context).scaffoldBackgroundColor;

    Widget? leadingWidget = leading;
    if (leadingWidget == null && automaticallyImplyLeading) {
      final route = ModalRoute.of(context);
      if (route?.canPop ?? false) {
        leadingWidget = GlassIconButton(
          icon: CupertinoIcons.back,
          sfSymbol: 'chevron.backward',
          iconSize: 18,
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => Navigator.of(context).maybePop(),
        );
      }
    }

    return SliverPersistentHeader(
      pinned: true,
      delegate: _AppleNavBarDelegate(
        title: title,
        largeTitle: largeTitle ?? leadingWidget == null,
        margin: appleContentInset(context),
        leading: leadingWidget,
        trailing: trailing,
        bottom: bottom,
        topPadding: MediaQuery.paddingOf(context).top,
        edgeColor: backgroundColor?.withValues(alpha: 1) ?? pageColor,
        palette: palette,
        textScaler: MediaQuery.textScalerOf(context),
      ),
    );
  }
}

class _AppleNavBarDelegate extends SliverPersistentHeaderDelegate {
  _AppleNavBarDelegate({
    required this.title,
    required this.largeTitle,
    required this.margin,
    required this.leading,
    required this.trailing,
    required this.bottom,
    required this.topPadding,
    required this.edgeColor,
    required this.palette,
    required this.textScaler,
  });

  final String title;
  final bool largeTitle;
  final double margin;
  final Widget? leading;
  final Widget? trailing;
  final PreferredSizeWidget? bottom;
  final double topPadding;
  final Color edgeColor;
  final ApplePalette palette;
  final TextScaler textScaler;

  /// With a large title the bar is a little taller than 44pt so the 44pt
  /// glass buttons keep some air above the title; inline bars are the
  /// standard 44pt (measured on iOS 26 Settings).
  double get _toolbarHeight => largeTitle ? 52 : 44;
  double get _largeTitleHeight => largeTitle ? 56 : 0;

  /// How far the scroll edge effect reaches past the bottom of the bar.
  static const double _edgeOverhang = 6;

  double get _bottomHeight => bottom?.preferredSize.height ?? 0;

  @override
  double get minExtent => topPadding + _toolbarHeight + _bottomHeight;

  @override
  double get maxExtent => minExtent + _largeTitleHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final theme = CupertinoTheme.of(context);
    final extent = (maxExtent - shrinkOffset).clamp(minExtent, maxExtent);
    final largeTitleExtent = extent - minExtent;
    final collapse =
        largeTitle ? 1 - largeTitleExtent / _largeTitleHeight : 1.0;

    // Content only passes under the bar once the large title has
    // collapsed; fade the edge effect in over the first few points.
    final scrolledUnder =
        ((shrinkOffset - _largeTitleHeight) / 14).clamp(0.0, 1.0);

    final largeTitleStyle =
        theme.textTheme.navLargeTitleTextStyle.copyWith(color: palette.label);
    final titleStyle =
        theme.textTheme.navTitleTextStyle.copyWith(color: palette.label);
    final showInlineTitle = !largeTitle || largeTitleExtent < 10;

    final dark = palette.brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Stack(
        clipBehavior: Clip.none,
        fit: StackFit.expand,
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: extent + _edgeOverhang,
            child: IgnorePointer(
              child: ScrollEdgeEffect(
                color: edgeColor,
                visibility: scrolledUnder,
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: topPadding,
            height: _toolbarHeight,
            child: Padding(
              padding: EdgeInsetsDirectional.symmetric(horizontal: margin),
              child: NavigationToolbar(
                leading: leading,
                middle: AnimatedOpacity(
                  opacity: showInlineTitle ? 1 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: titleStyle,
                  ),
                ),
                trailing: trailing,
                middleSpacing: 8,
              ),
            ),
          ),
          if (largeTitleExtent > 0)
            Positioned(
              left: 0,
              right: 0,
              top: topPadding + _toolbarHeight,
              height: largeTitleExtent,
              child: ClipRect(
                child: OverflowBox(
                  minHeight: 0,
                  maxHeight: double.infinity,
                  alignment: AlignmentDirectional.bottomStart,
                  child: Opacity(
                    opacity: (1 - collapse * 1.15).clamp(0.0, 1.0),
                    child: Padding(
                      padding: EdgeInsetsDirectional.only(
                        start: margin,
                        end: margin,
                        bottom: 8,
                      ),
                      child: Semantics(
                        header: true,
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: largeTitleStyle,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (bottom != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: _bottomHeight,
              child: bottom!,
            ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_AppleNavBarDelegate oldDelegate) {
    return title != oldDelegate.title ||
        largeTitle != oldDelegate.largeTitle ||
        margin != oldDelegate.margin ||
        leading != oldDelegate.leading ||
        trailing != oldDelegate.trailing ||
        bottom != oldDelegate.bottom ||
        topPadding != oldDelegate.topPadding ||
        edgeColor != oldDelegate.edgeColor ||
        palette != oldDelegate.palette ||
        textScaler != oldDelegate.textScaler;
  }
}

/// Toolbar icon button used in navigation bars (accent tinted, no ripple).
class NavBarIconButton extends StatelessWidget {
  const NavBarIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = 24,
    this.color,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      minimumSize: const Size(36, 36),
      onPressed: onPressed,
      child: Icon(
        icon,
        size: size,
        color: color ?? Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

/// Section header in the style of the App Store / Music
/// ("Title 3" heading with an optional "See All" action).
class AppleSectionHeader extends StatelessWidget {
  const AppleSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.padding = const EdgeInsets.fromLTRB(20, 20, 12, 8),
    this.trailing,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onAction,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: theme.textTheme.headlineSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (onAction != null && actionLabel == null)
                    Padding(
                      padding: const EdgeInsets.only(left: 4, top: 2),
                      child: Icon(
                        CupertinoIcons.chevron_forward,
                        size: 18,
                        color: context.palette.secondaryLabel,
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (trailing != null) trailing!,
          if (actionLabel != null)
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(32, 32),
              onPressed: onAction,
              child: Text(
                actionLabel!,
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: theme.colorScheme.primary),
              ),
            ),
        ],
      ),
    );
  }
}

/// Rounded square with a white glyph, as seen in iOS Settings.
class AppleIconBadge extends StatelessWidget {
  const AppleIconBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = 29,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: ShapeDecoration(
        color: color,
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(size * 0.25),
        ),
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.62),
    );
  }
}

/// Inset grouped list section (iOS Settings style).
class AppleSection extends StatelessWidget {
  const AppleSection({
    super.key,
    required this.children,
    this.header,
    this.footer,
    this.margin,
    this.dividerIndent,
  });

  /// iOS 26 inset grouped corner radius (measured on iOS 26 Settings).
  static const double radius = 26;

  final List<Widget> children;
  final String? header;
  final String? footer;

  /// Defaults to the screen's content inset (20pt / 16pt) on both sides.
  final EdgeInsetsGeometry? margin;

  /// Leading inset for separators between rows; defaults to the row's
  /// content inset.
  final double? dividerIndent;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final theme = Theme.of(context);
    final inset = appleContentInset(context);
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      rows.add(children[i]);
      if (i != children.length - 1) {
        rows.add(Padding(
          padding: EdgeInsetsDirectional.only(start: dividerIndent ?? inset),
          child: Divider(height: 0.5, thickness: 0.5, color: palette.separator),
        ));
      }
    }

    return Padding(
      padding: margin ?? EdgeInsets.symmetric(horizontal: inset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // iOS 26 section headers: sentence case, larger and semibold.
          if (header != null)
            Padding(
              padding: EdgeInsets.fromLTRB(inset, 24, inset, 8),
              child: Text(
                header!,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: palette.secondaryLabel,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            const SizedBox(height: 24),
          ClipRSuperellipse(
            borderRadius: BorderRadius.circular(radius),
            child: Material(
              color: palette.secondaryGroupedBackground,
              child: Column(children: rows),
            ),
          ),
          if (footer != null)
            Padding(
              padding: EdgeInsets.fromLTRB(inset, 8, inset, 0),
              child: Text(footer!, style: theme.textTheme.bodySmall),
            ),
        ],
      ),
    );
  }
}

/// A row inside an [AppleSection].
class AppleListTile extends StatelessWidget {
  const AppleListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.value,
    this.onTap,
    this.onLongPress,
    this.showChevron,
    this.titleColor,
    this.minHeight = 52,
  });

  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;

  /// Secondary text shown at the trailing edge (e.g. the current value).
  final String? value;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Defaults to `true` when [onTap] is set and no [trailing] is provided.
  final bool? showChevron;
  final Color? titleColor;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final theme = Theme.of(context);
    final chevron = showChevron ?? (onTap != null && trailing == null);

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: appleContentInset(context),
            vertical: 10,
          ),
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DefaultTextStyle.merge(
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(color: titleColor ?? palette.label),
                      child: title,
                    ),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: DefaultTextStyle.merge(
                          style: theme.textTheme.bodySmall,
                          child: subtitle!,
                        ),
                      ),
                  ],
                ),
              ),
              if (value != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    value!,
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(color: palette.secondaryLabel),
                  ),
                ),
              if (trailing != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: trailing!,
                ),
              if (chevron)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Icon(
                    CupertinoIcons.chevron_forward,
                    size: 17,
                    color: palette.tertiaryLabel,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// iOS switch row.
class AppleSwitchTile extends StatelessWidget {
  const AppleSwitchTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.leading,
    this.onLongPress,
  });

  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return AppleListTile(
      title: title,
      subtitle: subtitle,
      leading: leading,
      onTap: onChanged == null ? null : () => onChanged!(!value),
      onLongPress: onLongPress,
      showChevron: false,
      trailing: AppleSwitch(
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}

/// Grouped scrolling page with a large title (Settings-style).
class AppleGroupedPage extends StatelessWidget {
  const AppleGroupedPage({
    super.key,
    required this.title,
    required this.children,
    this.previousPageTitle,
    this.trailing,
  });

  final String title;
  final List<Widget> children;
  final String? previousPageTitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.groupedBackground,
      body: CustomScrollView(
        physics: kAppleScrollPhysics,
        slivers: [
          AppleSliverNavBar(
            title: title,
            previousPageTitle: previousPageTitle,
            trailing: trailing,
            pageBackgroundColor: palette.groupedBackground,
          ),
          SliverSafeArea(
            top: false,
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                ...children,
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

/// Content-unavailable placeholder (SwiftUI `ContentUnavailableView`).
class AppleEmptyState extends StatelessWidget {
  const AppleEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: palette.secondaryLabel),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(
                message!,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: palette.secondaryLabel),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 20),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Capsule shaped button. `filled` = accent background, otherwise the
/// tinted (accent on light fill) variant used by Apple Music & App Store.
class CapsuleButton extends StatelessWidget {
  const CapsuleButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.filled = true,
    this.height = 44,
    this.expand = false,
    this.loading = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool filled;
  final double height;
  final bool expand;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = context.palette;
    final fg = filled ? scheme.onPrimary : scheme.primary;
    final bg = filled ? scheme.primary : palette.tertiaryFill;

    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          CupertinoActivityIndicator(color: fg, radius: 9)
        else if (icon != null)
          Icon(icon, color: fg, size: 19),
        if ((icon != null || loading) && label.isNotEmpty)
          const SizedBox(width: 6),
        if (label.isNotEmpty)
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: fg,
                    fontSize: 16,
                  ),
            ),
          ),
      ],
    );

    return PressableScale(
      onTap: loading ? null : onPressed,
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: ShapeDecoration(
          color: bg,
          shape: const StadiumBorder(),
        ),
        child: content,
      ),
    );
  }
}

/// Shows an iOS 26 style alert (UIAlertController .alert): a rounded glass
/// card with capsule buttons. The preferred action is tinted; when an alert
/// also has a destructive action, its default action is the cancel button.
Future<T?> showAppleAlert<T>({
  required BuildContext context,
  required String title,
  String? message,
  required List<AppleAlertAction<T>> actions,
}) {
  HapticFeedback.mediumImpact();
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: 0.28),
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (context, _, __) => _AppleAlert<T>(
      title: title,
      message: message,
      actions: actions,
    ),
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeIn,
      );
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: Tween<double>(begin: 1.12, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _AppleAlert<T> extends StatelessWidget {
  const _AppleAlert({
    required this.title,
    required this.actions,
    this.message,
  });

  final String title;
  final String? message;
  final List<AppleAlertAction<T>> actions;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final theme = Theme.of(context);
    final dark = palette.brightness == Brightness.dark;
    final hasDestructive = actions.any((a) => a.isDestructive);

    Widget button(AppleAlertAction<T> a) {
      final preferred = a.isDefault && !a.isDestructive && !hasDestructive;
      final fill = preferred
          ? theme.colorScheme.primary
          : (dark ? const Color(0x3D767680) : const Color(0x1F767680));
      final color = a.isDestructive
          ? (dark ? const Color(0xFFFF453A) : const Color(0xFFFF3B30))
          : preferred
              ? Colors.white
              : palette.label;
      return CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: const Size(0, 48),
        onPressed: () {
          Navigator.of(context).pop(a.value);
          a.onPressed?.call();
        },
        child: Container(
          height: 48,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: ShapeDecoration(
            color: fill,
            shape: const StadiumBorder(),
          ),
          child: Text(
            a.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: color,
              fontWeight:
                  a.isDefault || preferred ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      );
    }

    final Widget buttons = actions.length <= 2
        ? Row(
            children: [
              for (var i = 0; i < actions.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(child: button(actions[i])),
              ],
            ],
          )
        : Column(
            children: [
              for (var i = 0; i < actions.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                SizedBox(width: double.infinity, child: button(actions[i])),
              ],
            ],
          );

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: LiquidGlass(
            borderRadius: 34,
            style: glassPanelStyle(dark, opacity: 0.86),
            child: Material(
              type: MaterialType.transparency,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (message != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        message!,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: palette.secondaryLabel),
                      ),
                    ],
                    const SizedBox(height: 20),
                    buttons,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AppleAlertAction<T> {
  const AppleAlertAction({
    required this.label,
    this.value,
    this.onPressed,
    this.isDefault = false,
    this.isDestructive = false,
  });

  final String label;
  final T? value;
  final VoidCallback? onPressed;
  final bool isDefault;
  final bool isDestructive;
}

/// Lets the user pick one of [options] from an iOS 26 menu anchored to
/// [anchor] (global rect) or, by default, to the widget that owns
/// [context]. The current [selected] value gets a checkmark. Resolves to
/// the picked value, or null when dismissed.
Future<T?> showAppleOptionsSheet<T>({
  required BuildContext context,
  required Map<T, String> options,
  T? selected,
  String? title,
  String? message,
  Rect? anchor,
  bool popUp = false,
}) {
  final size = MediaQuery.sizeOf(context);
  final rect = anchor ??
      globalRectOf(context) ??
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: 0,
        height: 0,
      );
  return showAppleMenu<T>(
    context: context,
    anchor: rect,
    items: options,
    selected: selected,
    title: title ?? message,
    popUp: popUp,
  );
}

/// Pull-down menu (iOS 14+) anchored to a button. The selected item is
/// marked with a leading checkmark.
class ApplePullDownButton<T> extends StatelessWidget {
  const ApplePullDownButton({
    super.key,
    required this.items,
    required this.onSelected,
    required this.child,
    this.selected,
    this.title,
    this.enabled = true,
  });

  final Map<T, String> items;
  final ValueChanged<T> onSelected;
  final T? selected;
  final Widget child;
  final String? title;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: !enabled
          ? null
          : () async {
              final rect = globalRectOf(context);
              if (rect == null) {
                return;
              }
              final value = await showAppleMenu<T>(
                context: context,
                anchor: rect,
                items: items,
                selected: selected,
                title: title,
              );
              if (value != null) {
                onSelected(value);
              }
            },
      child: child,
    );
  }
}

/// Opens the same menu as [ApplePullDownButton] next to [anchor] (global
/// coordinates), for triggers that are not Flutter buttons (e.g. native
/// Liquid Glass buttons). Completes with the chosen value, or null.
Future<T?> showApplePullDownMenu<T>({
  required BuildContext context,
  required Rect anchor,
  required Map<T, String> items,
  T? selected,
  String? title,
}) {
  return showAppleMenu<T>(
    context: context,
    anchor: anchor,
    items: items,
    selected: selected,
    title: title,
  );
}

/// iOS search field: a filled capsule, as in iOS 26.
class AppleSearchField extends StatefulWidget {
  const AppleSearchField({
    super.key,
    this.controller,
    this.focusNode,
    this.placeholder,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
  });

  /// Height of the field; the corners are fully rounded.
  static const double height = 44;

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? placeholder;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;

  @override
  State<AppleSearchField> createState() => _AppleSearchFieldState();
}

class _AppleSearchFieldState extends State<AppleSearchField> {
  TextEditingController? _ownController;

  TextEditingController get _controller =>
      widget.controller ?? (_ownController ??= TextEditingController());

  @override
  void dispose() {
    _ownController?.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final theme = Theme.of(context);
    final dark = palette.brightness == Brightness.dark;
    // No line-height override: with one, Flutter places CJK text (drawn
    // with a fallback font) visibly below the centre on iOS.
    final textStyle = theme.textTheme.bodyLarge;
    final controller = _controller;
    // The placeholder is a plain label centred in the row like the icon
    // (CupertinoTextField baseline-aligns its placeholder to the empty
    // editable line, which puts Chinese placeholders too low).
    return SizedBox(
      height: AppleSearchField.height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          // tertiarySystemFill
          color: dark ? const Color(0x3D767680) : const Color(0x1F767680),
          borderRadius: const BorderRadius.all(
            Radius.circular(AppleSearchField.height / 2),
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            Icon(
              CupertinoIcons.search,
              size: 19,
              color: palette.secondaryLabel,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Stack(
                alignment: AlignmentDirectional.centerStart,
                children: [
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: controller,
                    builder: (context, value, _) => value.text.isEmpty &&
                            !value.composing.isValid
                        ? IgnorePointer(
                            child: Text(
                              widget.placeholder ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textStyle?.copyWith(
                                  color: palette.secondaryLabel),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  CupertinoTextField(
                    controller: controller,
                    focusNode: widget.focusNode,
                    autofocus: widget.autofocus,
                    onChanged: widget.onChanged,
                    onSubmitted: widget.onSubmitted,
                    textInputAction: TextInputAction.search,
                    textAlignVertical: TextAlignVertical.center,
                    maxLines: 1,
                    style: textStyle,
                    cursorColor: theme.colorScheme.primary,
                    padding: EdgeInsets.zero,
                    decoration: null,
                  ),
                ],
              ),
            ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) => value.text.isEmpty
                  ? const SizedBox(width: 14)
                  : GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _clear,
                      child: Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                            8, 0, 14, 0),
                        child: Icon(
                          CupertinoIcons.xmark_circle_fill,
                          size: 18,
                          color: palette.tertiaryLabel,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// iOS 26 sheet: a floating, rounded glass card inset from the screen
/// edges, with a centred title and a glass done (checkmark) button.
class AppleSheet extends StatelessWidget {
  const AppleSheet({
    super.key,
    required this.title,
    required this.child,
    this.onDone,
  });

  final String title;
  final Widget child;

  /// Defaults to closing the sheet.
  final VoidCallback? onDone;

  static const double radius = 36;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final theme = Theme.of(context);
    final dark = palette.brightness == Brightness.dark;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(8, 0, 8, bottom > 0 ? bottom / 2 : 8),
      child: LiquidGlass(
        borderRadius: radius,
        style: glassPanelStyle(dark, opacity: 0.88),
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
                child: SizedBox(
                  height: 44,
                  child: NavigationToolbar(
                    middle: Text(
                      title,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    trailing: GlassIconButton(
                      icon: CupertinoIcons.checkmark_alt,
                      sfSymbol: 'checkmark',
                      iconSize: 18,
                      tooltip: MaterialLocalizations.of(context).okButtonLabel,
                      onPressed:
                          onDone ?? () => Navigator.of(context).maybePop(),
                    ),
                  ),
                ),
              ),
              child,
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

/// Presents [AppleSheet]-style content from the bottom of the screen.
Future<T?> showAppleSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return showCupertinoModalPopup<T>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.25),
    builder: builder,
  );
}

/// Non-scrolling top bar (iOS 26) for pages whose content cannot sit under
/// a translucent bar, such as web views: inline title, glass buttons.
class AppleTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppleTopBar({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
    this.closeIcon = false,
  });

  final String title;
  final Widget? leading;
  final Widget? trailing;

  /// Use a close (xmark) button instead of a back chevron.
  final bool closeIcon;

  static const double _height = 56;

  @override
  Size get preferredSize => const Size.fromHeight(_height);

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final top = MediaQuery.paddingOf(context).top;
    Widget? lead = leading;
    if (lead == null && (ModalRoute.of(context)?.canPop ?? false)) {
      lead = GlassIconButton(
        icon: closeIcon ? CupertinoIcons.xmark : CupertinoIcons.back,
        sfSymbol: closeIcon ? 'xmark' : 'chevron.backward',
        iconSize: 18,
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        onPressed: () => Navigator.of(context).maybePop(),
      );
    }
    final dark = palette.brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: ColoredBox(
        color: palette.background,
        child: Padding(
          padding: EdgeInsets.only(top: top),
          child: SizedBox(
            height: _height,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: NavigationToolbar(
                leading: lead,
                middle: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CupertinoTheme.of(context)
                      .textTheme
                      .navTitleTextStyle
                      .copyWith(color: palette.label),
                ),
                trailing: trailing,
                middleSpacing: 8,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Small capsule tag ("chip") used for gallery tags.
class AppleTagChip extends StatelessWidget {
  const AppleTagChip({
    super.key,
    required this.label,
    this.onTap,
    this.color,
    this.textColor,
    this.dense = false,
  });

  final String label;
  final VoidCallback? onTap;
  final Color? color;
  final Color? textColor;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final chip = Container(
      padding: dense
          ? const EdgeInsets.symmetric(horizontal: 7, vertical: 2)
          : const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: ShapeDecoration(
        color: color ?? palette.tertiaryFill,
        shape: const StadiumBorder(),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: dense ? 11 : 14,
          fontWeight: FontWeight.w500,
          height: 1.25,
          letterSpacing: dense ? 0.07 : -0.15,
          color: textColor ?? palette.label.withValues(alpha: 0.8),
        ),
      ),
    );
    if (onTap == null) {
      return chip;
    }
    return PressableScale(onTap: onTap, scale: 0.94, child: chip);
  }
}

/// Activity indicator sized for list footers / full page loading.
class AppleLoading extends StatelessWidget {
  const AppleLoading({super.key, this.radius = 12});

  final double radius;

  @override
  Widget build(BuildContext context) {
    return Center(child: CupertinoActivityIndicator(radius: radius));
  }
}
