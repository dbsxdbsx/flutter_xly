import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

enum SectionBorderStyle { normal, inset }

class MyGroupBox extends StatelessWidget {
  final Widget child;
  final String title;
  final Color borderColor;
  final Color titleColor;
  final double borderWidth;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final TextStyle? titleStyle;
  final SectionBorderStyle style;
  final bool _usesDefaultBorderWidth;
  final bool _usesDefaultBorderRadius;
  final bool _usesDefaultPadding;

  const MyGroupBox({
    super.key,
    required this.child,
    required this.title,
    this.borderColor = Colors.grey,
    this.titleColor = Colors.black,
    double? borderWidth,
    double? borderRadius,
    EdgeInsetsGeometry? padding,
    this.titleStyle,
    this.style = SectionBorderStyle.normal,
  })  : borderWidth = borderWidth ?? 1.0,
        borderRadius = borderRadius ?? 4.0,
        padding = padding ?? const EdgeInsets.only(top: 10),
        _usesDefaultBorderWidth = borderWidth == null,
        _usesDefaultBorderRadius = borderRadius == null,
        _usesDefaultPadding = padding == null;

  @override
  Widget build(BuildContext context) {
    final effectiveBorderWidth = _usesDefaultBorderWidth ? 1.w : borderWidth;
    final effectiveBorderRadius = _usesDefaultBorderRadius ? 4.r : borderRadius;
    final effectivePadding =
        _usesDefaultPadding ? EdgeInsets.only(top: 10.h) : padding;
    return Stack(
      children: [
        Container(
          margin: EdgeInsets.only(top: 10.h),
          decoration: style == SectionBorderStyle.inset
              ? BoxDecoration(
                  border: Border.all(
                    color: borderColor.withValues(alpha: 0.5),
                    width: effectiveBorderWidth,
                  ),
                  borderRadius: BorderRadius.circular(effectiveBorderRadius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white,
                      offset:
                          Offset(effectiveBorderWidth, effectiveBorderWidth),
                    ),
                    BoxShadow(
                      color: borderColor.withValues(alpha: 0.5),
                      offset:
                          Offset(-effectiveBorderWidth, -effectiveBorderWidth),
                    ),
                  ],
                )
              : BoxDecoration(
                  border: Border.all(
                      color: borderColor, width: effectiveBorderWidth),
                  borderRadius: BorderRadius.circular(effectiveBorderRadius),
                ),
          child: Padding(
            padding: effectivePadding,
            child: child,
          ),
        ),
        Positioned(
          left: 10.w,
          top: 0,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 5.w),
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Text(
              title,
              style: titleStyle ??
                  TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
            ),
          ),
        ),
      ],
    );
  }
}
