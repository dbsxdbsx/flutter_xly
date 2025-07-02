import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';
import 'package:xly/src/exit.dart';
import 'package:xly/src/platform.dart';
import 'package:xly/src/splash.dart';
import 'package:xly/src/toast/toast.dart';

class MyApp extends StatelessWidget {
  final Size designSize;
  final ThemeData? theme;
  final List<MyRoute> routes;
  final List<MyService>? services;
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

  final GlobalKey<NavigatorState>? navigatorKey;
  final bool enableDoubleClickFullScreen;
  final bool draggable;

  const MyApp._({
    required this.designSize,
    this.theme,
    this.splash,
    required this.routes,
    this.services,
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
    this.navigatorKey,
    this.enableDoubleClickFullScreen = false,
    this.draggable = true,
  });

  static Future<void> initialize({
    // 核必需参数
    required Size designSize,
    required List<MyRoute> routes,
    String? appName,

    // 服务配置
    List<MyService>? services,

    // 路由和页面配置
    MySplash? splash,
    Transition pageTransitionStyle = Transition.fade,
    Duration pageTransitionDuration = const Duration(milliseconds: 300),
    GlobalKey<NavigatorState>? navigatorKey,

    // UI自定义配置
    Widget Function(BuildContext, Widget?)?
        appBuilder, // 应用构建器，用于自定义UI层级（如添加FloatBar、全局遮罩等）

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

    // 1. 应用直接参数作为基础配置
    _globalEnableResizable.value = resizable;
    _globalEnableDoubleClickFullScreen.value = doubleClickToFullScreen;
    _globalEnableDraggable.value = draggable;

    // 2. 准备服务，但不立即注册。注册操作将推迟到UI构建阶段，以确保ScreenUtil等依赖项已准备就绪。
    // 3. 在所有配置应用完毕后，设置路由并运行应用
    runApp(MyApp._(
      designSize: designSize,
      theme: theme,
      routes: routes,
      services: services, // 保持 services 的传递，以备其他用途
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
      builder: (context, child) {
        // 在ScreenUtil初始化后，但在任何页面构建前，注册所有服务。
        // 这确保了服务可以安全地使用ScreenUtil，同时其配置能在路由和页面加载前生效。
        if (services != null) {
          for (final service in services!) {
            service.registerService();
          }
        }
        return _buildApp(context);
      },
    );
  }

  Widget _buildApp(BuildContext context) {
    Widget app = GetMaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: showDebugTag,
      title: appName ?? '',
      initialRoute: routes.isNotEmpty ? routes.first.path : '/',
      getPages: [
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

    // 应用用户自定义的UI构建器
    if (appBuilder != null) {
      processedChild = appBuilder!(context, processedChild);
    }

    processedChild = _buildKeyboardShortcuts(processedChild);

    // 将拖动区域包裹在最外层，确保在启动屏期间也能拖动
    return Obx(() => CustomDragArea(
          enableDoubleClickFullScreen: _globalEnableDoubleClickFullScreen.value,
          draggable: _globalEnableDraggable.value,
          child: Stack(
            children: [
              // 底层内容
              processedChild,

              // 顶层启动屏
              if (splash != null && !isSplashFinished.value)
                Visibility(
                  visible: !isSplashFinished.value,
                  child: splash!,
                ),
            ],
          ),
        ));
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
      child: child,
    );
  }

  /// 静态方法用于退出应用
  static Future<void> exit() async {
    await exitApp();
  }

  static final isSplashFinished = false.obs;
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

/// 服务注册类，用于在ScreenUtil初始化后注册GetX服务
class MyService<T> {
  final T Function() service;
  final bool permanent;
  final bool fenix;
  final String? tag;

  MyService({
    required this.service,
    this.permanent = false,
    this.fenix = false,
    this.tag,
  });

  void registerService() {
    if (permanent) {
      Get.put<T>(service(), permanent: true, tag: tag);
    } else if (fenix) {
      Get.lazyPut<T>(service, fenix: true, tag: tag);
    } else {
      Get.lazyPut<T>(service, tag: tag);
    }
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
