import 'dart:async';
import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:eros_n/common/global.dart';
import 'package:eros_n/common/provider/settings_provider.dart';
import 'package:eros_n/component/theme/theme.dart';
import 'package:eros_n/routes/routes.dart';
import 'package:eros_n/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:native_liquid_glass/native_liquid_glass.dart';
import 'package:window_size/window_size.dart';

import 'component/widget/broken_shield.dart';
import 'component/widget/desktop.dart';
import 'component/widget/liquid_glass.dart';
import 'component/widget/scroll_edge.dart';
import 'component/widget/system_ui_overlay.dart';
import 'generated/l10n.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Global.init();
  await LiquidGlassShader.load();
  await VariableBlurShader.load();

  initLogger();
  runApp(const ProviderScope(
    observers: [
      // LoggerObserver(),
    ],
    child: MyApp(),
  ));
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    doWhenWindowReady(() {
      setWindowVisibility(visible: true);
      setWindowTitle('Eros-N');
    });
  }
}

class MyApp extends StatefulHookConsumerWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state != AppLifecycleState.resumed) {}
    if (state == AppLifecycleState.resumed) {
      clipboardHelper.chkClipboardLink(context, ref);
    }
  }

  @override
  Widget build(BuildContext context) {
    logger.t('build MyApp');
    final themeMode =
        ref.watch(settingsProvider.select((settings) => settings.themeMode));

    final localeCode =
        ref.watch(settingsProvider.select((settings) => settings.localeCode));

    final themeColorLabel = ref
        .watch(settingsProvider.select((settings) => settings.themeColorLabel));

    final dynamicColor = themeColorLabel == ThemeConfig.dynamicThemeColorLabel;

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        final supportDynamicColors =
            lightDynamic != null && darkDynamic != null;

        logger.t('supportDynamicColors: $supportDynamicColors');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref
              .read(settingsProvider.notifier)
              .setSupportDynamicColors(supportDynamicColors);
        });

        late final Color lightAccent;
        late final Color darkAccent;
        if (supportDynamicColors && dynamicColor) {
          lightAccent = lightDynamic.harmonized().primary;
          darkAccent = darkDynamic.harmonized().primary;
        } else {
          lightAccent = ThemeConfig.accentOf(themeColorLabel, Brightness.light);
          darkAccent = ThemeConfig.accentOf(themeColorLabel, Brightness.dark);
        }

        ThemeConfig.lightColorScheme =
            ThemeConfig.buildColorScheme(lightAccent, Brightness.light);
        ThemeConfig.lightTheme =
            ThemeConfig.buildTheme(ThemeConfig.lightColorScheme);

        ThemeConfig.darkColorScheme =
            ThemeConfig.buildColorScheme(darkAccent, Brightness.dark);
        ThemeConfig.darkTheme =
            ThemeConfig.buildTheme(ThemeConfig.darkColorScheme);

        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          routeInformationParser: erosRouter.defaultRouteParser(),
          routeInformationProvider: erosRouter.routeInfoProvider(),
          routerDelegate: AutoRouterDelegate(
            erosRouter,
            navigatorObservers: () => [
              AppRouteObserver(),
              FlutterSmartDialog.observer,
              // Hides native Liquid Glass views under Flutter popups.
              LiquidGlassNavigatorObserver(),
            ],
          ),
          builder: SystemUIOverlay.init(
            builder: FlutterSmartDialog.init(
              styleBuilder: (child) {
                if (Platform.isWindows ||
                    Platform.isMacOS ||
                    Platform.isLinux) {
                  return Desktop(child: child);
                }
                return child;
              },
              builder: BrokenShield.init(),
            ),
          ),
          // builder: (BuildContext context, Widget? child) {
          //   final widget =
          //       BrokenShield(child: FlutterSmartDialog.init()(context, child));
          //   if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
          //     return Desktop(child: widget);
          //   }
          //   return widget;
          // },
          locale: locale(localeCode),
          onGenerateTitle: (BuildContext context) => L10n.of(context).app_title,
          // debugShowCheckedModeBanner: false,
          theme: ThemeConfig.lightTheme,
          darkTheme: ThemeConfig.darkTheme,
          themeMode: themeMode,
          supportedLocales: [...L10n.delegate.supportedLocales],
          localizationsDelegates: const [
            L10n.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
        );
      },
    );
  }
}

class LoggerObserver extends ProviderObserver {
  @override
  void didUpdateProvider(
    ProviderBase provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    logger.d('''
{
  "provider": "${provider.name ?? provider.runtimeType}",
  "previousValue": "$previousValue",
  "newValue": "$newValue"
}''');
  }
}

Locale? locale(String localeCode) {
  if (localeCode.isEmpty) {
    return null;
  }
  final parts = localeCode.split('_');
  return Locale(parts[0], parts[1]);
}
