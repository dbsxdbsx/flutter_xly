import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';

import '../platform.dart';
import '../window_enums.dart';
import 'dock_detector.dart';
import 'mouse_tracker.dart';
import 'window_animator.dart';
import 'window_focus_manager.dart';

/// 智能停靠管理器
///
/// 重构后的智能停靠管理器，作为各个组件的协调器：
/// - 使用 DockDetector 进行停靠检测
/// - 使用 WindowAnimator 处理动画
/// - 使用 MouseTracker 处理鼠标跟踪
/// - 使用 WindowFocusManager 处理焦点管理
class SmartDockManager {
  // 配置参数
  static bool _isSmartDockingEnabled = false;
  static double _smartDockVisibleWidth = 5.0;
  static bool _enableCornerDocking = true;

  // 停靠监听相关变量
  static Timer? _smartDockMonitorTimer;
  static Offset? _lastWindowPosition;
  static bool _isDragging = false;
  static DateTime? _lastMoveTime;

  /// 获取智能停靠启用状态
  static bool isSmartDockingEnabled() => _isSmartDockingEnabled;

  /// 启用/禁用智能停靠机制
  ///
  /// [enabled] 是否启用智能停靠
  /// [visibleWidth] 停靠时可见的宽度（默认5像素）
  ///
  /// 当启用时，用户拖动窗口使其部分超出屏幕边界松开鼠标，会自动触发停靠
  /// 系统会智能判断：
  /// - 如果窗口同时超出两个相邻边界（如左边和上边），则触发角落停靠
  /// - 如果窗口只超出一个边界，则触发边缘停靠
  static Future<void> setSmartEdgeDocking({
    required bool enabled,
    double visibleWidth = 5.0,
  }) async {
    if (!MyPlatform.isDesktop) return;

    _isSmartDockingEnabled = enabled;
    _smartDockVisibleWidth = visibleWidth;
    _enableCornerDocking = true; // 始终启用角落检测

    if (enabled) {
      // 启用智能停靠时，禁用Windows的自动最大化功能
      await WindowFocusManager.disableWindowsAutoMaximize();
      // 开始监听窗口位置变化
      await _startSmartDockingMonitor();
      // 初始化窗口焦点监听器
      WindowFocusManager.initialize();
    } else {
      // 禁用时，停止监听并恢复窗口
      await _stopSmartDockingMonitor();
      // 清理窗口焦点监听器
      WindowFocusManager.dispose();
      // 恢复Windows的自动最大化功能
      await WindowFocusManager.restoreWindowsAutoMaximize();
    }
  }

  /// 开始智能停靠监听
  static Future<void> _startSmartDockingMonitor() async {
    // 每50毫秒检查一次窗口位置变化
    _smartDockMonitorTimer = Timer.periodic(
      const Duration(milliseconds: 50),
      (timer) => _checkSmartDocking(),
    );

    debugPrint('智能停靠监听已启动');
  }

  /// 停止智能停靠监听
  static Future<void> _stopSmartDockingMonitor() async {
    _smartDockMonitorTimer?.cancel();
    _smartDockMonitorTimer = null;
    _lastWindowPosition = null;
    _isDragging = false;
    _lastMoveTime = null;

    // 停止动画和鼠标跟踪
    WindowAnimator.dispose();
    MouseTracker.dispose();
  }

  /// 检查智能停靠逻辑
  static void _checkSmartDocking() async {
    if (!_isSmartDockingEnabled) return;

    try {
      final currentPosition = await windowManager.getPosition();
      final currentTime = DateTime.now();

      // 检查窗口是否移动
      if (_lastWindowPosition != null) {
        final moved =
            (currentPosition.dx - _lastWindowPosition!.dx).abs() > 1 ||
                (currentPosition.dy - _lastWindowPosition!.dy).abs() > 1;

        if (moved) {
          _isDragging = true;
          _lastMoveTime = currentTime;
        } else if (_isDragging &&
            _lastMoveTime != null &&
            currentTime.difference(_lastMoveTime!).inMilliseconds > 100) {
          // 窗口停止移动超过100毫秒，检查是否需要停靠
          _isDragging = false;
          await _checkAndTriggerSmartDock(currentPosition);
        }
      }

      _lastWindowPosition = currentPosition;
    } catch (e) {
      debugPrint('智能停靠检查出错：$e');
    }
  }

