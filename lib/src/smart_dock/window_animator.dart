import 'package:flutter/animation.dart';
import 'package:flutter/scheduler.dart';
import 'package:window_manager/window_manager.dart';

import '../logger.dart';
import 'mouse_tracker.dart';
import 'native_window_helper.dart';
import 'window_focus_manager.dart';

/// 窗口动画控制器
///
/// 专门负责处理窗口位置的平滑动画，提供高性能的动画实现
class WindowAnimator {
  static Ticker? _animationTicker;
  static bool _isAnimating = false;
  static Offset? _currentAnimationTargetPosition;
  static Duration? _animationStartTime;

  /// 检查是否正在执行动画
  static bool get isAnimating => _isAnimating;

  /// 获取当前动画的目标位置
  static Offset? get currentTargetPosition => _currentAnimationTargetPosition;

  /// 使用动画将窗口平滑移动到目标位置
  ///
  /// [targetPosition] 目标位置
  /// [duration] 动画时长
  /// [curve] 动画曲线
  static Future<void> animateWindowTo(
    Offset targetPosition, {
    Duration duration = const Duration(milliseconds: 150),
    Curve curve = Curves.easeOutCubic,
  }) async {
    // 如果正在动画且目标位置相同，则不重复执行
    if (_isAnimating && _currentAnimationTargetPosition == targetPosition) {
      return;
    }

    // 停止当前动画
    if (_isAnimating) {
      _animationTicker?.dispose();
      _animationTicker = null;
    }

    _isAnimating = true;
    _currentAnimationTargetPosition = targetPosition;

    try {
      final startPosition = await windowManager.getPosition();

      // 如果距离很近，直接设置位置
      if ((startPosition - targetPosition).distance < 1.0) {
        await windowManager.setPosition(targetPosition);
        _isAnimating = false;
        _currentAnimationTargetPosition = null;
        return;
      }

      final tween = Tween<Offset>(begin: startPosition, end: targetPosition);
      _animationStartTime = null;

      // 创建Ticker进行高精度动画，使用vsync同步
      Offset? lastPosition;
      _animationTicker = Ticker((elapsed) async {
        try {
          _animationStartTime ??= elapsed;
          final animationElapsed = elapsed - _animationStartTime!;

          double progress =
              animationElapsed.inMicroseconds / duration.inMicroseconds;

          // 确保progress在有效范围内
          progress = progress.clamp(0.0, 1.0);

          if (progress >= 1.0) {
            // 确保最终位置精确
            await windowManager.setPosition(targetPosition);

            _animationTicker?.dispose();
            _animationTicker = null;
            _isAnimating = false;
            _currentAnimationTargetPosition = null;
            return;
          }

          final curvedProgress = curve.transform(progress);
          final currentPosition = tween.transform(curvedProgress);

          // 避免重复设置相同位置，减少系统调用
          if (lastPosition == null ||
              (currentPosition - lastPosition!).distance > 0.3) {
            await windowManager.setPosition(currentPosition);
            lastPosition = currentPosition;
          }
        } catch (e) {
          XlyLogger.error('动画帧处理出错', e);
          _animationTicker?.dispose();
          _animationTicker = null;
          _isAnimating = false;
          _currentAnimationTargetPosition = null;
        }
      });

      _animationTicker?.start();
    } catch (e) {
      XlyLogger.error('窗口动画失败', e);
      _isAnimating = false;
      _currentAnimationTargetPosition = null;
    }
  }

  /// 停止当前动画
  static void stopAnimation() {
    if (_isAnimating) {
      _animationTicker?.dispose();
      _animationTicker = null;
      _isAnimating = false;
      _currentAnimationTargetPosition = null;
      _animationStartTime = null;
    }
  }

  /// 清理所有动画资源
  static void dispose() {
    stopAnimation();
  }
}

/// 预定义的动画配置
class WindowAnimationPresets {
  /// 对齐动画配置（快速精确对齐）
  static const Duration alignDuration = Duration(milliseconds: 120);
  static const Curve alignCurve = Curves.easeOutQuart;

  /// 隐藏动画配置（快速隐藏）
  static const Duration hideDuration = Duration(milliseconds: 100);
  static const Curve hideCurve = Curves.easeInQuart;

  /// 显示动画配置（快速响应鼠标悬停）
  static const Duration showDuration = Duration(milliseconds: 80);
  static const Curve showCurve = Curves.easeOutQuart;

  /// 执行对齐动画
  static Future<void> alignTo(Offset position) async {
    await WindowAnimator.animateWindowTo(
      position,
      duration: alignDuration,
      curve: alignCurve,
    );
  }

  /// 执行隐藏动画
  static Future<void> hideTo(Offset position) async {
    await WindowAnimator.animateWindowTo(
      position,
      duration: hideDuration,
      curve: hideCurve,
    );
  }

  /// 执行显示动画
  static Future<void> showTo(Offset position) async {
    await WindowAnimator.animateWindowTo(
      position,
      duration: showDuration,
      curve: showCurve,
    );
  }

  /// 执行智能停靠显示动画（无激活）
  ///
  /// 专门用于智能停靠状态下的显示，确保窗口显示但不获得焦点
  /// 并且保持在任务栏下方但在其他应用上方
  static Future<void> showToInactive(Offset position) async {
    // 使用原生助手确保窗口以无激活方式显示，并设置正确的层级
    await NativeWindowHelper.showWindowNoActivate();
    await NativeWindowHelper.setBelowTaskbarButAboveOthers();

    // 然后执行动画
    await WindowAnimator.animateWindowTo(
      position,
      duration: showDuration,
      curve: showCurve,
    );
  }

  /// 智能显示动画（根据焦点状态自动选择是否激活）
  ///
  /// 根据当前窗口焦点状态和智能停靠状态，自动选择合适的显示方式
  static Future<void> smartShowTo(Offset position) async {
    // 需要导入 WindowFocusManager
    // 如果应该避免激活，则使用无激活显示
    try {
      // 动态导入以避免循环依赖
      final shouldAvoidActivation = !WindowFocusManager.isWindowFocused &&
          (MouseTracker.state == MouseTrackingState.edgeTracking ||
              MouseTracker.state == MouseTrackingState.cornerTracking);

      if (shouldAvoidActivation) {
        await showToInactive(position);
        XlyLogger.debug('智能显示：使用无激活显示');
      } else {
        await showTo(position);
        XlyLogger.debug('智能显示：使用正常显示');
      }
    } catch (e) {
      // 如果出错，回退到无激活显示
      XlyLogger.warning('智能显示检查出错，回退到无激活显示：$e');
      await showToInactive(position);
    }
  }
}
