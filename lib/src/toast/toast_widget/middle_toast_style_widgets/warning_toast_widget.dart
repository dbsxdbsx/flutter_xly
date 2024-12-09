import 'package:flutter/material.dart';
import 'base_toast_widget.dart';

class WarningToastWidget extends BaseToastWidget {
  const WarningToastWidget({
    super.key,
    required super.message,
    super.textStyle,
    super.backgroundColor,
    super.radius,
    super.padding,
  }) : super(
          icon: Icons.warning_amber_rounded,
          iconColor: Colors.amber,
        );
}
