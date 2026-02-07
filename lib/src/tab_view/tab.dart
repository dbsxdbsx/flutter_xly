import 'package:flutter/material.dart';

/// Tab 栏位置枚举
enum MyTabPosition {
  /// Tab 栏在内容区上方
  top,

  /// Tab 栏在内容区下方
  bottom,
}

/// Tab 栏水平布局模式
enum MyTabBarFit {
  /// 拉伸模式：Tab 栏水平填满容器宽度，各 Tab 等宽分配
  stretched,

  /// 紧凑模式（macOS 原版风格）：Tab 栏按内容收缩并居中，宽度由标签内容决定
  compact,
}

/// 单个 Tab 的数据定义
///
/// 用于描述 [MyTabView] 中每个 Tab 按钮的内容和样式。
/// 这是一个纯数据类，不是 Widget —— 实际渲染由 [MySegmentedControl] 内部处理。
///
/// 示例：
/// ```dart
/// MyTab(label: '棋谱')
/// MyTab(label: '日志', icon: Icon(Icons.list, size: 14))
/// ```
class MyTab {
  const MyTab({
    required this.label,
    this.icon,
    this.activeColor,
    this.inactiveColor,
    this.hoverColor,
    this.textStyle,
    this.activeTextStyle,
    this.padding,
    this.borderRadius,
  });

  /// Tab 标签文字
  final String label;

  /// 可选图标，显示在文字左侧
  final Widget? icon;

  /// 激活态背景色（默认：亮色模式白色，暗色模式 #646669）
  final Color? activeColor;

  /// 非激活态背景色（默认：透明）
  final Color? inactiveColor;

  /// 鼠标悬停时的背景色
  final Color? hoverColor;

  /// 非激活态文字样式
  final TextStyle? textStyle;

  /// 激活态文字样式
  final TextStyle? activeTextStyle;

  /// Tab 按钮内部 padding（传入已经用 ScreenUtil 转换过的值）
  final EdgeInsetsGeometry? padding;

  /// Tab 按钮圆角（传入已经用 ScreenUtil 转换过的值）
  final BorderRadius? borderRadius;
}
