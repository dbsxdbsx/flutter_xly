part of '../../xly.dart';

// 新的数据模型：浮动面板的按钮定义
class FloatPanelIconBtn {
  final IconData icon;
  final String? id; // 参与联动时填写；不需要联动可为空
  final FutureOr<void> Function()? onTap;
  final String? tooltip;
  final bool? disabled; // 显式禁用优先于联动

  const FloatPanelIconBtn({
    required this.icon,
    this.id,
    this.onTap,
    this.tooltip,
    this.disabled,
  });
}

enum PanelShape { rectangle, rounded }

enum DockType { inside, outside }

enum PanelState { expanded, closed }

/// 上下停靠时的展开方向
enum HorizontalExpandMode {
  /// 不横向展开，保持竖向展开
  none,

  /// 从左到右展开（handle 在左端，默认）
  leftToRight,

  /// 从右到左展开（handle 在右端）
  rightToLeft,
}

/// 面板停靠边缘方向（内部使用）
enum _DockEdge { left, right, top, bottom }

/// 禁用样式类型
enum DisabledStyleType { defaultX, dimOnly, custom }

/// 禁用样式配置
class DisabledStyle {
  final DisabledStyleType type;
  final Widget Function(double iconSize)? overlayBuilder;
  const DisabledStyle._(this.type, [this.overlayBuilder]);
  const DisabledStyle.defaultX() : this._(DisabledStyleType.defaultX);
  const DisabledStyle.dimOnly() : this._(DisabledStyleType.dimOnly);
  const DisabledStyle.custom(Widget Function(double iconSize) builder)
      : this._(DisabledStyleType.custom, builder);
}
