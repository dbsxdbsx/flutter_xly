import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

import '../window_enums.dart';
import 'window_animator.dart';

/// 鼠标跟踪状态
enum MouseTrackingState {
  /// 未启用
  disabled,

  /// 边缘跟踪
  edgeTracking,

  /// 角落跟踪
  cornerTracking,
}

/// 鼠标跟踪器
///
/// 负责监听鼠标位置变化，控制窗口的显示和隐藏
class MouseTracker {
  static Timer? _mouseTrackingTimer;
  static MouseTrackingState _state = MouseTrackingState.disabled;

  // 边缘跟踪状态
  static bool _isWindowHidden = false;
  static Offset? _alignedPosition;
  static Offset? _hiddenPosition;

  // 角落跟踪状态
  static bool _isCornerWindowHidden = false;
  static Offset? _cornerAlignedPosition;
  static Offset? _cornerHiddenPosition;

  /// 获取当前跟踪状态
  static MouseTrackingState get state => _state;

  /// 开始边缘鼠标跟踪
  ///
  /// [edge] 停靠边缘
  /// [alignedPosition] 对齐位置
  /// [hiddenPosition] 隐藏位置
  static void startEdgeTracking({
    required WindowEdge edge,
    required Offset alignedPosition,
    required Offset hiddenPosition,
  }) {
    _stopTracking();

    _state = MouseTrackingState.edgeTracking;
    _isWindowHidden = false;
    _alignedPosition = alignedPosition;
    _hiddenPosition = hiddenPosition;

    // 启动定期检查鼠标位置（每100毫秒检查一次）
    _mouseTrackingTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (timer) => _checkEdgeMousePosition(),
    );

