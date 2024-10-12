import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MyMenu {
  static OverlayEntry? _overlayEntry;

  static void show(
    BuildContext context,
    Offset position,
    List<MyMenuItem> menuItems, {
    MyMenuPopStyle animationStyle = MyMenuPopStyle.scale,
    double fontSize = 15,
    double iconPadding = 90,
    double itemHeight = 50,
    double borderRadius = 13,
    double blurSigma = 10,
    double borderWidth = 1,
    Color focusColor = const Color(0xFF007AFF),
  }) {
    _closeMenu();

    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final screenSize = overlay.size;

    double maxWidth = 0;
    for (var item in menuItems) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: item.text,
          style: TextStyle(fontSize: fontSize.sp),
        ),
        maxLines: 1,
        textDirection: TextDirection.ltr,
      )..layout(minWidth: 0, maxWidth: double.infinity);
      maxWidth = max(maxWidth, textPainter.width + iconPadding.w);
    }

    final menuHeight = itemHeight.h * menuItems.length;
    final menuSize = Size(maxWidth, menuHeight);

    final adjustedPosition =
        _adjustMenuPosition(screenSize, menuSize, position);

    _overlayEntry = OverlayEntry(
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _closeMenu,
        child: Stack(
          children: [
            Positioned(
              left: adjustedPosition.dx,
              top: adjustedPosition.dy,
              child: GestureDetector(
                onTap: () {}, // 防止点击菜单时关闭
                child: _AnimatedMenuWidget(
                  animationStyle: animationStyle,
                  child: Material(
                    color: Colors.transparent,
                    child: _MyMenuWidget(
                      menuItems: menuItems,
                      onItemSelected: (index) {
                        _closeMenu();
                        if (index >= 0 && index < menuItems.length) {
                          Future.microtask(() => menuItems[index].onTap());
                        }
                      },
                      fontSize: fontSize,
                      borderRadius: borderRadius,
                      blurSigma: blurSigma,
                      borderWidth: borderWidth,
                      focusColor: focusColor,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);

    // 添加路由监听，当路由变化时关闭菜单
    ModalRoute.of(context)?.addScopedWillPopCallback(() async {
      _closeMenu();
      return false;
    });
  }

  static Offset _adjustMenuPosition(
      Size screenSize, Size menuSize, Offset clickPosition) {
    double adjustedX = clickPosition.dx;
    double adjustedY = clickPosition.dy;

    // 如果菜单右侧超出屏幕右边缘, 则翻转X
    if (clickPosition.dx + menuSize.width > screenSize.width) {
      adjustedX = clickPosition.dx - menuSize.width;
    }

    // 如果菜单底部超出屏幕底部, 则翻转Y
    if (clickPosition.dy + menuSize.height > screenSize.height) {
      adjustedY = clickPosition.dy - menuSize.height;
    }

    return Offset(adjustedX, adjustedY);
  }

  static void showRight(
    BuildContext context,
    List<MyMenuItem> menuItems, {
    required Offset position,
    MyMenuPopStyle animationStyle = MyMenuPopStyle.scale,
    double fontSize = 15,
    double iconPadding = 90,
    double itemHeight = 50,
    double borderRadius = 13,
    double blurSigma = 10,
    double borderWidth = 1,
    Color focusColor = const Color(0xFF007AFF),
  }) {
    show(
      context,
      position,
      menuItems,
      animationStyle: animationStyle,
      fontSize: fontSize,
      iconPadding: iconPadding,
      itemHeight: itemHeight,
      borderRadius: borderRadius,
      blurSigma: blurSigma,
      borderWidth: borderWidth,
      focusColor: focusColor,
    );
  }

  static void _closeMenu() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}

// 定义动画样式枚举
enum MyMenuPopStyle {
  scale,
  fade,
  slideFromTop,
  slideFromRight,
  // 可以根据需要添加更多样式
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

    switch (widget.animationStyle) {
      case MyMenuPopStyle.scale:
        _animation = Tween<double>(begin: 0.8, end: 1.0).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
        );
        break;
      case MyMenuPopStyle.fade:
        _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeOut),
        );
        break;
      case MyMenuPopStyle.slideFromTop:
      case MyMenuPopStyle.slideFromRight:
        _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
        );
        break;
    }

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.animationStyle) {
      case MyMenuPopStyle.scale:
        return ScaleTransition(
          scale: _animation as Animation<double>,
          child: widget.child,
        );
      case MyMenuPopStyle.fade:
        return FadeTransition(
          opacity: _animation as Animation<double>,
          child: widget.child,
        );
      case MyMenuPopStyle.slideFromTop:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.1),
            end: Offset.zero,
          ).animate(_animation as Animation<double>),
          child: widget.child,
        );
      case MyMenuPopStyle.slideFromRight:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.1, 0),
            end: Offset.zero,
          ).animate(_animation as Animation<double>),
          child: widget.child,
        );
    }
  }
}

