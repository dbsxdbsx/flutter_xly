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
              // 运行时再次检查，兜底 Obx 重建前的竞态窗口
              if (!MyApp._globalEnableDraggable.value) return;
              await windowManager.startDragging();
            }
          : null,
      onDoubleTap: enableDoubleClickMaximize
          ? () async {
              // 检查是否处于智能停靠状态
              if (SmartDockManager.isSmartDockingEnabled()) {
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
