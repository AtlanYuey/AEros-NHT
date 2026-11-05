import 'package:eros_n/common/enum.dart';
import 'package:eros_n/component/widget/apple.dart';
import 'package:eros_n/generated/l10n.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