extension RightClickMenuExtension on Widget {
  Widget showRightMenu({
    required BuildContext context,
    required List<MyMenuItem> menuItems,
    MyMenuPopStyle animationStyle = MyMenuPopStyle.scale,
    double fontSize = 15,
    double iconPadding = 90,
    double itemHeight = 50,
    double borderRadius = 13,
    double blurSigma = 10,
    double borderWidth = 1,
    Color focusColor = const Color(0xFF007AFF),
  }) {
    return GestureDetector(
      onSecondaryTapDown: (TapDownDetails details) {
        MyMenu.show(
          context,
          details.globalPosition,
          menuItems,
          animationStyle: animationStyle,
          fontSize: fontSize,
          iconPadding: iconPadding,
          itemHeight: itemHeight,
          borderRadius: borderRadius,
          blurSigma: blurSigma,
          borderWidth: borderWidth,
          focusColor: focusColor,
        );
      },
      child: this,
    );
  }
}

class _MyMenuWidget extends StatelessWidget {
  final List<MyMenuItem> menuItems;
  final Function(int) onItemSelected;
  final double fontSize;
  final double borderRadius;
  final double blurSigma;
  final double borderWidth;
  final Color focusColor;

  const _MyMenuWidget({
    required this.menuItems,
    required this.onItemSelected,
    this.fontSize = 15,
    this.borderRadius = 13,
    this.blurSigma = 10,
    this.borderWidth = 1,
    this.focusColor = const Color(0xFF007AFF),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius.sp),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma.sp, sigmaY: blurSigma.sp),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(borderRadius.sp),
            border: Border.all(
                color: Colors.white.withOpacity(0.2), width: borderWidth.w),
          ),
          child: IntrinsicWidth(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List.generate(menuItems.length, (index) {
                return _buildMenuItem(index);
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(int index) {
    final item = menuItems[index];
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onItemSelected(index),
        highlightColor: focusColor.withOpacity(0.1),
        splashColor: focusColor.withOpacity(0.05),
        hoverColor: focusColor.withOpacity(0.05),
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
                  style:
                      TextStyle(color: Colors.black87, fontSize: fontSize.sp),
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

class MyMenuItem {
  final String text;
  final IconData icon;
  final VoidCallback onTap;

  MyMenuItem({required this.text, required this.icon, required this.onTap});
}

class MyMenuButton extends StatelessWidget {
  final Widget child;
  final List<MyMenuItem> menuItems;
  final bool useRightClick;
  final double fontSize;
  final double iconPadding;
  final double itemHeight;
  final double borderRadius;
  final double blurSigma;
  final double borderWidth;
  final Color focusColor;

  const MyMenuButton({
    super.key,
    required this.child,
    required this.menuItems,
    this.useRightClick = false,
    this.fontSize = 15,
    this.iconPadding = 60,
    this.itemHeight = 50,
    this.borderRadius = 13,
    this.blurSigma = 10,
    this.borderWidth = 1,
    this.focusColor = const Color(0xFF007AFF),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: useRightClick
          ? null
          : (TapDownDetails details) {
              final RenderBox renderBox =
                  context.findRenderObject() as RenderBox;
              final position = renderBox.localToGlobal(Offset.zero);
              final size = renderBox.size;
              _showMenu(context, position + Offset(0, size.height));
            },
      onSecondaryTapDown: useRightClick
          ? (TapDownDetails details) {
              _showMenu(context, details.globalPosition);
            }
          : null,
      child: child,
    );
  }

  void _showMenu(BuildContext context, Offset position) {
    MyMenu.show(
      context,
      position,
      menuItems,
      fontSize: fontSize,
      iconPadding: iconPadding,
      itemHeight: itemHeight,
      borderRadius: borderRadius,
      blurSigma: blurSigma,
      borderWidth: borderWidth,
      focusColor: focusColor,
    );
  }
}
