import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BaseToastWidget extends StatelessWidget {
  // 默认样式配置 - 使用 getter 以支持热重载
  Color get defaultBackgroundColor => Colors.black87.withOpacity(0.75);
  Color get defaultTextColor => Colors.white;
  Color get defaultIconColor => Colors.white;
  double get defaultIconSize => 32.sp;
  double get defaultFontSize => 16.sp;
  double get defaultBorderRadius => 8.w;
  EdgeInsets get defaultPadding => EdgeInsets.symmetric(
        horizontal: 24.w,
        vertical: 16.w,
      );

  final String message;
  final TextStyle? textStyle;
  final Color? backgroundColor;
  final double? radius;
  final EdgeInsetsGeometry? padding;
  final IconData? icon;
  final Color? iconColor;
  final double? iconSize;

  const BaseToastWidget({
    super.key,
    required this.message,
    this.textStyle,
    this.backgroundColor,
    this.radius,
    this.padding,
    this.icon,
    this.iconColor,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? defaultPadding,
      decoration: BoxDecoration(
        color: backgroundColor ?? defaultBackgroundColor,
        borderRadius: BorderRadius.circular(radius ?? defaultBorderRadius),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Icon(
              icon!,
              color: iconColor ?? defaultIconColor,
              size: iconSize ?? defaultIconSize,
            ),
          if (message.isNotEmpty) ...[
            if (icon != null) SizedBox(height: 8.w),
            Text(
              message,
              style: textStyle ??
                  TextStyle(
                    fontSize: defaultFontSize,
                    color: defaultTextColor,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
