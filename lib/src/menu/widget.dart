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
    List<MyMenuElement> menuElements, {
    MyMenuPopStyle animationStyle = MyMenuPopStyle.scale,
    MyMenuStyle style = const MyMenuStyle(),
  }) async {
    currentAnimationStyle = animationStyle;
    _closeMenu();
    _closeAllSubMenus();
    _menuCompleter = Completer<void>();

    final menuSize = calculateMenuSize(menuElements, style);
    final adjustedPosition = calculateMenuPosition(context, position, menuSize);

    _overlayEntry = OverlayEntry(
      builder: (context) => _MenuOverlay(
        position: adjustedPosition,
        menuElements: menuElements,
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
    List<MyMenuElement> menuElements,
    MyMenuPopStyle animationStyle,
    MyMenuStyle style,
  ) {
    return _MenuOverlay(
      position: position,
      menuElements: menuElements,
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

  static Size calculateMenuSize(
      List<MyMenuElement> menuElements, MyMenuStyle style) {
    double maxWidth = 0.0;
    double totalHeight = 0.0;

    for (var element in menuElements) {
      if (element is MyMenuItem) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: element.text,
            style: TextStyle(fontSize: style.fontSize.sp),
          ),
          maxLines: 1,
          textDirection: TextDirection.ltr,
        )..layout(minWidth: 0, maxWidth: double.infinity);

        double itemWidth = textPainter.width +
            (element.icon != null ? style.iconPadding.w : 0);
        maxWidth = max(maxWidth, itemWidth);
        totalHeight += style.itemHeight.h;
      } else if (element is MyMenuDivider) {
        totalHeight += element.height * element.thicknessMultiplier;
      }
    }

    return Size(maxWidth, totalHeight);
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
  final List<MyMenuElement> menuElements;
  final MyMenuPopStyle animationStyle;
  final MyMenuStyle style;
  final Function(MyMenuItem) onItemSelected;

  const _MenuOverlay({
    required this.position,
    required this.menuElements,
    required this.animationStyle,
    required this.style,
    required this.onItemSelected,
  });

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
                    menuElements: menuElements,
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
    required this.child,
    this.animationStyle = MyMenuPopStyle.scale,
  });

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
  final List<MyMenuElement> menuElements;
  final Function(MyMenuItem) onItemSelected;
  final MyMenuStyle style;
  final bool isSubMenu;
  final int level;

  const _MyMenuWidget({
    required this.menuElements,
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
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(style.borderRadius.sp),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2 * style.shadowRatio),
                blurRadius: 10.sp * style.shadowRatio,
                spreadRadius: 2.sp * style.shadowRatio,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(style.borderRadius.sp),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                  sigmaX: style.blurSigma.sp, sigmaY: style.blurSigma.sp),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(style.borderRadius.sp),
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.3 * style.shadowRatio),
                    width: 1.w * style.shadowRatio,
                  ),
                ),
                child: IntrinsicWidth(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: menuElements
                        .map((element) => _buildMenuElement(context, element))
                        .toList(),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuElement(BuildContext context, MyMenuElement element) {
    if (element is MyMenuItem) {
      return _buildMenuItem(context, element);
    } else if (element is MyMenuDivider) {
      return element.build(context);
    }
    return const SizedBox.shrink(); // 处理未知类型
  }

  Widget _buildMenuItem(BuildContext context, MyMenuItem item) {
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

      // 计算子菜单的位置，确保对齐并稍微重叠
      final double overlapWidth = 5.w; // 重叠宽度
      final Offset subMenuPosition = Offset(
          itemPosition.dx + itemBox.size.width - overlapWidth, itemPosition.dy);

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
          child: _MyMenuWidget(
            menuElements: item.subItems!,
            onItemSelected: onItemSelected,
            style: style,
            isSubMenu: true,
            level: level + 1,
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
    required this.item,
    required this.style,
    required this.onItemSelected,
    required this.level,
    required this.onHover,
  });

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
                item.text ?? '',
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
abstract class MyMenuElement {}

class MyMenuItem extends MyMenuElement {
  final String? text;
  final IconData? icon;
  final VoidCallback? onTap;
  final List<MyMenuElement>? subItems;

  MyMenuItem({
    this.text,
    this.icon,
    this.onTap,
    this.subItems,
  }) : assert(text != null && (onTap != null || subItems != null),
            '必须提供 text 和 onTap 或 subItems 中的一个');

  bool get hasSubMenu => subItems != null && subItems!.isNotEmpty;
}

class MyMenuDivider extends MyMenuElement {
  final double height;
  final Color color;
  final EdgeInsets margin;
  final double thicknessMultiplier;

  MyMenuDivider({
    this.height = 1.0,
    this.color = const Color(0x1F000000), // 更淡的灰色,透明度为0.12
    this.margin = const EdgeInsets.symmetric(horizontal: 8.0), // 添加水平边距
    this.thicknessMultiplier = 0.7,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: Container(
        height: height * thicknessMultiplier,
        color: color,
      ),
    );
  }
}
