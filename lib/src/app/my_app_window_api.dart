part of '../../xly.dart';

mixin MyAppWindowApi {
  /// 获取当前双击最大化功能的状态
  /// 在智能停靠状态下自动禁用双击最大化功能
  static bool isDoubleClickMaximizeEnabled() {
    // 检查是否处于智能停靠状态
    if (SmartDockManager.isSmartDockingEnabled()) {
      return false; // 智能停靠状态下禁用双击最大化
    }
    return MyApp._globalEnableDoubleClickMaximize.value;
  }

  /// 设置双击最大化功能的启用状态
  static Future<void> setDoubleClickMaximizeEnabled(bool enabled) async {
    MyApp._globalEnableDoubleClickMaximize.value = enabled;
  }

  /// 获取当前窗口大小调整功能的状态
  static bool isResizableEnabled() {
    return MyApp._globalEnableResizable.value;
  }

  /// 设置窗口大小调整功能的启用状态
  static Future<void> setResizableEnabled(bool enabled) async {
    MyApp._globalEnableResizable.value = enabled;
    await windowManager.setResizable(enabled);
  }

  /// 获取当前窗口拖动功能的状态
  static bool isDraggableEnabled() {
    return MyApp._globalEnableDraggable.value;
  }

  /// 设置窗口拖动功能的启用状态
  static Future<void> setDraggableEnabled(bool enabled) async {
    MyApp._globalEnableDraggable.value = enabled;
  }

  /// 获取当前标题栏的隐藏状态
  static bool isTitleBarHidden() {
    return MyApp._globalTitleBarHidden.value;
  }

  /// 设置标题栏的显示/隐藏状态
  static Future<void> setTitleBarHidden(bool hidden) async {
    MyApp._globalTitleBarHidden.value = hidden;
    await windowManager.setTitleBarStyle(
      hidden ? TitleBarStyle.hidden : TitleBarStyle.normal,
      windowButtonVisibility: false, // 保持一致性
    );
  }

  /// 获取当前窗口比例调整功能的状态
  static bool isAspectRatioEnabled() {
    return MyApp._globalEnableAspectRatio.value;
  }

  /// 设置窗口比例调整功能的启用状态
  static Future<void> setAspectRatioEnabled(bool enabled) async {
    MyApp._globalEnableAspectRatio.value = enabled;
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
    if (SmartDockManager.isSmartDockingEnabled()) {
      return false; // 智能停靠状态下禁用全屏功能
    }
    return MyApp._globalEnableFullScreen.value;
  }

  /// 设置全屏功能的启用状态
  static Future<void> setFullScreenEnabled(bool enabled) async {
    MyApp._globalEnableFullScreen.value = enabled;
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
    MyApp._globalWindowTitle.value = title;
    if (MyPlatform.isDesktop) {
      try {
        await windowManager.setTitle(title);
      } catch (e) {
        XlyLogger.error('设置窗口标题失败', e);
      }
    }
  }

  static String getWindowTitle() {
    return MyApp._globalWindowTitle.value;
  }
}
