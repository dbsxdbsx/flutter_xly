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
  final Color? cardColor;
  final Color? cardHoverColor;
  final Color? cardSplashColor;
  final Color? cardShadowColor;
  final double? cardElevation;
  final BorderRadius? cardBorderRadius;
  final BoxDecoration? decoration;
  final Color? textColor;
  final TextStyle? textStyle;
  final Widget? deleteBackground;
  final VisualDensity? visualDensity;

  static EdgeInsets defaultPadding(BuildContext context) =>
      EdgeInsets.symmetric(horizontal: 4.w);
  /// 默认 margin，返回的值已经是转换后的 screenutil 值
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
    this.cardColor,
    this.cardHoverColor,
    this.cardSplashColor,
    this.cardShadowColor,
    this.cardElevation,
    this.cardBorderRadius,
    this.decoration,
    this.textColor,
    this.textStyle,
    this.deleteBackground,
    this.visualDensity,
  });

  @override
  Widget build(BuildContext context) {
    // 用户传入的 margin 需要转换，defaultMargin 已经转换过
    final effectiveMargin = margin != null
        ? EdgeInsets.only(
            left: margin!.left.w,
            right: margin!.right.w,
            top: margin!.top.h,
            bottom: margin!.bottom.h,
          )
        : defaultMargin(context);
    Widget cardContent = Card(
      margin: effectiveMargin,
      elevation: cardElevation?.h ?? 2.h,
      shadowColor: cardShadowColor,
      shape: RoundedRectangleBorder(
        borderRadius: cardBorderRadius ?? BorderRadius.circular(12.r),
      ),
      color: cardColor,
      child: InkWell(
        onTap: onPressed,
        enableFeedback: false,
        hoverColor: cardHoverColor,
        splashColor: cardSplashColor,
        borderRadius: cardBorderRadius ?? BorderRadius.circular(12.r),
        child: ListTile(
          dense: true,
          visualDensity: visualDensity ?? VisualDensity.compact,
          horizontalTitleGap: leadingAndBodySpacing?.w,
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
