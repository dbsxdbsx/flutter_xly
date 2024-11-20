import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MyCard extends StatelessWidget {
  final Widget? leading;
  final Widget child;
  final Widget? trailing;
  final double? height;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? textColor;
  final double elevation;
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

  const MyCard({
    super.key,
    this.leading,
    required this.child,
    this.trailing,
    this.height,
    this.padding = const EdgeInsets.all(4),
    this.margin = const EdgeInsets.symmetric(
      vertical: 1.5,
      horizontal: 2,
    ),
    this.borderRadius = 4,
    this.backgroundColor,
    this.textColor,
    this.elevation = 2,
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
      color: backgroundColor ?? Colors.white,
      elevation: elevation.h,
      borderRadius: BorderRadius.circular(borderRadius.r),
      child: InkWell(
        onTap: onPressed,
        enableFeedback: true,
        highlightColor: Colors.black12,
        hoverColor: Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(borderRadius.r),
        child: Container(
          height: height?.h,
          decoration: decoration ??
              BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius.r),
                border: Border.all(
                  color: Colors.grey.withOpacity(0.2),
                  width: 1.w,
                ),
              ),
          child: ListTile(
            dense: true,
            visualDensity: const VisualDensity(horizontal: -4, vertical: -2),
            minVerticalPadding: 0,
            horizontalTitleGap: leadingAndBodySpacing?.w,
            contentPadding: padding is EdgeInsets
                ? EdgeInsets.symmetric(
                    horizontal: (padding as EdgeInsets).left.w,
                    vertical: (padding as EdgeInsets).top.h,
                  )
                : EdgeInsets.symmetric(horizontal: contentPadding!.w),
            leading: leading,
            trailing: trailing,
            title: child,
          ),
        ),
      ),
    );

    cardContent = Padding(
      padding: margin,
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
