part of '../xly.dart';

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

/// 服务注册类，用于注册GetX服务
///
/// 支持同步和异步服务初始化：
/// - 同步服务：使用 `service` 参数
/// - 异步服务：使用 `asyncService` 参数
///
/// 示例：
/// ```dart
/// // 同步服务
/// MyService<SettingsService>(service: () => SettingsService())
///
/// // 异步服务（需要异步初始化，如从数据库/网络加载配置）
/// MyService<ChatService>(asyncService: () async => ChatService())
/// ```
class MyService<T> {
  final T Function()? service;
  final Future<T> Function()? asyncService;
  final bool permanent;
  final bool fenix;
  final String? tag;

  MyService({
    this.service,
    this.asyncService,
    this.permanent = false,
    this.fenix = false,
    this.tag,
  }) : assert(
          (service != null) ^ (asyncService != null),
          'service 和 asyncService 必须且只能提供其中一个',
        );

  /// 注册服务到GetX依赖注入系统
  ///
  /// 对于异步服务，会等待其初始化完成后再返回
  Future<void> registerService() async {
    if (asyncService != null) {
      // 异步服务：使用 Get.putAsync
      await Get.putAsync<T>(
        asyncService!,
        permanent: permanent,
        tag: tag,
      );
    } else {
      // 同步服务：保持原有逻辑
      if (permanent) {
        Get.put<T>(service!(), permanent: true, tag: tag);
      } else if (fenix) {
        Get.lazyPut<T>(service!, fenix: true, tag: tag);
      } else {
        Get.lazyPut<T>(service!, tag: tag);
      }
    }
  }
}

class CustomDragArea extends StatelessWidget {
  final Widget child;
  final bool enableDoubleClickMaximize;
  final bool draggable;

  const CustomDragArea({
    super.key,
    required this.child,
    required this.enableDoubleClickMaximize,
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
      onDoubleTap: enableDoubleClickMaximize
          ? () async {
              // 检查是否处于智能停靠状态
              if (MyApp.isSmartDockingEnabled()) {
                XlyLogger.debug('智能停靠状态下已禁用双击最大化功能');
                return;
              }

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

    // 托盘配置 - 简化配置方式
    MyTray? tray,

    // 浮动面板 - 类似托盘的全局管理器
    FloatPanel? floatPanel,

    // 路由和页面配置
    MySplash? splash,
    Transition pageTransitionStyle = Transition.fade,
    Duration pageTransitionDuration = const Duration(milliseconds: 300),
    // UI自定义配置
    Widget Function(BuildContext, Widget?)?
        appBuilder, // 应用构建器，用于自定义UI层级（如全局遮罩等）

    // 窗口基础配置
    Size? minimumSize,
    bool centerWindowOnInit = true,
    bool showWindowOnInit = true,
    bool focusWindowOnInit = true,

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
    bool setAspectRatioEnabled = true,

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
    bool enableDebugLogging = false, // 包调试日志开关（默认关闭，避免污染用户日志）

    // 单实例配置
    bool singleInstance = true,
    String? singleInstanceKey,
    bool singleInstanceActivateOnSecond = true,

    // 初始化配置
    bool ensureScreenSize = true,
    bool initializeWidgetsBinding = true,
    bool initializeWindowManager = true,
    bool initializeGetStorage = true,
  }) async {
    // 首先初始化日志系统，以便后续初始化步骤可以使用日志
    XlyLogger.init(enabled: enableDebugLogging);
    XlyLogger.info('MyApp 初始化开始');

    if (ensureScreenSize) {
      await ScreenUtil.ensureScreenSize();
    }
    if (initializeWidgetsBinding) {
      WidgetsFlutterBinding.ensureInitialized();
    }
    if (initializeGetStorage) {
      await GetStorage.init();
    }

    // 单实例检查 - 在其他初始化之前进行，以免创建多余的窗口
    if (singleInstance) {
      final instanceKey = singleInstanceKey ?? appName ?? 'XlyFlutterApp';
      final isFirstInstance = await SingleInstanceManager.instance.initialize(
        instanceKey: instanceKey,
        activateExisting: singleInstanceActivateOnSecond,
        onActivate: MyPlatform.isDesktop
            ? () async {
                // 当收到激活请求时，显示并聚焦窗口
                try {
                  await windowManager.show();
                  await windowManager.focus();
                  await windowManager.setAlwaysOnTop(true);
                  // 短暂置顶后取消，避免影响用户体验
                  Future.delayed(const Duration(milliseconds: 100), () async {
                    try {
                      await windowManager.setAlwaysOnTop(false);
                    } catch (e) {
                      XlyLogger.error('取消窗口置顶失败', e);
                    }
                  });
                } catch (e) {
                  XlyLogger.error('激活窗口失败', e);
                }
              }
            : null,
      );

      if (!isFirstInstance) {
        // 不是首个实例，退出当前实例
        XlyLogger.info('检测到应用已在运行，当前实例即将退出');
        await exitApp();
        return;
      }
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
          centerWindow: centerWindowOnInit,
          focusWindow: focusWindowOnInit,
          showWindow: showWindowOnInit,
          setAspectRatio: setAspectRatio && setAspectRatioEnabled,
          minimumSize: minimumSize,
        );
      }
    }

