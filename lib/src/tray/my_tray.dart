import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../smart_dock/mouse_tracker.dart';
import '../smart_dock/native_window_helper.dart';
import '../smart_dock/smart_dock_manager.dart';

/// 托盘菜单项配置类
class MyTrayMenuItem {
  final String label;
  final VoidCallback? onTap;
  final String? icon;
  final bool enabled;
  final bool isSeparator;
  final List<MyTrayMenuItem>? submenu;

  const MyTrayMenuItem({
    required this.label,
    this.onTap,
    this.icon,
    this.enabled = true,
    this.isSeparator = false,
    this.submenu,
  });

  /// 创建分隔符菜单项
  const MyTrayMenuItem.separator()
      : label = '',
        onTap = null,
        icon = null,
        enabled = true,
        isSeparator = true,
        submenu = null;
}

/// MyTray 托盘管理器
class MyTray extends GetxService with TrayListener {
  static MyTray get to => Get.find();

  // 状态管理
  final isVisible = true.obs;
  final isTrayMode = false.obs; // 新增：是否处于托盘模式
  final currentIcon = Rx<String?>(null);
  final tooltip = ''.obs;
  final _isInitialized = false.obs;

  // 构造函数参数
  final String? iconPath;
  final String? initialTooltip;
  final List<MyTrayMenuItem>? initialMenuItems;

  // 当前设置的菜单项（用于动态设置的菜单）
  List<MyTrayMenuItem>? _currentMenuItems;

  /// 构造函数 - iconPath 可选，为空时自动使用默认应用图标
  MyTray({
    this.iconPath,
    String? tooltip,
    List<MyTrayMenuItem>? menuItems,
  })  : initialTooltip = tooltip,
        initialMenuItems = menuItems {
    if (tooltip != null) {
      this.tooltip.value = tooltip;
    }
  }

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  /// 获取默认应用图标路径
  /// 根据当前桌面平台返回对应的标准应用图标路径
  ///
  /// 只检查各平台的标准路径，如果不存在则抛出异常让应用构建失败
  String _getDefaultIconPath() {
    String defaultPath;

    if (Platform.isWindows) {
      defaultPath = 'windows/runner/resources/app_icon.ico';
    } else if (Platform.isMacOS) {
      // macOS 优先使用最高分辨率的图标
      defaultPath =
          'macos/Runner/Assets.xcassets/AppIcon.appiconset/app-icon-512@2x.png';
    } else if (Platform.isLinux) {
      defaultPath = 'snap/gui/app_icon.png';
    } else {
      // 非桌面平台不支持托盘功能
      throw Exception('MyTray: 当前平台不支持系统托盘功能');
    }

    // 检查默认图标文件是否存在
    if (!File(defaultPath).existsSync()) {
      final platformName = Platform.isWindows
          ? 'Windows'
          : Platform.isMacOS
              ? 'macOS'
              : 'Linux';

      throw Exception('''
MyTray 构建错误：未找到 $platformName 平台的默认应用图标！

缺失文件：$defaultPath

解决方案：
1. 【推荐】使用 XLY 图标生成工具自动生成所有平台图标：
   dart run xly:generate icon="path/to/your/source_icon.png"

2. 手动放置图标文件到：$defaultPath

3. 在 MyTray 构造函数中明确指定自定义图标路径：
   MyTray(iconPath: "your/custom/icon/path")

提示：建议使用 1024x1024 像素的 PNG 图像作为源图标。
''');
    }

    return defaultPath;
  }

  /// 初始化托盘
  Future<void> _initialize() async {
    try {
      // 确定要使用的图标路径
      String targetIconPath = iconPath ?? _getDefaultIconPath();

      // 获取绝对路径
      String absoluteIconPath = targetIconPath;

      // 如果是相对路径，尝试解析为绝对路径
      if (!targetIconPath.startsWith('/') && !targetIconPath.contains(':')) {
        // 对于Flutter资源，尝试不同的路径解析方式
        final file = File(targetIconPath);
        if (file.existsSync()) {
          absoluteIconPath = file.absolute.path;
        } else {
          // 尝试在当前工作目录中查找
          final currentDir = Directory.current.path;
          final fullPath = '$currentDir/$targetIconPath';
          final fullFile = File(fullPath);
          if (fullFile.existsSync()) {
            absoluteIconPath = fullFile.absolute.path;
          }
        }
      }

      // 验证图标文件存在性
      if (!File(absoluteIconPath).existsSync()) {
        throw Exception('托盘图标文件不存在: $absoluteIconPath (原路径: $targetIconPath)');
      }

      // 添加托盘监听器
      trayManager.addListener(this);

      // 初始化通知插件
      await _initializeNotifications();

      // 设置托盘图标
      await trayManager.setIcon(absoluteIconPath);

      // 设置工具提示
      if (initialTooltip != null) {
        await trayManager.setToolTip(initialTooltip!);
        tooltip.value = initialTooltip!;
      }

      // 设置右键菜单（如果有的话）
      if (initialMenuItems != null && initialMenuItems!.isNotEmpty) {
        await _updateContextMenu();
      }

      currentIcon.value = absoluteIconPath;
      _isInitialized.value = true;

      if (kDebugMode) {
        print('MyTray: 托盘初始化成功，使用图标: $absoluteIconPath');
      }
    } catch (e) {
      if (kDebugMode) {
        print('MyTray: 托盘初始化失败: $e');
      }
    }
  }

