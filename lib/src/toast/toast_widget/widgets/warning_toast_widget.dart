import 'package:flutter/material.dart';

class WarningToastWidget extends StatelessWidget {
  final String message;
  final TextStyle? textStyle;
  final Color? backgroundColor;
  final double radius;
  final EdgeInsetsGeometry padding;

  const WarningToastWidget({
    super.key,
    required this.message,
    this.textStyle,
    this.backgroundColor,
    this.radius = 20.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.black87.withOpacity(0.7),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.warning_amber_rounded, // 使用警告图标
            color: Colors.amber, // 使用黄色
            size: 28.0,
          ),
          const SizedBox(height: 8.0),
          Text(
            message,
            style: textStyle?.copyWith(color: Colors.white) ??
                const TextStyle(
                  fontSize: 16.0,
                  color: Colors.white,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
