import 'package:eros_n/common/enum.dart';
import 'package:eros_n/component/widget/apple.dart';
import 'package:eros_n/generated/l10n.dart';
import 'package:eros_n/component/theme/theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:native_liquid_glass/native_liquid_glass.dart';

typedef AsyncValueChanged<T> = Future<void> Function(T value);

/// Shared implementation for the async pull-down filter buttons.
class _AsyncPullDownButton<T> extends StatefulWidget {
  const _AsyncPullDownButton({
    super.key,
    required this.items,
    required this.initValue,
    required this.onSelected,
    required this.icon,
    this.title,
    this.iconSize,
  });

  final Map<T, String> items;
  final T initValue;
  final AsyncValueChanged<T> onSelected;
  final IconData icon;
  final String? title;
  final double? iconSize;

  @override
  State<_AsyncPullDownButton<T>> createState() =>
      _AsyncPullDownButtonState<T>();
}

class _AsyncPullDownButtonState<T> extends State<_AsyncPullDownButton<T>> {
  bool loading = false;

  Future<void> _onSelected(T val) async {
    try {
      setState(() {
        loading = true;
      });
      await widget.onSelected(val);
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return ApplePullDownButton<T>(
      items: widget.items,
      selected: widget.initValue,
      title: widget.title,
      enabled: !loading,
      onSelected: _onSelected,
      child: SizedBox(
        width: 38,
        height: 38,
        child: Center(
          child: loading
              ? const CupertinoActivityIndicator(radius: 9)
              : Icon(
                  widget.icon,
                  size: widget.iconSize ?? 23,
                  color: accent,
                ),
        ),
      ),
    );
  }
}

class SortPopupButton extends StatelessWidget {
  const SortPopupButton({
    super.key,
    required this.onSelected,
    this.initValue = SearchSort.recent,
    this.iconSize,
  });

  final AsyncValueChanged<SearchSort> onSelected;
  final SearchSort initValue;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final sortMap = {
      SearchSort.recent: L10n.of(context).recent,
      SearchSort.popularToday: L10n.of(context).popular_today,
      SearchSort.popularWeek: L10n.of(context).popular_week,
      SearchSort.popularMonth: L10n.of(context).popular_month,
      SearchSort.popular: L10n.of(context).popular,
    };

    return _AsyncPullDownButton<SearchSort>(
      items: sortMap,
      initValue: initValue,
      onSelected: onSelected,
      icon: CupertinoIcons.arrow_up_arrow_down_circle,
      iconSize: iconSize,
    );
  }
}

// LanguagesFilterPopupButton
class LanguagesFilterPopupButton extends StatelessWidget {
  const LanguagesFilterPopupButton({
    super.key,
    required this.onSelected,
    this.initValue = LanguagesFilter.all,
    this.iconSize,
  });

  final AsyncValueChanged<LanguagesFilter> onSelected;
  final LanguagesFilter initValue;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final languagesMap = {
      LanguagesFilter.all: L10n.of(context).all,
      LanguagesFilter.japanese: L10n.of(context).japanese,
      LanguagesFilter.chinese: L10n.of(context).chinese,
      LanguagesFilter.english: L10n.of(context).english,
      LanguagesFilter.translated: L10n.of(context).translated,
    };

    return _AsyncPullDownButton<LanguagesFilter>(
      items: languagesMap,
      initValue: initValue,
      onSelected: onSelected,
      icon: CupertinoIcons.globe,
      iconSize: iconSize,
    );
  }
}

/// Language and sort menus as one Liquid Glass capsule in the navigation
/// bar (iOS 26 bar button group). On iOS 26 the capsule is a native glass
/// button group; elsewhere a Flutter glass approximation.
class NavFilterButtons extends StatefulWidget {
  const NavFilterButtons({
    super.key,
    required this.language,
    required this.onLanguageSelected,
    required this.sort,
    required this.onSortSelected,
  });

  final LanguagesFilter language;
  final AsyncValueChanged<LanguagesFilter> onLanguageSelected;
  final SearchSort sort;
  final AsyncValueChanged<SearchSort> onSortSelected;

  @override
  State<NavFilterButtons> createState() => _NavFilterButtonsState();
}

class _NavFilterButtonsState extends State<NavFilterButtons> {
  static const double _size = 44;

  final _key = GlobalKey();
  int? _loadingIndex;

