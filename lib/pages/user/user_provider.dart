import 'dart:io';

import 'package:eros_n/common/global.dart';
import 'package:eros_n/component/models/index.dart';
import 'package:eros_n/network/app_dio/api_v2_auth.dart';
import 'package:eros_n/network/request.dart';
import 'package:eros_n/utils/logger.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart' as iaw;
import 'package:hooks_riverpod/hooks_riverpod.dart';

class UserNotifier extends StateNotifier<User> {
  UserNotifier(super.state);

  /// Finish a website login: keep the API tokens from its cookies and load
  /// the profile. Returns false when the cookies hold no token yet.
  Future<bool> loginWithCookies(Iterable<Cookie> cookies) async {
    if (!await ApiV2Auth.saveFromCookies(cookies)) {
      return false;
    }
    await loginGetMore();
    return true;
  }

  Future<void> loginGetMore() async {
    final token = ApiV2Auth.accessToken;
    if (token == null) {
      return;
    }
    state = state.copyWith(sessionid: token);
    hiveHelper.setUser(state);

    final user = await getCurrentUser();
    logger.d('current user ${user.userName}');
    state = state.copyWith(
      userName: user.userName,
      userId: user.userId,
      userUrl: user.userUrl,
      avatarUrl: user.avatarUrl,
    );
    hiveHelper.setUser(state);
  }

  Future<void> logout() async {
    await ApiV2Auth.clear();
    Global.cookieJar.deleteAll();
    iaw.CookieManager.instance().deleteAllCookies();
    state = const User();
    hiveHelper.setUser(state);
  }
}

final userProvider = StateNotifierProvider<UserNotifier, User>((ref) {
  final saved = hiveHelper.getUser();
  // Sessions from the old cookie based site cannot call the API; ask for a
  // new login instead of failing on every account request.
  if (saved.isLogin && !ApiV2Auth.isLoggedIn) {
    hiveHelper.setUser(const User());
    return UserNotifier(const User());
  }
  return UserNotifier(saved);
});
