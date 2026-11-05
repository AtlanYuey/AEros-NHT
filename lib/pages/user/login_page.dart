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
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  late final FocusNode _usernameFocusNode;
  late final FocusNode _passwordFocusNode;
  late bool _obscurePassword;
  late bool _logining;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
    _usernameFocusNode = FocusNode();
    _passwordFocusNode = FocusNode();
    _obscurePassword = true;
    _logining = false;
  }

  @override
  void dispose() {
    super.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocusNode.dispose();
    _passwordFocusNode.dispose();
  }

  Future<void> _login() async {
    logger.d('Username: ${_usernameController.text}');

    if (_logining) {
      return;
    }

    setState(() {
      _logining = true;
    });

    try {
      final result = await ref.read(userProvider.notifier).login(
            username: _usernameController.text.trim(),
            password: _passwordController.text.trim(),
          );
      if (result) {
        erosRouter.pop();
        ref.read(userProvider.notifier).loginGetMore();
      }
    } on NhError catch (e) {
      if (e.type == NhErrorType.loginCaptcha) {
        // log in with captcha
        logger.e('login need captcha');
        showAppleAlert<void>(
          context: context,
          title: L10n.of(context).login_need_captcha,
          message: L10n.of(context).please_login_web,
          actions: [
            AppleAlertAction(
              label: L10n.of(context).ok,
              isDefault: true,
              onPressed: _loginWithWebView,
            ),
          ],
        );
      } else if (e.type == NhErrorType.loginInvalid) {
        // log invalid
        logger.e('login invalid');
        context.showSnackBar(L10n.of(context).login_invalid);
      } else {
        logger.e(e);
        rethrow;
      }
    } catch (e) {
      logger.e(e);
      rethrow;
    } finally {
      setState(() {
        _logining = false;
      });
    }
  }

  Future<void> _loginWithWebView() async {
    final cookies = await erosRouter.pushNamed<List<Cookie>>(NHRoutes.webLogin);
    logger.d('==>> cookies: $cookies');
    if (cookies != null) {
      erosRouter.pop();
      await Global.cookieJar.delete(Uri.parse(NHConst.baseUrl));
      await Global.cookieJar
          .saveFromResponse(Uri.parse(NHConst.baseUrl), cookies);
      await ref.read(userProvider.notifier).loginGetMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final theme = Theme.of(context);
    final fieldStyle = theme.textTheme.bodyLarge;

    return Scaffold(
      backgroundColor: palette.groupedBackground,
      body: CustomScrollView(
        physics: kAppleScrollPhysics,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                  'nhentai.net',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: palette.secondaryLabel),
                ),
                AppleSection(
                  children: [
                    CupertinoTextField(
                      controller: _usernameController,
                      focusNode: _usernameFocusNode,
                      placeholder: L10n.of(context).username,
                      style: fieldStyle,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 13),
                      decoration: null,
                      autocorrect: false,
                      textInputAction: TextInputAction.next,
                      prefix: Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Icon(CupertinoIcons.person,
                            size: 20, color: palette.secondaryLabel),
                      ),
                      onEditingComplete: () {
                        _usernameFocusNode.unfocus();
                        FocusScope.of(context).requestFocus(_passwordFocusNode);
                      },
                    ),
                    CupertinoTextField(
                      controller: _passwordController,
                      focusNode: _passwordFocusNode,
                      placeholder: L10n.of(context).password,
                      style: fieldStyle,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 13),
                      decoration: null,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      prefix: Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Icon(CupertinoIcons.lock,
                            size: 20, color: palette.secondaryLabel),
                      ),
                      suffix: CupertinoButton(
                        padding: const EdgeInsets.only(right: 12),
                        minimumSize: const Size(32, 32),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        child: Icon(
                          _obscurePassword
                              ? CupertinoIcons.eye
                              : CupertinoIcons.eye_slash,
                          size: 20,
                          color: palette.secondaryLabel,
                        ),
                      ),
                      onEditingComplete: () {
                        _passwordFocusNode.unfocus();
                        _login();
                      },
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
                  child: CapsuleButton(
                    label: L10n.of(context).login,
                    height: 50,
                    expand: true,
                    loading: _logining,
                    onPressed: () async {
                      await _login();
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CupertinoButton(
                      onPressed: _loginWithWebView,
                      child: Text(
                        L10n.of(context).login_by_web,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: theme.colorScheme.primary),
                      ),
                    ),
                    Container(
                      width: 0.5,
                      height: 14,
                      color: palette.separator,
                    ),
                    CupertinoButton(
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
                  ],
                ),
                if (kDebugMode)
                  CupertinoButton(
                      onPressed: () async {
                        final u = await getInfoFromIndex(refresh: true);
                        logger.d('==>> u: $u');
                      },
                      child: const Text('Get info from Index')),
                if (kDebugMode)
                  CupertinoButton(
                      onPressed: () async {
                        final userUrl = ref.read(userProvider).userUrl ?? '';
                        logger.d('==>> userUrl: $userUrl');
                        if (userUrl.isNotEmpty) {
                          final u = await getInfoFromUserPage(
                              url: userUrl, refresh: true);
                          logger.d('==>> u: $u');
                        }
                      },
                      child: const Text('Get info from user page')),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
