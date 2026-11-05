import 'dart:io';

import 'package:auto_route/auto_route.dart';

import 'package:eros_n/common/const/const.dart';
import 'package:eros_n/common/global.dart';
import 'package:eros_n/component/exception/error.dart';
import 'package:eros_n/generated/l10n.dart';
import 'package:eros_n/network/request.dart';
import 'package:eros_n/pages/user/user_provider.dart';
import 'package:eros_n/routes/routes.dart';
import 'package:eros_n/utils/get_utils/get_utils.dart';
import 'package:eros_n/utils/logger.dart';
import 'package:flutter/foundation.dart';
import 'package:eros_n/component/theme/theme.dart';
import 'package:eros_n/component/widget/apple.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

@RoutePage()
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  bool _logining = false;

  Future<void> _loginWithWebView() async {
    if (_logining) {
      return;
    }
    final cookies = await erosRouter.pushNamed<List<Cookie>>(NHRoutes.webLogin);
    logger.d('web login cookies: ${cookies?.map((e) => e.name)}');
    if (cookies == null || !mounted) {
      return;
    }
    setState(() => _logining = true);
    try {
      final ok =
          await ref.read(userProvider.notifier).loginWithCookies(cookies);
      if (!mounted) {
        return;
      }
      if (ok) {
        erosRouter.pop();
      } else {
        context.showSnackBar(L10n.of(context).login_invalid);
      }
    } catch (e) {
      logger.e('login: $e');
      if (mounted) {
        context.showSnackBar('$e');
      }
    } finally {
      if (mounted) {
        setState(() => _logining = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final theme = Theme.of(context);

    Widget feature(IconData icon, String text) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 24, color: theme.colorScheme.primary),
              const SizedBox(width: 14),
              Expanded(
                child: Text(text, style: theme.textTheme.bodyMedium),
              ),
            ],
          ),
        );

    return Scaffold(
      backgroundColor: palette.groupedBackground,
      body: CustomScrollView(
        physics: kAppleScrollPhysics,
        slivers: [
          AppleSliverNavBar(
            title: L10n.of(context).login,
            pageBackgroundColor: palette.groupedBackground,
            backgroundColor: palette.brightness == Brightness.dark
                ? palette.bar
                : const Color(0xEBF2F2F7),
          ),
          SliverSafeArea(
            top: false,
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 16),
                Center(
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.colorScheme.primary.withValues(alpha: 0.75),
                          theme.colorScheme.primary,
                        ],
                      ),
                    ),
                    child: const Icon(
                      CupertinoIcons.person_fill,
                      size: 46,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  L10n.of(context).sign_in_tip,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                ),
                AppleSection(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                      child: Column(
                        children: [
                          feature(CupertinoIcons.lock_shield,
                              '在 nhentai.net 官方页面登录，人机验证（Turnstile）会在页面中显示'),
                          feature(
                              CupertinoIcons.heart, '登录后可同步收藏、收藏/取消收藏与发表评论'),
                          feature(CupertinoIcons.eye_slash,
                              '账号密码只在官方网页中输入，App 只保存登录令牌'),
                        ],
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
                  child: CapsuleButton(
                    label: '前往 nhentai.net 登录',
                    icon: CupertinoIcons.arrow_up_right_square,
                    height: 50,
                    expand: true,
                    loading: _logining,
                    onPressed: _loginWithWebView,
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: CupertinoButton(
                    onPressed: () {
                      erosRouter.push(NhWebViewRoute(
                        initialUrl: NHConst.registerUrl,
                        title: L10n.of(context).register,
                      ));
                    },
                    child: Text(
                      L10n.of(context).register,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.primary),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
