import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MyCard extends StatelessWidget {
  final Widget? leading;
  final Widget child;
  final Widget? trailing;
  final double? height;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? textColor;
  final double? elevation;
  final Color? shadowColor;
  final BoxDecoration? decoration;
  final TextStyle? textStyle;
  final bool isDraggable;
  final bool enableSwipeToDelete;
  final int? index;
  final VoidCallback? onPressed;
  final VoidCallback? onSwipeDeleted;
  final Widget? deleteBackground;
  final double? leadingAndBodySpacing;
  final double? contentPadding;

  static const EdgeInsets defaultPadding = EdgeInsets.all(4);
  static const EdgeInsets defaultMargin = EdgeInsets.symmetric(
    vertical: 4,
    horizontal: 8,
  );

  const MyCard({
    super.key,
    this.leading,
    required this.child,
    this.trailing,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = 12,
    this.backgroundColor,
    this.textColor,
    this.elevation,
    this.shadowColor,
    this.decoration,
    this.textStyle,
    this.isDraggable = false,
    this.enableSwipeToDelete = false,
    this.index,
    this.onPressed,
    this.onSwipeDeleted,
    this.deleteBackground,
    this.leadingAndBodySpacing = 16,
    this.contentPadding = 16,
  });

  @override
  Widget build(BuildContext context) {
    Widget cardContent = Material(
      color: backgroundColor ?? const Color(0xFFF7F2FA),
      elevation: elevation?.h ?? 2.h,
      shadowColor: shadowColor ?? Colors.grey.withOpacity(0.2),
      borderRadius: BorderRadius.circular(borderRadius.r),
      child: InkWell(
        onTap: onPressed,
        enableFeedback: true,
        highlightColor: Colors.black12,
        hoverColor: Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(borderRadius.r),
        child: ListTile(
          dense: true,
          visualDensity: VisualDensity(horizontal: -4.w, vertical: -4.h),
          minVerticalPadding: 0,
          horizontalTitleGap: leadingAndBodySpacing?.w,
          contentPadding: EdgeInsets.symmetric(
            horizontal: (padding ?? defaultPadding).left.w,
            vertical: (padding ?? defaultPadding).top.h,
          ),
          leading: leading,
          title: child,
          trailing: trailing,
        ),
      ),
    );

    cardContent = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: (margin ?? defaultMargin).left.w,
        vertical: (margin ?? defaultMargin).top.h,
      ),
      child: cardContent,
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
        child: SizedBox(
          width: double.infinity,
          child: cardContent,
        ),
      );
    } else {
      return cardContent;
    }
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
