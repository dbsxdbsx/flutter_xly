import 'package:flutter/material.dart';
import 'package:xly/xly.dart';

class MyBottomMenu extends StatelessWidget {
  final Widget child;
  final double height;
  final Color backgroundColor;
  final double borderRadius;

  const MyBottomMenu({
    super.key,
    required this.child,
    this.height = 250,
    this.backgroundColor = Colors.white,
    this.borderRadius = 20,
  });

  static void show({
    required Widget child,
    double height = 250,
    Color backgroundColor = Colors.white,
    double borderRadius = 20,
  }) {
    Get.bottomSheet(
      MyBottomMenu(
        height: height,
        backgroundColor: backgroundColor,
        borderRadius: borderRadius,
        child: child,
      ),
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(borderRadius.r)),
      ),
      backgroundColor: Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height.h,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(borderRadius.r)),
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

class MyBottomMenuContent extends StatelessWidget {
  final List<Widget> children;

  const MyBottomMenuContent({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}
