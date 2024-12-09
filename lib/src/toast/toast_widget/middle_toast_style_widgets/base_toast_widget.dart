import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BaseToastWidget extends StatelessWidget {
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
      padding:
          padding ?? EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.w),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.black87.withOpacity(0.7),
        borderRadius: BorderRadius.circular(radius ?? 8.w),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon!,
              color: iconColor ?? Colors.white,
              size: iconSize ?? 32.sp,
            ),
            SizedBox(height: 8.w),
          ],
          Text(
            message,
            style: textStyle ??
                TextStyle(
                  fontSize: 16.sp,
                  color: Colors.white,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
