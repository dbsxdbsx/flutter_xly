import 'package:flutter/material.dart';
import 'base_toast_widget.dart';

class ErrorToastWidget extends BaseToastWidget {
  const ErrorToastWidget({
    super.key,
    required super.message,
    super.textStyle,
    super.backgroundColor,
    super.radius,
    super.padding,
  }) : super(
          icon: Icons.error_outline,
          iconColor: Colors.red,
        );
}
