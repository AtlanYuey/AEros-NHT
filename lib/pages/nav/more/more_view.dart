import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:eros_n/common/global.dart';
import 'package:eros_n/generated/l10n.dart';
import 'package:eros_n/pages/nav/index/index_provider.dart';
import 'package:eros_n/pages/user/user_provider.dart';
import 'package:eros_n/routes/routes.dart';
import 'package:eros_n/utils/logger.dart';
import 'package:eros_n/component/theme/theme.dart';
import 'package:eros_n/component/widget/apple.dart';
import 'package:eros_n/utils/get_utils/extensions/context_extensions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

@RoutePage()
class MorePage extends StatefulHookConsumerWidget {
  const MorePage({super.key});

  @override
  ConsumerState<MorePage> createState() => _MorePageState();
}

class _MorePageState extends ConsumerState<MorePage>
    with AutomaticKeepAliveClientMixin {
  final ScrollController scrollController = ScrollController();
  IndexNotifier get indexProviderNoti => ref.read(indexProvider.notifier);

  @override
  void initState() {
    super.initState();
    indexProviderNoti.addScrollController(scrollController);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.groupedBackground,
      body: CustomScrollView(
        controller: scrollController,
        physics: kAppleScrollPhysics,
        slivers: [
          AppleSliverNavBar(
            title: L10n.of(context).more,
            heroTag: 'nav_more',
            pageBackgroundColor: palette.groupedBackground,
          ),
          SliverSafeArea(
            top: false,
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const _AccountSection(),
                AppleSection(
                  dividerIndent: appleContentInset(context) + 43,
                  children: [
                    AppleListTile(
                      leading: const AppleIconBadge(
                        icon: CupertinoIcons.arrow_down_circle_fill,
                        color: CupertinoColors.systemBlue,
                      ),
                      title: Text(L10n.of(context).download),
                      onTap: () {
                        showAppleAlert<void>(
                          context: context,
                          title: L10n.of(context).download,
                          message: L10n.of(context).feature_unavailable,
                          actions: [
                            AppleAlertAction(
                              label: L10n.of(context).ok,
                              isDefault: true,
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
                AppleSection(
                  dividerIndent: appleContentInset(context) + 43,
                  children: [
                    AppleListTile(
                      leading: const AppleIconBadge(
                        icon: CupertinoIcons.gear_alt_fill,
                        color: CupertinoColors.systemGrey,
                      ),
                      title: Text(L10n.of(context).settings),
                      onTap: () {
                        erosRouter.pushNamed(NHRoutes.settings);
                      },
                    ),
                    AppleListTile(
                      leading: const AppleIconBadge(
                        icon: CupertinoIcons.info_circle_fill,
                        color: CupertinoColors.systemIndigo,
                      ),
                      title: Text(L10n.of(context).about),
                      onTap: () {
                        erosRouter.pushNamed(NHRoutes.about);
                      },
                    ),
                  ],
                ),
                SizedBox(height: 40 + context.mediaQueryPadding.bottom),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class _AccountSection extends HookConsumerWidget {
  const _AccountSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final palette = context.palette;
    final theme = Theme.of(context);

    final avatar = Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            CupertinoColors.systemGrey2.resolveFrom(context),
            CupertinoColors.systemGrey.resolveFrom(context),
          ],
        ),
        image: user.isLogin && user.avatarUrl != null
            ? DecorationImage(
                image: CachedNetworkImageProvider(user.avatarUrl ?? ''),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: user.isLogin && user.avatarUrl != null
          ? null
          : const Icon(CupertinoIcons.person_fill,
              color: Colors.white, size: 34),
    );

    return AppleSection(
      children: [
        AppleListTile(
          minHeight: 84,
          leading: avatar,
          title: Text(
            user.isLogin ? (user.userName ?? '...') : L10n.of(context).login,
            style: theme.textTheme.titleLarge,
          ),
          subtitle: Text(
            user.isLogin ? 'nhentai.net' : L10n.of(context).sign_in_tip,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: palette.secondaryLabel),
          ),
          onTap: () {
            if (!user.isLogin) {
              erosRouter.pushNamed(NHRoutes.login);
              return;
            }
            logger.d('logout $user');
            showAppleAlert<void>(
              context: context,
              title: L10n.of(context).logout,
              message: L10n.of(context).logout_tip,
              actions: [
                AppleAlertAction(
                  label: L10n.of(context).cancel,
                  isDefault: true,
                ),
                AppleAlertAction(
                  label: L10n.of(context).logout,
                  isDestructive: true,
                  onPressed: () {
                    ref.read(userProvider.notifier).logout();
                  },
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
