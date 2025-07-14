import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

import '../window_enums.dart';

/// 停靠检测结果
class DockDetectionResult {
  final bool shouldDock;
  final WindowEdge? edge;
  final WindowCorner? corner;
  final double overflowAmount;

  const DockDetectionResult({
    required this.shouldDock,
    this.edge,
    this.corner,
    required this.overflowAmount,
  });

  /// 创建无停靠结果
  const DockDetectionResult.none()
      : shouldDock = false,
        edge = null,
        corner = null,
        overflowAmount = 0.0;

  /// 创建边缘停靠结果
  const DockDetectionResult.edge(this.edge, double overflow)
      : shouldDock = true,
        corner = null,
        overflowAmount = overflow;

  /// 创建角落停靠结果
  const DockDetectionResult.corner(this.corner, double overflow)
      : shouldDock = true,
        edge = null,
        overflowAmount = overflow;

  bool get isEdgeDock => shouldDock && edge != null;
  bool get isCornerDock => shouldDock && corner != null;
}

/// 停靠位置计算结果
class DockPositions {
  final Offset alignedPosition;
  final Offset hiddenPosition;

  const DockPositions({
    required this.alignedPosition,
    required this.hiddenPosition,
  });
}

/// 停靠检测器
///
/// 负责检测窗口是否应该停靠到屏幕边缘或角落，并计算停靠位置
class DockDetector {
  /// 最小边缘溢出阈值
  static const double minEdgeOverflow = 5.0;

  /// 最小角落溢出阈值
  static const double minCornerOverflow = 5.0;

  /// 最小角落总溢出阈值
  static const double minCornerTotalOverflow = 15.0;