  /// 初始化通知插件
  Future<void> _initializeNotifications() async {
    try {
      // 通知功能现在由 MyNotify 组件处理
      if (kDebugMode) {
        print('MyTray: 通知插件初始化成功（由MyNotify处理）');
      }
    } catch (e) {
      if (kDebugMode) {
        print('MyTray: 通知插件初始化失败: $e');
      }
    }
  }

  /// 更新右键菜单
  Future<void> _updateContextMenu() async {
    if (initialMenuItems == null || initialMenuItems!.isEmpty) return;

    try {
      final menuItems = <MenuItem>[];

      for (final item in initialMenuItems!) {
        if (item.isSeparator) {
          menuItems.add(MenuItem.separator());
        } else {
          menuItems.add(MenuItem(
            key: item.label,
            label: item.label,
          ));
        }
      }

      final menu = Menu(items: menuItems);
      await trayManager.setContextMenu(menu);
    } catch (e) {
      if (kDebugMode) {
        print('MyTray: 更新右键菜单失败: $e');
      }
    }
  }

  // TrayListener 事件处理
  @override
  Future<void> onTrayIconMouseDown() async {
    // 左键点击恢复窗口
    await pop();
  }

  @override
  Future<void> onTrayIconRightMouseDown() async {
    // 右键点击显示菜单
    if (kDebugMode) {
      print('MyTray: 托盘图标右键点击');
    }
    await trayManager.popUpContextMenu();
  }

  @override
  Future<void> onTrayMenuItemClick(MenuItem menuItem) async {
    // 处理菜单项点击事件
    if (kDebugMode) {
      print('MyTray: 菜单项点击: ${menuItem.label}');
    }

    // 查找对应的菜单项并执行回调
    if (initialMenuItems != null) {
      _handleMenuItemClick(initialMenuItems!, menuItem.key);
    }
    // 如果没有找到，尝试查找当前设置的菜单项
    if (_currentMenuItems != null) {
      _handleMenuItemClick(_currentMenuItems!, menuItem.key);
    }
  }

  /// 递归查找并处理菜单项点击
  void _handleMenuItemClick(List<MyTrayMenuItem> items, String? key) {
    for (final item in items) {
      if (item.label == key && item.onTap != null) {
        item.onTap!();
        return;
      }
      // 处理子菜单
      if (item.submenu != null) {
        _handleMenuItemClick(item.submenu!, key);
      }
    }
  }

  /// 设置托盘图标
  /// [iconPath] 图标路径，为空时使用默认应用图标
  Future<void> setIcon([String? iconPath]) async {
    try {
      if (!_isInitialized.value) return;

      // 确定要使用的图标路径
      String targetIconPath = iconPath ?? _getDefaultIconPath();

      // 获取绝对路径
      String absoluteIconPath = targetIconPath;

      // 如果是相对路径，尝试解析为绝对路径
      if (!targetIconPath.startsWith('/') && !targetIconPath.contains(':')) {
        final file = File(targetIconPath);
        if (file.existsSync()) {
          absoluteIconPath = file.absolute.path;
        } else {
          // 尝试在当前工作目录中查找
          final currentDir = Directory.current.path;
          final fullPath = '$currentDir/$targetIconPath';
          final fullFile = File(fullPath);
          if (fullFile.existsSync()) {
            absoluteIconPath = fullFile.absolute.path;
          }
        }
      }

      // 验证图标文件存在性
      if (!File(absoluteIconPath).existsSync()) {
        throw Exception('图标文件不存在: $absoluteIconPath (原路径: $targetIconPath)');
      }

      await trayManager.setIcon(absoluteIconPath);
      currentIcon.value = absoluteIconPath;

      if (kDebugMode) {
        print('MyTray: 设置图标成功: $absoluteIconPath');
      }
    } catch (e) {
      if (kDebugMode) {
        print('MyTray: 设置图标失败: $e');
      }
    }
  }

