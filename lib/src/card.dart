import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MyCard extends StatelessWidget {
  final int? index;
  final Widget? leading;
  final Widget child;
  final Widget? trailing;
  final double? height;
  final double? leadingAndBodySpacing;
  final double? contentPadding;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? backgroundColor;
  final Color? textColor;
  final double? elevation;
  final Color? shadowColor;
  final ShapeBorder shape;
  final BoxDecoration? decoration;
  final TextStyle? textStyle;
  final bool isDraggable;
  final bool enableSwipeToDelete;
  final VoidCallback? onPressed;
  final VoidCallback? onSwipeDeleted;
  final Widget? deleteBackground;

  static const EdgeInsets defaultPadding = EdgeInsets.all(4);
  static const EdgeInsets defaultMargin = EdgeInsets.symmetric(
    vertical: 4,
    horizontal: 8,
  );

  const MyCard({
    super.key,
    this.index,
    this.leading,
    required this.child,
    this.trailing,
    this.height,
    this.leadingAndBodySpacing = 16,
    this.contentPadding = 16,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.textColor,
    this.elevation,
    this.shadowColor,
    this.shape = const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
    this.decoration,
    this.textStyle,
    this.isDraggable = false,
    this.enableSwipeToDelete = false,
    this.onPressed,
    this.onSwipeDeleted,
    this.deleteBackground,
  });

  static ShapeBorder defaultShape(BuildContext context) {
    return RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12.r),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget cardContent = Card(
      margin: EdgeInsets.only(
        left: (margin ?? defaultMargin).left.w,
        right: (margin ?? defaultMargin).right.w,
        top: (margin ?? defaultMargin).top.h,
        bottom: (margin ?? defaultMargin).bottom.h,
      ),
      elevation: elevation?.h ?? 2.h,
      shadowColor: shadowColor,
      shape: shape,
      color: backgroundColor,
      child: InkWell(
        onTap: onPressed,
        enableFeedback: false,
        hoverColor: Colors.transparent,
        borderRadius: shape is RoundedRectangleBorder
            ? (shape as RoundedRectangleBorder).borderRadius as BorderRadius
            : null,
        child: ListTile(
          dense: true,
          visualDensity: VisualDensity(horizontal: -4.w, vertical: -4.h),
          horizontalTitleGap: leadingAndBodySpacing?.w,
          contentPadding: EdgeInsets.only(
            left: (padding ?? defaultPadding).left.w,
            right: (padding ?? defaultPadding).right.w,
            top: (padding ?? defaultPadding).top.h,
            bottom: (padding ?? defaultPadding).bottom.h,
          ),
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
