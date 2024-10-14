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
  late final double _containerSize;
  late final double _radius;

  @override
  void initState() {
    super.initState();
    _containerSize = widget.containerSizeRatio.sp * widget.iconSize;
    _radius = widget.radiusRatio.sp * _containerSize;
  }

  @override
  Widget build(BuildContext context) {
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
        width: _containerSize,
        height: _containerSize,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_radius),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.white70],
          ),
          boxShadow: _getBoxShadows(),
        ),
        child: Icon(
          widget.icon,
          size: widget.iconSize,
          color: widget.iconColor,
        ),
      ),
    );
  }

  List<BoxShadow> _getBoxShadows() {
    bool isActivated = widget.isPressed ?? false;
    if (_isDeepPressed) {
      _distance = 0.18.sp * _containerSize;
      _blur = 2.0;
    } else if (_isMenuOpen || isActivated) {
      _distance = 0.14.sp * _containerSize;
      _blur = 4.0;
    } else {
      _distance = 0.11.sp * _containerSize;
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
