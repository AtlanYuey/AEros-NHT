import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:eros_n/common/enum.dart';
import 'package:eros_n/common/provider/settings_provider.dart';
import 'package:eros_n/component/widget/apple.dart';
import 'package:eros_n/generated/l10n.dart';
import 'package:eros_n/pages/read/read_provider.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'setting_base.dart';

@RoutePage()
class ReadSettingPage extends HookConsumerWidget {
  const ReadSettingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readModel =
        ref.watch(settingsProvider.select((settings) => settings.readModel));
    return AppleGroupedPage(
      title: L10n.of(context).read,
      children: [
        AppleSection(
          header: L10n.of(context).display,
          children: [
            const FullScreenListTile(),
            AppleOptionTile<ReadModel>(
              title: L10n.of(context).read_model,
              value: readModel,
              options: readModelOptions(context),
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setReadModel(value);
              },
            ),
          ],
        ),
        AppleSection(
          children: [
            if (Platform.isAndroid) const VolumeKeyTurnPageListTile(),
            const AutoReadIntervalListTile(),
            const PreloadPagesCountListTile(),
          ],
        ),
      ],
    );
  }
}

Map<ReadModel, String> readModelOptions(BuildContext context) => {
      ReadModel.leftToRight: L10n.of(context).left_to_right,
      ReadModel.rightToLeft: L10n.of(context).right_to_left,
      ReadModel.webtoon: L10n.of(context).webtoon,
      ReadModel.curlVertical: L10n.of(context).curl_vertical,
      ReadModel.vertical: L10n.of(context).vertical,
    };

class VolumeKeyTurnPageListTile extends HookConsumerWidget {
  const VolumeKeyTurnPageListTile({
    Key? key,
    this.onReadView = false,
  }) : super(key: key);
  final bool onReadView;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final volumeKeyTurnPage = ref.watch(
        settingsProvider.select((settings) => settings.volumeKeyTurnPage));
    return AppleSwitchTile(
      title: Text(L10n.of(context).volume_key_turn_page),
      value: volumeKeyTurnPage,
      onChanged: (value) {
        ref.read(settingsProvider.notifier).setVolumeKeyTurnPage(value);

        if (onReadView) {
          if (value) {
            ref.read(readProvider.notifier).addVolumeKeydownListen();
          } else {
            ref.read(readProvider.notifier).closeVolumeKeydownListen();
          }
        }
      },
    );
  }
}

class FullScreenListTile extends HookConsumerWidget {
  const FullScreenListTile({
    Key? key,
    this.onReadView = false,
  }) : super(key: key);
  final bool onReadView;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fullScreenReader = ref.watch(
        settingsProvider.select((settings) => settings.fullScreenReader));
    return AppleSwitchTile(
      title: Text(L10n.of(context).full_screen),
      value: fullScreenReader,
      onChanged: (value) {
        ref.read(settingsProvider.notifier).setFullScreenReader(value);

        if (onReadView) {
          if (value) {
            ref.read(readProvider.notifier).setFullscreen();
          } else {
            ref.read(readProvider.notifier).unFullscreen();
          }
        }
      },
    );
  }
}

class PreloadPagesCountListTile extends HookConsumerWidget {
  const PreloadPagesCountListTile({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preloadPageCount = ref.watch(
        settingsProvider.select((settings) => settings.preloadPagesCount));
    return AppleSliderTile(
      title: L10n.of(context).preload_pages_count,
      valueLabel: '$preloadPageCount',
      value: preloadPageCount.toDouble(),
      min: 0,
      max: 7,
      divisions: 7,
      onChanged: (value) {
        ref.read(settingsProvider.notifier).setPreloadPagesCount(value.round());
      },
    );
  }
}

class AutoReadIntervalListTile extends HookConsumerWidget {
  const AutoReadIntervalListTile({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final autoReadInterval = ref.watch(
        settingsProvider.select((settings) => settings.autoReadInterval));

    return AppleSliderTile(
      title: L10n.of(context).auto_read_interval,
      valueLabel: '${autoReadInterval}s',
      value: autoReadInterval.toDouble(),
      min: 0.5,
      max: 10,
      divisions: 19,
      onChanged: (value) {
        ref.read(settingsProvider.notifier).setAutoReadInterval(value);
      },
    );
  }
}
