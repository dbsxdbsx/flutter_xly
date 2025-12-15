import 'dart:async';
import 'dart:io';

import 'package:get/get.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'package:xly/src/smart_dock/smart_dock.dart';

import '../logger.dart';
import '../platform.dart';
import '../smart_dock/mouse_tracker.dart';
import '../smart_dock/native_window_helper.dart';

/// 托盘菜单项配置类
class MyTrayMenuItem {
  /// 稳定键，用于唯一标识菜单项；不提供时回退使用 label
  final String? key;
  final String label;
  final FutureOr<void> Function()? onTap;
  final String? icon;
  final bool enabled;
  final bool isSeparator;
  final List<MyTrayMenuItem>? submenu;

  const MyTrayMenuItem({
    this.key,
    required this.label,
    this.onTap,
    this.icon,
    this.enabled = true,
    this.isSeparator = false,
    this.submenu,
  });

  /// 创建分隔符菜单项
  const MyTrayMenuItem.separator()
      : key = null,
        label = '',
        onTap = null,
        icon = null,
        enabled = true,
        isSeparator = true,
        submenu = null;

  /// 便捷复制（不可变模式）
  MyTrayMenuItem copyWith({
    String? key,
    String? label,
    FutureOr<void> Function()? onTap,
    String? icon,
    bool? enabled,
    bool? isSeparator,
    List<MyTrayMenuItem>? submenu,
  }) {
    return MyTrayMenuItem(
      key: key ?? this.key,
      label: label ?? this.label,
      onTap: onTap ?? this.onTap,
      icon: icon ?? this.icon,
      enabled: enabled ?? this.enabled,
      isSeparator: isSeparator ?? this.isSeparator,
      submenu: submenu ?? this.submenu,
    );
  }
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

  // 对外只读访问器：获取当前策略
  bool get hideTaskBarIcon => _hideTaskBarIcon.value;
  // 任务栏图标策略：托盘存在时是否隐藏任务栏图标（全局策略，可运行时调整）
  final _hideTaskBarIcon = true.obs;
  // 构造函数参数
  final String? iconPath;
  final String? initialTooltip;
  final List<MyTrayMenuItem>? initialMenuItems;
  // 新增：是否左击托盘切换显示/隐藏（可运行时修改）
  final _toggleOnClick = true.obs;

  // 私有：用于智能停靠下的切换记忆
  bool _smartDockShownByTray = false;

  // 当前设置的菜单项（用于动态设置的菜单）
  List<MyTrayMenuItem>? _currentMenuItems;

  /// 构造函数 - iconPath 可选，为空时自动使用默认应用图标
  MyTray({
    this.iconPath,
    String? tooltip,
    List<MyTrayMenuItem>? menuItems,
    bool hideTaskBarIcon = true,
    bool toggleOnClick = true,
  })  : initialTooltip = tooltip,
        initialMenuItems = menuItems {
    _hideTaskBarIcon.value = hideTaskBarIcon;
    _toggleOnClick.value = toggleOnClick;
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

    // 不再在此处强制检查默认图标是否存在
    // 交由初始化阶段的路径解析与兜底机制处理；若最终找不到会在 _initialize 抛出清晰错误
    return defaultPath;
  }