  /// 设置工具提示
  Future<void> setTooltip(String text) async {
    try {
      if (!_isInitialized.value) return;

      await trayManager.setToolTip(text);
      tooltip.value = text;

      if (kDebugMode) {
        print('MyTray: 设置工具提示成功: $text');
      }
    } catch (e) {
      if (kDebugMode) {
        print('MyTray: 设置工具提示失败: $e');
      }
    }
  }

  /// 设置右键菜单
  Future<void> setContextMenu(List<MyTrayMenuItem> items) async {
    try {
      if (!_isInitialized.value) return;

      // 保存当前菜单项
      _currentMenuItems = items;

      final menuItems = <MenuItem>[];

      for (final item in items) {
        if (item.isSeparator) {
          menuItems.add(MenuItem.separator());
        } else {
          menuItems.add(MenuItem(
            key: item.label,
            label: item.label,
          ));
        }
      }

      final menu = Menu(items: menuItems);
      await trayManager.setContextMenu(menu);

      if (kDebugMode) {
        print('MyTray: 设置右键菜单成功');
      }
    } catch (e) {
      if (kDebugMode) {
        print('MyTray: 设置右键菜单失败: $e');
      }
    }
  }

  /// 检查是否处于智能停靠模式
  bool _isInSmartDockMode() {
    try {
      // 需要导入相关模块
      return SmartDockManager.isSmartDockingEnabled() &&
          MouseTracker.state != MouseTrackingState.disabled;
    } catch (e) {
      if (kDebugMode) {
        print('MyTray: 检查智能停靠状态失败: $e');
      }
      return false;
    }
  }

  /// 进入托盘模式（智能隐藏：根据智能停靠状态决定行为）
  Future<void> hide() async {
    try {
      // 设置托盘模式状态
      isTrayMode.value = true;

      // 隐藏任务栏图标
      await windowManager.setSkipTaskbar(true);

      // 根据智能停靠状态决定是否隐藏窗口UI
      if (!_isInSmartDockMode()) {
        // 不在智能停靠状态，需要隐藏窗口UI
        await windowManager.hide();
        isVisible.value = false;

        if (kDebugMode) {
          print('MyTray: 已进入托盘模式（窗口UI已隐藏）');
        }
      } else {
        // 在智能停靠状态，只隐藏任务栏图标，让SmartDock管理窗口UI
        // 同时设置窗口为不激活任务栏模式，防止用户操作激活系统任务栏
        final noActivateResult =
            await NativeWindowHelper.setNoActivateTaskbar(true);

        if (kDebugMode) {
          print(
              'MyTray: 已进入托盘模式（智能停靠状态，窗口UI由SmartDock管理，任务栏激活控制：${noActivateResult ? "成功" : "失败"}）');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('MyTray: 进入托盘模式失败: $e');
      }
    }
  }

  /// 从托盘恢复窗口（退出托盘模式）
  Future<void> pop() async {
    try {
      // 退出托盘模式
      isTrayMode.value = false;
      await windowManager.setSkipTaskbar(false);

      // 恢复正常的任务栏激活行为
      await NativeWindowHelper.setNoActivateTaskbar(false);

      // 确保窗口可见并获得焦点
      await windowManager.show();
      await windowManager.focus();
      isVisible.value = true;

      if (kDebugMode) {
        print('MyTray: 已退出托盘模式（窗口已恢复，任务栏激活已恢复）');
      }
    } catch (e) {
      if (kDebugMode) {
        print('MyTray: 从托盘恢复失败: $e');
      }
    }
  }

  /// 销毁托盘
  Future<void> destroy() async {
    try {
      if (!_isInitialized.value) return;

      trayManager.removeListener(this);
      await trayManager.destroy();

      // 通知插件会自动清理，无需手动清理

      _isInitialized.value = false;

      if (kDebugMode) {
        print('MyTray: 托盘已销毁');
      }
    } catch (e) {
      if (kDebugMode) {
        print('MyTray: 销毁托盘失败: $e');
      }
    }
  }

  /// 检查是否已初始化
  bool get isInitialized => _isInitialized.value;

  @override
  void onClose() {
    destroy();
    super.onClose();
  }
}
