import 'package:flutter/material.dart';

import 'base_toast_widget.dart';

class InfoToastWidget extends BaseToastWidget {
  const InfoToastWidget({
    super.key,
    required super.message,
    super.textStyle,
    super.backgroundColor,
  }) : super(
          icon: Icons.info_outline,
          iconColor: Colors.blue,
        );
}
