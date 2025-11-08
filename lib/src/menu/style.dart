import 'dart:ui';

import 'package:flutter_screenutil/flutter_screenutil.dart';

class MyMenuStyle {
  final double fontSize;
  final double iconPadding;
  final double itemHeight;
  final double borderRadius;
  final double blurSigma;
  final double borderWidth;
  final Color focusColor;
  final double shadowRatio;

  /// 创建菜单样式
  ///
  /// 注意：传入的数值应该是设计稿尺寸（基于你的 ScreenUtil 初始化设计稿）
  /// 例如：如果设计稿是 375px，那么 fontSize: 15 表示设计稿上的 15px
  MyMenuStyle({
    double fontSize = 15,
    double iconPadding = 90,
    double itemHeight = 50,
    double borderRadius = 13,
    double blurSigma = 10,
    double borderWidth = 1,
    this.focusColor = const Color(0xFF007AFF),
    this.shadowRatio = 0.5,
  })  : fontSize = fontSize.sp,
        iconPadding = iconPadding.w,
        itemHeight = itemHeight.h,
        borderRadius = borderRadius.r,
        blurSigma = blurSigma.r,
        borderWidth = borderWidth.w;
}
