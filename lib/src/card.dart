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
  final ShapeBorder? borderShape;
  final BoxDecoration? decoration;
  final Color? textColor;
  final TextStyle? textStyle;
  final Widget? deleteBackground;

  static EdgeInsets defaultPadding(BuildContext context) => EdgeInsets.all(0.w);
  static EdgeInsets defaultMargin(BuildContext context) => EdgeInsets.symmetric(
        vertical: 4.h,
        horizontal: 8.w,
      );

  static ShapeBorder defaultBorderShape(BuildContext context) =>
      RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12.r)),
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
    this.borderShape,
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
      shape: borderShape ?? defaultBorderShape(context),
      color: backgroundColor,
      child: Padding(
        padding: padding ?? defaultPadding(context),
        child: InkWell(
          onTap: onPressed,
          enableFeedback: false,
          hoverColor: hoverColor,
          splashColor: splashColor,
          borderRadius: (borderShape ?? defaultBorderShape(context))
                  is RoundedRectangleBorder
              ? ((borderShape ?? defaultBorderShape(context))
                      as RoundedRectangleBorder)
                  .borderRadius as BorderRadius
              : null,
          child: ListTile(
            dense: true,
            visualDensity: VisualDensity(horizontal: -4.w, vertical: -4.h),
            horizontalTitleGap: leadingAndBodySpacing?.w,
            leading: leading,
            title: child,
            trailing: trailing,
          ),
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
