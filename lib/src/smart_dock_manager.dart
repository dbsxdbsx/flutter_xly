import 'dart:async';

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

import 'platform.dart';
import 'window_enums.dart';

/// 智能停靠管理器
///
/// 负责处理窗口的智能边缘和角落停靠功能，包括：
/// - 自动检测窗口拖拽到屏幕边界的行为
/// - 智能判断边缘停靠或角落停靠
/// - 鼠标悬停显示/隐藏窗口
/// - 状态管理和清理
class SmartDockManager {
  // 智能边缘停靠相关变量
  static bool _isSmartDockingEnabled = false;
  static double _smartDockVisibleWidth = 5.0;
  static bool _enableCornerDocking = false;

  // 智能停靠监听相关变量
  static Timer? _smartDockMonitorTimer;
  static Offset? _lastWindowPosition;
  static bool _isDragging = false;
  static DateTime? _lastMoveTime;

  // 智能隐藏监听相关变量（边缘）
  static Timer? _smartHideTimer;
  static bool _isSmartHideEnabled = false;
  static bool _isWindowHidden = false;
  static Offset? _alignedPosition;
  static Offset? _hiddenPosition;

  // 智能角落隐藏监听相关变量
  static Timer? _smartCornerHideTimer;
  static bool _isSmartCornerHideEnabled = false;
  static bool _isCornerWindowHidden = false;
  static Offset? _cornerAlignedPosition;
  static Offset? _cornerHiddenPosition;

