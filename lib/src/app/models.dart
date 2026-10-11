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

/// 桌面端整窗拖拽与双击最大化的根手势层。
///
/// 双击检测**只**在 [Listener] 层做，全程不参与手势竞技场。这里**禁止**注册
/// [DoubleTapGestureRecognizer]（哪怕回调是空的）：它会让全 App 每一次点击都被
/// hold 约 300ms，且双击时内层 `onTap` / `onTapDown` 可能一次都不触发。
///
/// 拖拽用 [MyWindowDragGestureRecognizer]，而不是默认的 `PanGestureRecognizer`
///（鼠标只要 2px 就认，点击手抖足以把 pointer 交给操作系统原生移动循环）。
///
/// 双击按 hitTest 分成三种情况，见 [classifyDesktopHit]。
class CustomDragArea extends StatefulWidget {
  final Widget child;
  final bool enableDoubleClickMaximize;
  final bool draggable;

  /// 测试或自定义最大化切换；为 null 时走 `window_manager`。
  final Future<void> Function()? onToggleMaximize;

  const CustomDragArea({
    super.key,
    required this.child,
    required this.enableDoubleClickMaximize,
    required this.draggable,
    this.onToggleMaximize,
  });

  @override
  State<CustomDragArea> createState() => _CustomDragAreaState();
}

class _CustomDragAreaState extends State<CustomDragArea> {
  Offset? _currentDownPos;
  DateTime? _lastTapTime;
  Offset? _lastTapPos;

  /// 第二次 DOWN 时预先缓存的分类，避免内层回调改树后 UP 时误判成 background。
  MyDesktopHitKind? _preClassifiedHit;

  static const _kTapMoveTolerance = kDoubleTapSlop;

  void _onPointerDown(PointerDownEvent event) {
    if (event.kind != PointerDeviceKind.mouse) return;
    _currentDownPos = event.position;

    if (_lastTapTime != null &&
        _lastTapPos != null &&
        DateTime.now().difference(_lastTapTime!) < kDoubleTapTimeout &&
        (event.position - _lastTapPos!).distance < kDoubleTapSlop) {
      _preClassifiedHit = classifyDesktopHit(event.position);
    } else {
      _preClassifiedHit = null;
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    if (event.kind != PointerDeviceKind.mouse) return;
    final downPos = _currentDownPos;
    _currentDownPos = null;
    if (downPos == null) return;

    if ((event.position - downPos).distance > _kTapMoveTolerance) {
      _lastTapTime = null;
      _lastTapPos = null;
      _preClassifiedHit = null;
      return;
    }

    final now = DateTime.now();
    if (_lastTapTime != null &&
        _lastTapPos != null &&
        now.difference(_lastTapTime!) < kDoubleTapTimeout &&
        (event.position - _lastTapPos!).distance < kDoubleTapSlop) {
      _onMouseDoubleTap(event.position);
      _lastTapTime = null;
      _lastTapPos = null;
      return;
    }

    _lastTapTime = now;
    _lastTapPos = event.position;
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (event.kind != PointerDeviceKind.mouse) return;
    _currentDownPos = null;
    _preClassifiedHit = null;
    _lastTapTime = null;
    _lastTapPos = null;
  }

  void _onMouseDoubleTap(Offset globalPosition) {
    if (!widget.enableDoubleClickMaximize) return;
    final classification =
        _preClassifiedHit ?? classifyDesktopHit(globalPosition);
    _preClassifiedHit = null;

    switch (classification) {
      case MyDesktopHitKind.editable:
      case MyDesktopHitKind.interactive:
        return;
      case MyDesktopHitKind.background:
        _toggleWindowMaximize();
    }
  }

  Future<void> _toggleWindowMaximize() async {
    if (MySmartDock.isSmartDockingEnabled()) {
      XlyLogger.debug('智能停靠状态下已禁用双击最大化功能');
      return;
    }

    final custom = widget.onToggleMaximize;
    if (custom != null) {
      await custom();
      return;
    }

    try {
      final isMaximized = await windowManager.isMaximized();
      if (isMaximized) {
        await windowManager.restore();
      } else {
        await windowManager.maximize();
      }
    } catch (e) {
      XlyLogger.warning('窗口最大化切换失败: $e');
    }
  }

  bool _isSuspectedSecondTap(Offset globalPosition) {
    final lastTime = _lastTapTime;
    final lastPos = _lastTapPos;
    if (lastTime == null || lastPos == null) return false;
    return DateTime.now().difference(lastTime) < kDoubleTapTimeout &&
        (globalPosition - lastPos).distance < kDoubleTapSlop;
  }

  bool _isWindowDragEnabled() =>
      widget.draggable && MyApp._globalEnableDraggable.value;

  void _onWindowDragStart(DragStartDetails details) {
    if (!_isWindowDragEnabled()) return;
    if (_isSuspectedSecondTap(details.globalPosition)) return;
    windowManager.startDragging();
  }

  @override
  Widget build(BuildContext context) {
    // 窗口拖动/最大化是桌面物理能力，window_manager 在移动端无实现。
    // 传入 [CustomDragArea.onToggleMaximize] 时仍挂 Listener，便于 widget 测试
    // （测试绑定默认是 Android，[MyPlatform.isDesktop] 为 false）。
    if (!MyPlatform.isDesktop && widget.onToggleMaximize == null) {
      return widget.child;
    }

    Widget result = widget.child;
    // 桌面端恒挂识别器，开关只在识别器内部判断。若随 [draggable] 增删这一层，
    // Listener 的 child 类型会变，整棵 App 子树（含 Navigator）被卸载重挂，
    // 页面状态全丢、正在进行的手势也断掉。
    if (MyPlatform.isDesktop) {
      result = RawGestureDetector(
        behavior: HitTestBehavior.translucent,
        gestures: <Type, GestureRecognizerFactory>{
          MyWindowDragGestureRecognizer: GestureRecognizerFactoryWithHandlers<
              MyWindowDragGestureRecognizer>(
            () => MyWindowDragGestureRecognizer(debugOwner: this),
            (instance) => instance
              ..isEnabled = _isWindowDragEnabled
              ..onStart = _onWindowDragStart,
          ),
        },
        child: result,
      );
    }

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: result,
    );
  }
}

/// 拖拽保护区域，用于解决子组件拖拽手势与窗口拖拽之间的竞争冲突。
///
/// 桌面端 [CustomDragArea] 的窗口拖拽识别器会与子组件拖拽手势竞争，
/// 导致 [ReorderableDelayedDragStartListener]、[Draggable] 等组件
/// 一挪鼠标就变成拖整扇窗口。
///
/// 现在等价于 [MyWindowDragExcludeZone]：在本区域按下的 pointer，窗口拖拽
/// 识别器直接不追踪。旧实现靠按下时翻转全局 `draggable`，会让
/// [CustomDragArea] 增删一层 [RawGestureDetector]，把整棵 App 子树卸载重挂。
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
class MyDragProtectedArea extends StatelessWidget {
  final Widget child;

  const MyDragProtectedArea({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!MyPlatform.isDesktop) return child;
    return MyWindowDragExcludeZone(child: child);
  }
}
