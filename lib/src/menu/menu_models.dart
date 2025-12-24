import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 菜单元素基类
abstract class MyMenuElement {}

/// 菜单项
class MyMenuItem extends MyMenuElement {
  final String? text;
  final IconData? icon;
  final FutureOr<void> Function()? onTap;
  final List<MyMenuElement>? subItems;
  final bool enabled;

  MyMenuItem({
    this.text,
    this.icon,
    this.onTap,
    this.subItems,
    this.enabled = true,
  }) : assert(
          text != null && (onTap != null || subItems != null),
          '必须提供 text 和 onTap 或 subItems 中的一个',
        );

  bool get hasSubMenu => subItems != null && subItems!.isNotEmpty;
}

/// 菜单分隔线
class MyMenuDivider extends MyMenuElement {
  final double height;
  final Color color;
  final EdgeInsets margin;
  final double thicknessMultiplier;

  MyMenuDivider({
    this.height = 1.0,
    this.color = const Color(0x1F000000),
    this.margin = const EdgeInsets.symmetric(horizontal: 8.0),
    this.thicknessMultiplier = 0.7,
  });

  Widget build(BuildContext context) {
    // 转换 margin 为 screenutil 适配后的值
    final adaptiveMargin = EdgeInsets.only(
      left: margin.left.w,
      right: margin.right.w,
      top: margin.top.h,
      bottom: margin.bottom.h,
    );
    return Padding(
      padding: adaptiveMargin,
      child: Container(
        height: (height * thicknessMultiplier).h,
        color: color,
      ),
    );
  }
}

/// 菜单弹出动画样式
enum MyMenuPopStyle {
  scale,
  fade,
  slideFromTop,
  slideFromRight,
}
