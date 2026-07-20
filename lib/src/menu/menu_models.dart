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

/// 菜单分隔线。
///
/// [height] 与 [margin] 均返回当前逻辑像素；显式传入值会直接使用，
/// 省略时才由组件把内置设计默认值换算一次。
class MyMenuDivider extends MyMenuElement {
  final double? _height;
  final Color color;
  final EdgeInsets? _margin;
  final double thicknessMultiplier;

  MyMenuDivider({
    double? height,
    this.color = const Color(0x1F000000),
    EdgeInsets? margin,
    this.thicknessMultiplier = 0.7,
  })  : _height = height,
        _margin = margin;

  /// 分隔线基准高度，单位为当前逻辑像素。
  double get height => _height ?? 1.h;

  /// 分隔线外边距，单位为当前逻辑像素。
  EdgeInsets get margin => _margin ?? EdgeInsets.symmetric(horizontal: 8.w);

  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: Container(
        height: height * thicknessMultiplier,
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