  /// 检测窗口是否应该停靠
  ///
  /// [windowPosition] 当前窗口位置
  /// [enableCornerDocking] 是否启用角落停靠
  static Future<DockDetectionResult> detectDocking(
    Offset windowPosition, {
    bool enableCornerDocking = true,
  }) async {
    try {
      final display = await screenRetriever.getPrimaryDisplay();
      if (display.visiblePosition == null || display.visibleSize == null) {
        return const DockDetectionResult.none();
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
      if (enableCornerDocking) {
        final cornerResult = _detectCornerDocking(
          leftOverflow,
          rightOverflow,
          topOverflow,
          bottomOverflow,
        );
        if (cornerResult.shouldDock) {
          return cornerResult;
        }
      }

      // 检查边缘停靠
      return _detectEdgeDocking(
        leftOverflow,
        rightOverflow,
        topOverflow,
        bottomOverflow,
      );
    } catch (e) {
      debugPrint('停靠检测出错：$e');
      return const DockDetectionResult.none();
    }
  }

  /// 检测角落停靠
  static DockDetectionResult _detectCornerDocking(
    double leftOverflow,
    double rightOverflow,
    double topOverflow,
    double bottomOverflow,
  ) {
    WindowCorner? targetCorner;
    double maxCornerOverflow = 0;

    // 检查所有角落，选择超出最多的角落
    // 要求两个方向都至少超出指定像素才算角落停靠

    // 检查左上角
    if (leftOverflow >= minCornerOverflow && topOverflow >= minCornerOverflow) {
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

    // 如果检测到角落停靠且总超出量足够
    if (targetCorner != null && maxCornerOverflow > minCornerTotalOverflow) {
      debugPrint(
        '触发智能角落停靠到${targetCorner.name}，超出屏幕：${maxCornerOverflow.toStringAsFixed(1)}px',
      );
      return DockDetectionResult.corner(targetCorner, maxCornerOverflow);
    }

    return const DockDetectionResult.none();
  }

  /// 检测边缘停靠
  static DockDetectionResult _detectEdgeDocking(
    double leftOverflow,
    double rightOverflow,
    double topOverflow,
    double bottomOverflow,
  ) {
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

    // 如果找到了需要停靠的边缘且超出量足够
    if (targetEdge != null && maxOverflow > minEdgeOverflow) {
      debugPrint(
        '触发智能边缘停靠到${targetEdge.name}，超出屏幕：${maxOverflow.toStringAsFixed(1)}px',
      );
      return DockDetectionResult.edge(targetEdge, maxOverflow);
    }

    return const DockDetectionResult.none();
  }

  /// 计算边缘停靠位置
  ///
  /// [edge] 停靠边缘
  /// [currentPosition] 当前窗口位置
  /// [visibleWidth] 隐藏时可见宽度
  static Future<DockPositions> calculateEdgePositions(
    WindowEdge edge,
    Offset currentPosition,
    double visibleWidth,
  ) async {
    final display = await screenRetriever.getPrimaryDisplay();
    final windowSize = await windowManager.getSize();
    final workArea = display.visibleSize!;
    final workAreaPosition = display.visiblePosition!;

    // 计算对齐位置（只调整溢出的轴，保持另一轴的当前位置）
    Offset alignedPosition;
    Offset hiddenPosition;

    switch (edge) {
      case WindowEdge.left:
        final clampedY = currentPosition.dy.clamp(
          workAreaPosition.dy,
          workAreaPosition.dy + workArea.height - windowSize.height,
        );
        alignedPosition = Offset(workAreaPosition.dx, clampedY);
        hiddenPosition = Offset(
          alignedPosition.dx - windowSize.width + visibleWidth,
          alignedPosition.dy,
        );
        break;
      case WindowEdge.right:
        final clampedY = currentPosition.dy.clamp(
          workAreaPosition.dy,
          workAreaPosition.dy + workArea.height - windowSize.height,
        );
        alignedPosition = Offset(
          workAreaPosition.dx + workArea.width - windowSize.width,
          clampedY,
        );
        hiddenPosition = Offset(
          alignedPosition.dx + windowSize.width - visibleWidth,
          alignedPosition.dy,
        );
        break;
      case WindowEdge.top:
        final clampedX = currentPosition.dx.clamp(
          workAreaPosition.dx,
          workAreaPosition.dx + workArea.width - windowSize.width,
        );
        alignedPosition = Offset(clampedX, workAreaPosition.dy);
        hiddenPosition = Offset(
          alignedPosition.dx,
          alignedPosition.dy - windowSize.height + visibleWidth,
        );
        break;
      case WindowEdge.bottom:
        final clampedX = currentPosition.dx.clamp(
          workAreaPosition.dx,
          workAreaPosition.dx + workArea.width - windowSize.width,
        );
        alignedPosition = Offset(
          clampedX,
          workAreaPosition.dy + workArea.height - windowSize.height,
        );
        hiddenPosition = Offset(
          alignedPosition.dx,
          alignedPosition.dy + windowSize.height - visibleWidth,
        );
        break;
    }

    return DockPositions(
      alignedPosition: alignedPosition,
      hiddenPosition: hiddenPosition,
    );
  }

  /// 计算角落停靠位置
  ///
  /// [corner] 停靠角落
  /// [visibleSize] 隐藏时可见大小
  static Future<DockPositions> calculateCornerPositions(
    WindowCorner corner,
    double visibleSize,
  ) async {
    final display = await screenRetriever.getPrimaryDisplay();
    final windowSize = await windowManager.getSize();
    final workArea = display.visibleSize!;
    final workAreaPosition = display.visiblePosition!;

    // 计算对齐位置（完全对齐到角落）
    Offset alignedPosition;
    Offset hiddenPosition;

    // 角落隐藏时的可见区域
    final cornerVisibleWidth = visibleSize * 2; // 水平方向可见宽度
    final cornerVisibleHeight = visibleSize; // 垂直方向可见高度

    switch (corner) {
      case WindowCorner.topLeft:
        alignedPosition = Offset(
          workAreaPosition.dx,
          workAreaPosition.dy,
        );
        hiddenPosition = Offset(
          alignedPosition.dx - windowSize.width + cornerVisibleWidth,
          alignedPosition.dy - windowSize.height + cornerVisibleHeight,
        );
        break;
      case WindowCorner.topRight:
        alignedPosition = Offset(
          workAreaPosition.dx + workArea.width - windowSize.width,
          workAreaPosition.dy,
        );
        hiddenPosition = Offset(
          alignedPosition.dx + windowSize.width - cornerVisibleWidth,
          alignedPosition.dy - windowSize.height + cornerVisibleHeight,
        );
        break;
      case WindowCorner.bottomLeft:
        alignedPosition = Offset(
          workAreaPosition.dx,
          workAreaPosition.dy + workArea.height - windowSize.height,
        );
        hiddenPosition = Offset(
          alignedPosition.dx - windowSize.width + cornerVisibleWidth,
          alignedPosition.dy + windowSize.height - cornerVisibleHeight,
        );
        break;
      case WindowCorner.bottomRight:
        alignedPosition = Offset(
          workAreaPosition.dx + workArea.width - windowSize.width,
          workAreaPosition.dy + workArea.height - windowSize.height,
        );
        hiddenPosition = Offset(
          alignedPosition.dx + windowSize.width - cornerVisibleWidth,
          alignedPosition.dy + windowSize.height - cornerVisibleHeight,
        );
        break;
    }

    return DockPositions(
      alignedPosition: alignedPosition,
      hiddenPosition: hiddenPosition,
    );
  }
}
