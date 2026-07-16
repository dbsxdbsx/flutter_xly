import 'dart:async';

import 'package:flutter/material.dart';

import 'menu_models.dart';
import 'style.dart';
import 'widget.dart';

typedef MyMenuAnchorBuilder = Widget Function(
  BuildContext context,
  VoidCallback showMenu,
);

/// 将 xly 菜单挂接到任意现有控件，不接管控件自身的视觉样式。
///
/// 典型用法：
/// ```dart
/// MyMenuAnchor(
///   menuElements: items,
///   builder: (_, showMenu) => IconButton(
///     icon: const Icon(Icons.menu),
///     onPressed: showMenu,
///   ),
/// )
/// ```
///
/// 左键锚定菜单与 [RightClickMenuExtension] 最终均由 [MyMenu] 渲染；
/// 两者只在锚点来源（控件矩形 / 鼠标坐标）上不同。
class MyMenuAnchor extends StatefulWidget {
  final List<MyMenuElement> menuElements;
  final MyMenuAnchorBuilder builder;
  final MyMenuPopStyle animationStyle;
  final MyMenuStyle? style;

  /// 菜单成功开始显示及最终关闭时分别回调 `true` / `false`。
  final ValueChanged<bool>? onOpenChanged;

  /// 锚点与菜单之间的逻辑像素间距。
  ///
  /// 锚点矩形来自 RenderBox，已经处于逻辑坐标系，因此这里不再套 ScreenUtil。
  final double gap;

  /// 菜单相对于锚点的起始对齐策略。
  ///
  /// - [MyMenuAnchorOrigin.edge]（默认）：从锚点边缘弹出，适合宽按钮或工具栏。
  /// - [MyMenuAnchorOrigin.center]：从锚点中心象限引出，适合小图标按钮。
  final MyMenuAnchorOrigin anchorOrigin;

  const MyMenuAnchor({
    super.key,
    required this.menuElements,
    required this.builder,
    this.animationStyle = MyMenuPopStyle.reveal,
    this.style,
    this.gap = 4,
    this.onOpenChanged,
    this.anchorOrigin = MyMenuAnchorOrigin.edge,
  }) : assert(gap >= 0, 'gap 必须大于等于 0');

  @override
  State<MyMenuAnchor> createState() => _MyMenuAnchorState();
}

class _MyMenuAnchorState extends State<MyMenuAnchor> {
  final _anchorKey = GlobalKey();
  int _showRequest = 0;

  void _showMenu() {
    final request = ++_showRequest;
    unawaited(_showMenuAsync(request));
  }

  Future<void> _showMenuAsync(int request) async {
    final anchorContext = _anchorKey.currentContext;
    final box = anchorContext?.findRenderObject() as RenderBox?;
    if (anchorContext == null || box == null || !box.hasSize) return;

    final topLeft = box.localToGlobal(Offset.zero);
    final anchorRect = topLeft & box.size;
    widget.onOpenChanged?.call(true);
    try {
      await MyMenu.showAnchored(
        anchorContext,
        anchorRect,
        widget.menuElements,
        animationStyle: widget.animationStyle,
        style: widget.style,
        gap: widget.gap,
        anchorOrigin: widget.anchorOrigin,
      );
    } finally {
      if (mounted && request == _showRequest) {
        widget.onOpenChanged?.call(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: _anchorKey,
      child: widget.builder(context, _showMenu),
    );
  }
}
