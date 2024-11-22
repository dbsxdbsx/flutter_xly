import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:oktoast/oktoast.dart';
import 'package:window_manager/window_manager.dart';
import 'package:xly/src/exit.dart';
import 'package:xly/src/float_panel.dart';
import 'package:xly/src/platform.dart';
import 'package:xly/src/splash.dart';
import 'package:xly/src/toast.dart';

class MyRoute<T extends GetxController> {
  final String path;
  final Widget page;
  final T Function() controller;

  MyRoute({
    required this.path,
    required this.page,
    required this.controller,
  });

  void registerController() {
    Get.lazyPut<T>(controller);
  }
}

class MyApp extends StatelessWidget {
  final Size designSize;
  final ThemeData? theme;
  final List<MyRoute> routes;
  final Widget Function(BuildContext, Widget?)? appBuilder;
  final String appName;
  final bool useOKToast;
  final bool dragToMoveArea;
  final bool showDebugTag;
  final MySplash? splash;
  final LogicalKeyboardKey? keyToRollBack;
  final Duration exitGapTime;
  final String exitInfoText;
  final String backInfoText;
  final Transition pageTransitionStyle;
  final Duration pageTransitionDuration;
  final MyFloatPanel? globalFloatPanel;
  final GlobalKey<NavigatorState>? navigatorKey;

  const MyApp._({
    required this.designSize,
    this.theme,
    this.splash,
    required this.routes,
    this.appBuilder,
    required this.appName,
    this.useOKToast = true,
    this.dragToMoveArea = true,
    this.showDebugTag = true,
    this.keyToRollBack,
    this.exitGapTime = const Duration(seconds: 2),
    this.exitInfoText = '再按一次退出App',
    this.backInfoText = '再按一次返回上一页',
    this.pageTransitionStyle = Transition.fade,
    this.pageTransitionDuration = const Duration(milliseconds: 300),
    this.globalFloatPanel,
    this.navigatorKey,
  });

  static Future<void> initialize({
    required Size designSize,
    String appName = 'MyApp',
    bool ensureScreenSize = true,
    bool initializeWidgetsBinding = true,
    bool initializeWindowManager = true,
    required List<MyRoute> routes,
    Widget Function(BuildContext, Widget?)? appBuilder,
    bool setTitleBarHidden = true,
    bool setWindowButtonVisibility = false,
    bool setSkipTaskbar = false,
    bool setResizable = true,
    bool setMaximizable = true,
    bool centerWindow = true,
    bool focusWindow = true,
    bool showWindow = true,
    bool setAspectRatio = true,
    bool useOKToast = true,
    bool dragToMoveArea = true,
    bool showDebugTag = true,
    ThemeData? theme,
    Size? minimumSize,
    MySplash? splash,
    LogicalKeyboardKey? keyToRollBack,
    String exitInfoText = '再按一次退出App',
    String backInfoText = '再按一次返回上一页',
    Duration exitGapTime = const Duration(seconds: 2),
    Transition pageTransitionStyle = Transition.fade,
    Duration pageTransitionDuration = const Duration(milliseconds: 300),
    MyFloatPanel? globalFloatPanel,
    GlobalKey<NavigatorState>? navigatorKey,
  }) async {
    if (ensureScreenSize) {
      await ScreenUtil.ensureScreenSize();
    }
    if (initializeWidgetsBinding) {
      WidgetsFlutterBinding.ensureInitialized();
    }

    if (MyPlatform.isDesktop) {
      if (initializeWindowManager) {
        await _initializeWindowManager(
          designSize,
          appName,
          setTitleBarHidden: setTitleBarHidden,
          setWindowButtonVisibility: setWindowButtonVisibility,
          setSkipTaskbar: setSkipTaskbar,
          setResizable: setResizable,
          setMaximizable: setMaximizable,
          centerWindow: centerWindow,
          focusWindow: focusWindow,
          showWindow: showWindow,
          setAspectRatio: setAspectRatio,
          minimumSize: minimumSize,
        );
      }
    }

    runApp(MyApp._(
      designSize: designSize,
      theme: theme,
      routes: routes,
      appBuilder: appBuilder,
      appName: appName,
      useOKToast: useOKToast,
      dragToMoveArea: dragToMoveArea,
      showDebugTag: showDebugTag,
      splash: splash,
      keyToRollBack: keyToRollBack,
      exitGapTime: exitGapTime,
      exitInfoText: exitInfoText,
      backInfoText: backInfoText,
      pageTransitionStyle: pageTransitionStyle,
      pageTransitionDuration: pageTransitionDuration,
      globalFloatPanel: globalFloatPanel,
      navigatorKey: navigatorKey,
    ));
  }