    // 1. 应用直接参数作为基础配置
    _globalEnableResizable.value = resizable;
    _globalEnableDoubleClickMaximize.value = doubleClickToFullScreen;
    _globalEnableDraggable.value = draggable;
    _globalEnableAspectRatio.value = setAspectRatioEnabled;
    _globalEnableAspectRatio.value = setAspectRatioEnabled;

    // 2. 处理tray参数，自动转换为MyService
    List<MyService> finalServices = services != null ? List.from(services) : [];

    if (tray != null) {
      // 检查services中是否已有MyTray服务
      bool hasTrayService = finalServices.any((service) {
        try {
          // 检查同步服务
          if (service.service != null) {
            return service.service!() is MyTray;
          }
          // 检查异步服务类型
          if (service.asyncService != null) {
            return service.asyncService.runtimeType
                .toString()
                .contains('MyTray');
          }
          return false;
        } catch (e) {
          return false;
        }
      });

      if (hasTrayService) {
        // 如果services中已有MyTray，移除它并使用tray参数提供的配置
        finalServices.removeWhere((service) {
          try {
            if (service.service != null) {
              return service.service!() is MyTray;
            }
            if (service.asyncService != null) {
              return service.asyncService.runtimeType
                  .toString()
                  .contains('MyTray');
            }
            return false;
          } catch (e) {
            return false;
          }
        });

        XlyLogger.warning('MyApp: 检测到services中已有MyTray配置，将使用tray参数提供的配置覆盖');
      }

      // 添加tray参数提供的MyTray服务
      finalServices.add(
        MyService<MyTray>(
          service: () => tray,
          permanent: true,
        ),
      );
    }

    // 3. 若提供 floatPanel，则作为全局服务注册（类似 tray）
    if (floatPanel != null) {
      finalServices.add(MyService<FloatPanel>(
        service: () => floatPanel,
        permanent: true,
      ));
    }

    // 4. 在runApp之前注册所有服务（支持异步服务）
    // 注意：此时ScreenUtil已通过ensureScreenSize()初始化，服务可以安全使用
    // 按照用户输入的顺序依次注册，保证服务依赖关系
    // 如果服务注册失败，异常会自然向上传播，终止应用初始化
    for (final service in finalServices) {
      await service.registerService();
    }

