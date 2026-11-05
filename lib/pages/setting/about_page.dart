import 'package:auto_route/auto_route.dart';
import 'package:eros_n/common/global.dart';
import 'package:eros_n/component/theme/theme.dart';
import 'package:eros_n/component/widget/apple.dart';
import 'package:eros_n/generated/l10n.dart';
import 'package:eros_n/routes/routes.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

@RoutePage()
class AboutPage extends StatelessWidget {
  const AboutPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    return AppleGroupedPage(
      title: L10n.of(context).about,
      children: [
        const SizedBox(height: 12),
        Center(
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRSuperellipse(
              borderRadius: BorderRadius.circular(22),
              child: Image.asset(
                'assets/images/app_icon.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          L10n.of(context).app_title,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text(
          '${L10n.of(context).version} ${Global.packageInfo.version} '
          '(${Global.packageInfo.buildNumber})',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: palette.secondaryLabel),
        ),
        AppleSection(
          children: [
            AppleListTile(
              title: const Text('Author'),
              value: 'erosTeam',
              onTap: () => launchUrlString(
                'https://github.com/erosTeam',
                mode: LaunchMode.externalApplication,
              ),
            ),
            AppleListTile(
              title: const Text('GitHub'),
              value: 'eros_n',
              trailing: Icon(
                CupertinoIcons.arrow_up_right_square,
                size: 18,
                color: palette.tertiaryLabel,
              ),
              onTap: () => launchUrlString(
                'https://github.com/erosTeam/eros_n',
                mode: LaunchMode.externalApplication,
              ),
            ),
            AppleListTile(
              title: const Text('License'),
              onTap: () {
                erosRouter.pushNamed(NHRoutes.license);
              },
            ),
          ],
        ),
      ],
    );
  }
}
