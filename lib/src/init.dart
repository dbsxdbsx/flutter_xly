import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:oktoast/oktoast.dart';
import 'package:window_manager/window_manager.dart';
import 'package:xly/src/exit.dart';
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
  final bool escToExit;
  final Duration exitGapTime;
  final String exitInfoText;

  const MyApp._({
    required this.designSize,
    this.theme,
    required this.routes,
    this.appBuilder,
    required this.appName,
    this.useOKToast = true,
    this.dragToMoveArea = true,
    this.showDebugTag = true,
    this.splash,
    this.escToExit = true,
    this.exitGapTime = const Duration(seconds: 2),
    this.exitInfoText = '再按一次退出App',
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
    bool escToExit = true,
    Duration exitGapTime = const Duration(seconds: 2),
    String exitInfoText = '再按一次退出App',
  }) async {
    if (ensureScreenSize) {
      await ScreenUtil.ensureScreenSize();
    }
    if (initializeWidgetsBinding) {
      WidgetsFlutterBinding.ensureInitialized();
    }

    // TODO: integrated with platform dart file
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
      escToExit: escToExit,
      exitGapTime: exitGapTime,
      exitInfoText: exitInfoText,
    ));
  }

  static Future<void> _initializeWindowManager(
    Size defaultSize,
    String appName, {
    bool setTitleBarHidden = true,
    bool setWindowButtonVisibility = false,
    bool setSkipTaskbar = false,
    bool setResizable = true,
    bool setMinisizable = true,
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
    if (setMinisizable) await windowManager.setMinimizable(true);
    if (setMaximizable) await windowManager.setMaximizable(true);
    if (setResizable) await windowManager.setResizable(true);

    if (setSkipTaskbar) await windowManager.setSkipTaskbar(true);

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
              transition: Transition.fade,
              transitionDuration: const Duration(milliseconds: 300),
            )),
      ],
      builder: (context, child) => _buildAppContent(context, child),
      theme: _buildTheme(),
      defaultTransition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
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

    return _buildKeyboardShortcuts(processedChild);
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

    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.select): const ActivateIntent(),
        if (escToExit)
          LogicalKeySet(LogicalKeyboardKey.escape):
              VoidCallbackIntent(() async {
            final now = DateTime.now();
            if (lastPressedTime == null ||
                now.difference(lastPressedTime!) > exitGapTime) {
              lastPressedTime = now;
              toast(exitInfoText, duration: exitGapTime);
            } else {
              // 在间隔时间内再次按下ESC,退出应用
              await MyApp.exit();
            }
          }),
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
