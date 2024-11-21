import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MyCard extends StatelessWidget {
  final int? index;
  final Widget? leading;
  final Widget child;
  final Widget? trailing;
  final VoidCallback? onPressed;
  final bool isDraggable;
  final bool enableSwipeToDelete;
  final VoidCallback? onSwipeDeleted;
  final double? height;
  final double? leadingAndBodySpacing;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? backgroundColor;
  final Color? hoverColor;
  final Color? splashColor;
  final Color? shadowColor;
  final double? elevation;
  final BorderRadius? borderRadius;
  final BoxDecoration? decoration;
  final Color? textColor;
  final TextStyle? textStyle;
  final Widget? deleteBackground;

  static EdgeInsets defaultPadding(BuildContext context) =>
      EdgeInsets.symmetric(horizontal: 4.w);
  static EdgeInsets defaultMargin(BuildContext context) => EdgeInsets.symmetric(
        horizontal: 6.w,
        vertical: 1.5.h,
      );

  const MyCard({
    super.key,
    this.index,
    this.leading,
    required this.child,
    this.trailing,
    this.onPressed,
    this.isDraggable = false,
    this.enableSwipeToDelete = false,
    this.onSwipeDeleted,
    this.height,
    this.leadingAndBodySpacing,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.hoverColor,
    this.splashColor,
    this.shadowColor,
    this.elevation,
    this.borderRadius,
    this.decoration,
    this.textColor,
    this.textStyle,
    this.deleteBackground,
  });

  @override
  Widget build(BuildContext context) {
    Widget cardContent = Card(
      margin: EdgeInsets.only(
        left: (margin ?? defaultMargin(context)).left.w,
        right: (margin ?? defaultMargin(context)).right.w,
        top: (margin ?? defaultMargin(context)).top.h,
        bottom: (margin ?? defaultMargin(context)).bottom.h,
      ),
      elevation: elevation?.h ?? 2.h,
      shadowColor: shadowColor,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(12.r),
      ),
      color: backgroundColor,
      child: InkWell(
        onTap: onPressed,
        enableFeedback: false,
        hoverColor: hoverColor,
        splashColor: splashColor,
        borderRadius: borderRadius ?? BorderRadius.circular(12.r),
        child: ListTile(
          dense: true,
          visualDensity: VisualDensity(horizontal: -4.w, vertical: -4.h),
          horizontalTitleGap: leadingAndBodySpacing?.w,
          // minLeadingWidth: 24.w,
          contentPadding:
              padding ?? defaultPadding(context), // NOTE：必须有，否则card最右侧会有空白
          leading: leading,
          title: child,
          trailing: trailing,
        ),
      ),
    );

    if (enableSwipeToDelete) {
      cardContent = Dismissible(
        key: Key(child.toString()),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onSwipeDeleted?.call(),
        background: deleteBackground ?? _defaultDeleteBackground(),
        child: cardContent,
      );
    }

    if (isDraggable) {
      return ReorderableDragStartListener(
        index: index!,
        child: cardContent,
      );
    }

    return cardContent;
  }

  Widget _defaultDeleteBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: EdgeInsets.only(right: 20.w),
      color: Colors.red,
      child: Icon(
        Icons.delete,
        color: Colors.white,
        size: 16.sp,
      ),
    );
  }
}
