import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MyCard extends StatelessWidget {
  final bool isDraggable;
  final VoidCallback? onPressed;
  final int? index;
  final Color? backgroundColor;
  final Color? textColor;
  final double elevation;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Widget? leading;
  final Widget? trailing;
  final TextStyle? textStyle;
  final BoxDecoration? decoration;
  final bool enableSwipeToDelete;
  final VoidCallback? onSwipeDeleted;
  final Widget? deleteBackground;
  final double? height;
  final Widget child;

  const MyCard({
    super.key,
    required this.child,
    this.isDraggable = false,
    this.onPressed,
    this.index,
    this.backgroundColor,
    this.textColor,
    this.elevation = 2,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 8,
    this.leading,
    this.trailing,
    this.textStyle,
    this.decoration,
    this.enableSwipeToDelete = false,
    this.onSwipeDeleted,
    this.deleteBackground,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    Widget cardContent = Material(
      color: backgroundColor ?? Colors.white,
      elevation: elevation,
      borderRadius: BorderRadius.circular(borderRadius.r),
      child: InkWell(
        onTap: onPressed,
        enableFeedback: true,
        highlightColor: Colors.black12,
        hoverColor: Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(borderRadius.r),
        child: Container(
          height: height?.h,
          padding: padding,
          decoration: decoration ?? BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius.r),
            border: Border.all(
              color: Colors.grey.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                SizedBox(width: 8.w),
              ],
              Expanded(child: child),
              if (trailing != null) ...[
                SizedBox(width: 8.w),
                trailing!,
              ],
            ],
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
      child: const Icon(Icons.delete, color: Colors.white),
    );
  }
}
