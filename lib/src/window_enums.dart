/// 窗口边缘位置枚举
enum WindowEdge {
  /// 左边缘
  left,

  /// 右边缘
  right,

  /// 上边缘
  top,

  /// 下边缘
  bottom,
}

/// 窗口角落位置枚举
enum WindowCorner {
  /// 左上角
  topLeft,

  /// 右上角
  topRight,

  /// 左下角
  bottomLeft,

  /// 右下角
  bottomRight,
}

/// 窗口停靠类型枚举
enum WindowDockType {
  /// 边缘停靠
  edge,

  /// 角落停靠
  corner,
}
