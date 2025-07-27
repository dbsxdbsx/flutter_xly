import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

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
  final currentIcon = Rx<String?>(null);
  final tooltip = ''.obs;
  final _isInitialized = false.obs;

  // 构造函数参数
  final String iconPath;
  final String? initialTooltip;
  final List<MyTrayMenuItem>? initialMenuItems;

  // 当前设置的菜单项（用于动态设置的菜单）
  List<MyTrayMenuItem>? _currentMenuItems;

  /// 构造函数 - 需要强制提供图标路径
  MyTray({
    required this.iconPath,
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

  /// 初始化托盘
  Future<void> _initialize() async {
    try {
      // 获取绝对路径
      String absoluteIconPath = iconPath;

      // 如果是相对路径，尝试解析为绝对路径
      if (!iconPath.startsWith('/') && !iconPath.contains(':')) {
        // 对于Flutter资源，尝试不同的路径解析方式
        final file = File(iconPath);
        if (file.existsSync()) {
          absoluteIconPath = file.absolute.path;
        } else {
          // 尝试在当前工作目录中查找
          final currentDir = Directory.current.path;
          final fullPath = '$currentDir/$iconPath';
          final fullFile = File(fullPath);
          if (fullFile.existsSync()) {
            absoluteIconPath = fullFile.absolute.path;
          }
        }
      }

      // 验证图标文件存在性
      if (!File(absoluteIconPath).existsSync()) {
        throw Exception('托盘图标文件不存在: $absoluteIconPath (原路径: $iconPath)');
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
  Future<void> setIcon(String iconPath) async {
    try {
      if (!_isInitialized.value) return;

      // 获取绝对路径
      String absoluteIconPath = iconPath;

      // 如果是相对路径，尝试解析为绝对路径
      if (!iconPath.startsWith('/') && !iconPath.contains(':')) {
        final file = File(iconPath);
        if (file.existsSync()) {
          absoluteIconPath = file.absolute.path;
        } else {
          // 尝试在当前工作目录中查找
          final currentDir = Directory.current.path;
          final fullPath = '$currentDir/$iconPath';
          final fullFile = File(fullPath);
          if (fullFile.existsSync()) {
            absoluteIconPath = fullFile.absolute.path;
          }
        }
      }

      // 验证图标文件存在性
      if (!File(absoluteIconPath).existsSync()) {
        throw Exception('图标文件不存在: $absoluteIconPath (原路径: $iconPath)');
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

  /// 隐藏窗口到托盘
  Future<void> hide() async {
    try {
      await windowManager.hide();
      isVisible.value = false;

      if (kDebugMode) {
        print('MyTray: 窗口已隐藏到托盘');
      }
    } catch (e) {
      if (kDebugMode) {
        print('MyTray: 隐藏到托盘失败: $e');
      }
    }
  }

  /// 从托盘恢复窗口
  Future<void> pop() async {
    try {
      await windowManager.show();
      await windowManager.focus();
      isVisible.value = true;

      if (kDebugMode) {
        print('MyTray: 窗口已从托盘恢复');
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
