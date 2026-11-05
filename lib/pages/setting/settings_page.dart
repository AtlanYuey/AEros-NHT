import 'package:auto_route/auto_route.dart';
import 'package:eros_n/common/global.dart';
import 'package:eros_n/component/widget/apple.dart';
import 'package:eros_n/generated/l10n.dart';
import 'package:eros_n/routes/routes.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

@RoutePage()
class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppleGroupedPage(
      title: L10n.of(context).settings,
      children: [
        AppleSection(
          dividerIndent: 59,
          children: [
            AppleListTile(
              leading: const AppleIconBadge(
                icon: CupertinoIcons.gear_alt_fill,
                color: CupertinoColors.systemGrey,
              ),
              title: Text(L10n.of(context).general),
              onTap: () {
                erosRouter.pushNamed(NHRoutes.generalSetting);
              },
            ),
            AppleListTile(
              leading: const AppleIconBadge(
                icon: CupertinoIcons.textformat_size,
                color: CupertinoColors.systemBlue,
              ),
              title: Text(L10n.of(context).appearance),
              onTap: () {
                erosRouter.pushNamed(NHRoutes.appearanceSetting);
              },
            ),
            AppleListTile(
              leading: const AppleIconBadge(
                icon: CupertinoIcons.book_fill,
                color: CupertinoColors.systemOrange,
              ),
              title: Text(L10n.of(context).read),
              onTap: () {
                erosRouter.pushNamed(NHRoutes.readSetting);
              },
            ),
          ],
        ),
        AppleSection(
          dividerIndent: 59,
          children: [
            AppleListTile(
              leading: const AppleIconBadge(
                icon: CupertinoIcons.hammer_fill,
                color: CupertinoColors.systemPurple,
              ),
              title: Text(L10n.of(context).advanced),
              onTap: () {
                erosRouter.pushNamed(NHRoutes.advancedSetting);
              },
            ),
          ],
        ),
      ],
    );
  }
}
