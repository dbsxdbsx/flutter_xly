import 'package:flutter/material.dart' hide BoxDecoration, BoxShadow;
import 'package:flutter_inset_box_shadow/flutter_inset_box_shadow.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'lib.dart';

class MyMenuButton extends StatefulWidget {
  final IconData icon;
  final double iconSize;
  final Color iconColor;
  final List<MyMenuItem> menuItems;
  final MyMenuStyle menuStyle;
  final Color shadowColor1;
  final Color shadowColor2;
  final double containerSizeRatio;
  final double radiusRatio;
  final bool? isPressed;

  const MyMenuButton({
    super.key,
    this.icon = Icons.menu,
    this.iconSize = 24,
    this.iconColor = Colors.black87,
    required this.menuItems,
    this.menuStyle = const MyMenuStyle(),
    this.shadowColor1 = const Color(0xff494d52),
    this.shadowColor2 = const Color(0xff090d12),
    this.containerSizeRatio = 1.39,
    this.radiusRatio = 0.26,
    this.isPressed,
  });

  @override
  _MyMenuButtonState createState() => _MyMenuButtonState();
}

class _MyMenuButtonState extends State<MyMenuButton> {
  double _distance = 0.0;
  double _blur = 0.0;
  bool _isDeepPressed = false;
  bool _isMenuOpen = false;

  @override
  Widget build(BuildContext context) {
    // 计算自定义缩放因子
    final double scaleFactor = 0.8 + (1.w / ScreenUtil().screenWidth) * 0.2;

    // 使用自定义缩放因子来计算尺寸
    final double containerSize =
        widget.containerSizeRatio * widget.iconSize * scaleFactor;
    final double radius = widget.radiusRatio * widget.iconSize; // 保持固定值
    final double iconSize = widget.iconSize * scaleFactor;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isDeepPressed = true),
      onTapUp: (TapUpDetails details) async {
        setState(() {
          _isDeepPressed = false;
          _isMenuOpen = true;
        });
        await _showMenu(context, details.globalPosition);
      },
      onTapCancel: () => setState(() {
        _isDeepPressed = false;
        _isMenuOpen = false;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: containerSize,
        height: containerSize,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.white70],
          ),
          boxShadow: _getBoxShadows(containerSize),
        ),
        child: Icon(
          widget.icon,
          size: iconSize,
          color: widget.iconColor,
        ),
      ),
    );
  }

  List<BoxShadow> _getBoxShadows(double containerSize) {
    bool isActivated = widget.isPressed ?? false;
    if (_isDeepPressed) {
      _distance = 0.18 * containerSize;
      _blur = 2.0;
    } else if (_isMenuOpen || isActivated) {
      _distance = 0.14 * containerSize;
      _blur = 4.0;
    } else {
      _distance = 0.11 * containerSize;
      _blur = 6.0;
    }

    return [
      BoxShadow(
        color: widget.shadowColor1,
        offset: Offset(-_distance * 0.3, -_distance * 0.15),
        blurRadius: _blur,
        spreadRadius: 0.0,
        inset: _isDeepPressed || _isMenuOpen || isActivated,
      ),
      BoxShadow(
        color: widget.shadowColor2,
        offset: Offset(_distance, _distance),
        blurRadius: _blur,
        spreadRadius: 0.0,
        inset: _isDeepPressed || _isMenuOpen || isActivated,
      ),
    ];
  }

  Future<void> _showMenu(BuildContext context, Offset position) async {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect positionRect = RelativeRect.fromRect(
      Rect.fromPoints(position, position),
      Offset.zero & overlay.size,
    );

    try {
      await MyMenu.show(
        context,
        position,
        widget.menuItems,
        animationStyle: MyMenuPopStyle.scale,
        style: widget.menuStyle,
      );
    } finally {
      // 菜单关闭后恢复按钮原始状态
      if (mounted) {
        setState(() {
          _isMenuOpen = false;
        });
      }
    }
  }
}
