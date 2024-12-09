import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LoadingWidget extends StatelessWidget {
  final String? message;
  final Color? spinnerColor;
  final Color? backgroundColor;
  final double? spinnerSize;
  final TextStyle? textStyle;

  const LoadingWidget({
    super.key,
    this.message,
    this.spinnerColor,
    this.backgroundColor,
    this.spinnerSize,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.w),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.black87.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8.w),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: spinnerSize ?? 32.sp,
            height: spinnerSize ?? 32.sp,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                spinnerColor ?? Colors.white,
              ),
            ),
          ),
          if (message != null) ...[
            SizedBox(height: 8.w),
            Text(
              message!,
              style: textStyle ??
                  TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
