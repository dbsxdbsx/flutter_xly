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

/// 锚定菜单的起始对齐策略。
enum MyMenuAnchorOrigin {
  /// 菜单从锚点控件的对应边缘弹出（传统下拉）。
  ///
  /// 适合宽按钮、工具栏或 AppBar 操作。
  edge,

  /// 菜单从锚点控件的中心象限引出（田字格模式）。
  ///
  /// 菜单的起始角与锚点中心对齐，朝展开方向生长，
  /// 适合小尺寸图标按钮，视觉上有明确的方向性和起源感。
  center,
}

/// 菜单弹出动画样式
enum MyMenuPopStyle {
  scale,
  fade,
  slideFromTop,
  slideFromRight,

  /// 从靠近触发源的边角向最终放置方向裁剪展开。
  reveal,
}
