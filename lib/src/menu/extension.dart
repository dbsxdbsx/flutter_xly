import 'package:flutter/material.dart';

import 'menu_models.dart';
import 'style.dart';
import 'widget.dart';

extension RightClickMenuExtension on Widget {
  Widget showRightMenu({
    required BuildContext context,
    required List<MyMenuElement> menuElements,
    MyMenuPopStyle animationStyle = MyMenuPopStyle.scale,
    MyMenuStyle? style,
  }) {
    style ??= MyMenuStyle();
    return GestureDetector(
      onSecondaryTapDown: (TapDownDetails details) {
        MyMenu.show(
          context,
          details.globalPosition,
          menuElements,
          animationStyle: animationStyle,
          style: style,
        );
      },
      child: this,
    );
  }
}
