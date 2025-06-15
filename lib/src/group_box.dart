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

  const MyGroupBox({
    super.key,
    required this.child,
    required this.title,
    this.borderColor = Colors.grey,
    this.titleColor = Colors.black,
    this.borderWidth = 1.0,
    this.borderRadius = 4.0,
    this.padding = const EdgeInsets.only(top: 10.0),
    this.titleStyle,
    this.style = SectionBorderStyle.normal,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          margin: EdgeInsets.only(top: 10.h),
          decoration: style == SectionBorderStyle.inset
              ? BoxDecoration(
                  border: Border.all(
                      color: borderColor.withValues(alpha: 0.5),
                      width: borderWidth.w),
                  borderRadius: BorderRadius.circular(borderRadius.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white,
                      offset: Offset(borderWidth.w, borderWidth.w),
                    ),
                    BoxShadow(
                      color: borderColor.withValues(alpha: 0.5),
                      offset: Offset(-borderWidth.w, -borderWidth.w),
                    ),
                  ],
                )
              : BoxDecoration(
                  border: Border.all(color: borderColor, width: borderWidth.w),
                  borderRadius: BorderRadius.circular(borderRadius.r),
                ),
          child: Padding(
            padding: padding,
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
