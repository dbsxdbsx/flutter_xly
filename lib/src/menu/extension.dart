import 'package:flutter/material.dart';
import 'package:xly/src/menu/widget.dart';

import 'style.dart';

extension RightClickMenuExtension on Widget {
  Widget showRightMenu({
    required BuildContext context,
    required List<MyMenuElement> menuElements,
    MyMenuPopStyle animationStyle = MyMenuPopStyle.scale,
    MyMenuStyle style = const MyMenuStyle(),
  }) {
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
