import 'package:auto_route/auto_route.dart';
import 'package:eros_n/common/provider/tag_translate_provider.dart';
import 'package:eros_n/component/widget/apple.dart';
import 'package:eros_n/generated/l10n.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

@RoutePage()
class AdvancedSettingPage extends HookConsumerWidget {
  const AdvancedSettingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allNhTag = ref.watch(allNhTagProvider);
    return AppleGroupedPage(
      title: L10n.of(context).advanced,
      children: [
        AppleSection(
          header: L10n.of(context).tag,
          footer: 'Long press to update',
          children: [
            AppleListTile(
              title: Text(L10n.of(context).tags_data),
              value: allNhTag.when(
                data: (data) => '${data.length}',
                loading: () => '…',
                error: (error, stack) => 'error',
              ),
              trailing: allNhTag.isLoading
                  ? const CupertinoActivityIndicator(radius: 8)
                  : null,
              onLongPress: () {
                ref.read(tagTranslateProvider.notifier).updateNhTags();
              },
            ),
          ],
        ),
      ],
    );
  }
}
