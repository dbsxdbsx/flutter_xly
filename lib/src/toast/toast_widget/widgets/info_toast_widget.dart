import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class InfoToastWidget extends StatelessWidget {
  final String message;
  final TextStyle? textStyle;
  final Color? backgroundColor;

  const InfoToastWidget({
    super.key,
    required this.message,
    this.textStyle,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final defaultBackgroundColor = Colors.black87.withOpacity(0.7);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.w),
      decoration: BoxDecoration(
        color: backgroundColor ?? defaultBackgroundColor,
        borderRadius: BorderRadius.circular(8.w),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.blue,
            size: 32.sp,
          ),
          SizedBox(height: 8.w),
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
