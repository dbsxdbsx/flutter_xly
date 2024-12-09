import 'package:flutter/material.dart';

class LoadingWidget extends StatelessWidget {
  final String? message;
  final Color? spinnerColor;
  final Color? backgroundColor;
  final double? spinnerSize;
  final TextStyle? textStyle;

  const LoadingWidget({
    super.key,
    this.message,
    this.spinnerColor,
    this.backgroundColor,
    this.spinnerSize,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.black54,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: spinnerSize ?? 40,
            height: spinnerSize ?? 40,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                spinnerColor ?? Colors.white,
              ),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 8),
            Text(
              message!,
              style: textStyle ??
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
