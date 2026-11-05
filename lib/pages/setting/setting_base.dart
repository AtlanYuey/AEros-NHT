import 'package:eros_n/component/theme/theme.dart';
import 'package:eros_n/component/widget/apple.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Row that shows the current value and opens an iOS action sheet with
/// all options (the selected one carries a checkmark).
class AppleOptionTile<T> extends StatelessWidget {
  const AppleOptionTile({
    super.key,
    required this.title,
    required this.options,
    required this.value,
    required this.onChanged,
    this.leading,
    this.subtitle,
  });

  final String title;
  final Map<T, String> options;
  final T value;
  final ValueChanged<T> onChanged;
  final Widget? leading;
  final Widget? subtitle;

  @override
  Widget build(BuildContext context) {
    return AppleListTile(
      leading: leading,
      title: Text(title),
      subtitle: subtitle,
      value: options[value],
      showChevron: true,
      onTap: () async {
        // iOS 26 pop-up button: the menu opens from the value at the
        // trailing edge of the row.
        final row = globalRectOf(context);
        final result = await showAppleOptionsSheet<T>(
          context: context,
          options: options,
          selected: value,
          popUp: true,
          // The value at the trailing edge of the row: the menu morphs out
          // of it with the selected item over the row.
          anchor: row == null
              ? null
              : Rect.fromLTRB(row.right - 150, row.top + 6, row.right - 16,
                  row.bottom - 6),
        );
        if (result != null) {
          onChanged(result);
        }
      },
    );
  }
}

/// Row with a title, the current value and an iOS slider beneath.
class AppleSliderTile extends StatelessWidget {
  const AppleSliderTile({
    super.key,
    required this.title,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.divisions,
  });

  final String title;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: theme.textTheme.bodyLarge)),
              Text(
                valueLabel,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: palette.secondaryLabel,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          SizedBox(
            width: double.infinity,
            child: AppleSlider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              activeColor: theme.colorScheme.primary,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
