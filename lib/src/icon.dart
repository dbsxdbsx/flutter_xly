import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MyIcon extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final double? size;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double? hoverShadowRadius;
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
    this.hoverColor,
    this.splashColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = (hoverShadowRadius ?? 20).w;
    final effectiveSize = size?.w ?? 20.w;

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
        minWidth: effectiveRadius,
        minHeight: effectiveRadius,
      ),
      splashRadius: effectiveRadius * 0.8,
      icon: iconWidget,
      onPressed: onPressed,
      splashColor: splashColor ?? Colors.grey.withOpacity(0.3),
      hoverColor: hoverColor ?? Colors.grey.withOpacity(0.1),
    );
  }
}
