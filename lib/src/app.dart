import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';
import 'package:xly/src/exit.dart';
import 'package:xly/src/float_panel.dart';
import 'package:xly/src/platform.dart';
import 'package:xly/src/splash.dart';
import 'package:xly/src/toast/toast.dart';

class MyApp extends StatelessWidget {
  final Size designSize;
  final ThemeData? theme;
  final List<MyRoute> routes;
  final Widget Function(BuildContext, Widget?)? appBuilder;
  final String? appName;
  final bool useToast;
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
  final bool enableDoubleClickFullScreen;
  final bool draggable;

  const MyApp._({
    required this.designSize,
    this.theme,
    this.splash,
    required this.routes,
    this.appBuilder,
    this.appName,
    this.useToast = true,
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
    this.enableDoubleClickFullScreen = false,
    this.draggable = true,
  });

  static Future<void> initialize({
    // 核必需参数
    required Size designSize,
    required List<MyRoute> routes,
    String? appName,

    // 路由和页面配置
    MySplash? splash,
    Widget Function(BuildContext, Widget?)? appBuilder,
    Transition pageTransitionStyle = Transition.fade,
    Duration pageTransitionDuration = const Duration(milliseconds: 300),
    GlobalKey<NavigatorState>? navigatorKey,

    // 窗口基础配置
    Size? minimumSize,
    bool centerWindow = true,
    bool showWindow = true,
    bool focusWindow = true,

    // 窗口交互配置
    bool draggable = true,
    bool resizable = true,
    bool doubleClickToFullScreen = false,

    // 窗口行为配置
    bool setTitleBarHidden = true,
    bool setWindowButtonVisibility = false,
    bool setSkipTaskbar = false,
    bool setMaximizable = true,
    bool setAspectRatio = true,

    // UI和主题配置
    ThemeData? theme,
    bool showDebugTag = true,
    bool dragToMoveArea = true,
    MyFloatPanel? globalFloatPanel,

    // 其他功能配置
    LogicalKeyboardKey? keyToRollBack,
    String exitInfoText = '再按一次退出App',
    String backInfoText = '再按一次返回上一页',
    Duration exitGapTime = const Duration(seconds: 2),
    bool useOKToast = true,

    // 初始化配置
    bool ensureScreenSize = true,
    bool initializeWidgetsBinding = true,
    bool initializeWindowManager = true,
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
          setResizable: resizable,
          setMaximizable: setMaximizable,
          centerWindow: centerWindow,
          focusWindow: focusWindow,
          showWindow: showWindow,
          setAspectRatio: setAspectRatio,
          minimumSize: minimumSize,
        );
      }
    }

    // 初始化时设置全局状态
    _globalEnableResizable.value = resizable;
    _globalEnableDoubleClickFullScreen.value = doubleClickToFullScreen;
    _globalEnableDraggable.value = draggable;

    runApp(MyApp._(
      designSize: designSize,
      theme: theme,
      routes: routes,
      appBuilder: appBuilder,
      appName: appName,
      useToast: useOKToast,
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
      enableDoubleClickFullScreen: doubleClickToFullScreen,
      draggable: draggable,
    ));
  }

  static Future<void> _initializeWindowManager(
    Size defaultSize,
    String? appName, {
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

    _globalTitleBarHidden.value = setTitleBarHidden;
    if (setTitleBarHidden) {
      await windowManager.setTitleBarStyle(TitleBarStyle.hidden,
          windowButtonVisibility: setWindowButtonVisibility);
    }

    if (appName != null) {
      await windowManager.setTitle(appName);
    }

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
      title: appName ?? '',
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

    return useToast ? MyToast(child: app) : app;
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

      // 检查是否切换路由或者超过了时间间隔
      bool shouldResetTimer = lastRoute != currentRoute ||
          lastPressedTime == null ||
          now.difference(lastPressedTime!) > exitGapTime;

      if (shouldResetTimer) {
        lastPressedTime = now;
        lastRoute = currentRoute;
        if (currentRoute == routes.first.path) {
          MyToast.show(exitInfoText, duration: exitGapTime);
        } else {
          MyToast.show(backInfoText, duration: exitGapTime);
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
      child: Obx(() => CustomDragArea(
            enableDoubleClickFullScreen:
                _globalEnableDoubleClickFullScreen.value,
            draggable: _globalEnableDraggable.value,
            child: child,
          )),
    );
  }

  /// 静态方法用于退出应用
  static Future<void> exit() async {
    await exitApp();
  }

  static final _globalEnableDoubleClickFullScreen = false.obs;
  static final _globalEnableResizable = false.obs;
  static final _globalEnableDraggable = true.obs;
  static final _globalTitleBarHidden = true.obs;

  /// 获取当前双击最大化功能的状态
  static bool isDoubleClickFullScreenEnabled() {
    return _globalEnableDoubleClickFullScreen.value;
  }

  /// 设置双击最大化功能的启用状态
  static Future<void> setDoubleClickFullScreenEnabled(bool enabled) async {
    _globalEnableDoubleClickFullScreen.value = enabled;
  }

  /// 获取当前窗口大小调整功能的状态
  static bool isResizableEnabled() {
    return _globalEnableResizable.value;
  }

  /// 设置窗口大小调整功能的启用状态
  static Future<void> setResizableEnabled(bool enabled) async {
    _globalEnableResizable.value = enabled;
    await windowManager.setResizable(enabled);
  }

  /// 获取当前窗口拖动功能的状态
  static bool isDraggableEnabled() {
    return _globalEnableDraggable.value;
  }

  /// 设置窗口拖动功能的启用状态
  static Future<void> setDraggableEnabled(bool enabled) async {
    _globalEnableDraggable.value = enabled;
  }

  /// 获取当前标题栏的隐藏状态
  static bool isTitleBarHidden() {
    return _globalTitleBarHidden.value;
  }

  /// 设置标题栏的显示/隐藏状态
  static Future<void> setTitleBarHidden(bool hidden) async {
    _globalTitleBarHidden.value = hidden;
    await windowManager.setTitleBarStyle(
      hidden ? TitleBarStyle.hidden : TitleBarStyle.normal,
      windowButtonVisibility: false, // 保持一致性
    );
  }

  /// 停靠窗口到指定角落
  ///
  /// [corner] 要停靠到的角落位置
  /// 返回 true 表示停靠成功，false 表示停靠失败
  ///
  /// 此方法会自动检测屏幕工作区域，避开任务栏
  static Future<bool> dockToCorner(WindowCorner corner) async {
    if (!MyPlatform.isDesktop) return false;

    try {
      final display = await screenRetriever.getPrimaryDisplay();
      if (display.visiblePosition == null || display.visibleSize == null) {
        return false;
      }

      final windowSize = await windowManager.getSize();
      final workArea = display.visibleSize!;
      final workAreaPosition = display.visiblePosition!;

      // 获取DPI缩放因子来修正位置精度
      final scaleFactor = display.scaleFactor ?? 1.0;

      // 计算边框偏移量（Windows窗口可能有不可见边框）
      // 在高DPI环境下，通常需要微调更多像素来达到完美贴边
      // 根据用户反馈，增加偏移量以获得更好的贴边效果
      final edgeOffset = scaleFactor > 1.0 ? 16.0 / scaleFactor : 10.0;

      // 顶部边缘需要额外的偏移，因为Windows标题栏区域的处理方式不同
      // final topEdgeOffset = scaleFactor > 1.0 ? 20.0 / scaleFactor : 14.0;
      debugPrint("""scaleFactor: $scaleFactor, edgeOffset: $edgeOffset""");
      final topEdgeOffset = edgeOffset - 0.95 * edgeOffset;

      late Offset position;
      switch (corner) {
        case WindowCorner.topLeft:
          position = Offset(
            workAreaPosition.dx - edgeOffset,
            workAreaPosition.dy - topEdgeOffset,
          );
          break;
        case WindowCorner.topRight:
          position = Offset(
            workAreaPosition.dx +
                workArea.width -
                windowSize.width +
                edgeOffset,
            workAreaPosition.dy - topEdgeOffset,
          );
          break;
        case WindowCorner.bottomLeft:
          position = Offset(
            workAreaPosition.dx - edgeOffset,
            workAreaPosition.dy +
                workArea.height -
                windowSize.height +
                edgeOffset,
          );
          break;
        case WindowCorner.bottomRight:
          position = Offset(
            workAreaPosition.dx +
                workArea.width -
                windowSize.width +
                edgeOffset,
            workAreaPosition.dy +
                workArea.height -
                windowSize.height +
                edgeOffset,
          );
          break;
      }

      // 确保位置值是整数，避免亚像素定位问题
      final adjustedPosition = Offset(
        position.dx.roundToDouble(),
        position.dy.roundToDouble(),
      );

      await windowManager.setPosition(adjustedPosition);
      return true;
    } catch (e) {
      return false;
    }
  }
}

/// 窗口角落位置枚举
enum WindowCorner {
  /// 左上角
  topLeft,

  /// 右上角
  topRight,

  /// 左下角
  bottomLeft,

  /// 右下角
  bottomRight,
}

class VoidCallbackIntent extends Intent {
  final VoidCallback callback;

  const VoidCallbackIntent(this.callback);
}

class WindowSettings extends GetxController {
  static WindowSettings get to => Get.find();
  final enableDoubleClickFullScreen = false.obs;
}

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

class CustomDragArea extends StatelessWidget {
  final Widget child;
  final bool enableDoubleClickFullScreen;
  final bool draggable;

  const CustomDragArea({
    super.key,
    required this.child,
    required this.enableDoubleClickFullScreen,
    required this.draggable,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: draggable
          ? (details) async {
              await windowManager.startDragging();
            }
          : null,
      onDoubleTap: enableDoubleClickFullScreen
          ? () async {
              bool isMaximized = await windowManager.isMaximized();
              if (isMaximized) {
                await windowManager.restore();
              } else {
                await windowManager.maximize();
              }
            }
          : null,
      behavior: HitTestBehavior.translucent,
      child: child,
    );
  }
}
