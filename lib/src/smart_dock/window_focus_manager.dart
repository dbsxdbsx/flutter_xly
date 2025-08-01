import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';

import '../platform.dart';
import '../tray/my_tray.dart';
import 'mouse_tracker.dart';
import 'native_window_helper.dart';

/// 窗口焦点管理器
///
/// 负责监听窗口焦点变化，并在失去焦点时维持智能停靠状态
class WindowFocusManager with WindowListener {
  static bool _isWindowFocused = true;
  static WindowFocusManager? _instance;
  static Timer? _focusStateMonitorTimer;
  static bool? _originalMaximizable;

  /// 获取窗口焦点状态
  static bool get isWindowFocused => _isWindowFocused;

  /// 检查是否应该避免窗口激活
  ///
  /// 当窗口处于智能停靠状态且失去焦点时，应该避免激活
  static bool get shouldAvoidActivation =>
      !_isWindowFocused &&
      (MouseTracker.state == MouseTrackingState.edgeTracking ||
          MouseTracker.state == MouseTrackingState.cornerTracking);

  /// 初始化窗口焦点监听器
  static void initialize() {
    if (_instance == null) {
      _instance = WindowFocusManager();
      windowManager.addListener(_instance!);

      // 初始化原生窗口助手
      NativeWindowHelper.initialize();

      // 启动焦点状态监控定时器，每500毫秒检查一次
      _focusStateMonitorTimer = Timer.periodic(
        const Duration(milliseconds: 500),
        (timer) => _monitorFocusState(),
      );
    }
  }

  /// 清理窗口焦点监听器
  static void dispose() {
    if (_instance != null) {
      windowManager.removeListener(_instance!);
      _instance = null;
    }

    // 停止焦点状态监控定时器
    _focusStateMonitorTimer?.cancel();
    _focusStateMonitorTimer = null;
  }

  /// 禁用Windows的自动最大化功能
  static Future<void> disableWindowsAutoMaximize() async {
    if (!MyPlatform.isWindows) return;

    try {
      // 保存当前的最大化状态
      _originalMaximizable = await windowManager.isMaximizable();

      // 禁用窗口最大化功能，防止触碰屏幕顶部时自动最大化
      await windowManager.setMaximizable(false);

      debugPrint('智能停靠：已禁用Windows自动最大化功能');
    } catch (e) {
      debugPrint('智能停靠：禁用Windows自动最大化功能时出错：$e');
    }
  }

  /// 恢复Windows的自动最大化功能
  static Future<void> restoreWindowsAutoMaximize() async {
    if (!MyPlatform.isWindows) return;

    try {
      // 恢复原始的最大化状态
      if (_originalMaximizable != null) {
        await windowManager.setMaximizable(_originalMaximizable!);
        _originalMaximizable = null;
        debugPrint('智能停靠：已恢复Windows自动最大化功能');
      }
    } catch (e) {
      debugPrint('智能停靠：恢复Windows自动最大化功能时出错：$e');
    }
  }

  /// 监控焦点状态，确保智能停靠在失去焦点时仍能正常工作
  static void _monitorFocusState() async {
    if (!_isWindowFocused &&
        (MouseTracker.state == MouseTrackingState.edgeTracking ||
            MouseTracker.state == MouseTrackingState.cornerTracking)) {
      // 当窗口失去焦点且处于智能停靠状态时，定期维护停靠状态
      _maintainSmartDockStateOnBlur();
    }
  }

  /// 窗口获得焦点时的处理
  @override
  void onWindowFocus() {
    _isWindowFocused = true;
    debugPrint('智能停靠：窗口获得焦点');

    // 窗口重新获得焦点时，取消置顶状态（如果之前设置了的话）
    _restoreNormalStateOnFocus();
  }

  /// 在窗口重新获得焦点时恢复正常状态
  static void _restoreNormalStateOnFocus() async {
    try {
      // 检查是否处于托盘模式
      try {
        if (MyTray.to.isTrayMode.value) {
          // 处于托盘模式，不恢复任务栏显示，但可以取消置顶状态
          if (MouseTracker.state != MouseTrackingState.disabled) {
            await windowManager.setAlwaysOnTop(false);
            debugPrint('智能停靠：窗口获得焦点，但处于托盘模式，保持任务栏隐藏');
          }
          return;
        }
      } catch (e) {
        // MyTray可能未初始化，继续执行原有逻辑
        debugPrint('智能停靠：检查托盘模式状态失败：$e');
      }

      // 如果当前处于智能停靠状态，取消置顶设置
      if (MouseTracker.state != MouseTrackingState.disabled) {
        await windowManager.setAlwaysOnTop(false);
        debugPrint('智能停靠：窗口获得焦点，取消置顶状态');
      }
    } catch (e) {
      debugPrint('智能停靠：恢复正常状态时出错：$e');
    }
  }

  /// 窗口失去焦点时的处理
  @override
  void onWindowBlur() {
    _isWindowFocused = false;
    debugPrint('智能停靠：窗口失去焦点');

    // 当窗口失去焦点时，强制保持智能停靠状态
    _maintainSmartDockStateOnBlur();
  }

  /// 在窗口失去焦点时维持智能停靠状态
  static void _maintainSmartDockStateOnBlur() async {
    try {
      final mouseState = MouseTracker.state;

      if (mouseState == MouseTrackingState.edgeTracking ||
          mouseState == MouseTrackingState.cornerTracking) {
        // 检查窗口是否已经是置顶状态，避免重复设置
        final isAlreadyOnTop = await windowManager.isAlwaysOnTop();
        if (!isAlreadyOnTop) {
          // 使用新的智能停靠层级设置，确保在任务栏下方但在其他应用上方
          final success =
              await NativeWindowHelper.setBelowTaskbarButAboveOthers();
          if (!success) {
            // 原生方法失败，使用延迟 + 标准方法
            await Future.delayed(const Duration(milliseconds: 50));
            await windowManager.show(inactive: true);
            await windowManager.setAlwaysOnTop(true);
          }
          debugPrint('智能停靠：失去焦点时维持停靠状态（${success ? "任务栏下方" : "标准"}方法）');
        }
      }
    } catch (e) {
      debugPrint('智能停靠：维持失去焦点状态时出错：$e');
    }
  }
}
