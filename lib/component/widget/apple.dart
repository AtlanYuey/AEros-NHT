import 'dart:ui';

import 'package:eros_n/component/theme/theme.dart';
import 'package:eros_n/generated/l10n.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// A small kit of widgets that follow Apple's Human Interface Guidelines.
///
/// Everything here is built on top of the Material/Cupertino primitives
/// already used by the app so pages can adopt the iOS look incrementally.

const kAppleScrollPhysics =
    BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());

/// Frosted "liquid glass" surface: blurred backdrop, translucent fill and
/// a hairline highlight border.
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(28)),
    this.padding,
    this.color,
    this.blur = 24,
    this.shadow = true,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final double blur;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: shadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(
                      alpha:
                          palette.brightness == Brightness.dark ? 0.45 : 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: ClipRSuperellipse(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: ShapeDecoration(
              color: color ?? palette.glass,
              shape: RoundedSuperellipseBorder(
                borderRadius: borderRadius,
                side: BorderSide(color: palette.glassBorder, width: 0.6),
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Circular glass button, used for floating toolbar actions over content
/// (e.g. back / share buttons above a cover image).
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = 40,
    this.iconSize = 20,
    this.color,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final double iconSize;
  final Color? color;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    Widget button = GlassContainer(
      borderRadius: BorderRadius.circular(size / 2),
      shadow: false,
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

/// iOS large-title navigation bar for scroll views.
///
/// Wraps [CupertinoSliverNavigationBar] with app-wide defaults:
/// transparent until content scrolls beneath it, then frosted.
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
  });

  final String title;
  final Widget? leading;
  final Widget? trailing;
  final PreferredSizeWidget? bottom;
  final String? previousPageTitle;
  final Object? heroTag;
  final bool automaticallyImplyLeading;

  /// Bar color once content scrolls beneath it (blurred).
  final Color? backgroundColor;

  /// Color of the page behind the bar; while the large title is fully
  /// expanded the bar blends into it (iOS 15+ scroll-edge appearance).
  final Color? pageBackgroundColor;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return CupertinoPageScaffoldBackgroundColor(
      color: pageBackgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
      child: _buildBar(palette),
    );
  }

  Widget _buildBar(ApplePalette palette) {
    return CupertinoSliverNavigationBar(
      largeTitle: Text(title),
      leading: leading,
      trailing: trailing,
      bottom: bottom,
      bottomMode: bottom == null ? null : NavigationBarBottomMode.always,
      previousPageTitle: previousPageTitle,
      automaticallyImplyLeading: automaticallyImplyLeading,
      transitionBetweenRoutes: false,
      heroTag: heroTag ?? 'nav_$title',
      stretch: true,
      backgroundColor: backgroundColor ?? palette.bar,
      border: Border(
        bottom: BorderSide(color: palette.separator, width: 0.0),
      ),
    );
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
    this.margin = const EdgeInsets.fromLTRB(16, 0, 16, 0),
    this.dividerIndent = 16,
  });

  final List<Widget> children;
  final String? header;
  final String? footer;
  final EdgeInsetsGeometry margin;

  /// Leading inset for separators between rows.
  final double dividerIndent;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final theme = Theme.of(context);
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      rows.add(children[i]);
      if (i != children.length - 1) {
        rows.add(Padding(
          padding: EdgeInsetsDirectional.only(start: dividerIndent),
          child: Divider(height: 0.5, thickness: 0.5, color: palette.separator),
        ));
      }
    }

    return Padding(
      padding: margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 7),
              child: Text(
                header!.toUpperCase(),
                style: theme.textTheme.bodySmall,
              ),
            )
          else
            const SizedBox(height: 22),
          ClipRSuperellipse(
            borderRadius: BorderRadius.circular(12),
            child: Material(
              color: palette.secondaryGroupedBackground,
              child: Column(children: rows),
            ),
          ),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 7, 16, 0),
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
    this.minHeight = 44,
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
      trailing: CupertinoSwitch(
        value: value,
        onChanged: onChanged,
        activeTrackColor: CupertinoColors.systemGreen,
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
            backgroundColor: palette.brightness == Brightness.dark
                ? palette.bar
                : const Color(0xEBF2F2F7),
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

/// Shows a native looking alert (UIAlertController .alert).
Future<T?> showAppleAlert<T>({
  required BuildContext context,
  required String title,
  String? message,
  required List<AppleAlertAction<T>> actions,
}) {
  return showCupertinoDialog<T>(
    context: context,
    barrierDismissible: true,
    builder: (context) => CupertinoAlertDialog(
      title: Text(title),
      content: message == null ? null : Text(message),
      actions: actions
          .map(
            (a) => CupertinoDialogAction(
              isDefaultAction: a.isDefault,
              isDestructiveAction: a.isDestructive,
              onPressed: () {
                Navigator.of(context).pop(a.value);
                a.onPressed?.call();
              },
              child: Text(a.label),
            ),
          )
          .toList(),
    ),
  );
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

/// Shows an action sheet listing [options]; the current [selected] value
/// gets a checkmark. Resolves to the picked value (or null if cancelled).
Future<T?> showAppleOptionsSheet<T>({
  required BuildContext context,
  required Map<T, String> options,
  T? selected,
  String? title,
  String? message,
}) {
  final accent = Theme.of(context).colorScheme.primary;
  return showCupertinoModalPopup<T>(
    context: context,
    builder: (context) => CupertinoActionSheet(
      title: title == null ? null : Text(title),
      message: message == null ? null : Text(message),
      actions: options.entries
          .map(
            (e) => CupertinoActionSheetAction(
              isDefaultAction: e.key == selected,
              onPressed: () => Navigator.of(context).pop(e.key),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(width: 26),
                  Flexible(
                    child: Text(
                      e.value,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: accent),
                    ),
                  ),
                  SizedBox(
                    width: 26,
                    child: e.key == selected
                        ? Icon(CupertinoIcons.checkmark_alt,
                            size: 20, color: accent)
                        : null,
                  ),
                ],
              ),
            ),
          )
          .toList(),
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(L10n.of(context).cancel),
      ),
    ),
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
    final palette = context.palette;
    final theme = Theme.of(context);
    return PopupMenuButton<T>(
      enabled: enabled,
      tooltip: title ?? '',
      padding: EdgeInsets.zero,
      position: PopupMenuPosition.under,
      offset: const Offset(0, 6),
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 280),
      onSelected: onSelected,
      itemBuilder: (context) => [
        if (title != null)
          PopupMenuItem<T>(
            enabled: false,
            height: 30,
            child: Text(
              title!,
              style: theme.textTheme.labelMedium,
            ),
          ),
        ...items.entries.map(
          (e) => PopupMenuItem<T>(
            value: e.key,
            height: 44,
            child: Row(
              children: [
                SizedBox(
                  width: 26,
                  child: e.key == selected
                      ? Icon(CupertinoIcons.checkmark_alt,
                          size: 18, color: palette.label)
                      : null,
                ),
                Expanded(
                  child: Text(
                    e.value,
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
      child: child,
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
