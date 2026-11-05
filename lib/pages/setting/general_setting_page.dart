import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:eros_n/common/const/const.dart';
import 'package:eros_n/common/provider/settings_provider.dart';
import 'package:eros_n/component/widget/apple.dart';
import 'package:eros_n/generated/l10n.dart';
import 'package:eros_n/pages/setting/setting_base.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:open_by_default/open_by_default.dart';

@RoutePage()
class GeneralSettingPage extends HookConsumerWidget {
  const GeneralSettingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeCode =
        ref.watch(settingsProvider.select((settings) => settings.localeCode));
    final hideBottomNavigationOnScroll = ref.watch(settingsProvider
        .select((settings) => settings.hideBottomNavigationOnScroll));
    final clipboardDetection = ref.watch(
        settingsProvider.select((settings) => settings.clipboardDetection));

    final localeOptions = <String, String>{'': L10n.of(context).system};
    for (final locale in L10n.delegate.supportedLocales) {
      final code = '${locale.languageCode}_${locale.countryCode ?? ''}';
      localeOptions[code] = NHConst.localeMap[code] ?? code;
    }

    return AppleGroupedPage(
      title: L10n.of(context).general,
      children: [
        AppleSection(
          children: [
            AppleOptionTile<String>(
              title: L10n.of(context).language,
              options: localeOptions,
              value: localeCode,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setLocaleCode(value);
              },
            ),
          ],
        ),
        AppleSection(
          children: [
            AppleSwitchTile(
              title: Text(L10n.of(context).hide_bottom_navigation_on_scroll),
              value: hideBottomNavigationOnScroll,
              onChanged: (value) {
                ref
                    .read(settingsProvider.notifier)
                    .setHideBottomNavigationOnScroll(value);
              },
            ),
            AppleSwitchTile(
              title: Text(L10n.of(context).clipboard_detection),
              value: clipboardDetection,
              onChanged: (value) {
                ref
                    .read(settingsProvider.notifier)
                    .setClipboardDetection(value);
              },
            ),
          ],
        ),
        if (Platform.isAndroid)
          AppleSection(
            footer: L10n.of(context).open_supported_links_tip,
            children: [
              AppleListTile(
                title: Text(L10n.of(context).open_supported_links),
                onTap: OpenByDefault.open,
              ),
            ],
          ),
      ],
    );
  }
}
