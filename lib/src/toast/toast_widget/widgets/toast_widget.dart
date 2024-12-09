import 'package:flutter/material.dart';

class ToastWidget extends StatelessWidget {
  final String message;
  final TextStyle textStyle;
  final Color backgroundColor;
  final double radius;
  final EdgeInsetsGeometry padding;

  const ToastWidget({
    super.key,
    required this.message,
    required this.textStyle,
    required this.backgroundColor,
    required this.radius,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Text(
        message,
        style: textStyle,
        textAlign: TextAlign.center,
      ),
    );
  }
}