    // 5. 在所有配置应用完毕后，设置路由并运行应用
    if (appName != null) {
      _globalWindowTitle.value = appName;
    }
    runApp(MyApp._(
      designSize: designSize,
      theme: theme,
      routes: routes,
      services: null, // 服务已注册，不再需要传递
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
      _globalWindowTitle.value = appName;
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

    // 配置窗口的初始可见性、焦点和位置。
    if (showWindow) {
      await windowManager.show();
      if (focusWindow) {
        await windowManager.focus();
      }
    }
    if (centerWindow) {
      await windowManager.center();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: designSize,
      builder: (context, child) {
        // 服务已在 MyApp.initialize() 中注册完成
        return _buildApp(context);
      },
    );
  }

  Widget _buildApp(BuildContext context) {
    return Obx(() {
      final effectiveTitle = _globalWindowTitle.value.isNotEmpty
          ? _globalWindowTitle.value
          : (appName ?? '');
      Widget app = GetMaterialApp(
        navigatorKey: Get.key,
        debugShowCheckedModeBanner: showDebugTag,
        title: effectiveTitle,
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
        // 使用 builder 包裹一层 Overlay，确保 Get.snackbar 等依赖 overlayContext
        // 的功能在对话框关闭回调等边界场景下仍能正常工作
        // 参考: https://github.com/jonataslaw/getx/issues/3425
        builder: (context, child) {
          return Overlay(
            initialEntries: [
              OverlayEntry(
                builder: (context) {
                  return _buildAppContent(context, child);
                },
              ),
            ],
          );
        },
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
        // 隐式路由联动：当路由变化时，若当前路由名与某个 item.id 或 '/'+id 匹配，则自动设置禁用联动
        routingCallback: (routing) {
          final current = routing?.current;
          if (current == null) return;
          if (!Get.isRegistered<FloatPanel>()) return;
          final fp = FloatPanel.to;
          for (final item in fp.items) {
            final id = item.id;
            if (id == null) continue;
            if (current == id || current == '/$id') {
              // 仅禁用当前页面对应按钮，并清理旧的禁用集合，保证“单选禁用”效果
              fp.iconBtns.enableAll();
              fp.iconBtn(id).setEnabled(false);
              break;
            }
          }
        },
      );

      // 包装 Toast
      if (useToast) {
        app = MyToast(child: app);
      }

      return app;
    });
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
          enableDoubleClickMaximize: _globalEnableDoubleClickMaximize.value,
          draggable: _globalEnableDraggable.value,
          child: Stack(
            children: [
              // 底层内容
              processedChild,

              // 全局浮动面板（页面之上，splash 之下）
              if (Get.isRegistered<FloatPanel>())
                Obx(() {
                  final fp = FloatPanel.to;
                  if (!fp.visible.value) return const SizedBox.shrink();
                  return _FloatBoxPanel(
                    items: fp.items,
                    // 传入设计值，缩放在 _FloatBoxPanel 内部处理
                    panelWidthInput: fp.panelWidth.value,
                    backgroundColor: fp.backgroundColor.value,
                    panelShape: fp.panelShape.value,
                    borderRadiusInput: fp.borderRadius.value,
                    dockType: fp.dockType.value,
                    panelButtonColor: fp.panelButtonColor.value,
                    customButtonColor: fp.customButtonColor.value,
                    dockActivate: fp.dockActivate.value,
                    innerButtonFocusColor: fp.handleFocusColor.value,
                    customButtonFocusColor: fp.focusColor.value,
                    // 新增从 FloatPanel 读取的配置
                    borderColor: fp.borderColor.value,
                    initialPanelIcon: fp.initialPanelIcon.value,
                    panelAnimDuration: fp.panelAnimDuration.value,
                    panelAnimCurve: fp.panelAnimCurve.value,
                    dockAnimDuration: fp.dockAnimDuration.value,
                    dockAnimCurve: fp.dockAnimCurve.value,
                  );
                }),

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
      // 优先让当前可关闭层（如 Drawer、Dialog、BottomSheet 等）消费 ESC / 回退
      final popped = await Get.key.currentState?.maybePop() ?? false;
      if (popped) return;

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
    // 清理单实例管理器资源
    await SingleInstanceManager.instance.dispose();
    await exitApp();
  }

  static final isSplashFinished = false.obs;
  static final _globalEnableDoubleClickMaximize = false.obs;
  static final _globalEnableResizable = false.obs;
  static final _globalEnableDraggable = true.obs;
  static final _globalTitleBarHidden = true.obs;
  static final _globalEnableAspectRatio = true.obs;
  static final _globalEnableFullScreen = true.obs;
  static final _globalWindowTitle = ''.obs;

  /// 获取当前双击最大化功能的状态
  /// 在智能停靠状态下自动禁用双击最大化功能
  static bool isDoubleClickMaximizeEnabled() {
    // 检查是否处于智能停靠状态
    if (isSmartDockingEnabled()) {
      return false; // 智能停靠状态下禁用双击最大化
    }
    return _globalEnableDoubleClickMaximize.value;
  }

  /// 设置双击最大化功能的启用状态
  static Future<void> setDoubleClickMaximizeEnabled(bool enabled) async {
    _globalEnableDoubleClickMaximize.value = enabled;
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

  /// 获取当前窗口比例调整功能的状态
  static bool isAspectRatioEnabled() {
    return _globalEnableAspectRatio.value;
  }

  /// 设置窗口比例调整功能的启用状态
  static Future<void> setAspectRatioEnabled(bool enabled) async {
    _globalEnableAspectRatio.value = enabled;
    if (MyPlatform.isDesktop) {
      if (enabled) {
        // 获取当前窗口大小并设置比例
        final currentSize = await windowManager.getSize();
        await windowManager
            .setAspectRatio(currentSize.width / currentSize.height);
      } else {
        // 移除比例限制，设置为0表示无限制
        await windowManager.setAspectRatio(0);
      }
    }
  }

  /// 获取当前全屏功能的状态
  /// 在智能停靠状态下自动禁用全屏功能
  static bool isFullScreenEnabled() {
    // 检查是否处于智能停靠状态
    if (isSmartDockingEnabled()) {
      return false; // 智能停靠状态下禁用全屏功能
    }
    return _globalEnableFullScreen.value;
  }

  /// 设置全屏功能的启用状态
  static Future<void> setFullScreenEnabled(bool enabled) async {
    _globalEnableFullScreen.value = enabled;
  }

  /// 切换全屏状态
  /// 在智能停靠状态下此方法无效
  static Future<void> toggleFullScreen() async {
    if (!isFullScreenEnabled()) {
      XlyLogger.debug('全屏功能已禁用（可能处于智能停靠状态）');
      return;
    }

    if (!MyPlatform.isDesktop) return;

    try {
      final isFullScreen = await windowManager.isFullScreen();
      if (isFullScreen) {
        await windowManager.setFullScreen(false);
        XlyLogger.info('已退出全屏模式');
      } else {
        await windowManager.setFullScreen(true);
        XlyLogger.info('已进入全屏模式');
      }
    } catch (e) {
      XlyLogger.error('切换全屏状态时出错', e);
    }
  }

  /// Window Title APIs
  static Future<void> setWindowTitle(String title) async {
    _globalWindowTitle.value = title;
    if (MyPlatform.isDesktop) {
      try {
        await windowManager.setTitle(title);
      } catch (e) {
        XlyLogger.error('设置窗口标题失败', e);
      }
    }
  }

  static String getWindowTitle() {
    return _globalWindowTitle.value;
  }

  /// 停靠窗口到指定角落（简单对齐，不隐藏）
  ///
  /// [corner] 要停靠到的角落位置
  /// 返回 true 表示停靠成功，false 表示停靠失败
  ///
  /// **注意**: 此方法仅将窗口对齐到角落位置，不会隐藏窗口或提供鼠标交互。
  /// 如需类似QQ的智能停靠功能（自动隐藏/显示），请使用 [setSmartEdgeDocking]。
  ///
  /// 此方法会自动检测屏幕工作区域，避开任务栏。
  ///
  /// 使用场景：
  /// - 简单的窗口定位需求
  /// - 不需要隐藏/显示交互的场景
  /// - 一次性窗口位置调整
  ///
  /// 示例：
  /// ```dart
  /// // 将窗口对齐到左上角
  /// await MyApp.dockToCorner(WindowCorner.topLeft);
  /// ```
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
      XlyLogger.debug('scaleFactor: $scaleFactor, edgeOffset: $edgeOffset');
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

  /// 启用窗口边缘停靠功能（类似QQ的停靠行为）
  ///
  /// [edge] 要停靠到的边缘位置
  /// [visibleWidth] 停靠时可见的窗口宽度（像素），默认为5像素
  /// [hoverDelay] 鼠标悬停多久后显示窗口（毫秒），默认300毫秒
  /// 返回 true 表示启用成功，false 表示启用失败
  ///
  /// 此功能会：
  /// 1. 将窗口移动到指定边缘，大部分隐藏，只留小部分可见
  /// 2. 监听鼠标位置，当鼠标悬停在可见部分时显示完整窗口
  /// 3. 当鼠标离开窗口区域时，重新隐藏到边缘
  static Future<bool> enableEdgeDocking({
    required WindowEdge edge,
    double visibleWidth = 5.0,
    int hoverDelay = 300,
  }) async {
    if (!MyPlatform.isDesktop) return false;

    try {
      final display = await screenRetriever.getPrimaryDisplay();
      if (display.visiblePosition == null || display.visibleSize == null) {
        return false;
      }

      final windowSize = await windowManager.getSize();
      final workArea = display.visibleSize!;
      final workAreaPosition = display.visiblePosition!;

      // 计算停靠位置
      Offset dockPosition;
      switch (edge) {
        case WindowEdge.left:
          dockPosition = Offset(
            workAreaPosition.dx - windowSize.width + visibleWidth,
            workAreaPosition.dy + (workArea.height - windowSize.height) / 2,
          );
          break;
        case WindowEdge.right:
          dockPosition = Offset(
            workAreaPosition.dx + workArea.width - visibleWidth,
            workAreaPosition.dy + (workArea.height - windowSize.height) / 2,
          );
          break;
        case WindowEdge.top:
          dockPosition = Offset(
            workAreaPosition.dx + (workArea.width - windowSize.width) / 2,
            workAreaPosition.dy - windowSize.height + visibleWidth,
          );
          break;
        case WindowEdge.bottom:
          dockPosition = Offset(
            workAreaPosition.dx + (workArea.width - windowSize.width) / 2,
            workAreaPosition.dy + workArea.height - visibleWidth,
          );
          break;
      }

      // 移动窗口到停靠位置
      await windowManager.setPosition(dockPosition);

      // 启动鼠标位置监听
      _startMousePositionMonitoring(
        edge: edge,
        dockPosition: dockPosition,
        windowSize: windowSize,
        visibleWidth: visibleWidth,
        hoverDelay: hoverDelay,
        workAreaPosition: workAreaPosition,
        workArea: workArea,
      );

      return true;
    } catch (e) {
      XlyLogger.error('启用边缘停靠失败', e);
      return false;
    }
  }

  /// 禁用窗口边缘停靠功能
  static void disableEdgeDocking() {
    _mouseMonitorTimer?.cancel();
    _mouseMonitorTimer = null;
    _hoverTimer?.cancel();
    _hoverTimer = null;
    _isEdgeDockingEnabled = false;

    // 停止智能停靠管理器
    SmartDockManager.stopAll();
  }

  // 私有变量用于鼠标监听
  static Timer? _mouseMonitorTimer;
  static Timer? _hoverTimer;
  static bool _isEdgeDockingEnabled = false;
  static bool _isWindowExpanded = false;
  static Offset? _dockPosition;
  static Offset? _expandPosition;

  /// 开始监听鼠标位置
  static void _startMousePositionMonitoring({
    required WindowEdge edge,
    required Offset dockPosition,
    required Size windowSize,
    required double visibleWidth,
    required int hoverDelay,
    required Offset workAreaPosition,
    required Size workArea,
  }) {
    _isEdgeDockingEnabled = true;
    _dockPosition = dockPosition;

    // 计算展开位置
    switch (edge) {
      case WindowEdge.left:
        _expandPosition = Offset(workAreaPosition.dx, dockPosition.dy);
        break;
      case WindowEdge.right:
        _expandPosition = Offset(
          workAreaPosition.dx + workArea.width - windowSize.width,
          dockPosition.dy,
        );
        break;
      case WindowEdge.top:
        _expandPosition = Offset(dockPosition.dx, workAreaPosition.dy);
        break;
      case WindowEdge.bottom:
        _expandPosition = Offset(
          dockPosition.dx,
          workAreaPosition.dy + workArea.height - windowSize.height,
        );
        break;
    }

    // 定期检查鼠标位置（每100毫秒检查一次）
    _mouseMonitorTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (timer) => _checkMousePosition(
        edge: edge,
        dockPosition: dockPosition,
        windowSize: windowSize,
        visibleWidth: visibleWidth,
        hoverDelay: hoverDelay,
      ),
    );
  }

  /// 检查鼠标位置并处理窗口显示/隐藏
  static void _checkMousePosition({
    required WindowEdge edge,
    required Offset dockPosition,
    required Size windowSize,
    required double visibleWidth,
    required int hoverDelay,
  }) async {
    if (!_isEdgeDockingEnabled) return;

    try {
      // 获取当前鼠标位置
      final mousePosition = await _getMousePosition();
      if (mousePosition == null) return;

      // 计算可见区域的边界
      Rect visibleArea;
      switch (edge) {
        case WindowEdge.left:
          visibleArea = Rect.fromLTWH(
            dockPosition.dx + windowSize.width - visibleWidth,
            dockPosition.dy,
            visibleWidth,
            windowSize.height,
          );
          break;
        case WindowEdge.right:
          visibleArea = Rect.fromLTWH(
            dockPosition.dx,
            dockPosition.dy,
            visibleWidth,
            windowSize.height,
          );
          break;
        case WindowEdge.top:
          visibleArea = Rect.fromLTWH(
            dockPosition.dx,
            dockPosition.dy + windowSize.height - visibleWidth,
            windowSize.width,
            visibleWidth,
          );
          break;
        case WindowEdge.bottom:
          visibleArea = Rect.fromLTWH(
            dockPosition.dx,
            dockPosition.dy,
            windowSize.width,
            visibleWidth,
          );
          break;
      }

      // 检查鼠标是否在可见区域内
      final isMouseInVisibleArea = visibleArea.contains(mousePosition);

      if (isMouseInVisibleArea && !_isWindowExpanded) {
        // 鼠标进入可见区域，启动悬停计时器
        _hoverTimer?.cancel();
        _hoverTimer = Timer(Duration(milliseconds: hoverDelay), () {
          _expandWindow();
        });
      } else if (!isMouseInVisibleArea && _isWindowExpanded) {
        // 鼠标离开窗口区域，检查是否需要收缩
        final windowArea = Rect.fromLTWH(
          _expandPosition!.dx,
          _expandPosition!.dy,
          windowSize.width,
          windowSize.height,
        );

        if (!windowArea.contains(mousePosition)) {
          _hoverTimer?.cancel();
          _collapseWindow();
        }
      }
    } catch (e) {
      XlyLogger.error('检查鼠标位置时出错', e);
    }
  }

  /// 展开窗口
  static Future<void> _expandWindow() async {
    if (_expandPosition == null) return;

    try {
      await windowManager.setPosition(_expandPosition!);
      _isWindowExpanded = true;
    } catch (e) {
      XlyLogger.error('展开窗口时出错', e);
    }
  }

  /// 收缩窗口到停靠位置
  static Future<void> _collapseWindow() async {
    if (_dockPosition == null) return;

    try {
      await windowManager.setPosition(_dockPosition!);
      _isWindowExpanded = false;
    } catch (e) {
      XlyLogger.error('收缩窗口时出错', e);
    }
  }

  /// 获取当前鼠标位置（相对于屏幕）
  static Future<Offset?> _getMousePosition() async {
    try {
      // 使用screen_retriever包获取真实的鼠标光标位置
      final cursorPosition = await screenRetriever.getCursorScreenPoint();
      return cursorPosition;
    } catch (e) {
      XlyLogger.error('获取鼠标位置失败', e);
      return null;
    }
  }

  /// 简化版边缘停靠功能（基于窗口焦点事件）
  ///
  /// [edge] 要停靠到的边缘位置
  /// [visibleWidth] 停靠时可见的窗口宽度（像素），默认为5像素
  /// 返回 true 表示启用成功，false 表示启用失败
  ///
  /// 此版本使用窗口焦点事件来控制显示/隐藏，更简单但功能略有限制
  static Future<bool> enableSimpleEdgeDocking({
    required WindowEdge edge,
    double visibleWidth = 5.0,
  }) async {
    if (!MyPlatform.isDesktop) return false;

    try {
      final display = await screenRetriever.getPrimaryDisplay();
      if (display.visiblePosition == null || display.visibleSize == null) {
        return false;
      }

      final windowSize = await windowManager.getSize();
      final workArea = display.visibleSize!;
      final workAreaPosition = display.visiblePosition!;

      // 计算停靠位置
      Offset dockPosition;
      Offset expandPosition;

      switch (edge) {
        case WindowEdge.left:
          dockPosition = Offset(
            workAreaPosition.dx - windowSize.width + visibleWidth,
            workAreaPosition.dy + (workArea.height - windowSize.height) / 2,
          );
          expandPosition = Offset(workAreaPosition.dx, dockPosition.dy);
          break;
        case WindowEdge.right:
          dockPosition = Offset(
            workAreaPosition.dx + workArea.width - visibleWidth,
            workAreaPosition.dy + (workArea.height - windowSize.height) / 2,
          );
          expandPosition = Offset(
            workAreaPosition.dx + workArea.width - windowSize.width,
            dockPosition.dy,
          );
          break;
        case WindowEdge.top:
          dockPosition = Offset(
            workAreaPosition.dx + (workArea.width - windowSize.width) / 2,
            workAreaPosition.dy - windowSize.height + visibleWidth,
          );
          expandPosition = Offset(dockPosition.dx, workAreaPosition.dy);
          break;
        case WindowEdge.bottom:
          dockPosition = Offset(
            workAreaPosition.dx + (workArea.width - windowSize.width) / 2,
            workAreaPosition.dy + workArea.height - visibleWidth,
          );
          expandPosition = Offset(
            dockPosition.dx,
            workAreaPosition.dy + workArea.height - windowSize.height,
          );
          break;
      }

      // 保存位置信息
      _dockPosition = dockPosition;
      _expandPosition = expandPosition;
      _isEdgeDockingEnabled = true;
      _isWindowExpanded = false;

      // 移动窗口到停靠位置
      await windowManager.setPosition(dockPosition);

      return true;
    } catch (e) {
      XlyLogger.error('启用简单边缘停靠失败', e);
      return false;
    }
  }

  /// 手动展开停靠的窗口
  static Future<void> expandDockedWindow() async {
    if (!_isEdgeDockingEnabled || _isWindowExpanded) return;
    await _expandWindow();
  }

  /// 手动收缩窗口到停靠位置
  static Future<void> collapseDockedWindow() async {
    if (!_isEdgeDockingEnabled || !_isWindowExpanded) return;
    await _collapseWindow();
  }

  /// 切换停靠窗口的展开/收缩状态
  static Future<void> toggleDockedWindow() async {
    if (!_isEdgeDockingEnabled) return;

    if (_isWindowExpanded) {
      await collapseDockedWindow();
    } else {
      await expandDockedWindow();
    }
  }

  /// 启用角落停靠功能（类似QQ的角落停靠行为）
  ///
  /// [corner] 要停靠到的角落位置
  /// [visibleSize] 停靠时可见的窗口尺寸（像素），默认为20x20像素
  /// [hoverDelay] 鼠标悬停多久后显示窗口（毫秒），默认300毫秒
  /// 返回 true 表示启用成功，false 表示启用失败
  ///
  /// 此功能会：
  /// 1. 将窗口移动到指定角落，大部分隐藏，只留小部分可见
  /// 2. 监听鼠标位置，当鼠标悬停在可见部分时显示完整窗口
  /// 3. 当鼠标离开窗口区域时，重新隐藏到角落
  static Future<bool> enableCornerDocking({
    required WindowCorner corner,
    double visibleSize = 20.0,
    int hoverDelay = 300,
  }) async {
    if (!MyPlatform.isDesktop) return false;

    try {
      final display = await screenRetriever.getPrimaryDisplay();
      if (display.visiblePosition == null || display.visibleSize == null) {
        return false;
      }

      final windowSize = await windowManager.getSize();
      final workArea = display.visibleSize!;
      final workAreaPosition = display.visiblePosition!;

      // 计算停靠位置（角落位置，大部分隐藏）
      // 角落停靠时露出一个L形区域，比正方形更容易找到
      final cornerVisibleWidth = visibleSize * 2; // 水平方向可见宽度
      final cornerVisibleHeight = visibleSize; // 垂直方向可见高度

      Offset dockPosition;
      switch (corner) {
        case WindowCorner.topLeft:
          dockPosition = Offset(
            workAreaPosition.dx - windowSize.width + cornerVisibleWidth,
            workAreaPosition.dy - windowSize.height + cornerVisibleHeight,
          );
          break;
        case WindowCorner.topRight:
          dockPosition = Offset(
            workAreaPosition.dx + workArea.width - cornerVisibleWidth,
            workAreaPosition.dy - windowSize.height + cornerVisibleHeight,
          );
          break;
        case WindowCorner.bottomLeft:
          dockPosition = Offset(
            workAreaPosition.dx - windowSize.width + cornerVisibleWidth,
            workAreaPosition.dy + workArea.height - cornerVisibleHeight,
          );
          break;
        case WindowCorner.bottomRight:
          dockPosition = Offset(
            workAreaPosition.dx + workArea.width - cornerVisibleWidth,
            workAreaPosition.dy + workArea.height - cornerVisibleHeight,
          );
          break;
      }

      // 移动窗口到停靠位置
      await windowManager.setPosition(dockPosition);

      // 启动鼠标位置监听
      _startCornerMousePositionMonitoring(
        corner: corner,
        dockPosition: dockPosition,
        windowSize: windowSize,
        visibleSize: visibleSize,
        hoverDelay: hoverDelay,
        workAreaPosition: workAreaPosition,
        workArea: workArea,
      );

      return true;
    } catch (e) {
      XlyLogger.error('启用角落停靠失败', e);
      return false;
    }
  }

  /// 启用/禁用智能停靠机制（类似QQ的智能停靠功能）
  ///
  /// [enabled] 是否启用智能停靠
  /// [visibleWidth] 停靠时可见的宽度（默认5像素）
  ///
  /// **与 [dockToCorner] 的区别**：
  /// - [dockToCorner]: 仅对齐到角落，不隐藏，无鼠标交互
  /// - [setSmartEdgeDocking]: 自动检测 + 智能隐藏 + 鼠标交互
  ///
  /// **智能停靠行为**：
  /// 1. **自动检测**: 监听窗口拖拽，当窗口超出屏幕边界时自动触发
  /// 2. **两步式停靠**: 先对齐到目标位置，再根据鼠标位置智能隐藏
  /// 3. **智能判断**:
  ///    - 窗口同时超出两个相邻边界（如左边和上边）→ 角落停靠
  ///    - 窗口只超出一个边界 → 边缘停靠
  /// 4. **鼠标交互**: 鼠标悬停显示完整窗口，离开后自动隐藏
  ///
  /// **使用场景**：
  /// - 需要类似QQ的智能停靠体验
  /// - 希望窗口能自动隐藏以节省屏幕空间
  /// - 需要鼠标悬停交互的应用
  ///
  /// **示例**：
  /// ```dart
  /// // 启用智能停靠
  /// await MyApp.setSmartEdgeDocking(enabled: true, visibleWidth: 8.0);
  ///
  /// // 禁用智能停靠
  /// await MyApp.setSmartEdgeDocking(enabled: false);
  /// ```
  static Future<void> setSmartEdgeDocking({
    required bool enabled,
    double visibleWidth = 5.0,
  }) async {
    await SmartDockManager.setSmartEdgeDocking(
      enabled: enabled,
      visibleWidth: visibleWidth,
    );
  }

  /// 获取智能边缘停靠的启用状态
  static bool isSmartDockingEnabled() {
    return SmartDockManager.isSmartDockingEnabled();
  }

  /// 开始监听角落停靠的鼠标位置
  static void _startCornerMousePositionMonitoring({
    required WindowCorner corner,
    required Offset dockPosition,
    required Size windowSize,
    required double visibleSize,
    required int hoverDelay,
    required Offset workAreaPosition,
    required Size workArea,
  }) {
    _isEdgeDockingEnabled = true;
    _dockPosition = dockPosition;

    // 计算展开位置（完整显示在角落）
    switch (corner) {
      case WindowCorner.topLeft:
        _expandPosition = Offset(workAreaPosition.dx, workAreaPosition.dy);
        break;
      case WindowCorner.topRight:
        _expandPosition = Offset(
          workAreaPosition.dx + workArea.width - windowSize.width,
          workAreaPosition.dy,
        );
        break;
      case WindowCorner.bottomLeft:
        _expandPosition = Offset(
          workAreaPosition.dx,
          workAreaPosition.dy + workArea.height - windowSize.height,
        );
        break;
      case WindowCorner.bottomRight:
        _expandPosition = Offset(
          workAreaPosition.dx + workArea.width - windowSize.width,
          workAreaPosition.dy + workArea.height - windowSize.height,
        );
        break;
    }

    // 定期检查鼠标位置（每100毫秒检查一次）
    _mouseMonitorTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (timer) => _checkCornerMousePosition(
        corner: corner,
        dockPosition: dockPosition,
        windowSize: windowSize,
        visibleSize: visibleSize,
        hoverDelay: hoverDelay,
      ),
    );
  }

  /// 检查角落停靠的鼠标位置
  static void _checkCornerMousePosition({
    required WindowCorner corner,
    required Offset dockPosition,
    required Size windowSize,
    required double visibleSize,
    required int hoverDelay,
  }) async {
    if (!_isEdgeDockingEnabled) return;

    try {
      // 获取当前鼠标位置
      final mousePosition = await _getMousePosition();
      if (mousePosition == null) return;

      // 计算可见区域的边界（角落的L形区域）
      // 创建一个更大的矩形区域，便于鼠标悬停
      final cornerVisibleWidth = visibleSize * 2;
      final cornerVisibleHeight = visibleSize;

      Rect visibleArea;
      switch (corner) {
        case WindowCorner.topLeft:
          // 左上角：露出右下角的矩形区域
          visibleArea = Rect.fromLTWH(
            dockPosition.dx + windowSize.width - cornerVisibleWidth,
            dockPosition.dy + windowSize.height - cornerVisibleHeight,
            cornerVisibleWidth,
            cornerVisibleHeight,
          );
          break;
        case WindowCorner.topRight:
          // 右上角：露出左下角的矩形区域
          visibleArea = Rect.fromLTWH(
            dockPosition.dx,
            dockPosition.dy + windowSize.height - cornerVisibleHeight,
            cornerVisibleWidth,
            cornerVisibleHeight,
          );
          break;
        case WindowCorner.bottomLeft:
          // 左下角：露出右上角的矩形区域
          visibleArea = Rect.fromLTWH(
            dockPosition.dx + windowSize.width - cornerVisibleWidth,
            dockPosition.dy,
            cornerVisibleWidth,
            cornerVisibleHeight,
          );
          break;
        case WindowCorner.bottomRight:
          // 右下角：露出左上角的矩形区域
          visibleArea = Rect.fromLTWH(
            dockPosition.dx,
            dockPosition.dy,
            cornerVisibleWidth,
            cornerVisibleHeight,
          );
          break;
      }

      // 检查鼠标是否在可见区域内
      final isMouseInVisibleArea = visibleArea.contains(mousePosition);

      if (isMouseInVisibleArea && !_isWindowExpanded) {
        // 鼠标进入可见区域，启动悬停计时器
        _hoverTimer?.cancel();
        _hoverTimer = Timer(Duration(milliseconds: hoverDelay), () {
          _expandWindow();
        });
      } else if (!isMouseInVisibleArea && _isWindowExpanded) {
        // 鼠标离开窗口区域，检查是否需要收缩
        final windowArea = Rect.fromLTWH(
          _expandPosition!.dx,
          _expandPosition!.dy,
          windowSize.width,
          windowSize.height,
        );

        if (!windowArea.contains(mousePosition)) {
          _hoverTimer?.cancel();
          _collapseWindow();
        }
      }
    } catch (e) {
      XlyLogger.error('检查角落鼠标位置时出错', e);
    }
  }
}
