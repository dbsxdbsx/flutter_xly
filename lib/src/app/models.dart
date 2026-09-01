part of '../../app.dart';

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

/// [MyApp.initialize] `bootstrap` 项的失败等级。未分级时按 [degraded]。
enum MyBootstrapSeverity {
  /// 没有它不能装成已启动：叠层停在错误态，不揭开首页。
  fatal,

  /// 壳能出，但缺一块能力：按公式揭开，首页须能表达缺失。
  degraded,

  /// 增强项：失败只打日志，不影响门闩。
  optional,
}

/// 无 tag 的 `void` / `dynamic` 被登记进 GetX。门闩按 fatal 处理，不看 [MyBootstrapSeverity]。
///
/// GetX 注册键是 Type+tag，公开 API 无法枚举 tag，因此带 tag 的擦除登记检测不到。
class MyBootstrapContractError extends StateError {
  MyBootstrapContractError(
    super.message, {
    this.cause,
    this.causeStackTrace,
  });

  /// 同一任务里先污染 DI、随后又抛出的原始异常。
  final Object? cause;
  final StackTrace? causeStackTrace;
}

/// 首帧提交后再跑的 blocking 初始化项。
///
/// 旧 [MyService] 列表仍在 `runApp` 前注册，语义不变。
/// 首页数据层应 `await MyApp.bootstrapReady`，不要对未就绪依赖直接 `Get.find`。
///
/// 任意工作走 [run]。登记异步 GetX 服务走 [putAsync]。
class MyBootstrapTask {
  MyBootstrapTask._(
    this._body, {
    this.severity = MyBootstrapSeverity.degraded,
    this.debugLabel,
  });

  /// 任意会完成的工作。返回类型由闭包推断，不会预先钉成 `void`。
  static MyBootstrapTask run<T>(
    Future<T> Function() body, {
    MyBootstrapSeverity severity = MyBootstrapSeverity.degraded,
    String? debugLabel,
  }) {
    return MyBootstrapTask._(
      () => _executeGuarded(body),
      severity: severity,
      debugLabel: debugLabel,
    );
  }

  /// 带类型地把异步服务登记进 GetX（[permanent] / [tag] 原样交给 GetX）。
  static MyBootstrapTask putAsync<T extends Object>(
    Future<T> Function() builder, {
    MyBootstrapSeverity severity = MyBootstrapSeverity.degraded,
    String? debugLabel,
    bool permanent = false,
    String? tag,
  }) {
    return run(
      () => Get.putAsync<T>(builder, permanent: permanent, tag: tag),
      severity: severity,
      debugLabel: debugLabel,
    );
  }

  final Future<void> Function() _body;
  final MyBootstrapSeverity severity;
  final String? debugLabel;

  /// 门闩与测试调用。
  Future<void> execute() => _body();

  static Future<void> _executeGuarded<T>(Future<T> Function() body) async {
    final voidBefore = Get.isRegistered<void>();
    final dynamicBefore = Get.isRegistered<dynamic>();
    Object? thrown;
    StackTrace? thrownSt;
    try {
      await body();
    } catch (e, st) {
      thrown = e;
      thrownSt = st;
    }

    final voidAdded = !voidBefore && Get.isRegistered<void>();
    final dynamicAdded = !dynamicBefore && Get.isRegistered<dynamic>();
    if (voidAdded) {
      await Get.delete<void>(force: true);
    }
    if (dynamicAdded) {
      await Get.delete<dynamic>(force: true);
    }
    if (voidAdded || dynamicAdded) {
      throw MyBootstrapContractError(
        'MyBootstrapTask: GetX 把实例登记成了 '
        '${voidAdded ? 'void' : 'dynamic'}。'
        '登记异步服务请用 MyBootstrapTask.putAsync<YourType>(...)。',
        cause: thrown,
        causeStackTrace: thrownSt,
      );
    }
    if (thrown != null) {
      Error.throwWithStackTrace(thrown, thrownSt!);
    }
  }
}

/// 启动叠层门闩阶段。
enum MySplashPhase {
  /// 正在跑 blocking bootstrap，或还在等品牌一圈 / 静态脸 [MySplash.minVisible]。
  running,

  /// blocking 项全部成功。
  ready,

  /// 仅 degraded / optional 失败，或 bootstrap 超时且无未决 fatal。
  degraded,

  /// 有 fatal 失败：叠层留错误态。
  fatal,

  /// 已按公式揭开（或无叠层）。
  finished,
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
    // 窗口拖动/最大化是桌面物理能力，window_manager 在移动端无实现，
    // 直接调用会抛 MissingPluginException。框架层兜底：非桌面平台零开销透传。
    if (!MyPlatform.isDesktop) return child;
    return GestureDetector(
      onPanStart: draggable
          ? (details) async {
              // 运行时再次检查，兜底 Obx 重建前的竞态窗口
              if (!MyApp._globalEnableDraggable.value) return;
              await windowManager.startDragging();
            }
          : null,
      onDoubleTap: enableDoubleClickMaximize
          ? () async {
              // 检查是否处于智能停靠状态
              if (MySmartDock.isSmartDockingEnabled()) {
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

/// 拖拽保护区域，用于解决子组件拖拽手势与窗口拖拽之间的竞争冲突。
///
/// 桌面端 [CustomDragArea] 的 `onPanStart` 会拦截所有 pan 手势来触发
/// `windowManager.startDragging()`，导致 [ReorderableListView]、[Draggable]
/// 等需要拖拽手势的组件无法正常工作。
///
/// 本组件通过在 pointer 事件层（早于手势识别阶段）临时禁用窗口拖拽来解决此问题：
/// - `onPointerDown`: 保存当前拖拽状态并禁用窗口拖拽
/// - `onPointerUp` / `onPointerCancel`: 恢复先前的拖拽状态
///
/// 移动端不存在此问题，组件会直接返回 [child]，零开销。
///
/// 示例：
/// ```dart
/// MyDragProtectedArea(
///   child: ReorderableListView(
///     children: items,
///     onReorder: (oldIndex, newIndex) { /* ... */ },
///   ),
/// )
/// ```
class MyDragProtectedArea extends StatefulWidget {
  final Widget child;

  const MyDragProtectedArea({
    super.key,
    required this.child,
  });

  @override
  State<MyDragProtectedArea> createState() => _MyDragProtectedAreaState();
}

class _MyDragProtectedAreaState extends State<MyDragProtectedArea> {
  bool _savedDraggable = true;

  void _onPointerDown(PointerDownEvent _) {
    _savedDraggable = MyApp._globalEnableDraggable.value;
    MyApp._globalEnableDraggable.value = false;
  }

  void _onPointerUp(PointerUpEvent _) {
    MyApp._globalEnableDraggable.value = _savedDraggable;
  }

  void _onPointerCancel(PointerCancelEvent _) {
    MyApp._globalEnableDraggable.value = _savedDraggable;
  }

  @override
  Widget build(BuildContext context) {
    if (!MyPlatform.isDesktop) return widget.child;
    return Listener(
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: widget.child,
    );
  }
}
