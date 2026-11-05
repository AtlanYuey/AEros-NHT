import 'package:auto_route/auto_route.dart';
import 'package:eros_n/common/enum.dart';
import 'package:eros_n/common/provider/settings_provider.dart';
import 'package:eros_n/common/provider/tag_translate_provider.dart';
import 'package:eros_n/component/theme/theme.dart';
import 'package:eros_n/component/widget/apple.dart';
import 'package:eros_n/generated/l10n.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'setting_base.dart';

@RoutePage()
class AppearanceSettingPage extends HookConsumerWidget {
  const AppearanceSettingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode =
        ref.watch(settingsProvider.select((settings) => settings.themeMode));
    final useGalleryTint = ref
        .watch(settingsProvider.select((settings) => settings.useGalleryTint));
    final listModel =
        ref.watch(settingsProvider.select((settings) => settings.listModel));
    final showTags =
        ref.watch(settingsProvider.select((settings) => settings.showTags));
    final tagLayoutOnItem = ref
        .watch(settingsProvider.select((settings) => settings.tagLayoutOnItem));
    final isTagTranslate = ref
        .watch(settingsProvider.select((settings) => settings.isTagTranslate));
    final tagTranslateInfo = ref.watch(tagTranslateProvider);
    final isCoverBlur =
        ref.watch(settingsProvider.select((settings) => settings.isCoverBlur));

    return AppleGroupedPage(
      title: L10n.of(context).appearance,
      children: [
        AppleSection(
          header: L10n.of(context).theme,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: SizedBox(
                width: double.infinity,
                child: CupertinoSlidingSegmentedControl<ThemeMode>(
                  groupValue: themeMode,
                  children: {
                    ThemeMode.system: _SegmentLabel(
                      icon: CupertinoIcons.circle_lefthalf_fill,
                      label: L10n.of(context).system,
                    ),
                    ThemeMode.light: _SegmentLabel(
                      icon: CupertinoIcons.sun_max_fill,
                      label: L10n.of(context).light,
                    ),
                    ThemeMode.dark: _SegmentLabel(
                      icon: CupertinoIcons.moon_fill,
                      label: L10n.of(context).dark,
                    ),
                  },
                  onValueChanged: (value) {
                    if (value != null) {
                      HapticFeedback.selectionClick();
                      ref.read(settingsProvider.notifier).setThemeMode(value);
                    }
                  },
                ),
              ),
            ),
            const _AccentColorPicker(),
            AppleSwitchTile(
              title: Text(L10n.of(context).use_gallery_tint),
              subtitle: Text(L10n.of(context).use_gallery_tint_tip),
              value: useGalleryTint,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setUseGalleryTint(value);
              },
            ),
          ],
        ),
        AppleSection(
          header: L10n.of(context).list_style,
          children: [
            AppleOptionTile<ListModel>(
              title: L10n.of(context).list_model,
              value: listModel,
              options: {
                ListModel.list: L10n.of(context).list,
                ListModel.grid: L10n.of(context).grid,
                ListModel.waterfall: L10n.of(context).waterfall,
                ListModel.waterfallCompact: L10n.of(context).waterfall_compact,
              },
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setListModel(value);
              },
            ),
            AppleSwitchTile(
              title: Text(L10n.of(context).show_tags),
              subtitle: Text(L10n.of(context).show_tags_tip),
              value: showTags,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setShowTags(value);
              },
              onLongPress: () {
                ref.read(tagTranslateProvider.notifier).updateNhTags();
              },
            ),
            AppleOptionTile<TagLayoutOnItem>(
              title: L10n.of(context).tag_layout_on_item,
              value: tagLayoutOnItem,
              options: {
                TagLayoutOnItem.wrap: L10n.of(context).wrap,
                TagLayoutOnItem.singleLine: L10n.of(context).single_line,
              },
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setTagLayoutOnItem(value);
              },
            ),
            AppleSwitchTile(
              title: Text(L10n.of(context).tag_translation),
              subtitle: Text(L10n.of(context)
                  .tag_translation_tip(tagTranslateInfo.version ?? '')),
              value: isTagTranslate,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setTagTranslate(value);
              },
              onLongPress: () {
                ref.read(tagTranslateProvider.notifier).updateDb(force: true);
              },
            ),
            AppleSwitchTile(
              title: Text(L10n.of(context).cover_blur),
              value: isCoverBlur,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setCoverBlur(value);
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _SegmentLabel extends StatelessWidget {
  const _SegmentLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: context.palette.label),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Row of color swatches, like the accent color picker on macOS.
class _AccentColorPicker extends HookConsumerWidget {
  const _AccentColorPicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final supportDynamicColors = ref.watch(
        settingsProvider.select((settings) => settings.supportDynamicColors));
    final themeColorLabel = ref
        .watch(settingsProvider.select((settings) => settings.themeColorLabel));
    final brightness = Theme.of(context).brightness;

    final labels = <String>[
      if (supportDynamicColors) ThemeConfig.dynamicThemeColorLabel,
      ...ThemeConfig.accentColors.keys,
    ];

    if (!supportDynamicColors &&
        themeColorLabel == ThemeConfig.dynamicThemeColorLabel) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(settingsProvider.notifier)
            .setThemeColorLabel(ThemeConfig.defaultThemeColorLabel);
      });
    }

    // A label that is no longer offered falls back to the default accent.
    final selectedLabel = labels.contains(themeColorLabel)
        ? themeColorLabel
        : ThemeConfig.defaultThemeColorLabel;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 0, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            L10n.of(context).accent_color,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: 16),
              itemCount: labels.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final label = labels[index];
                final isDynamic = label == ThemeConfig.dynamicThemeColorLabel;
                final selected = label == selectedLabel;
                return Semantics(
                  label: label,
                  selected: selected,
                  button: true,
                  child: PressableScale(
                    scale: 0.88,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      ref
                          .read(settingsProvider.notifier)
                          .setThemeColorLabel(label);
                    },
                    child: _Swatch(
                      color: isDynamic
                          ? null
                          : ThemeConfig.accentOf(label, brightness),
                      selected: selected,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color, required this.selected});

  /// null = dynamic (wallpaper) color.
  final Color? color;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final decoration = color == null
        ? const BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(colors: [
              Color(0xFFFF3B30),
              Color(0xFFFF9500),
              Color(0xFFFFCC00),
              Color(0xFF34C759),
              Color(0xFF007AFF),
              Color(0xFFAF52DE),
              Color(0xFFFF3B30),
            ]),
          )
        : BoxDecoration(shape: BoxShape.circle, color: color);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 34,
      height: 34,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected
              ? (color ?? context.palette.label).withValues(alpha: 0.55)
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: DecoratedBox(
        decoration: decoration,
        child: selected
            ? const Icon(CupertinoIcons.checkmark_alt,
                size: 16, color: Colors.white)
            : null,
      ),
    );
  }
}
