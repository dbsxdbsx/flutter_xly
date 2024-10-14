import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:oktoast/oktoast.dart';

void toast(
  String message, {
  bool? forever,
  Duration? duration,
  TextStyle? textStyle,
  Color? backgroundColor,
  double? radius,
  EdgeInsetsGeometry? textPadding,
  ToastPosition? position,
  bool stackToasts = false,
  Duration animationDuration = const Duration(milliseconds: 500),
  Curve animationCurve = Curves.easeOutCubic,
}) {
  showToast(
    message,
    dismissOtherToast: !stackToasts,
    duration: forever == true
        ? const Duration(days: 365)
        : duration ?? const Duration(seconds: 3),
    textStyle: textStyle ?? TextStyle(fontSize: 25.sp, color: Colors.white),
    backgroundColor: backgroundColor ?? Colors.black87.withOpacity(0.7),
    radius: radius ?? 20.0,
    textPadding:
        textPadding ?? EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.w),
    position: position ?? ToastPosition.center,
    animationBuilder: (context, child, controller, direction) {
      return ScaleTransition(
        scale: Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
          parent: controller,
          curve: animationCurve,
        )),
        child: FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
            parent: controller,
            curve: animationCurve,
          )),
          child: child,
        ),
      );
    },
    animationDuration: animationDuration,
    animationCurve: animationCurve,
  );
}

void hideAllToasts([int milliseconds = 0]) {
  Future.delayed(Duration(milliseconds: milliseconds), () {
    dismissAllToast(showAnim: false);
  });
}
