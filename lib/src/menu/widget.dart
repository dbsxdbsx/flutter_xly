import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'style.dart';

// 1. 枚举和常量定义
enum MyMenuPopStyle { scale, fade, slideFromTop, slideFromRight }

// 2. 核心类定义
class MyMenu {
  static OverlayEntry? _overlayEntry;
  static Completer<void>? _menuCompleter;

  static Future<void> show(
    BuildContext context,
    Offset position,
    List<MyMenuItem> menuItems, {
    MyMenuPopStyle animationStyle = MyMenuPopStyle.scale,
    MyMenuStyle style = const MyMenuStyle(),
  }) async {
    _closeMenu();
    _menuCompleter = Completer<void>();

    final menuSize = _calculateMenuSize(menuItems, style);
    final adjustedPosition = _adjustMenuPosition(
      Overlay.of(context).context.findRenderObject()! as RenderBox,
      menuSize,
      position,
    );

    _overlayEntry = OverlayEntry(
      builder: (context) => _buildMenuOverlay(
        context,
        adjustedPosition,
        menuItems,
        animationStyle,
        style,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _addRouteListener(context);

    return _menuCompleter!.future;
  }

  static Widget _buildMenuOverlay(
    BuildContext context,
    Offset position,
    List<MyMenuItem> menuItems,
    MyMenuPopStyle animationStyle,
    MyMenuStyle style,
  ) {
    return _MenuOverlay(
      position: position,
      menuItems: menuItems,
      animationStyle: animationStyle,
      style: style,
    );
  }

  static Size _calculateMenuSize(
      List<MyMenuItem> menuItems, MyMenuStyle style) {
    double maxWidth = menuItems.fold(0.0, (maxWidth, item) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: item.text,
          style: TextStyle(fontSize: style.fontSize.sp),
        ),
        maxLines: 1,
        textDirection: TextDirection.ltr,
      )..layout(minWidth: 0, maxWidth: double.infinity);
      return max(maxWidth, textPainter.width + style.iconPadding.w);
    });

    return Size(maxWidth, style.itemHeight.h * menuItems.length);
  }

  static Offset _adjustMenuPosition(
      RenderBox overlay, Size menuSize, Offset clickPosition) {
    final screenSize = overlay.size;
    return Offset(
      clickPosition.dx + menuSize.width > screenSize.width
          ? clickPosition.dx - menuSize.width
          : clickPosition.dx,
      clickPosition.dy + menuSize.height > screenSize.height
          ? clickPosition.dy - menuSize.height
          : clickPosition.dy,
    );
  }

  static void _addRouteListener(BuildContext context) {
    ModalRoute.of(context)?.addScopedWillPopCallback(() async {
      _closeMenu();
      return false;
    });
  }

  static void _closeMenu() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _menuCompleter?.complete();
    _menuCompleter = null;
  }
}

// 3. 辅助类和组件
class _MenuOverlay extends StatelessWidget {
  final Offset position;
  final List<MyMenuItem> menuItems;
  final MyMenuPopStyle animationStyle;
  final MyMenuStyle style;

  const _MenuOverlay({
    Key? key,
    required this.position,
    required this.menuItems,
    required this.animationStyle,
    required this.style,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: MyMenu._closeMenu,
      child: Stack(
        children: [
          Positioned(
            left: position.dx,
            top: position.dy,
            child: GestureDetector(
              onTap: () {}, // 防止点击菜单时关闭
              child: _AnimatedMenuWidget(
                animationStyle: animationStyle,
                child: Material(
                  color: Colors.transparent,
                  child: _MyMenuWidget(
                    menuItems: menuItems,
                    onItemSelected: (index) {
                      MyMenu._closeMenu();
                      if (index >= 0 && index < menuItems.length) {
                        Future.microtask(() => menuItems[index].onTap());
                      }
                    },
                    style: style,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedMenuWidget extends StatefulWidget {
  final Widget child;
  final MyMenuPopStyle animationStyle;

  const _AnimatedMenuWidget({
    Key? key,
    required this.child,
    this.animationStyle = MyMenuPopStyle.scale,
  }) : super(key: key);

  @override
  _AnimatedMenuWidgetState createState() => _AnimatedMenuWidgetState();
}

class _AnimatedMenuWidgetState extends State<_AnimatedMenuWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _animation = _createAnimation();
    _controller.forward();
  }

  Animation<double> _createAnimation() {
    switch (widget.animationStyle) {
      case MyMenuPopStyle.scale:
        return Tween<double>(begin: 0.8, end: 1.0).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
        );
      case MyMenuPopStyle.fade:
        return Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeOut),
        );
      case MyMenuPopStyle.slideFromTop:
      case MyMenuPopStyle.slideFromRight:
        return Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
        );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildAnimatedWidget();
  }

  Widget _buildAnimatedWidget() {
    switch (widget.animationStyle) {
      case MyMenuPopStyle.scale:
        return ScaleTransition(scale: _animation, child: widget.child);
      case MyMenuPopStyle.fade:
        return FadeTransition(opacity: _animation, child: widget.child);
      case MyMenuPopStyle.slideFromTop:
        return SlideTransition(
          position:
              Tween<Offset>(begin: const Offset(0, -0.1), end: Offset.zero)
                  .animate(_animation),
          child: widget.child,
        );
      case MyMenuPopStyle.slideFromRight:
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(0.1, 0), end: Offset.zero)
              .animate(_animation),
          child: widget.child,
        );
    }
  }
}

class _MyMenuWidget extends StatelessWidget {
  final List<MyMenuItem> menuItems;
  final Function(int) onItemSelected;
  final MyMenuStyle style;

  const _MyMenuWidget({
    required this.menuItems,
    required this.onItemSelected,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(style.borderRadius.sp),
      child: BackdropFilter(
        filter: ImageFilter.blur(
            sigmaX: style.blurSigma.sp, sigmaY: style.blurSigma.sp),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(style.borderRadius.sp),
            border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: style.borderWidth.w),
          ),
          child: IntrinsicWidth(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: menuItems.asMap().entries.map((entry) {
                return _buildMenuItem(entry.key, entry.value);
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(int index, MyMenuItem item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onItemSelected(index),
        highlightColor: style.focusColor.withOpacity(0.1),
        splashColor: style.focusColor.withOpacity(0.05),
        hoverColor: style.focusColor.withOpacity(0.05),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 10.w, horizontal: 16.w),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, color: Colors.black87, size: 18.sp),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  item.text,
                  style: TextStyle(
                      color: Colors.black87, fontSize: style.fontSize.sp),
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 4. 公共类和扩展
class MyMenuItem {
  final String text;
  final IconData icon;
  final VoidCallback onTap;

  MyMenuItem({required this.text, required this.icon, required this.onTap});
}
