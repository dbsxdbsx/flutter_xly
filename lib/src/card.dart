import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MyCard extends StatelessWidget {
  final String text;
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
  final Widget Function(BuildContext, Widget)? cardBuilder;
  final bool enableSwipeToDelete;
  final bool enableBtnToDelete;
  final VoidCallback? onDelete;
  final Widget? deleteBackground;
  final double? height;
  final double fontSize;

  const MyCard({
    super.key,
    required this.text,
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
    this.cardBuilder,
    this.enableSwipeToDelete = false,
    this.enableBtnToDelete = false,
    this.onDelete,
    this.deleteBackground,
    this.height,
    this.fontSize = 16, // 使用普通的 double 值
  });

  @override
  Widget build(BuildContext context) {
    Widget cardContent = Card(
      elevation: elevation,
      margin: margin,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius.r),
      ),
      color: backgroundColor,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(borderRadius.r),
        child: Container(
          height: height?.h, // 在这里应用 .h
          padding: padding,
          decoration: decoration,
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                SizedBox(width: 8.w),
              ],
              Expanded(
                child: Text(
                  text,
                  style: textStyle ??
                      TextStyle(
                        fontSize: fontSize.sp, // 在这里应用 .sp
                        color: textColor,
                      ),
                ),
              ),
              if (trailing != null) ...[
                SizedBox(width: 8.w),
                trailing!,
              ],
              if (enableBtnToDelete) ...[
                SizedBox(width: 8.w),
                IconButton(
                  icon: Icon(Icons.delete, size: 20.w),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (cardBuilder != null) {
      cardContent = cardBuilder!(context, cardContent);
    }

    if (enableSwipeToDelete) {
      cardContent = Dismissible(
        key: Key(text),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onDelete?.call(),
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
