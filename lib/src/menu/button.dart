import 'package:flutter/material.dart' hide BoxDecoration, BoxShadow;
import 'package:flutter_inset_shadow/flutter_inset_shadow.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'anchor.dart';
import 'menu_models.dart';
import 'style.dart';

class MyMenuButton extends StatefulWidget {
  final IconData icon;
  final double iconSize;
  final Color iconColor;
  final List<MyMenuElement> menuItems;
  final MyMenuStyle? menuStyle;
  final MyMenuPopStyle animationStyle;
  final double menuGap;

  /// 左上高光阴影颜色。
  final Color shadowColor1;

  /// 右下深度阴影颜色。
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
    this.menuStyle,
    this.animationStyle = MyMenuPopStyle.reveal,
    this.menuGap = 4,
    this.shadowColor1 = const Color(0x90494d52),
    this.shadowColor2 = const Color(0x78090d12),
    this.containerSizeRatio = 1.39,
    this.radiusRatio = 0.26,
    this.isPressed,
  });

  @override
  MyMenuButtonState createState() => MyMenuButtonState();
}

class MyMenuButtonState extends State<MyMenuButton> {
  double _distance = 0.0;
  double _blur = 0.0;
  bool _isDeepPressed = false;
  bool _isMenuOpen = false;

  bool get _isSunken =>
      _isDeepPressed || _isMenuOpen || (widget.isPressed ?? false);

  @override
  Widget build(BuildContext context) {
    final double iconSize = widget.iconSize.sp;
    final double containerSize = widget.containerSizeRatio * iconSize;
    final double radius = widget.radiusRatio * iconSize;

    return MyMenuAnchor(
      menuElements: widget.menuItems,
      animationStyle: widget.animationStyle,
      style: widget.menuStyle,
      gap: widget.menuGap,
      anchorOrigin: MyMenuAnchorOrigin.center,
      onOpenChanged: (isOpen) {
        if (mounted && _isMenuOpen != isOpen) {
          setState(() => _isMenuOpen = isOpen);
        }
      },
      builder: (_, showMenu) => GestureDetector(
        onTapDown: (_) => setState(() => _isDeepPressed = true),
        onTapUp: (_) {
          setState(() => _isDeepPressed = false);
          showMenu();
        },
        onTapCancel: () => setState(() => _isDeepPressed = false),
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
            boxShadow: _buildShadows(containerSize),
          ),
          child: Icon(
            widget.icon,
            size: iconSize,
            color: widget.iconColor,
          ),
        ),
      ),
    );
  }

  List<BoxShadow> _buildShadows(double containerSize) {
    if (_isDeepPressed) {
      _distance = 0.13 * containerSize;
      _blur = 3.r;
    } else if (_isSunken) {
      _distance = 0.10 * containerSize;
      _blur = 4.r;
    } else {
      _distance = 0.11 * containerSize;
      _blur = 6.r;
    }

    return [
      BoxShadow(
        color: widget.shadowColor1,
        offset: Offset(-_distance * 0.3, -_distance * 0.15),
        blurRadius: _blur,
        inset: _isSunken,
      ),
      BoxShadow(
        color: widget.shadowColor2,
        offset: Offset(_distance, _distance),
        blurRadius: _blur,
        inset: _isSunken,
      ),
    ];
  }
}
