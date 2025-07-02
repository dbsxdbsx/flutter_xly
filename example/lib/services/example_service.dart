import 'package:xly/xly.dart';

/// 示例服务 - 演示如何在ScreenUtil初始化后安全使用.sp等扩展方法
class ExampleService extends GetxService {
  static ExampleService get to => Get.find();

  final windowDraggable = true.obs;
  final windowResizable = false.obs;

  @override
  Future<void> onInit() async {
    super.onInit();

    // 初始化SharedPreferences
    final prefs = await SharedPreferences.getInstance();

    // 恢复窗口可拖动状态
    final savedDraggable = prefs.getBool('window_draggable') ?? true;
    windowDraggable.value = savedDraggable;
    await MyApp.setDraggableEnabled(savedDraggable);

    // 恢复窗口可调整大小状态
    final savedResizable = prefs.getBool('window_resizable') ?? true;
    windowResizable.value = savedResizable;
    await MyApp.setResizableEnabled(savedResizable);
  }

  Future<void> setWindowDraggable(bool enabled) async {
    windowDraggable.value = enabled;
    await MyApp.setDraggableEnabled(enabled);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('window_draggable', enabled);
  }

  Future<void> setWindowResizable(bool enabled) async {
    windowResizable.value = enabled;
    await MyApp.setResizableEnabled(enabled);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('window_resizable', enabled);
  }
}