    debugPrint('智能隐藏监听已启动，边缘：${edge.name}');
  }

  /// 开始角落鼠标跟踪
  ///
  /// [corner] 停靠角落
  /// [alignedPosition] 对齐位置
  /// [hiddenPosition] 隐藏位置
  static void startCornerTracking({
    required WindowCorner corner,
    required Offset alignedPosition,
    required Offset hiddenPosition,
  }) {
    _stopTracking();

    _state = MouseTrackingState.cornerTracking;
    _isCornerWindowHidden = false;
    _cornerAlignedPosition = alignedPosition;
    _cornerHiddenPosition = hiddenPosition;

    // 启动定期检查鼠标位置（每100毫秒检查一次）
    _mouseTrackingTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (timer) => _checkCornerMousePosition(),
    );

    debugPrint('智能角落隐藏监听已启动，角落：${corner.name}');
  }

  /// 停止鼠标跟踪
  static void stopTracking() {
    _stopTracking();
    debugPrint('鼠标跟踪已停止');
  }

  /// 内部停止跟踪方法
  static void _stopTracking() {
    _mouseTrackingTimer?.cancel();
    _mouseTrackingTimer = null;
    _state = MouseTrackingState.disabled;

    // 清理边缘跟踪状态
    _isWindowHidden = false;
    _alignedPosition = null;
    _hiddenPosition = null;

    // 清理角落跟踪状态
    _isCornerWindowHidden = false;
    _cornerAlignedPosition = null;
    _cornerHiddenPosition = null;
  }

  /// 检查边缘鼠标位置
  static void _checkEdgeMousePosition() async {
    if (_state != MouseTrackingState.edgeTracking) return;

    try {
      // 获取当前鼠标位置和实际窗口位置
      final mousePosition = await _getMousePosition();
      if (mousePosition == null) return;

      final actualWindowPosition = await windowManager.getPosition();
      final windowSize = await windowManager.getSize();

      // 只有在不处于动画状态时才检查位置偏移
      if (!WindowAnimator.isAnimating) {
        // 检查窗口是否仍然在对齐位置附近（允许小误差）
        final expectedPosition =
            _isWindowHidden ? _hiddenPosition! : _alignedPosition!;
        final positionDifference =
            (actualWindowPosition - expectedPosition).distance;

        // 如果窗口被移动到了其他位置（距离超过10像素），停止跟踪
        if (positionDifference > 10.0) {
          debugPrint('窗口已被移动离开对齐位置，停止智能隐藏监听');
          stopTracking();
          return;
        }
      }

      // 计算当前窗口区域（根据是否隐藏状态）
      final currentWindowPosition =
          _isWindowHidden ? _hiddenPosition! : _alignedPosition!;
      final windowArea = Rect.fromLTWH(
        currentWindowPosition.dx,
        currentWindowPosition.dy,
        windowSize.width,
        windowSize.height,
      );

      final isMouseInWindow = windowArea.contains(mousePosition);

      if (!_isWindowHidden && !isMouseInWindow) {
        // 窗口未隐藏且鼠标不在窗口内，隐藏窗口
        await WindowAnimationPresets.hideTo(_hiddenPosition!);
        _isWindowHidden = true;
        debugPrint('智能隐藏：窗口已隐藏');
      } else if (_isWindowHidden && isMouseInWindow) {
        // 窗口已隐藏且鼠标在窗口内，显示窗口（无激活）
        await WindowAnimationPresets.showToInactive(_alignedPosition!);
        _isWindowHidden = false;
        debugPrint('智能隐藏：窗口已显示（无激活）');
      }
    } catch (e) {
      debugPrint('智能隐藏检查出错：$e');
    }
  }

  /// 检查角落鼠标位置
  static void _checkCornerMousePosition() async {
    if (_state != MouseTrackingState.cornerTracking) return;

    try {
      // 获取当前鼠标位置和实际窗口位置
      final mousePosition = await _getMousePosition();
      if (mousePosition == null) return;

      final actualWindowPosition = await windowManager.getPosition();
      final windowSize = await windowManager.getSize();

      // 只有在不处于动画状态时才检查位置偏移
      if (!WindowAnimator.isAnimating) {
        // 检查窗口是否仍然在对齐位置附近（允许小误差）
        final expectedPosition = _isCornerWindowHidden
            ? _cornerHiddenPosition!
            : _cornerAlignedPosition!;
        final positionDifference =
            (actualWindowPosition - expectedPosition).distance;

        // 如果窗口被移动到了其他位置（距离超过10像素），停止跟踪
        if (positionDifference > 10.0) {
          debugPrint('窗口已被移动离开角落对齐位置，停止智能角落隐藏监听');
          stopTracking();
          return;
        }
      }

      // 计算当前窗口区域（根据是否隐藏状态）
      final currentWindowPosition = _isCornerWindowHidden
          ? _cornerHiddenPosition!
          : _cornerAlignedPosition!;
      final windowArea = Rect.fromLTWH(
        currentWindowPosition.dx,
        currentWindowPosition.dy,
        windowSize.width,
        windowSize.height,
      );

      final isMouseInWindow = windowArea.contains(mousePosition);

      if (!_isCornerWindowHidden && !isMouseInWindow) {
        // 窗口未隐藏且鼠标不在窗口内，隐藏窗口到角落
        await WindowAnimationPresets.hideTo(_cornerHiddenPosition!);
        _isCornerWindowHidden = true;
        debugPrint('智能角落隐藏：窗口已隐藏到角落');
      } else if (_isCornerWindowHidden && isMouseInWindow) {
        // 窗口已隐藏且鼠标在窗口内，显示窗口到对齐位置（无激活）
        await WindowAnimationPresets.showToInactive(_cornerAlignedPosition!);
        _isCornerWindowHidden = false;
        debugPrint('智能角落隐藏：窗口已显示到对齐位置（无激活）');
      }
    } catch (e) {
      debugPrint('智能角落隐藏检查出错：$e');
    }
  }

  /// 获取当前鼠标位置（相对于屏幕）
  static Future<Offset?> _getMousePosition() async {
    try {
      // 使用screen_retriever包获取真实的鼠标光标位置
      final cursorPosition = await screenRetriever.getCursorScreenPoint();
      return cursorPosition;
    } catch (e) {
      debugPrint('获取鼠标位置失败：$e');
      return null;
    }
  }

  /// 清理所有资源
  static void dispose() {
    stopTracking();
  }
}