  /// 解析托盘图标的最终绝对路径（统一逻辑，兼容Debug/Release与不同启动方式）
  Future<String> _resolveIconPath([String? providedPath]) async {
    // 确定目标相对/绝对路径：为空则使用平台默认的“应用图标相对路径”
    final String targetIconPath = providedPath ?? _getDefaultIconPath();

    // 若已是绝对路径（如带盘符/根路径），直接校验返回
    if (targetIconPath.startsWith('/') || targetIconPath.contains(':')) {
      if (!File(targetIconPath).existsSync()) {
        throw Exception('图标文件不存在: $targetIconPath');
      }
      return File(targetIconPath).absolute.path;
    }

    // 1) 直接/当前目录（工程根或运行目录）
    final directFile = File(targetIconPath);
    if (directFile.existsSync()) return directFile.absolute.path;

    final currentDir = Directory.current.path;
    final curJoin = File('$currentDir/$targetIconPath');
    if (curJoin.existsSync()) return curJoin.absolute.path;

    // 2) 优先检查自动生成的图标资产（统一路径）
    try {
      final exeDir = await MyPlatform.getAppDirectory();
      String autoGenFileName;
      if (Platform.isWindows) {
        autoGenFileName = 'app_icon.ico';
      } else {
        autoGenFileName = 'app_icon.png'; // macOS 和 Linux 都用 PNG
      }

      final autoGenPath =
          '$exeDir/data/flutter_assets/assets/_auto_tray_icon_gen/$autoGenFileName';
      final autoGenFile = File(autoGenPath);
      if (autoGenFile.existsSync()) return autoGenFile.absolute.path;
    } catch (_) {
      // 忽略，继续尝试其他路径
    }

    // 3) 发布结构：<exeDir>/data/flutter_assets/<targetIconPath>（向后兼容）
    try {
      final exeDir = await MyPlatform.getAppDirectory();
      final assetsPath = '$exeDir/data/flutter_assets/$targetIconPath';
      final assetsFile = File(assetsPath);
      if (assetsFile.existsSync()) return assetsFile.absolute.path;
    } catch (_) {
      // 忽略，走下一步资产复制兜底
    }

    // 4) 资产复制兜底：从 assets/_auto_tray_icon_gen/<fileName> 复制到应用目录
    try {
      String autoGenFileName;
      if (Platform.isWindows) {
        autoGenFileName = 'app_icon.ico';
      } else {
        autoGenFileName = 'app_icon.png';
      }

      final pasted = await MyPlatform.getFilePastedFromAssets(
          '_auto_tray_icon_gen/$autoGenFileName');
      if (await pasted.exists()) return pasted.path;
    } catch (_) {
      // 继续尝试原有路径兜底
    }

    // 5) 最后兜底：从原始平台路径复制
    try {
      final pasted = await MyPlatform.getFilePastedFromAssets(targetIconPath);
      if (await pasted.exists()) return pasted.path;
    } catch (_) {
      // 复制失败时继续抛出统一异常
    }

    throw Exception('托盘图标文件未找到，期望: $targetIconPath');
  }

  /// 初始化托盘
  Future<void> _initialize() async {
    try {
      // 统一解析图标路径
      final absoluteIconPath = await _resolveIconPath(iconPath);

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

      // 应用任务栏图标显示策略（隐藏/显示）
      await windowManager.setSkipTaskbar(_hideTaskBarIcon.value);

      XlyLogger.info('MyTray: 托盘初始化成功，使用图标: $absoluteIconPath');
    } catch (e) {
      XlyLogger.error('MyTray: 托盘初始化失败', e);
    }
  }

  /// 初始化通知插件
  Future<void> _initializeNotifications() async {
    try {
      // 通知功能现在由 MyNotify 组件处理
      XlyLogger.info('MyTray: 通知插件初始化成功（由MyNotify处理）');
    } catch (e) {
      XlyLogger.error('MyTray: 通知插件初始化失败', e);
    }
  }

  /// 更新右键菜单（使用原生 disabled 与 onClick 实现禁用与点击回调）
  Future<void> _updateContextMenu() async {
    if (initialMenuItems == null || initialMenuItems!.isEmpty) return;

    try {
      final menu = Menu(items: _buildMenuItems(initialMenuItems!));
      await trayManager.setContextMenu(menu);
    } catch (e) {
      XlyLogger.error('MyTray: 更新右键菜单失败', e);
    }
  }

