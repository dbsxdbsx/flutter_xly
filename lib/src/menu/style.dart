import 'dart:ui';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../platform.dart';

class MyMenuStyle {
  final double _fontSize;
  final double _iconPadding;
  final double _itemHeight;
  final double _borderRadius;
  final double _blurSigma;
  final double _borderWidth;
  final Color focusColor;
  final Color surfaceColor;
  final Color borderColor;
  final double shadowRatio;

  /// 当前窗口下的适配值。
  ///
  /// 样式保存设计稿原值，通过 getter 延迟换算，避免窗口尺寸变化后
  /// 样式值冻结，而菜单内部 padding/icon 又按新尺寸换算。
  double get fontSize => _fontSize.sp;
  double get iconPadding => _iconPadding.w;
  double get itemHeight => _itemHeight.r;

  // 视觉效果参数使用稳定的逻辑像素，不随窗口尺寸无限放大。
  double get borderRadius => _borderRadius;
  double get blurSigma => _blurSigma;
  double get borderWidth => _borderWidth;

  /// 创建菜单样式
  ///
  /// [fontSize]、[iconPadding]、[itemHeight] 是设计稿尺寸，会动态适配；
  /// [borderRadius]、[blurSigma]、[borderWidth] 是稳定的逻辑像素效果值，
  /// 避免桌面窗口变化时圆角、模糊与细边框被无限放大。
  MyMenuStyle({
    double fontSize = 15,
    double iconPadding = 90,
    double itemHeight = 48,
    double borderRadius = 10,
    double blurSigma = 16,
    double borderWidth = 1,
    this.focusColor = const Color(0xFF000000),
    this.surfaceColor = const Color(0xB8F9FAFC),
    this.borderColor = const Color(0x14000000),
    this.shadowRatio = 0.3,
  })  : _fontSize = fontSize,
        _iconPadding = iconPadding,
        _itemHeight = itemHeight,
        _borderRadius = borderRadius,
        _blurSigma = blurSigma,
        _borderWidth = borderWidth;

  /// 按交互平台选择密度；视觉材质保持一致。
  factory MyMenuStyle.adaptive() {
    if (MyPlatform.isDesktop) {
      return MyMenuStyle(fontSize: 14, itemHeight: 40);
    }
    return MyMenuStyle();
  }
}
