import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MyIcon extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;

  /// 图标的视觉尺寸，单位为当前逻辑像素。
  ///
  /// 需要响应式适配时由调用方传入 `24.w` 等 ScreenUtil 值。
  final double? size;
  final VoidCallback? onPressed;
  final String? tooltip;

  /// 水波纹和悬停反馈的视觉半径，单位为当前逻辑像素。
  ///
  /// 只影响反馈效果，不改变图标尺寸或点击区域。
  final double? hoverShadowRadius;

  /// 最小点击区域的边长，单位为当前逻辑像素。
  ///
  /// 它与 [size]、[hoverShadowRadius] 相互独立。移动端可显式传入
  /// [kMinInteractiveDimension]，在不放大图标的前提下满足触控要求。
  final double? tapTargetSize;
  final Color? hoverColor;
  final Color? splashColor;

  const MyIcon({
    super.key,
    required this.icon,
    this.iconColor,
    this.size,
    this.onPressed,
    this.tooltip,
    this.hoverShadowRadius,
    this.tapTargetSize,
    this.hoverColor,
    this.splashColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = hoverShadowRadius ?? 20.w;
    final effectiveSize = size ?? 20.w;
    final effectiveTapTargetSize = tapTargetSize ?? 20.w;

    Widget iconWidget = Icon(
      icon,
      color: iconColor ?? Colors.grey,
      size: effectiveSize,
    );

    if (tooltip != null) {
      iconWidget = Tooltip(
        message: tooltip!,
        child: iconWidget,
      );
    }

    return IconButton(
      padding: EdgeInsets.all(4.w),
      constraints: BoxConstraints(
        minWidth: effectiveTapTargetSize,
        minHeight: effectiveTapTargetSize,
      ),
      splashRadius: effectiveRadius * 0.8,
      icon: iconWidget,
      onPressed: onPressed,
      splashColor: splashColor ?? Colors.grey.withValues(alpha: 0.3),
      hoverColor: hoverColor ?? Colors.grey.withValues(alpha: 0.1),
    );
  }
}
