import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

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
    _closeMenu(); // 关闭现有菜单
    _closeAllSubMenus(); // 关闭所有子菜单
    _menuCompleter = Completer<void>();

    _showMenu(context, position, menuElements, style); // 显示新菜单

    return _menuCompleter!.future;
  }

  static void _showMenu(BuildContext context, Offset position,
      List<MyMenuElement> menuElements, MyMenuStyle style) {
    final menuSize = calculateMenuSize(menuElements, style);
    final adjustedPosition = calculateMenuPosition(context, position, menuSize);

    _overlayEntry = OverlayEntry(
      builder: (context) => LayoutBuilder(
        builder: (context, constraints) {
          return _MenuOverlay(
            position: adjustedPosition,
            menuElements: menuElements,
            animationStyle: currentAnimationStyle,
            style: style,
            onItemSelected: (item) {
              if (item.onTap != null) {
                _closeMenu();
                Future.microtask(item.onTap!);
              }
            },
          );
        },
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _addRouteListener(context);
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
        totalHeight += element.height.h * element.thicknessMultiplier;
      }
    }

    return Size(maxWidth, totalHeight);
  }

  static void _addRouteListener(BuildContext context) {
    // 使用 PopScope 替代已弃用的 addScopedWillPopCallback
    // 注意：这里我们不直接使用 PopScope，而是通过监听路由变化来处理
    final route = ModalRoute.of(context);
    if (route != null) {
      route.addLocalHistoryEntry(LocalHistoryEntry(
        onRemove: () {
          _closeMenu();
        },
      ));
    }
  }

  static void _closeMenu() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _menuCompleter?.complete();
    _menuCompleter = null;

    _closeAllSubMenus(); // 确保所有子菜单也被关闭
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
    if (dy + menuSize.height > screenSize.height) {
      // 如果底部超出屏幕,尝试向上调整
      dy = screenSize.height - menuSize.height;
      // 如果向上调整后顶部超出屏幕,则将顶部对齐到屏幕顶部
      if (dy < 0) {
        dy = 0;
      }
    }

    return Offset(dx, dy);
  }

  static void _closeAllSubMenus() {
    for (var entry in activeSubMenus.value) {
      entry.remove();
    }
    activeSubMenus.value = [];
  }
}

// 3. GetX控制器
class AnimatedMenuController extends GetxController
    with GetSingleTickerProviderStateMixin {
  late AnimationController animationController;
  late Animation<double> animation;
  final MyMenuPopStyle animationStyle;

  AnimatedMenuController(this.animationStyle);

  @override
  void onInit() {
    super.onInit();
    animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    animation = _createAnimation();
    animationController.forward();
  }

  Animation<double> _createAnimation() {
    switch (animationStyle) {
      case MyMenuPopStyle.scale:
        return Tween<double>(begin: 0.8, end: 1.0).animate(
          CurvedAnimation(
              parent: animationController, curve: Curves.easeOutCubic),
        );
      case MyMenuPopStyle.fade:
        return Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: animationController, curve: Curves.easeOut),
        );
      case MyMenuPopStyle.slideFromTop:
      case MyMenuPopStyle.slideFromRight:
        return Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
              parent: animationController, curve: Curves.easeOutCubic),
        );
    }
  }

  @override
  void onClose() {
    animationController.dispose();
    super.onClose();
  }
}

// 4. 辅助类和组件
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final menuSize = MyMenu.calculateMenuSize(menuElements, style);
        final adjustedPosition = MyMenu.calculateMenuPosition(
          context,
          position,
          menuSize,
        );

        return Stack(
          children: [
            // 添加一个全屏的透明层来捕获点击事件
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: MyMenu._closeMenu,
                child: Container(color: Colors.transparent),
              ),
            ),
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
                      menuElements: menuElements,
                      onItemSelected: onItemSelected,
                      style: style,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AnimatedMenuWidget extends GetView<AnimatedMenuController> {
  final Widget child;
  final MyMenuPopStyle animationStyle;

  const _AnimatedMenuWidget({
    required this.child,
    this.animationStyle = MyMenuPopStyle.scale,
  });

  @override
  Widget build(BuildContext context) {
    Get.put(AnimatedMenuController(animationStyle));
    return _buildAnimatedWidget();
  }

  Widget _buildAnimatedWidget() {
    switch (animationStyle) {
      case MyMenuPopStyle.scale:
        return ScaleTransition(scale: controller.animation, child: child);
      case MyMenuPopStyle.fade:
        return FadeTransition(opacity: controller.animation, child: child);
      case MyMenuPopStyle.slideFromTop:
        return SlideTransition(
          position:
              Tween<Offset>(begin: const Offset(0, -0.1), end: Offset.zero)
                  .animate(controller.animation),
          child: child,
        );
      case MyMenuPopStyle.slideFromRight:
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(0.1, 0), end: Offset.zero)
              .animate(controller.animation),
          child: child,
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
            borderRadius: BorderRadius.circular(style.borderRadius.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2 * style.shadowRatio),
                blurRadius: 10.r * style.shadowRatio,
                spreadRadius: 2.r * style.shadowRatio,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(style.borderRadius.r),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                  sigmaX: style.blurSigma.r, sigmaY: style.blurSigma.r),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(style.borderRadius.r),
                  border: Border.all(
                    color:
                        Colors.grey.withValues(alpha: 0.3 * style.shadowRatio),
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
        highlightColor: style.focusColor.withValues(alpha: 0.1),
        splashColor: style.focusColor.withValues(alpha: 0.05),
        hoverColor: style.focusColor.withValues(alpha: 0.05),
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

      // 计算子菜单的位置,确保与父菜单项顶部对齐
      final double overlapWidth = 5.w; // 重叠宽度
      final Offset subMenuPosition = Offset(
        itemPosition.dx + itemBox.size.width - overlapWidth,
        itemPosition.dy, // 使用父菜单项的y坐标
      );

      final Offset adjustedPosition = MyMenu.calculateMenuPosition(
        context,
        subMenuPosition,
        menuSize,
        isSubMenu: true,
        parentMenuSize: itemBox.size,
        alignedY: itemPosition.dy, // 使用父菜单项的y坐标
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
      // 如果不是子菜单项,移除所有子菜单
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
        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 16.w),
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

// 5. 公共类和扩展
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
    this.color = const Color(0x1F000000),
    this.margin = const EdgeInsets.symmetric(horizontal: 8.0),
    this.thicknessMultiplier = 0.7,
  });

  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: Container(
        height: (height * thicknessMultiplier).h,
        color: color,
      ),
    );
  }
}
