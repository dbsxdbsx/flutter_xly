import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 按钮形状枚举
enum MyButtonShape {
  normal,
  cube,
  round,
}

/// 图标位置枚举
enum MyIconPosition {
  left,
  right,
  top,
  bottom,
}

/// 一个灵活的按钮小部件，支持多种形状样式和图标位置
class MyButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;
  final MyButtonShape shape;
  final MyIconPosition? iconPosition;
  final double size;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color outlineColor;
  final double outlineWidth;
  final LinearGradient? gradient;
  final double elevation;
  final double cornerRadius;

  const MyButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.shape = MyButtonShape.normal,
    this.iconPosition,
    this.size = 45,
    this.backgroundColor = Colors.teal,
    this.foregroundColor = Colors.white,
    this.outlineColor = Colors.transparent,
    this.outlineWidth = 0,
    this.gradient,
    this.elevation = 5,
    this.cornerRadius = 0.5, // 0.0 到 1.0 之间的值，表示圆角程度
  });

  @override
  Widget build(BuildContext context) {
    switch (shape) {
      case MyButtonShape.normal:
        return _buildNormalButton();
      case MyButtonShape.cube:
        return _buildCubeButton();
      case MyButtonShape.round:
        return _buildRoundButton();
    }
  }

  double get _effectiveCornerRadius {
    switch (shape) {
      case MyButtonShape.normal:
        return 12.r * cornerRadius;
      case MyButtonShape.cube:
        return 8.r * cornerRadius;
      case MyButtonShape.round:
        return size.w / 2;
    }
  }

  Widget _buildNormalButton() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(_effectiveCornerRadius),
        boxShadow: [
          if (elevation > 0)
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: elevation,
              offset: Offset(0, elevation / 2),
            ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          foregroundColor: foregroundColor,
          backgroundColor:
              gradient != null ? Colors.transparent : backgroundColor,
          elevation: 0, // 我们使用 BoxDecoration 来处理阴影
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_effectiveCornerRadius),
            side: BorderSide(
              color: outlineColor,
              width: outlineWidth,
            ),
          ),
        ),
        child: _buildButtonContent(isNormal: true),
      ),
    );
  }

  Widget _buildCubeButton() {
    return Container(
      width: size.w,
      height: size.w,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_effectiveCornerRadius),
        border: Border.all(
          color: outlineColor,
          width: outlineWidth,
        ),
        color: gradient == null ? backgroundColor : null,
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4.w,
            offset: Offset(2.w, 2.w),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(_effectiveCornerRadius),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(_effectiveCornerRadius),
          child: _buildButtonContent(isCube: true),
        ),
      ),
    );
  }

  Widget _buildRoundButton() {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        shape: CircleBorder(
          side: BorderSide(
            color: outlineColor,
            width: outlineWidth,
          ),
        ),
        padding: EdgeInsets.all(size.w / 4),
        elevation: elevation,
      ),
      child: _buildButtonContent(isCube: true),
    );
  }

  Widget _buildButtonContent({bool isCube = false, bool isNormal = false}) {
    Widget iconWidget = icon != null
        ? Icon(icon, color: foregroundColor, size: 20.w)
        : const SizedBox.shrink();
    Widget textWidget = Text(
      text,
      style: TextStyle(
        color: foregroundColor,
        fontSize: isCube ? 13.sp : 16.sp,
        fontWeight: FontWeight.bold,
      ),
      textAlign: TextAlign.center,
    );

    List<Widget> children = [];
    double spacing = isCube ? 2.w : 8.w;

    MyIconPosition effectiveIconPosition = iconPosition ??
        (shape == MyButtonShape.normal
            ? MyIconPosition.left
            : MyIconPosition.top);

    switch (effectiveIconPosition) {
      case MyIconPosition.left:
        children = [iconWidget, SizedBox(width: spacing), textWidget];
        break;
      case MyIconPosition.right:
        children = [textWidget, SizedBox(width: spacing), iconWidget];
        break;
      case MyIconPosition.top:
        children = [iconWidget, SizedBox(height: spacing), textWidget];
        break;
      case MyIconPosition.bottom:
        children = [textWidget, SizedBox(height: spacing), iconWidget];
        break;
    }

    return effectiveIconPosition == MyIconPosition.left ||
            effectiveIconPosition == MyIconPosition.right
        ? Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: children,
          )
        : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: children,
          );
  }
}
