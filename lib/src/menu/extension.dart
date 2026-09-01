import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'menu_models.dart';
import 'style.dart';
import 'widget.dart';

extension RightClickMenuExtension on Widget {
  Widget showRightMenu({
    required BuildContext context,
    required List<MyMenuElement> menuElements,
    MyMenuPopStyle animationStyle = MyMenuPopStyle.reveal,
    MyMenuStyle? style,
  }) {
    // 必须用 Listener，不能用 GestureDetector(onSecondaryTapDown)。
    // Flutter 只要存在 TapGestureRecognizer，就会给
    // RenderSemanticsGestureHandler.onTap 填上非空回调；整页右键热区
    // 会被桌面双击分类误判成 interactive，空白处无法最大化。
    return Listener(
      onPointerDown: (event) {
        if (event.buttons != kSecondaryMouseButton) return;
        MyMenu.show(
          context,
          event.position,
          menuElements,
          animationStyle: animationStyle,
          style: style,
        );
      },
      child: this,
    );
  }
}