  // 动画相关变量
  static Timer? _animationTimer;
  static bool _isAnimating = false;
  static Offset? _currentAnimationTargetPosition;

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
      // 启用智能停靠时，开始监听窗口位置变化
      await _startSmartDockingMonitor();
    } else {
      // 禁用时，停止监听并恢复窗口
      await _stopSmartDockingMonitor();
    }
  }

  /// 获取智能边缘停靠的启用状态
  static bool isSmartDockingEnabled() {
    return _isSmartDockingEnabled;
  }

  /// 开始智能停靠监听
  static Future<void> _startSmartDockingMonitor() async {
    // 每100毫秒检查一次窗口位置
    _smartDockMonitorTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (timer) => _checkSmartDocking(),
    );

    // 获取初始窗口位置
    try {
      _lastWindowPosition = await windowManager.getPosition();
    } catch (e) {
      debugPrint('获取窗口位置失败：$e');
    }
  }

  /// 停止智能停靠监听
  static Future<void> _stopSmartDockingMonitor() async {
    _smartDockMonitorTimer?.cancel();
    _smartDockMonitorTimer = null;
    _lastWindowPosition = null;
    _isDragging = false;
    _lastMoveTime = null;

    // 停止智能隐藏监听
    _stopSmartHideMonitoring();
    _stopSmartCornerHideMonitoring();

    // 如果当前处于停靠状态，恢复窗口
    // 注意：这里需要调用外部的disableEdgeDocking方法
    // 在实际使用中，可能需要通过回调或其他方式处理
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

  /// 智能边缘对齐：先将窗口对齐到屏幕边缘，然后启用鼠标监听隐藏功能
  static Future<void> _enableSmartEdgeAlignment({
    required WindowEdge edge,
    required double visibleWidth,
  }) async {
    try {
      final display = await screenRetriever.getPrimaryDisplay();
      if (display.visiblePosition == null || display.visibleSize == null) {
        return;
      }

      final windowSize = await windowManager.getSize();
      final currentPosition = await windowManager.getPosition();
      final workArea = display.visibleSize!;
      final workAreaPosition = display.visiblePosition!;

      // 第一步：将窗口对齐到屏幕边缘（只调整溢出的轴，保持另一轴的当前位置）
      Offset alignedPosition;
      switch (edge) {
        case WindowEdge.left:
          // 对齐到左边缘，保持当前垂直位置（但确保在屏幕范围内）
          final clampedY = currentPosition.dy.clamp(
            workAreaPosition.dy,
            workAreaPosition.dy + workArea.height - windowSize.height,
          );
          alignedPosition = Offset(workAreaPosition.dx, clampedY);
          break;
        case WindowEdge.right:
          // 对齐到右边缘，保持当前垂直位置（但确保在屏幕范围内）
          final clampedY = currentPosition.dy.clamp(
            workAreaPosition.dy,
            workAreaPosition.dy + workArea.height - windowSize.height,
          );
          alignedPosition = Offset(
            workAreaPosition.dx + workArea.width - windowSize.width,
            clampedY,
          );
          break;
        case WindowEdge.top:
          // 对齐到上边缘，保持当前水平位置（但确保在屏幕范围内）
          final clampedX = currentPosition.dx.clamp(
            workAreaPosition.dx,
            workAreaPosition.dx + workArea.width - windowSize.width,
          );
          alignedPosition = Offset(clampedX, workAreaPosition.dy);
          break;
        case WindowEdge.bottom:
          // 对齐到下边缘，保持当前水平位置（但确保在屏幕范围内）
          final clampedX = currentPosition.dx.clamp(
            workAreaPosition.dx,
            workAreaPosition.dx + workArea.width - windowSize.width,
          );
          alignedPosition = Offset(
            clampedX,
            workAreaPosition.dy + workArea.height - windowSize.height,
          );
          break;
      }

      // 移动窗口到对齐位置
      await _animateWindowTo(alignedPosition);

      // 第二步：启用鼠标监听，当鼠标离开窗口时隐藏
      _startSmartHideMonitoring(
        edge: edge,
        alignedPosition: alignedPosition,
        windowSize: windowSize,
        visibleWidth: visibleWidth,
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
      final display = await screenRetriever.getPrimaryDisplay();
      if (display.visiblePosition == null || display.visibleSize == null) {
        return;
      }

      final windowSize = await windowManager.getSize();
      final workArea = display.visibleSize!;
      final workAreaPosition = display.visiblePosition!;

      // 第一步：将窗口对齐到屏幕角落（不隐藏）
      Offset alignedPosition;
      switch (corner) {
        case WindowCorner.topLeft:
          alignedPosition = Offset(
            workAreaPosition.dx, // 对齐到左边缘
            workAreaPosition.dy, // 对齐到上边缘
          );
          break;
        case WindowCorner.topRight:
          alignedPosition = Offset(
            workAreaPosition.dx + workArea.width - windowSize.width, // 对齐到右边缘
            workAreaPosition.dy, // 对齐到上边缘
          );
          break;
        case WindowCorner.bottomLeft:
          alignedPosition = Offset(
            workAreaPosition.dx, // 对齐到左边缘
            workAreaPosition.dy + workArea.height - windowSize.height, // 对齐到下边缘
          );
          break;
        case WindowCorner.bottomRight:
          alignedPosition = Offset(
            workAreaPosition.dx + workArea.width - windowSize.width, // 对齐到右边缘
            workAreaPosition.dy + workArea.height - windowSize.height, // 对齐到下边缘
          );
          break;
      }

      // 移动窗口到对齐位置
      await _animateWindowTo(alignedPosition);

      // 第二步：启用鼠标监听，当鼠标离开窗口时隐藏到角落
      _startSmartCornerHideMonitoring(
        corner: corner,
        alignedPosition: alignedPosition,
        windowSize: windowSize,
        visibleSize: visibleSize,
      );
    } catch (e) {
      debugPrint('智能角落对齐失败：$e');
    }
  }

  /// 开始智能隐藏监听（只在鼠标不按压且窗口已对齐时工作）
  static void _startSmartHideMonitoring({
    required WindowEdge edge,
    required Offset alignedPosition,
    required Size windowSize,
    required double visibleWidth,
  }) {
    _isSmartHideEnabled = true;
    _isWindowHidden = false;
    _alignedPosition = alignedPosition;

    // 计算隐藏位置
    switch (edge) {
      case WindowEdge.left:
        _hiddenPosition = Offset(
          alignedPosition.dx - windowSize.width + visibleWidth,
          alignedPosition.dy,
        );
        break;
      case WindowEdge.right:
        _hiddenPosition = Offset(
          alignedPosition.dx + windowSize.width - visibleWidth,
          alignedPosition.dy,
        );
        break;
      case WindowEdge.top:
        _hiddenPosition = Offset(
          alignedPosition.dx,
          alignedPosition.dy - windowSize.height + visibleWidth,
        );
        break;
      case WindowEdge.bottom:
        _hiddenPosition = Offset(
          alignedPosition.dx,
          alignedPosition.dy + windowSize.height - visibleWidth,
        );
        break;
    }

    // 启动定期检查鼠标位置（每100毫秒检查一次）
    _smartHideTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (timer) => _checkSmartHideMousePosition(windowSize),
    );

    debugPrint('智能隐藏监听已启动，边缘：${edge.name}');
  }

  /// 检查智能隐藏的鼠标位置
  static void _checkSmartHideMousePosition(Size windowSize) async {
    if (!_isSmartHideEnabled) return;

    try {
      // 获取当前鼠标位置和实际窗口位置
      final mousePosition = await _getMousePosition();
      if (mousePosition == null) return;

      final actualWindowPosition = await windowManager.getPosition();

      // 只有在不处于动画状态时才检查位置偏移
      if (!_isAnimating) {
        // 检查窗口是否仍然在对齐位置附近（允许小误差）
        final expectedPosition =
            _isWindowHidden ? _hiddenPosition! : _alignedPosition!;
        final positionDifference =
            (actualWindowPosition - expectedPosition).distance;

        // 如果窗口被移动到了其他位置（距离超过10像素），停止智能隐藏监听
        if (positionDifference > 10.0) {
          debugPrint('窗口已被移动离开对齐位置，停止智能隐藏监听');
          _stopSmartHideMonitoring();
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
        await _animateWindowTo(_hiddenPosition!);
        _isWindowHidden = true;
        debugPrint('智能隐藏：窗口已隐藏');
      } else if (_isWindowHidden && isMouseInWindow) {
        // 窗口已隐藏且鼠标在窗口内，显示窗口
        await _animateWindowTo(_alignedPosition!);
        _isWindowHidden = false;
        debugPrint('智能隐藏：窗口已显示');
      }
    } catch (e) {
      debugPrint('智能隐藏检查出错：$e');
    }
  }

  /// 停止智能隐藏监听
  static void _stopSmartHideMonitoring() {
    _smartHideTimer?.cancel();
    _smartHideTimer = null;
    _isSmartHideEnabled = false;
    _isWindowHidden = false;
    _alignedPosition = null;
    _hiddenPosition = null;
  }

  /// 开始智能角落隐藏监听（只在鼠标不按压且窗口已对齐时工作）
  static void _startSmartCornerHideMonitoring({
    required WindowCorner corner,
    required Offset alignedPosition,
    required Size windowSize,
    required double visibleSize,
  }) {
    _isSmartCornerHideEnabled = true;
    _isCornerWindowHidden = false;
    _cornerAlignedPosition = alignedPosition;

    // 计算隐藏位置（角落位置，大部分隐藏）
    final cornerVisibleWidth = visibleSize * 2; // 水平方向可见宽度
    final cornerVisibleHeight = visibleSize; // 垂直方向可见高度

    switch (corner) {
      case WindowCorner.topLeft:
        _cornerHiddenPosition = Offset(
          alignedPosition.dx - windowSize.width + cornerVisibleWidth,
          alignedPosition.dy - windowSize.height + cornerVisibleHeight,
        );
        break;
      case WindowCorner.topRight:
        _cornerHiddenPosition = Offset(
          alignedPosition.dx + windowSize.width - cornerVisibleWidth,
          alignedPosition.dy - windowSize.height + cornerVisibleHeight,
        );
        break;
      case WindowCorner.bottomLeft:
        _cornerHiddenPosition = Offset(
          alignedPosition.dx - windowSize.width + cornerVisibleWidth,
          alignedPosition.dy + windowSize.height - cornerVisibleHeight,
        );
        break;
      case WindowCorner.bottomRight:
        _cornerHiddenPosition = Offset(
          alignedPosition.dx + windowSize.width - cornerVisibleWidth,
          alignedPosition.dy + windowSize.height - cornerVisibleHeight,
        );
        break;
    }

    // 启动定期检查鼠标位置（每100毫秒检查一次）
    _smartCornerHideTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (timer) => _checkSmartCornerHideMousePosition(windowSize),
    );

    debugPrint('智能角落隐藏监听已启动，角落：${corner.name}');
  }

  /// 检查智能角落隐藏的鼠标位置
  static void _checkSmartCornerHideMousePosition(Size windowSize) async {
    if (!_isSmartCornerHideEnabled) return;

    try {
      // 获取当前鼠标位置和实际窗口位置
      final mousePosition = await _getMousePosition();
      if (mousePosition == null) return;

      final actualWindowPosition = await windowManager.getPosition();

      // 只有在不处于动画状态时才检查位置偏移
      if (!_isAnimating) {
        // 检查窗口是否仍然在对齐位置附近（允许小误差）
        final expectedPosition = _isCornerWindowHidden
            ? _cornerHiddenPosition!
            : _cornerAlignedPosition!;
        final positionDifference =
            (actualWindowPosition - expectedPosition).distance;

        // 如果窗口被移动到了其他位置（距离超过10像素），停止智能角落隐藏监听
        if (positionDifference > 10.0) {
          debugPrint('窗口已被移动离开角落对齐位置，停止智能角落隐藏监听');
          _stopSmartCornerHideMonitoring();
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
        await _animateWindowTo(_cornerHiddenPosition!);
        _isCornerWindowHidden = true;
        debugPrint('智能角落隐藏：窗口已隐藏到角落');
      } else if (_isCornerWindowHidden && isMouseInWindow) {
        // 窗口已隐藏且鼠标在窗口内，显示窗口到对齐位置
        await _animateWindowTo(_cornerAlignedPosition!);
        _isCornerWindowHidden = false;
        debugPrint('智能角落隐藏：窗口已显示到对齐位置');
      }
    } catch (e) {
      debugPrint('智能角落隐藏检查出错：$e');
    }
  }

  /// 停止智能角落隐藏监听
  static void _stopSmartCornerHideMonitoring() {
    _smartCornerHideTimer?.cancel();
    _smartCornerHideTimer = null;
    _isSmartCornerHideEnabled = false;
    _isCornerWindowHidden = false;
    _cornerAlignedPosition = null;
    _cornerHiddenPosition = null;
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

  /// 使用动画将窗口平滑移动到目标位置
  ///
  /// [targetPosition] 目标位置
  /// [duration] 动画时长
  /// [curve] 动画曲线
  static Future<void> _animateWindowTo(
    Offset targetPosition, {
    Duration duration = const Duration(milliseconds: 150),
    Curve curve = Curves.easeOut,
  }) async {
    // 新增：如果正在动画且目标位置相同，则不重复执行
    if (_isAnimating && _currentAnimationTargetPosition == targetPosition) {
      return;
    }

    if (_isAnimating) {
      _animationTimer?.cancel();
    }

    _isAnimating = true;
    _currentAnimationTargetPosition = targetPosition; // 设置当前动画目标位置

    try {
      final startPosition = await windowManager.getPosition();
      if ((startPosition - targetPosition).distance < 1.0) {
        await windowManager.setPosition(targetPosition);
        _isAnimating = false;
        _currentAnimationTargetPosition = null; // 动画结束，清空目标位置
        return;
      }

      final tween = Tween<Offset>(begin: startPosition, end: targetPosition);

      const frameRate = 60;
      final totalFrames = (duration.inMilliseconds * frameRate / 1000).round();
      if (totalFrames <= 0) {
        await windowManager.setPosition(targetPosition);
        _isAnimating = false;
        _currentAnimationTargetPosition = null; // 动画结束，清空目标位置
        return;
      }

      final startTime = DateTime.now();

      _animationTimer = Timer.periodic(
        Duration(milliseconds: 1000 ~/ frameRate),
        (timer) async {
          final elapsed = DateTime.now().difference(startTime);
          double progress = elapsed.inMilliseconds / duration.inMilliseconds;

          if (progress >= 1.0) {
            progress = 1.0;
            timer.cancel();
            _isAnimating = false;
            _animationTimer = null;
            _currentAnimationTargetPosition = null; // 动画结束，清空目标位置
          }

          final curvedProgress = curve.transform(progress);
          final currentPosition = tween.transform(curvedProgress);

          await windowManager.setPosition(currentPosition);

          if (progress == 1.0) {
            await windowManager.setPosition(targetPosition);
          }
        },
      );
    } catch (e) {
      debugPrint('窗口动画失败: $e');
      _isAnimating = false;
      _currentAnimationTargetPosition = null; // 动画失败，清空目标位置
    }
  }

  /// 检查并触发智能停靠
  static Future<void> _checkAndTriggerSmartDock(Offset windowPosition) async {
    try {
      final display = await screenRetriever.getPrimaryDisplay();
      if (display.visiblePosition == null || display.visibleSize == null) {
        return;
      }

      final windowSize = await windowManager.getSize();
      final workArea = display.visibleSize!;
      final workAreaPosition = display.visiblePosition!;

      // 计算窗口超出屏幕边界的距离
      final leftOverflow = workAreaPosition.dx - windowPosition.dx;
      final rightOverflow = (windowPosition.dx + windowSize.width) -
          (workAreaPosition.dx + workArea.width);
      final topOverflow = workAreaPosition.dy - windowPosition.dy;
      final bottomOverflow = (windowPosition.dy + windowSize.height) -
          (workAreaPosition.dy + workArea.height);

      // 如果启用了角落停靠，优先检测角落
      if (_enableCornerDocking) {
        WindowCorner? targetCorner;
        double maxCornerOverflow = 0;

        // 检查所有角落，选择超出最多的角落
        // 要求两个方向都至少超出5像素才算角落停靠
        const minCornerOverflow = 5.0;

        // 检查左上角
        if (leftOverflow >= minCornerOverflow &&
            topOverflow >= minCornerOverflow) {
          final cornerOverflow = leftOverflow + topOverflow;
          if (cornerOverflow > maxCornerOverflow) {
            maxCornerOverflow = cornerOverflow;
            targetCorner = WindowCorner.topLeft;
          }
        }

        // 检查右上角
        if (rightOverflow >= minCornerOverflow &&
            topOverflow >= minCornerOverflow) {
          final cornerOverflow = rightOverflow + topOverflow;
          if (cornerOverflow > maxCornerOverflow) {
            maxCornerOverflow = cornerOverflow;
            targetCorner = WindowCorner.topRight;
          }
        }

        // 检查左下角
        if (leftOverflow >= minCornerOverflow &&
            bottomOverflow >= minCornerOverflow) {
          final cornerOverflow = leftOverflow + bottomOverflow;
          if (cornerOverflow > maxCornerOverflow) {
            maxCornerOverflow = cornerOverflow;
            targetCorner = WindowCorner.bottomLeft;
          }
        }

        // 检查右下角
        if (rightOverflow >= minCornerOverflow &&
            bottomOverflow >= minCornerOverflow) {
          final cornerOverflow = rightOverflow + bottomOverflow;
          if (cornerOverflow > maxCornerOverflow) {
            maxCornerOverflow = cornerOverflow;
            targetCorner = WindowCorner.bottomRight;
          }
        }

        // 如果检测到角落停靠
        if (targetCorner != null && maxCornerOverflow > 15) {
          // 总超出量至少15像素才触发角落停靠
          debugPrint(
              '触发智能角落停靠到${targetCorner.name}，超出屏幕：${maxCornerOverflow.toStringAsFixed(1)}px');

          // 启用智能角落对齐（先对齐到角落，然后启用鼠标监听）
          await _enableSmartCornerAlignment(
            corner: targetCorner,
            visibleSize: _smartDockVisibleWidth * 3, // 角落停靠使用3倍大小，更容易找到
          );
          return;
        }
      }

      // 如果没有角落停靠或未检测到角落，检查边缘停靠
      WindowEdge? targetEdge;
      double maxOverflow = 0;

      if (leftOverflow > maxOverflow) {
        targetEdge = WindowEdge.left;
        maxOverflow = leftOverflow;
      }
      if (rightOverflow > maxOverflow) {
        targetEdge = WindowEdge.right;
        maxOverflow = rightOverflow;
      }
      if (topOverflow > maxOverflow) {
        targetEdge = WindowEdge.top;
        maxOverflow = topOverflow;
      }
      if (bottomOverflow > maxOverflow) {
        targetEdge = WindowEdge.bottom;
        maxOverflow = bottomOverflow;
      }

      // 如果找到了需要停靠的边缘
      if (targetEdge != null && maxOverflow > 5) {
        // 至少超出5像素才触发边缘停靠
        debugPrint(
            '触发智能边缘停靠到${targetEdge.name}，超出屏幕：${maxOverflow.toStringAsFixed(1)}px');

        // 启用新的智能边缘对齐（先对齐到边缘，然后启用鼠标监听）
        await _enableSmartEdgeAlignment(
          edge: targetEdge,
          visibleWidth: _smartDockVisibleWidth,
        );
      } else {
        // 只有在没有活跃的智能隐藏监听时，才停止监听
        // 如果已经有隐藏监听在运行，说明窗口可能处于已对齐状态，不应该停止
        if (!_isSmartHideEnabled && !_isSmartCornerHideEnabled) {
          debugPrint('窗口未停靠在边缘或角落，且无活跃隐藏监听，停止所有智能隐藏监听。');
        } else {
          debugPrint('窗口未溢出但有活跃的隐藏监听，保持监听状态。');
        }
      }
    } catch (e) {
      debugPrint('智能停靠触发出错：$e');
    }
  }

  /// 停止所有智能停靠功能
  static Future<void> stopAll() async {
    await _stopSmartDockingMonitor();
  }
}
