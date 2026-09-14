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

  /// 第二行说明文字，对应 ListTile.subtitle（勿把多行 Column 塞进 [child]/title）。
  final Widget? subtitle;

  /// 标题行下方的整行附件（告警、状态等）。
  ///
  /// 有此项时改用两行表格：底栏与 title 同栏，因而能伸到
  /// [trailing] 底下，又不钻到 [leading] 下面。
  /// [trailing] 仍只相对 title + subtitle 垂直居中。
  final Widget? below;

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
    this.subtitle,
    this.below,
  });

  /// 有 [below] 时不用 [ListTile]：标题与底栏必须落在同一栏，
  /// 才能在不猜 M2/M3 `minLeadingWidth` 的前提下左对齐、并伸到
  /// [trailing] 底下。
  Widget _buildTitledCardWithBelow(
    BuildContext context,
    EdgeInsets contentPadding,
  ) {
    final theme = Theme.of(context);
    final tileTheme = ListTileTheme.of(context);
    final density = visualDensity ?? VisualDensity.compact;
    final titleGap =
        (leadingAndBodySpacing ?? tileTheme.horizontalTitleGap ?? 16) +
            density.horizontal * 2;
    final minLeadingWidth =
        tileTheme.minLeadingWidth ?? (theme.useMaterial3 ? 24.0 : 40.0);
    final minVertical =
        tileTheme.minVerticalPadding ?? (theme.useMaterial3 ? 8.0 : 4.0);
    final verticalPad = (minVertical + density.vertical * 2).clamp(0.0, 24.0);

    return Padding(
      padding: EdgeInsets.only(
        left: contentPadding.left,
        right: contentPadding.right,
        top: contentPadding.top + verticalPad,
        bottom: contentPadding.bottom + verticalPad,
      ),
      child: Table(
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        columnWidths: const {
          0: IntrinsicColumnWidth(),
          1: FlexColumnWidth(),
        },
        children: [
          TableRow(
            children: [
              leading == null
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: EdgeInsets.only(right: titleGap),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minWidth: minLeadingWidth),
                        child: leading,
                      ),
                    ),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        child,
                        if (subtitle != null) subtitle!,
                      ],
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
            ],
          ),
          TableRow(
            children: [
              const SizedBox.shrink(),
              below!,
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveMargin = margin ?? defaultMargin(context);
    final contentPadding = padding ?? defaultPadding(context);
    Widget tileContent = below != null
        ? _buildTitledCardWithBelow(context, contentPadding)
        : ListTile(
            dense: true,
            visualDensity: visualDensity ?? VisualDensity.compact,
            horizontalTitleGap: leadingAndBodySpacing,
            contentPadding: contentPadding, // NOTE：必须有，否则card最右侧会有空白
            leading: leading,
            title: child,
            subtitle: subtitle,
            trailing: trailing,
          );

    if (height != null) {
      tileContent = SizedBox(height: height, child: tileContent);
    }

    Widget cardContent = Card(
      margin: effectiveMargin,
      elevation: cardElevation ?? 2.h,
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
        child: tileContent,
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
