import 'package:flutter/material.dart';
import 'base_toast_widget.dart';

class OkToastWidget extends BaseToastWidget {
  const OkToastWidget({
    super.key,
    required super.message,
    super.textStyle,
    super.backgroundColor,
    super.radius,
    super.padding,
  }) : super(
          icon: Icons.check_circle_outline,
          iconColor: Colors.green,
        );
}
