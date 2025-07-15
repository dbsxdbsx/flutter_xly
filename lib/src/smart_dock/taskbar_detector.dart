import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:screen_retriever/screen_retriever.dart';

import '../window_enums.dart';

/// Taskbar位置信息
class TaskbarInfo {
  /// Taskbar所在的边缘，如果无法检测则为null
  final WindowEdge? edge;

  /// Taskbar的厚度（像素）
  final double thickness;

  /// 完整屏幕尺寸
  final Size fullScreenSize;

  /// 完整屏幕位置
  final Offset fullScreenPosition;

  /// 工作区域尺寸
  final Size workAreaSize;

  /// 工作区域位置
  final Offset workAreaPosition;

  const TaskbarInfo({
    required this.edge,
    required this.thickness,
    required this.fullScreenSize,
    required this.fullScreenPosition,
    required this.workAreaSize,
    required this.workAreaPosition,
  });

  /// 检查指定边缘是否有taskbar
  bool hasTaskbarOnEdge(WindowEdge edge) => this.edge == edge;

  /// 检查指定角落是否有taskbar在其任一边缘
  bool hasTaskbarOnCorner(WindowCorner corner) {
    if (edge == null) return false;

    switch (corner) {
      case WindowCorner.topLeft:
        return edge == WindowEdge.top || edge == WindowEdge.left;
      case WindowCorner.topRight:
        return edge == WindowEdge.top || edge == WindowEdge.right;
      case WindowCorner.bottomLeft:
        return edge == WindowEdge.bottom || edge == WindowEdge.left;
      case WindowCorner.bottomRight:
        return edge == WindowEdge.bottom || edge == WindowEdge.right;
    }
  }

  /// 获取taskbar外边缘的坐标
  /// 返回taskbar外边缘相对于完整屏幕的坐标
  double getTaskbarOuterEdgeCoordinate() {
    if (edge == null) return 0.0;

    switch (edge!) {
      case WindowEdge.left:
        return fullScreenPosition.dx + thickness;
      case WindowEdge.right:
        return fullScreenPosition.dx + fullScreenSize.width - thickness;
      case WindowEdge.top:
        return fullScreenPosition.dy + thickness;
      case WindowEdge.bottom:
        return fullScreenPosition.dy + fullScreenSize.height - thickness;
    }
  }
}

/// Taskbar检测器
class TaskbarDetector {
  /// 检测taskbar位置信息
  static Future<TaskbarInfo> detectTaskbar() async {
    try {
      final display = await screenRetriever.getPrimaryDisplay();

      // 获取完整屏幕信息
      final fullScreenSize = display.size;
      final fullScreenPosition = Offset.zero; // 主屏幕通常从(0,0)开始

      // 获取工作区域信息
      final workAreaSize = display.visibleSize ?? Size.zero;
      final workAreaPosition = display.visiblePosition ?? Offset.zero;

      // 检测taskbar位置
      WindowEdge? taskbarEdge;
      double taskbarThickness = 0.0;

      // 通过比较完整屏幕和工作区域来检测taskbar位置
      if (workAreaPosition.dx > fullScreenPosition.dx) {
        // 左边有taskbar
        taskbarEdge = WindowEdge.left;
        taskbarThickness = workAreaPosition.dx - fullScreenPosition.dx;
      } else if (workAreaPosition.dx + workAreaSize.width <
          fullScreenPosition.dx + fullScreenSize.width) {
        // 右边有taskbar
        taskbarEdge = WindowEdge.right;
        taskbarThickness = (fullScreenPosition.dx + fullScreenSize.width) -
            (workAreaPosition.dx + workAreaSize.width);
      } else if (workAreaPosition.dy > fullScreenPosition.dy) {
        // 上边有taskbar
        taskbarEdge = WindowEdge.top;
        taskbarThickness = workAreaPosition.dy - fullScreenPosition.dy;
      } else if (workAreaPosition.dy + workAreaSize.height <
          fullScreenPosition.dy + fullScreenSize.height) {
        // 下边有taskbar
        taskbarEdge = WindowEdge.bottom;
        taskbarThickness = (fullScreenPosition.dy + fullScreenSize.height) -
            (workAreaPosition.dy + workAreaSize.height);
      }

      debugPrint(
          'Taskbar检测结果: edge=${taskbarEdge?.name}, thickness=${taskbarThickness.toStringAsFixed(1)}px');

      return TaskbarInfo(
        edge: taskbarEdge,
        thickness: taskbarThickness,
        fullScreenSize: fullScreenSize,
        fullScreenPosition: fullScreenPosition,
        workAreaSize: workAreaSize,
        workAreaPosition: workAreaPosition,
      );
    } catch (e) {
      debugPrint('Taskbar检测失败: $e');
      return const TaskbarInfo(
        edge: null,
        thickness: 0.0,
        fullScreenSize: Size.zero,
        fullScreenPosition: Offset.zero,
        workAreaSize: Size.zero,
        workAreaPosition: Offset.zero,
      );
    }
  }
}