  /// 检查并触发智能停靠
  static Future<void> _checkAndTriggerSmartDock(Offset windowPosition) async {
    try {
      // 使用新的DockDetector进行检测
      final result = await DockDetector.detectDocking(
        windowPosition,
        enableCornerDocking: _enableCornerDocking,
      );

      if (!result.shouldDock) {
        // 如果没有检测到停靠需求，且当前没有活跃的鼠标跟踪，则输出调试信息
        if (MouseTracker.state == MouseTrackingState.disabled) {
          debugPrint('窗口未停靠在边缘或角落，且无活跃隐藏监听，停止所有智能隐藏监听。');
        } else {
          debugPrint('窗口未溢出但有活跃的隐藏监听，保持监听状态。');
        }
        return;
      }

      // 检查是否已经有活跃的鼠标跟踪，避免重复启动
      if (MouseTracker.state != MouseTrackingState.disabled) {
        debugPrint('已有活跃的鼠标跟踪，跳过重复停靠触发');
        return;
      }

      if (result.isCornerDock) {
        // 角落停靠
        await _enableSmartCornerAlignment(
          corner: result.corner!,
          visibleSize: _smartDockVisibleWidth * 3, // 角落停靠使用3倍大小，更容易找到
        );
      } else if (result.isEdgeDock) {
        // 边缘停靠
        await _enableSmartEdgeAlignment(
          edge: result.edge!,
          visibleWidth: _smartDockVisibleWidth,
        );
      }
    } catch (e) {
      debugPrint('智能停靠触发出错：$e');
    }
  }

  /// 智能边缘对齐：先将窗口对齐到屏幕边缘，然后启用鼠标监听隐藏功能
  static Future<void> _enableSmartEdgeAlignment({
    required WindowEdge edge,
    required double visibleWidth,
  }) async {
    try {
      final currentPosition = await windowManager.getPosition();

      // 使用DockDetector计算停靠位置
      final positions = await DockDetector.calculateEdgePositions(
        edge,
        currentPosition,
        visibleWidth,
      );

      // 第一步：将窗口对齐到屏幕边缘
      await WindowAnimationPresets.alignTo(positions.alignedPosition);

      // 第二步：启用鼠标监听，当鼠标离开窗口时隐藏
      MouseTracker.startEdgeTracking(
        edge: edge,
        alignedPosition: positions.alignedPosition,
        hiddenPosition: positions.hiddenPosition,
      );
    } catch (e) {
      debugPrint('智能边缘对齐失败：$e');
    }
  }

  /// 智能角落对齐：先将窗口对齐到屏幕角落，然后启用鼠标监听隐藏功能
  static Future<void> _enableSmartCornerAlignment({
    required WindowCorner corner,
    required double visibleSize,
  }) async {
    try {
      // 使用DockDetector计算停靠位置
      final positions = await DockDetector.calculateCornerPositions(
        corner,
        visibleSize,
      );

      // 第一步：将窗口对齐到屏幕角落
      await WindowAnimationPresets.alignTo(positions.alignedPosition);

      // 第二步：启用鼠标监听，当鼠标离开窗口时隐藏到角落
      MouseTracker.startCornerTracking(
        corner: corner,
        alignedPosition: positions.alignedPosition,
        hiddenPosition: positions.hiddenPosition,
      );
    } catch (e) {
      debugPrint('智能角落对齐失败：$e');
    }
  }

  /// 停止所有智能停靠功能
  static Future<void> stopAll() async {
    // 停止所有组件
    WindowAnimator.dispose();
    MouseTracker.dispose();
    WindowFocusManager.dispose();

    await _stopSmartDockingMonitor();

    // 确保恢复Windows功能
    await WindowFocusManager.restoreWindowsAutoMaximize();
  }
}
