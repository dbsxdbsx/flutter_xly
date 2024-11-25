import 'package:flutter/material.dart';
import 'package:xly/xly.dart';

/// 统一的对话框管理类
class MyDialogSheet {
  /// 显示底部弹出菜单
  static Future<T?> showBottom<T>({
    required Widget child,
    double? height,
    Color backgroundColor = Colors.white,
    double? borderRadius,
  }) {
    final actualHeight = height ?? 250.h;
    final actualBorderRadius = borderRadius ?? 20.r;

    return Get.bottomSheet(
      _BottomSheetContainer(
        height: actualHeight,
        backgroundColor: backgroundColor,
        borderRadius: actualBorderRadius,
        child: child,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(actualBorderRadius)),
      ),
      backgroundColor: Colors.transparent,
    );
  }
}

/// 内部使用的底部菜单容器组件
class _BottomSheetContainer extends StatelessWidget {
  final Widget child;
  final double height;
  final Color backgroundColor;
  final double borderRadius;

  const _BottomSheetContainer({
    required this.child,
    required this.height,
    required this.backgroundColor,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(borderRadius)),
      ),
      child: Column(
        children: [
          SizedBox(height: 10.h),
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 20.h),
          Expanded(child: child),
        ],
      ),
    );
  }
}
