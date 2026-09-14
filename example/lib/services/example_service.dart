import 'package:xly/xly.dart';

/// 示例服务 - 演示如何在ScreenUtil初始化后安全使用.sp等扩展方法
class ExampleService extends GetxService {
  static ExampleService get to => Get.find();

  static const showWindowOnInitKey = 'show_window_on_init';
  static const hideTaskBarIconKey = 'hide_task_bar_icon';

  /// 本次进程启动时实际传给 [MyApp.initialize] 的值，由 `main` 写入。
  static bool thisLaunchShowWindowOnInit = false;

  final windowDraggable = true.obs;
  final windowResizable = false.obs;
  final smartDocking = false.obs;
  final aspectRatio = false.obs;
  final showWindowOnInit = false.obs;
  final hideTaskBarIcon = false.obs;
  late GetStorage _storage;

  static bool readShowWindowOnInit() {
    return MyStorage.box.read<bool>(showWindowOnInitKey) ?? false;
  }

  static bool readHideTaskBarIcon() {
    return MyStorage.box.read<bool>(hideTaskBarIconKey) ?? false;
  }

  @override
  Future<void> onInit() async {
    super.onInit();

    // 使用本应用命名容器（MyApp.initialize 已 init MyStorage）
    _storage = MyStorage.box;

    // 恢复窗口可拖动状态
    final savedDraggable = _storage.read('window_draggable') ?? true;
    windowDraggable.value = savedDraggable;
    await MyApp.setDraggableEnabled(savedDraggable);

    // 恢复窗口可调整大小状态
    final savedResizable = _storage.read('window_resizable') ?? true;
    windowResizable.value = savedResizable;
    await MyApp.setResizableEnabled(savedResizable);

    // 恢复智能停靠状态
    final savedSmartDocking = _storage.read('smart_docking') ?? false;
    smartDocking.value = savedSmartDocking;
    await MyApp.setSmartEdgeDocking(
      enabled: savedSmartDocking,
      visibleWidth: 10.0,
    );

    // 恢复窗口比例调整状态
    final savedAspectRatio = _storage.read('aspect_ratio') ?? false;
    aspectRatio.value = savedAspectRatio;
    await MyApp.setAspectRatioEnabled(savedAspectRatio);

    showWindowOnInit.value = readShowWindowOnInit();
    hideTaskBarIcon.value = readHideTaskBarIcon();
  }

  Future<void> setShowWindowOnInit(bool enabled) async {
    showWindowOnInit.value = enabled;
    await _storage.write(showWindowOnInitKey, enabled);
  }

  Future<void> setHideTaskBarIcon(bool hide) async {
    hideTaskBarIcon.value = hide;
    await _storage.write(hideTaskBarIconKey, hide);
  }

  Future<void> setWindowDraggable(bool enabled) async {
    windowDraggable.value = enabled;
    await MyApp.setDraggableEnabled(enabled);

    await _storage.write('window_draggable', enabled);
  }

  Future<void> setWindowResizable(bool enabled) async {
    windowResizable.value = enabled;
    await MyApp.setResizableEnabled(enabled);

    await _storage.write('window_resizable', enabled);
  }

  Future<void> setSmartDocking(bool enabled) async {
    smartDocking.value = enabled;
    await MyApp.setSmartEdgeDocking(
      enabled: enabled,
      visibleWidth: 10.0,
    );

    await _storage.write('smart_docking', enabled);
  }

  Future<void> setAspectRatio(bool enabled) async {
    aspectRatio.value = enabled;
    await MyApp.setAspectRatioEnabled(enabled);

    await _storage.write('aspect_ratio', enabled);
  }

  /// 退出应用
  Future<void> exitApp() async {
    await MyApp.exit();
  }
}
