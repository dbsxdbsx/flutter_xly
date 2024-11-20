import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MyIconButton extends StatelessWidget {
  final IconData icon;
  final double? iconSize;
  final Color? iconColor;
  final VoidCallback? onPressed;
  final EdgeInsetsGeometry? padding;
  final BoxConstraints? constraints;

  const MyIconButton({
    super.key,
    required this.icon,
    this.iconSize = 16,
    this.iconColor,
    this.onPressed,
    this.padding,
    this.constraints,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        icon,
        size: iconSize?.sp,
        color: iconColor,
      ),
      onPressed: onPressed,
      padding: padding ?? EdgeInsets.all(8.w),
      constraints: constraints ??
          BoxConstraints(
            minWidth: 32.w,
            minHeight: 32.w,
          ),
    );
  }
}