  Map<LanguagesFilter, String> _languages(BuildContext context) => {
        LanguagesFilter.all: L10n.of(context).all,
        LanguagesFilter.japanese: L10n.of(context).japanese,
        LanguagesFilter.chinese: L10n.of(context).chinese,
        LanguagesFilter.english: L10n.of(context).english,
        LanguagesFilter.translated: L10n.of(context).translated,
      };

  Map<SearchSort, String> _sorts(BuildContext context) => {
        SearchSort.recent: L10n.of(context).recent,
        SearchSort.popularToday: L10n.of(context).popular_today,
        SearchSort.popularWeek: L10n.of(context).popular_week,
        SearchSort.popularMonth: L10n.of(context).popular_month,
        SearchSort.popular: L10n.of(context).popular,
      };

  Future<void> _open<T>(
    int index,
    Map<T, String> items,
    T selected,
    AsyncValueChanged<T> onSelected,
  ) async {
    if (_loadingIndex != null) {
      return;
    }
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      return;
    }
    final origin = box.localToGlobal(Offset.zero);
    final value = await showApplePullDownMenu<T>(
      context: context,
      anchor: Rect.fromLTWH(origin.dx + index * _size, origin.dy, _size,
          box.size.height),
      items: items,
      selected: selected,
    );
    if (value == null || !mounted) {
      return;
    }
    setState(() => _loadingIndex = index);
    try {
      await onSelected(value);
    } finally {
      if (mounted) {
        setState(() => _loadingIndex = null);
      }
    }
  }

  void _openLanguage() => _open<LanguagesFilter>(0, _languages(context),
      widget.language, widget.onLanguageSelected);

  void _openSort() =>
      _open<SearchSort>(1, _sorts(context), widget.sort, widget.onSortSelected);

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final busy = _loadingIndex != null;

    Widget spinner(int index) => Positioned(
          left: index * _size,
          top: 0,
          width: _size,
          height: _size,
          child: const IgnorePointer(
            child: Center(child: CupertinoActivityIndicator(radius: 9)),
          ),
        );

    if (useNativeLiquidGlass) {
      LiquidGlassButtonData button(String symbol, VoidCallback onPressed,
          {required bool hidden}) {
        return LiquidGlassButtonData(
          icon: NativeLiquidGlassIcon.sfSymbol(symbol),
          iconSize: 18,
          iconColor: hidden ? Colors.transparent : palette.label,
          width: _size,
          height: _size,
          enabled: !busy,
          glassEffectUnionId: 'nav_filters',
          onPressed: onPressed,
        );
      }

      return SizedBox(
        key: _key,
        width: _size * 2,
        height: _size,
        child: Stack(
          children: [
            Positioned.fill(
              child: LiquidGlassButtonGroup(
                spacing: 0,
                buttons: [
                  button('globe', _openLanguage, hidden: _loadingIndex == 0),
                  button('arrow.up.arrow.down', _openSort,
                      hidden: _loadingIndex == 1),
                ],
              ),
            ),
            if (_loadingIndex != null) spinner(_loadingIndex!),
          ],
        ),
      );
    }

    Widget icon(int index, IconData data, VoidCallback onPressed) {
      return SizedBox(
        width: _size,
        height: _size,
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: busy ? null : onPressed,
          child: _loadingIndex == index
              ? const SizedBox.shrink()
              : Icon(data, size: 21, color: palette.label),
        ),
      );
    }

    final dark = palette.brightness == Brightness.dark;
    return GlassContainer(
      borderRadius: _size / 2,
      style: (dark ? LiquidGlassStyle.dark : LiquidGlassStyle.light).copyWith(
        refraction: 6,
        bevel: 10,
        blur: 6,
        tint: dark ? const Color(0x4D000000) : const Color(0x4DFFFFFF),
        shadowBlur: 10,
        shadowOffset: const Offset(0, 3),
      ),
      child: SizedBox(
        key: _key,
        width: _size * 2,
        height: _size,
        child: Stack(
          children: [
            Row(
              children: [
                icon(0, CupertinoIcons.globe, _openLanguage),
                icon(1, CupertinoIcons.arrow_up_arrow_down, _openSort),
              ],
            ),
            if (_loadingIndex != null) spinner(_loadingIndex!),
          ],
        ),
      ),
    );
  }
}

