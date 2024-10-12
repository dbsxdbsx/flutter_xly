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
  static MyMenuPopStyle currentAnimationStyle = MyMenuPopStyle.scale;
  static final ValueNotifier<List<OverlayEntry>> activeSubMenus =
      ValueNotifier<List<OverlayEntry>>([]);

  static Future<void> show(
    BuildContext context,
    Offset position,
    List<MyMenuItem> menuItems, {
    MyMenuPopStyle animationStyle = MyMenuPopStyle.scale,
    MyMenuStyle style = const MyMenuStyle(),
  }) async {
    currentAnimationStyle = animationStyle;
    _closeMenu();
    _closeAllSubMenus();
    _menuCompleter = Completer<void>();

    final menuSize = calculateMenuSize(menuItems, style);
    final adjustedPosition = calculateMenuPosition(context, position, menuSize);

    _overlayEntry = OverlayEntry(
      builder: (context) => _MenuOverlay(
        position: adjustedPosition,
        menuItems: menuItems,
        animationStyle: animationStyle,
        style: style,
        onItemSelected: (item) {
          if (item.onTap != null) {
            _closeMenu();
            Future.microtask(item.onTap!);
          }
        },
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
      onItemSelected: (item) {
        if (item.onTap != null) {
          _closeMenu();
          Future.microtask(item.onTap!);
        }
      },
    );
  }

  static Size calculateMenuSize(List<MyMenuItem> menuItems, MyMenuStyle style) {
    double maxWidth = menuItems.fold(0.0, (maxWidth, item) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: item.text,
          style: TextStyle(fontSize: style.fontSize.sp),
        ),
        maxLines: 1,
        textDirection: TextDirection.ltr,
      )..layout(minWidth: 0, maxWidth: double.infinity);

      double itemWidth =
          textPainter.width + (item.icon != null ? style.iconPadding.w : 0);
      return max(maxWidth, itemWidth);
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

  static Offset calculateMenuPosition(
    BuildContext context,
    Offset position,
    Size menuSize, {
    bool isSubMenu = false,
    Size? parentMenuSize,
    double? alignedY,
  }) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final Size screenSize = overlay.size;

    double dx = position.dx;
    double dy = alignedY ?? position.dy;

    if (isSubMenu) {
      // 对于子菜单,我们首先尝试将其放置在父菜单的右侧
      if (dx + menuSize.width <= screenSize.width) {
        // 如果右侧有足够的空间,就保持在右侧
        dx = position.dx;
      } else if (position.dx - menuSize.width >= 0) {
        // 如果左侧有足够的空间,就放置在左侧
        dx = position.dx - menuSize.width;
      } else {
        // 如果两侧都没有足够的空间,就选择空间较大的一侧
        dx = (position.dx > screenSize.width / 2)
            ? 0
            : screenSize.width - menuSize.width;
      }

      // 使用传入的alignedY作为子菜单的顶部位置
      dy = alignedY ?? position.dy;
    } else {
      // 对于根菜单,保持原来的逻辑
      if (dx + menuSize.width > screenSize.width) {
        dx = screenSize.width - menuSize.width;
      }
    }

    // 确保不会超出上下边界
    dy = dy.clamp(0, screenSize.height - menuSize.height);

    return Offset(dx, dy);
  }

  static void _closeAllSubMenus() {
    for (var entry in activeSubMenus.value) {
      entry.remove();
    }
    activeSubMenus.value = [];
  }
}

// 3. 辅助类和组件
class _MenuOverlay extends StatelessWidget {
  final Offset position;
  final List<MyMenuItem> menuItems;
  final MyMenuPopStyle animationStyle;
  final MyMenuStyle style;
  final Function(MyMenuItem) onItemSelected;