  static Future<void> _initializeWindowManager(
    Size defaultSize,
    String appName, {
    bool setTitleBarHidden = true,
    bool setWindowButtonVisibility = false,
    bool setSkipTaskbar = false,
    bool setResizable = true,
    bool setMinimizable = true,
    bool setMaximizable = true,
    bool centerWindow = true,
    bool focusWindow = true,
    bool showWindow = true,
    bool setAspectRatio = true,
    Size? minimumSize,
  }) async {
    await WindowManager.instance.ensureInitialized();
    await windowManager.waitUntilReadyToShow();
    await windowManager.setPreventClose(false);

    if (setTitleBarHidden) {
      await windowManager.setTitleBarStyle(TitleBarStyle.hidden,
          windowButtonVisibility: setWindowButtonVisibility);
    }
    await windowManager.setTitle(appName);
    await windowManager.setSize(defaultSize);
    if (setAspectRatio) {
      await windowManager
          .setAspectRatio(defaultSize.width / defaultSize.height);
    }

    if (minimumSize != null) {
      await windowManager.setMinimumSize(minimumSize);
    }
    await windowManager.setMinimizable(setMinimizable);
    await windowManager.setMaximizable(setMaximizable);
    await windowManager.setResizable(setResizable);

    if (setSkipTaskbar) await windowManager.setSkipTaskbar(setSkipTaskbar);

    if (centerWindow) await windowManager.center();
    if (focusWindow) await windowManager.focus();
    if (showWindow) await windowManager.show();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: designSize,
      builder: (context, child) => _buildApp(context),
    );
  }

  Widget _buildApp(BuildContext context) {
    Widget app = GetMaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: showDebugTag,
      title: appName,
      initialRoute: splash != null
          ? '/splash'
          : (routes.isNotEmpty ? routes.first.path : '/'),
      getPages: [
        if (splash != null)
          GetPage(
            name: '/splash',
            page: () => splash!,
            transition: Transition.fade,
            transitionDuration: Duration.zero,
          ),
        ...routes.map((route) => GetPage(
              name: route.path,
              page: () => route.page,
              binding: BindingsBuilder(() {
                route.registerController();
              }),
              transition: pageTransitionStyle,
              transitionDuration: pageTransitionDuration,
            )),
      ],
      builder: (context, child) => _buildAppContent(context, child),
      theme: _buildTheme(),
      defaultTransition: pageTransitionStyle,
      transitionDuration: pageTransitionDuration,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'CN'),
        Locale('en', 'US'),
      ],
      locale: const Locale('zh', 'CN'),
    );

    return useOKToast ? OKToast(child: app) : app;
  }

  ThemeData _buildTheme() {
    return theme ??
        ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        );
  }

  Widget _buildAppContent(BuildContext context, Widget? child) {
    Widget processedChild = _buildMediaQueryWrapper(context, child);
    processedChild = _buildSafeArea(processedChild);

    if (appBuilder != null) {
      processedChild = appBuilder!(context, processedChild);
    }

    processedChild = _buildKeyboardShortcuts(processedChild);

    // 如果提供了全局浮动面板，则添加它
    if (globalFloatPanel != null) {
      processedChild = Stack(
        children: [
          processedChild,
          globalFloatPanel!,
        ],
      );
    }

    return processedChild;
  }

  Widget _buildMediaQueryWrapper(BuildContext context, Widget? child) {
    return MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: const TextScaler.linear(1.0)),
      child: child!,
    );
  }

  Widget _buildKeyboardShortcuts(Widget child) {
    DateTime? lastPressedTime;
    String? lastRoute;

    Future<void> handleRollBackIntent() async {
      final now = DateTime.now();
      final currentRoute = Get.currentRoute;

      // 检查是否切换了路由或者超过了时间间隔
      bool shouldResetTimer = lastRoute != currentRoute ||
          lastPressedTime == null ||
          now.difference(lastPressedTime!) > exitGapTime;

      if (shouldResetTimer) {
        lastPressedTime = now;
        lastRoute = currentRoute;
        if (currentRoute == routes.first.path) {
          toast(exitInfoText, duration: exitGapTime);
        } else {
          toast(backInfoText, duration: exitGapTime);
        }
      } else {
        if (currentRoute == routes.first.path) {
          await MyApp.exit();
        } else {
          Get.back();
        }
        // 重置计时器和路由记录
        lastPressedTime = null;
        lastRoute = null;
      }
    }

    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.select): const ActivateIntent(),
        if (keyToRollBack != null)
          LogicalKeySet(keyToRollBack!):
              VoidCallbackIntent(handleRollBackIntent),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          VoidCallbackIntent: CallbackAction<VoidCallbackIntent>(
            onInvoke: (VoidCallbackIntent intent) => intent.callback(),
          ),
        },
        child: child,
      ),
    );
  }

  Widget _buildSafeArea(Widget child) {
    return SafeArea(
      child: dragToMoveArea ? DragToMoveArea(child: child) : child,
    );
  }

  /// 静态方法用于退出应用
  static Future<void> exit() async {
    await exitApp();
  }
}

class VoidCallbackIntent extends Intent {
  final VoidCallback callback;

  const VoidCallbackIntent(this.callback);
}