  /// 将 MyTrayMenuItem 列表映射为 menu_base.MenuItem 列表
  List<MenuItem> _buildMenuItems(List<MyTrayMenuItem> items) {
    final result = <MenuItem>[];
    for (final item in items) {
      if (item.isSeparator) {
        result.add(MenuItem.separator());
        continue;
      }
      final displayKey = item.key ?? item.label;
      if (item.submenu != null && item.submenu!.isNotEmpty) {
        result.add(
          MenuItem.submenu(
            key: displayKey,
            label: item.label,
            disabled: !item.enabled,
            submenu: Menu(items: _buildMenuItems(item.submenu!)),
            onClick: (_) async {
              if (item.onTap != null) {
                try {
                  await item.onTap!();
                } catch (e, s) {
                  XlyLogger.error('MyTrayMenuItem.onTap error: $e', s);
                }
              }
            },
          ),
        );
      } else {
        result.add(
          MenuItem(
            key: displayKey,
            label: item.label,
            disabled: !item.enabled,
            onClick: (_) async {
              if (item.onTap != null) {
                try {
                  await item.onTap!();
                } catch (e, s) {
                  XlyLogger.error('MyTrayMenuItem.onTap error: $e', s);
                }
              }
            },
          ),
        );
      }
    }
    return result;
  }

  // TrayListener 事件处理
  @override
  Future<void> onTrayIconMouseDown() async {
    // 左键点击行为：
    // - 当 toggleOnClick=false：保持现状（智能停靠下模拟悬停弹出；否则恢复显示并聚焦）
    // - 当 toggleOnClick=true：切换语义
    if (!_toggleOnClick.value) {
      if (_isInSmartDockMode()) {
        await MouseTracker.simulateHoverReveal();
      } else {
        await pop();
      }
      return;
    }

    if (_isInSmartDockMode()) {
      // 智能停靠：在“无激活弹出”和“强制收起到隐藏位”之间切换
      if (_smartDockShownByTray) {
        await MouseTracker.forceCollapseToHidden();
        _smartDockShownByTray = false;
      } else {
        await MouseTracker.simulateHoverReveal();
        _smartDockShownByTray = true;
      }
    } else {
      // 非智能停靠：在 hide()/pop() 之间切换
      if (isTrayMode.value || !isVisible.value) {
        await pop();
        _smartDockShownByTray = false;
      } else {
        await hide();
      }
    }
  }

  @override
  Future<void> onTrayIconRightMouseDown() async {
    // 右键点击显示菜单
    XlyLogger.debug('MyTray: 托盘图标右键点击');

    // 修复Windows上托盘菜单无法通过点击空白区域关闭的问题
    // 参考：https://github.com/leanflutter/tray_manager/issues/63
    // 注意：bringAppToFront参数虽被标记为deprecated，但仍是解决此问题的最简方案
    await trayManager.popUpContextMenu(bringAppToFront: true);
  }