  const _MenuOverlay({
    Key? key,
    required this.position,
    required this.menuItems,
    required this.animationStyle,
    required this.style,
    required this.onItemSelected,
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
                    onItemSelected: onItemSelected,
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
  final Function(MyMenuItem) onItemSelected;
  final MyMenuStyle style;
  final bool isSubMenu;
  final int level;

  const _MyMenuWidget({
    required this.menuItems,
    required this.onItemSelected,
    required this.style,
    this.isSubMenu = false,
    this.level = 0,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<OverlayEntry>>(
      valueListenable: MyMenu.activeSubMenus,
      builder: (context, activeSubMenus, child) {
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
                  children: menuItems
                      .map((item) =>
                          _buildMenuItem(context, item, activeSubMenus))
                      .toList(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuItem(BuildContext context, MyMenuItem item,
      List<OverlayEntry> activeSubMenus) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.hasSubMenu ? null : () => onItemSelected(item),
        onHover: (isHovering) {
          if (isHovering) {
            _handleMenuItemHover(context, item);
          }
        },
        highlightColor: style.focusColor.withOpacity(0.1),
        splashColor: style.focusColor.withOpacity(0.05),
        hoverColor: style.focusColor.withOpacity(0.05),
        child: _SubMenuBuilder(
          item: item,
          style: style,
          onItemSelected: onItemSelected,
          level: level,
          onHover: (isHovering) {
            if (isHovering) {
              _handleMenuItemHover(context, item);
            }
          },
        ),
      ),
    );
  }

  void _handleMenuItemHover(BuildContext context, MyMenuItem item) {
    if (item.hasSubMenu) {
      // 移除当前级别之后的所有子菜单
      while (MyMenu.activeSubMenus.value.length > level) {
        final lastEntry = MyMenu.activeSubMenus.value.removeLast();
        lastEntry.remove();
      }

      // 获取当前菜单项的全局位置
      final RenderBox itemBox = context.findRenderObject() as RenderBox;
      final Offset itemPosition = itemBox.localToGlobal(Offset.zero);
      final Size menuSize = MyMenu.calculateMenuSize(item.subItems!, style);

      // 计算子菜单的位置，确保对齐
      final Offset subMenuPosition =
          Offset(itemPosition.dx + itemBox.size.width, itemPosition.dy);

      final Offset adjustedPosition = MyMenu.calculateMenuPosition(
        context,
        subMenuPosition,
        menuSize,
        isSubMenu: true,
        alignedY: itemPosition.dy, // 使用当前项的y坐标
      );

      final newOverlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          left: adjustedPosition.dx,
          top: adjustedPosition.dy,
          child: _AnimatedMenuWidget(
            animationStyle: MyMenu.currentAnimationStyle,
            child: _MyMenuWidget(
              menuItems: item.subItems!,
              onItemSelected: onItemSelected,
              style: style,
              isSubMenu: true,
              level: level + 1,
            ),
          ),
        ),
      );

      Overlay.of(context).insert(newOverlayEntry);
      MyMenu.activeSubMenus.value = [
        ...MyMenu.activeSubMenus.value,
        newOverlayEntry
      ];
    } else {
      // 如果不是子菜单项，移除所有子菜单
      while (MyMenu.activeSubMenus.value.length > level) {
        final lastEntry = MyMenu.activeSubMenus.value.removeLast();
        lastEntry.remove();
      }
    }
  }
}

class _SubMenuBuilder extends StatelessWidget {
  final MyMenuItem item;
  final MyMenuStyle style;
  final Function(MyMenuItem) onItemSelected;
  final int level;
  final Function(bool) onHover;

  const _SubMenuBuilder({
    Key? key,
    required this.item,
    required this.style,
    required this.onItemSelected,
    required this.level,
    required this.onHover,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10.w, horizontal: 16.w),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.icon != null) ...[
              Icon(item.icon, color: Colors.black87, size: 18.sp),
              SizedBox(width: 8.w),
            ],
            Expanded(
              child: Text(
                item.text,
                style: TextStyle(
                    color: Colors.black87, fontSize: style.fontSize.sp),
                maxLines: 1,
              ),
            ),
            if (item.hasSubMenu)
              Icon(Icons.arrow_right, color: Colors.black87, size: 18.sp),
          ],
        ),
      ),
    );
  }
}

// 4. 公共类和扩展
class MyMenuItem {
  final String text;
  final IconData? icon;
  final VoidCallback? onTap;
  final List<MyMenuItem>? subItems;

  MyMenuItem({
    required this.text,
    this.icon,
    this.onTap,
    this.subItems,
  }) : assert(onTap != null || subItems != null, '必须提供 onTap 或 subItems 中的一个');

  bool get hasSubMenu => subItems != null && subItems!.isNotEmpty;
}
