part of '../../xly.dart';

class MyApp extends StatelessWidget with MyAppWindowApi, MyAppDocking {
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

    // ── 异常处理（开箱即用） ──────────────────────────
    // 默认装好 FlutterError.onError + PlatformDispatcher.instance.onError 两个 root-level
    // 异常 hook，无需用户自己包 runZonedGuarded 即可覆盖 widget 树异常和未捕获异步异常。
    // 检测到外部已设置过这两个 hook 时会跳过自动安装并打 warning，不抢用户既有逻辑。
    bool installErrorHandlers = true,
    // 自定义异常 sink；不传则统一走 XlyLogger.error 打日志。
    // 接 Sentry / Crashlytics 时把上报回调传进来即可，例如：
    //   onError: (e, st) => Sentry.captureException(e, stackTrace: st)
    void Function(Object error, StackTrace stack)? onError,

    // ── Zone 守护（默认关闭，向后兼容保留参数） ─────────
    // ⚠️ 0.38.2 起默认值由 true 改为 false。
    // 默认关的原因：Zone Guard 是"应用边界"决策，不是库的责任。开了之后，xly 的内部 Zone
    // 会跟用户在 main 里自己写的 runZonedGuarded / WidgetsFlutterBinding.ensureInitialized()
    // 冲突，启动时抛 `Zone mismatch`（典型踩坑：Sentry / Crashlytics 标准接入流程）。
    // 默认走 `installErrorHandlers` 路线已经能覆盖 99% 的应用异常需求，无需 Zone。
    // 仍想用 Zone Guard（拦截自定义 print/Timer/Microtask 等）时显式传 true 即可，
    // binding 已经被前置到 Zone 之外初始化，不会再有 mismatch。
    bool enableZoneGuard = false,
  }) async {
    // 首先初始化日志系统，以便后续初始化步骤可以使用日志
    XlyLogger.init(enabled: enableDebugLogging);
    XlyLogger.info('MyApp 初始化开始');

    // ⚠️ binding 必须在调用方当前 Zone 中初始化，并且必须先于任何可能新建 Zone 的逻辑
    // （包括下面的 enableZoneGuard 分支）。Flutter 铁律：binding 与 runApp 必须同 Zone，
    // 否则 framework 启动时直接抛 `Zone mismatch`。`ensureInitialized()` 本身幂等，
    // 用户在 main 里已经手动调过也不会冲突。
    if (initializeWidgetsBinding) {
      WidgetsFlutterBinding.ensureInitialized();
    }

    // 安装全局异常 hook（FlutterError.onError + PlatformDispatcher.onError）
    // 见 _installErrorHandlers 注释：检测到外部已设置就跳过，不抢用户逻辑。
    if (installErrorHandlers) {
      _installErrorHandlers(onError);
    }

    Future<void> initializeInCurrentZone() async {
      if (ensureScreenSize) {
        await ScreenUtil.ensureScreenSize();
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
      List<MyService> finalServices =
          services != null ? List.from(services) : [];

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

    if (enableZoneGuard) {
      // 老用户显式开 Zone Guard 时仍然支持。
      // binding 已在 Zone 外初始化（见函数顶部），不会触发 Zone mismatch。
      await runZonedGuarded(
        () async {
          await initializeInCurrentZone();
        },
        (error, stackTrace) {
          XlyLogger.error('MyApp 初始化阶段未捕获异常 (Zone Guard)', error, stackTrace);
          onError?.call(error, stackTrace);
          Error.throwWithStackTrace(error, stackTrace);
        },
      );
      return;
    }

    // 默认路径：try/catch 兜底初始化阶段异常。
    // 运行时异步异常由 _installErrorHandlers 装的 root-level hook 兜底，无需 Zone。
    try {
      await initializeInCurrentZone();
    } catch (error, stackTrace) {
      XlyLogger.error('MyApp 初始化失败', error, stackTrace);
      // 初始化失败是致命的：直接 rethrow 让 main 看到，避免被 onError 沉默吞掉
      rethrow;
    }
  }

  /// 安装 root-level 异常 hook，作为 `runZonedGuarded` 的轻量替代。
  ///
  /// 同时装两个 hook 覆盖 Flutter 几乎所有异常源：
  /// - `FlutterError.onError`：Widget 构建/布局/绘制阶段、framework 异步错误
  /// - `PlatformDispatcher.instance.onError`：所有 Zone 抛到 root 的未捕获异步异常
  ///   （Flutter 3.3+ 引入的 root-level hook，不依赖任何 Zone）
  ///
  /// 检测策略——只在 hook 仍是默认值时安装，避免覆盖用户自定义逻辑：
  /// - `FlutterError.onError` 默认是 `FlutterError.presentError`，不等于它就跳过
  /// - `PlatformDispatcher.instance.onError` 默认是 `null`，不为 `null` 就跳过
  ///
  /// 高级用户接 Sentry / Crashlytics 时可走两条路：
  /// 1. 传入 `onError` 参数：xly 自己装 hook，把异常 sink 给用户的 callback
  /// 2. 自己手动设 `FlutterError.onError` / `PlatformDispatcher.onError` 后再调 initialize：
  ///    xly 检测到已设置就跳过，完全交回用户掌控
  static void _installErrorHandlers(
      void Function(Object error, StackTrace stack)? sink) {
    final defaultSink = sink ??
        (Object e, StackTrace st) =>
            XlyLogger.error('未捕获异常 (PlatformDispatcher/FlutterError)', e, st);

    if (FlutterError.onError == FlutterError.presentError) {
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        defaultSink(details.exception, details.stack ?? StackTrace.empty);
      };
    } else {
      XlyLogger.warning('FlutterError.onError 已被外部设置，xly 跳过自动安装；'
          '若想接管 widget 树异常，请把异常 sink 通过 MyApp.initialize(onError: ...) 注入。');
    }

    if (PlatformDispatcher.instance.onError == null) {
      PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
        defaultSink(error, stack);
        return true; // 标记已处理，避免再 propagate 到 root error handler
      };
    } else {
      XlyLogger.warning('PlatformDispatcher.instance.onError 已被外部设置，xly 跳过自动安装；'
          '若想接管异步异常，请把异常 sink 通过 MyApp.initialize(onError: ...) 注入。');
    }
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
                  // 只传缩放基础值，其他配置由 controller 从 FloatPanel.to 实时读取
                  return _FloatBoxPanel(
                    panelWidthInput: fp.panelWidth.value,
                    borderRadiusInput: fp.borderRadius.value,
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
}