  @override
  Future<void> onTrayMenuItemClick(MenuItem menuItem) async {
    // 原生 onClick 已触发回调，这里仅记录日志与兼容处理
    XlyLogger.debug('MyTray: 菜单项点击: ${menuItem.key}/${menuItem.label}');
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

      // 如果是相对路径，尝试解析为绝对路径（Debug/Release 兼容）
      if (!targetIconPath.startsWith('/') && !targetIconPath.contains(':')) {
        // 1) 直接路径（工程根目录或当前工作目录）
        final directFile = File(targetIconPath);
        if (directFile.existsSync()) {
          absoluteIconPath = directFile.absolute.path;
        } else {
          // 2) 当前工作目录拼接
          final currentDir = Directory.current.path;
          final fullPath = '$currentDir/$targetIconPath';
          final fullFile = File(fullPath);
          if (fullFile.existsSync()) {
            absoluteIconPath = fullFile.absolute.path;
          } else {
            // 3) 发布版目录结构兜底：<exeDir>/data/flutter_assets/<targetIconPath>
            try {
              final exeDir = File(Platform.resolvedExecutable).parent.path;
              final assetsPath = '$exeDir/data/flutter_assets/$targetIconPath';
              final assetsFile = File(assetsPath);
              if (assetsFile.existsSync()) {
                absoluteIconPath = assetsFile.absolute.path;
              }
            } catch (_) {
              // 忽略解析异常
            }
          }
        }
      }

      // 验证图标文件存在性
      if (!File(absoluteIconPath).existsSync()) {
        throw Exception('图标文件不存在: $absoluteIconPath (原路径: $targetIconPath)');
      }

      await trayManager.setIcon(absoluteIconPath);
      currentIcon.value = absoluteIconPath;

      XlyLogger.info('MyTray: 设置图标成功: $absoluteIconPath');
    } catch (e) {
      XlyLogger.error('MyTray: 设置图标失败', e);
    }
  }

  /// 设置工具提示
  Future<void> setTooltip(String text) async {
    try {
      if (!_isInitialized.value) return;

      await trayManager.setToolTip(text);
      tooltip.value = text;

      XlyLogger.info('MyTray: 设置工具提示成功: $text');
    } catch (e) {
      XlyLogger.error('MyTray: 设置工具提示失败', e);
    }
  }

  /// 设置右键菜单
  Future<void> setContextMenu(List<MyTrayMenuItem> items) async {
    try {
      if (!_isInitialized.value) return;

      // 保存当前菜单项
      _currentMenuItems = items;

      final menu = Menu(items: _buildMenuItems(items));
      await trayManager.setContextMenu(menu);

      XlyLogger.info('MyTray: 设置右键菜单成功');
    } catch (e) {
      XlyLogger.error('MyTray: 设置右键菜单失败', e);
    }
  }

  // === 便捷API：查询/修改禁用状态 ===

  /// 获取当前菜单中指定 key 的启用状态（未找到返回 false）
  bool getMenuItemEnabled(String key) {
    final item = _findItemByKey(_currentMenuItems ?? initialMenuItems, key);
    return item?.enabled ?? false;
  }

  /// 设置指定 key 的启用状态，返回是否找到并更新
  Future<bool> setMenuItemEnabled(String key, bool enabled) async {
    final updated = _updateEnabledRecursive(
      _currentMenuItems ?? initialMenuItems,
      key,
      enabled,
    );
    if (updated) {
      // 重建并应用菜单
      final source = _currentMenuItems ?? initialMenuItems!;
      await setContextMenu(source);
    }
    return updated;
  }

  /// 便捷切换
  Future<bool> toggleMenuItemEnabled(String key) async {
    final cur = getMenuItemEnabled(key);
    return setMenuItemEnabled(key, !cur);
  }

  // --- 内部：查找/更新 ---
  MyTrayMenuItem? _findItemByKey(List<MyTrayMenuItem>? list, String searchKey) {
    if (list == null) return null;
    for (final it in list) {
      if (!it.isSeparator) {
        final k = it.key ?? it.label;
        if (k == searchKey) return it;
      }
      if (it.submenu != null && it.submenu!.isNotEmpty) {
        final hit = _findItemByKey(it.submenu, searchKey);
        if (hit != null) return hit;
      }
    }
    return null;
  }

  bool _updateEnabledRecursive(
    List<MyTrayMenuItem>? list,
    String searchKey,
    bool enabled,
  ) {
    if (list == null) return false;
    for (var i = 0; i < list.length; i++) {
      final it = list[i];
      if (!it.isSeparator) {
        final k = it.key ?? it.label;
        if (k == searchKey) {
          list[i] = it.copyWith(enabled: enabled);
          return true;
        }
      }
      if (it.submenu != null && it.submenu!.isNotEmpty) {
        final hit = _updateEnabledRecursive(it.submenu, searchKey, enabled);
        if (hit) return true;
      }
    }
    return false;
  }

  /// 检查是否处于智能停靠模式
  bool _isInSmartDockMode() {
    try {
      // 需要导入相关模块
      return SmartDockManager.isSmartDockingEnabled() &&
          MouseTracker.state != MouseTrackingState.disabled;
    } catch (e) {
      XlyLogger.error('MyTray: 检查智能停靠状态失败', e);
      return false;
    }
  }

  /// 进入托盘模式（智能隐藏：根据智能停靠状态决定行为）
  Future<void> hide() async {
    try {
      // 设置托盘模式状态
      isTrayMode.value = true;

      // 根据策略设置任务栏图标显示/隐藏
      await windowManager.setSkipTaskbar(_hideTaskBarIcon.value);

      // 根据智能停靠状态决定是否隐藏窗口UI
      if (!_isInSmartDockMode()) {
        // 不在智能停靠状态，需要隐藏窗口UI
        await windowManager.hide();
        isVisible.value = false;

        XlyLogger.info('MyTray: 已进入托盘模式（窗口UI已隐藏）');
      } else {
        // 在智能停靠状态：
        // 1) 隐藏任务栏图标（已执行）
        // 2) 设置窗口为不激活任务栏模式，防止用户操作激活系统任务栏
        // 3) 若当前为展开态，强制收起到智能停靠的隐藏位置（但保留悬停可唤醒能力）
        final noActivateResult = await NativeWindowHelper.setNoActivateTaskbar(
          true,
        );

        // 强制收起到隐藏位置（不会禁用悬停，仅改变当前可见状态）
        await MouseTracker.forceCollapseToHidden();

        XlyLogger.info(
          'MyTray: 已进入托盘模式（智能停靠），已强制收起到隐藏位；任务栏激活控制：${noActivateResult ? "成功" : "失败"}',
        );
      }
      // 无论普通/智能停靠，隐藏后重置托盘展开记忆
      _smartDockShownByTray = false;
    } catch (e) {
      XlyLogger.error('MyTray: 进入托盘模式失败', e);
    }
  }

  /// 从托盘恢复窗口（退出托盘模式）
  Future<void> pop() async {
    try {
      // 退出托盘模式
      isTrayMode.value = false;

      // 遵从策略，不强制显示任务栏图标
      await windowManager.setSkipTaskbar(_hideTaskBarIcon.value);

      // 恢复正常的任务栏激活行为
      await NativeWindowHelper.setNoActivateTaskbar(false);

      // 确保窗口可见并获得焦点
      await windowManager.show();
      await windowManager.focus();
      isVisible.value = true;
      // 退出托盘模式后，重置托盘展开记忆
      _smartDockShownByTray = false;

      XlyLogger.info('MyTray: 已退出托盘模式（窗口已恢复，任务栏激活已恢复）');
    } catch (e) {
      XlyLogger.error('MyTray: 从托盘恢复失败', e);
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

      XlyLogger.info('MyTray: 托盘已销毁');
    } catch (e) {
      XlyLogger.error('MyTray: 销毁托盘失败', e);
    }
  }

  // === 任务栏图标策略：对外API ===
  bool getHideTaskBarIcon() => _hideTaskBarIcon.value;

  /// toggleOnClick: 对外API（get/set/toggle）
  bool getToggleOnClick() => _toggleOnClick.value;
  Future<void> setToggleOnClick(bool enabled) async {
    _toggleOnClick.value = enabled;
  }

  Future<void> toggleToggleOnClick() async {
    _toggleOnClick.value = !_toggleOnClick.value;
  }

  /// 设置任务栏图标隐藏策略（全局），默认立即生效
  Future<void> _setHideTaskBarIcon(bool hide, {bool applyNow = true}) async {
    _hideTaskBarIcon.value = hide;
    if (applyNow && _isInitialized.value) {
      await windowManager.setSkipTaskbar(_hideTaskBarIcon.value);
    }
  }

  /// 便捷方法：显示任务栏图标
  Future<void> showTaskbarIcon() => _setHideTaskBarIcon(false);

  /// 便捷方法：隐藏任务栏图标
  Future<void> hideTaskbarIcon() => _setHideTaskBarIcon(true);

  /// 检查是否已初始化
  bool get isInitialized => _isInitialized.value;

  @override
  void onClose() {
    destroy();
    super.onClose();
  }
}
