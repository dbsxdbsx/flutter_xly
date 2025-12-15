import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../logger.dart';
import 'menu_models.dart';
import 'style.dart';

// ============================================================================
// 核心菜单管理器
// ============================================================================

/// 菜单管理器 - 负责菜单的显示和生命周期管理
class MyMenu {
  MyMenu._(); // 私有构造函数

  // 全局单例管理器
  static final _MenuStateManager _stateManager = _MenuStateManager();

  /// 显示右键菜单
  ///
  /// [context] - 上下文
  /// [position] - 菜单弹出位置（全局坐标）
  /// [menuElements] - 菜单项列表
  /// [animationStyle] - 动画样式
  /// [style] - 菜单样式
  static Future<void> show(
    BuildContext context,
    Offset position,
    List<MyMenuElement> menuElements, {
    MyMenuPopStyle animationStyle = MyMenuPopStyle.scale,
    MyMenuStyle? style,
  }) async {
    style ??= MyMenuStyle();
    return _stateManager.showMenu(
      context,
      position,
      menuElements,
      animationStyle: animationStyle,
      style: style,
    );
  }

  /// 计算菜单尺寸（公开方法，供内部使用）
  static Size calculateMenuSize(
    List<MyMenuElement> menuElements,
    MyMenuStyle style,
  ) {
    return _MenuSizeCalculator.calculate(menuElements, style);
  }

  /// 计算菜单位置（公开方法，供内部使用）
  static Offset calculateMenuPosition(
    BuildContext context,
    Offset position,
    Size menuSize, {
    bool isSubMenu = false,
    Size? parentMenuSize,
    double? alignedY,
    double? itemHeightHint,
  }) {
    return _MenuPositionCalculator.calculate(
      context,
      position,
      menuSize,
      isSubMenu: isSubMenu,
      parentMenuSize: parentMenuSize,
      alignedY: alignedY,
      itemHeightHint: itemHeightHint,
    );
  }

  /// 关闭所有菜单
  static void closeAll() {
    _stateManager.closeAll();
  }

  // 内部使用：获取活跃子菜单通知器
  static ValueNotifier<List<OverlayEntry>> get _activeSubMenus =>
      _stateManager.activeSubMenus;
}

// ============================================================================
// 菜单状态管理器
// ============================================================================

/// 菜单状态管理器 - 管理菜单的状态和生命周期
class _MenuStateManager {
  OverlayEntry? _mainMenuEntry;
  Completer<void>? _menuCompleter;
  MyMenuPopStyle _currentAnimationStyle = MyMenuPopStyle.scale;

  // 活跃的子菜单列表
  final ValueNotifier<List<OverlayEntry>> activeSubMenus =
      ValueNotifier<List<OverlayEntry>>([]);

  // 主菜单矩形（用于避免子菜单与已有菜单重叠）
  Rect? mainMenuRect;

  // 活跃菜单矩形列表（与 activeSubMenus 一一对应）
  final ValueNotifier<List<Rect>> activeMenuRects =
      ValueNotifier<List<Rect>>([]);

  /// 显示菜单
  Future<void> showMenu(
    BuildContext context,
    Offset position,
    List<MyMenuElement> menuElements, {
    MyMenuPopStyle animationStyle = MyMenuPopStyle.scale,
    required MyMenuStyle style,
  }) async {
    _currentAnimationStyle = animationStyle;
    closeAll(); // 关闭现有菜单
    _menuCompleter = Completer<void>();

    _showMainMenu(context, position, menuElements, style);

    return _menuCompleter!.future;
  }

  /// 显示主菜单
  void _showMainMenu(
    BuildContext context,
    Offset position,
    List<MyMenuElement> menuElements,
    MyMenuStyle style,
  ) {
    _mainMenuEntry = OverlayEntry(
      builder: (context) => _MenuOverlay(
        position: position,
        menuElements: menuElements,
        animationStyle: _currentAnimationStyle,
        style: style,
        onClose: _closeMainMenu,
        onItemSelected: (item) {
          if (item.onTap != null) {
            _closeMainMenu();
            // 使用 microtask 确保菜单关闭动画完成后再执行回调
            Future.microtask(() async {
              try {
                await item.onTap!();
              } catch (e, s) {
                XlyLogger.error('MyMenuItem.onTap error', e, s);
              }
            });
          }
        },
        onLayoutRect: (rect) {
          mainMenuRect = rect;
        },
      ),
    );

    // 使用 rootOverlay 确保在 Dialog/BottomSheet 内也能正常显示
    Overlay.of(context, rootOverlay: true).insert(_mainMenuEntry!);
    _addNavigationListener(context);
  }

  /// 添加导航监听器，路由变化时自动关闭菜单
  void _addNavigationListener(BuildContext context) {
    final route = ModalRoute.of(context);
    if (route != null) {
      route.addLocalHistoryEntry(
        LocalHistoryEntry(onRemove: _closeMainMenu),
      );
    }
  }

  /// 关闭主菜单
  void _closeMainMenu() {
    _mainMenuEntry?.remove();
    _mainMenuEntry = null;
    _menuCompleter?.complete();
    _menuCompleter = null;
    _closeAllSubMenus();
  }

  /// 关闭所有子菜单
  void _closeAllSubMenus() {
    for (var entry in activeSubMenus.value) {
      entry.remove();
    }
    activeSubMenus.value = [];
    activeMenuRects.value = [];
  }

  /// 关闭所有菜单
  void closeAll() {
    _closeMainMenu();
    mainMenuRect = null;
    activeMenuRects.value = [];
  }
}

// ============================================================================
// 菜单尺寸计算器
// ============================================================================

/// 菜单尺寸计算器 - 负责计算菜单的尺寸
class _MenuSizeCalculator {
  _MenuSizeCalculator._();

  static Size calculate(
    List<MyMenuElement> menuElements,
    MyMenuStyle style, {
    double? rowHeightOverride,
  }) {
    double maxWidth = 0.0;
    double totalHeight = 0.0;

    for (var element in menuElements) {
      if (element is MyMenuItem) {
        // 计算实际所需宽度：文字宽度 + 图标/箭头 + 左右内边距
        final textWidth = _calculateTextWidth(element.text ?? '', style);
        final double horizontalPadding = 16.w + 16.w; // 与 _MenuItemWidget 一致
        final double iconAndGap =
            element.icon != null ? (18.sp + 8.w) : 0; // 图标尺寸+间距
        final double arrowWidth = element.hasSubMenu ? 18.sp : 0; // 右侧箭头
        final itemWidth =
            textWidth + iconAndGap + arrowWidth + horizontalPadding;

        maxWidth = max(maxWidth, itemWidth);

        // 高度采用 override（例如传入父项真实高度），未提供则退回样式值
        totalHeight += rowHeightOverride ?? style.itemHeight;
      } else if (element is MyMenuDivider) {
        totalHeight += element.height.h * element.thicknessMultiplier;
      }
    }

    return Size(maxWidth, totalHeight);
  }

  static double _calculateTextWidth(String text, MyMenuStyle style) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: style.fontSize),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(minWidth: 0, maxWidth: double.infinity);

    return textPainter.width;
  }
}

// ============================================================================
// 菜单位置计算器
// ============================================================================

/// 菜单位置计算器 - 负责计算菜单的最佳显示位置
class _MenuPositionCalculator {
  _MenuPositionCalculator._();

  /// 计算菜单位置
  ///
  /// 策略：
  /// 1. 主菜单：优先在点击位置右下方显示
  /// 2. 如果右侧空间不足，尝试左侧
  /// 3. 如果下方空间不足，尝试上方
  /// 4. 确保菜单不会超出屏幕边界
  static Offset calculate(
    BuildContext context,
    Offset position,
    Size menuSize, {
    bool isSubMenu = false,
    Size? parentMenuSize,
    double? alignedY,
    double? itemHeightHint,
    List<Rect> avoidRects = const [],
    double? parentMenuLeft,
  }) {
    final screenSize = _getScreenSize(context);

    if (isSubMenu) {
      return _calculateSubMenuPosition(
        position,
        menuSize,
        screenSize,
        alignedY,
        parentMenuSize: parentMenuSize,
        itemHeightHint: itemHeightHint,
        avoidRects: avoidRects,
        parentMenuLeft: parentMenuLeft,
      );
    } else {
      return _calculateMainMenuPosition(
        position,
        menuSize,
        screenSize,
      );
    }
  }

  /// 获取屏幕尺寸
  static Size _getScreenSize(BuildContext context) {
    // 使用 rootOverlay 确保在 Dialog/BottomSheet 内也能正常获取
    final overlay =
        Overlay.of(context, rootOverlay: true).context.findRenderObject()
            as RenderBox;
    return overlay.size;
  }

  /// 计算主菜单位置
  static Offset _calculateMainMenuPosition(
    Offset clickPosition,
    Size menuSize,
    Size screenSize,
  ) {
    double x = clickPosition.dx;
    double y = clickPosition.dy;

    // 水平位置计算
    final rightSpace = screenSize.width - clickPosition.dx;
    final leftSpace = clickPosition.dx;

    if (rightSpace >= menuSize.width) {
      // 右侧有足够空间
      x = clickPosition.dx;
    } else if (leftSpace >= menuSize.width) {
      // 左侧有足够空间
      x = clickPosition.dx - menuSize.width;
    } else {
      // 两侧都不够，选择空间较大的一侧
      if (rightSpace >= leftSpace) {
        x = max(0, screenSize.width - menuSize.width);
      } else {
        x = 0;
      }
    }

    // 垂直位置计算
    final bottomSpace = screenSize.height - clickPosition.dy;
    final topSpace = clickPosition.dy;

    if (bottomSpace >= menuSize.height) {
      // 下方有足够空间
      y = clickPosition.dy;
    } else if (topSpace >= menuSize.height) {
      // 上方有足够空间
      y = clickPosition.dy - menuSize.height;
    } else {
      // 上下都不够，靠下对齐
      y = max(0, screenSize.height - menuSize.height);
    }

    // 边界保护
    x = x.clamp(0.0, max(0, screenSize.width - menuSize.width));
    y = y.clamp(0.0, max(0, screenSize.height - menuSize.height));

    return Offset(x, y);
  }

  /// 计算子菜单位置
  static Offset _calculateSubMenuPosition(
    Offset parentPosition,
    Size menuSize,
    Size screenSize,
    double? alignedY, {
    Size? parentMenuSize,
    double? itemHeightHint,
    List<Rect> avoidRects = const [],
    double? parentMenuLeft,
  }) {
    // 与父菜单之间保留一个水平间隙，避免视觉重叠
    final double gap = 0.w; // 去除主菜单与子菜单间隙，紧贴对齐

    // parentPosition.dx 代表父菜单右边缘（在 _showSubMenu 中传入的是 item 的右侧）
    final double parentRight = parentPosition.dx;
    // 如果能获取到父菜单宽度，则推导出父菜单左边缘；否则退化为 parentRight
    final double parentLeft = parentMenuSize != null
        ? parentRight - parentMenuSize.width
        : parentRight;

    // 计算左右可用空间（需扣除 gap）
    final double rightSpace = screenSize.width - (parentRight + gap);
    final double leftSpace = parentLeft - gap;

    // 先计算两个候选位置
    final double candidateRightX = parentRight + gap;
    // 左侧候选优先使用父菜单容器左边界；若不可用则退回到条目左边界
    final double effectiveParentLeft = parentMenuLeft ?? parentLeft;
    final double candidateLeftX = effectiveParentLeft - gap - menuSize.width;

    // 先按可用空间选择一侧
    double x = rightSpace >= menuSize.width
        ? candidateRightX
        : (leftSpace >= menuSize.width
            ? candidateLeftX
            : (rightSpace >= leftSpace
                ? max(0, screenSize.width - menuSize.width)
                : 0));

    // 垂直对齐策略：
    // 1) 首选让子菜单的顶部与当前条目的顶部对齐；
    // 2) 若到底部溢出，则尝试让子菜单底部与当前条目的底部对齐；
    // 3) 最后做屏幕裁剪（clamp）。
    final double itemTop = alignedY ?? parentPosition.dy;
    final double parentItemHeight = parentMenuSize?.height ?? 0;
    // 为避免高度估算差异导致的1px上下偏移，这里直接使用父项的实际高度来对齐
    final double firstRowHeight = parentItemHeight;

    // 以“条目中心 == 子菜单第一行中心”为默认策略，保证水平线对齐
    double y = itemTop + parentItemHeight / 2 - firstRowHeight / 2;

    // 若底部溢出，退化为“与父项底部对齐”的策略
    if (y + menuSize.height > screenSize.height) {
      final double itemBottom = itemTop + parentItemHeight;
      y = itemBottom - menuSize.height;
    }

    // 对齐到像素边界，减少亚像素渲染导致的轻微错位
    y = y.roundToDouble();

    // 再做重叠避让：若与任一已有菜单矩形重叠，则尝试另一侧
    bool overlapsAt(Offset p) {
      final rect = Rect.fromLTWH(p.dx, p.dy, menuSize.width, menuSize.height);
      for (final r in avoidRects) {
        if (rect.overlaps(r)) return true;
      }
      return false;
    }

    final Offset rightPos = Offset(candidateRightX, y);
    final Offset leftPos = Offset(candidateLeftX, y);

    final bool rightOverlap = overlapsAt(rightPos);
    final bool leftOverlap = overlapsAt(leftPos);

    if (x == candidateRightX && rightOverlap && !leftOverlap) {
      x = candidateLeftX;
    } else if (x == candidateLeftX && leftOverlap && !rightOverlap) {
      x = candidateRightX;
    }

    // 若最终位置仍然重叠，则沿垂直方向做智能避让（先向下，后向上），直到不重叠或到达边界
    if (overlapsAt(Offset(x, y))) {
      final double topBound = 0.0;
      final double bottomBound = max(0, screenSize.height - menuSize.height);
      final double step =
          max(4.w, (parentItemHeight > 0 ? parentItemHeight : 24.h) / 2);
      const int maxIter = 40; // 安全上限
      for (int i = 1; i <= maxIter; i++) {
        final double tryDown = y + i * step;
        if (tryDown <= bottomBound && !overlapsAt(Offset(x, tryDown))) {
          y = tryDown;
          break;
        }
        final double tryUp = y - i * step;
        if (tryUp >= topBound && !overlapsAt(Offset(x, tryUp))) {
          y = tryUp;
          break;
        }
      }
    }

    // 若仍重叠，则进行横向多跳避让（先向左再向右），必要时再做一次微量垂直调整
    if (overlapsAt(Offset(x, y))) {
      final double leftBound = 0.0;
      final double rightBound = max(0, screenSize.width - menuSize.width);
      final double hStep = max(8.w, menuSize.width * 0.25);
      const int hMaxIter = 20;
      bool resolved = false;
      for (int i = 1; i <= hMaxIter; i++) {
        final double tryLeft = max(leftBound, x - i * hStep);
        if (!overlapsAt(Offset(tryLeft, y))) {
          x = tryLeft;
          resolved = true;
          break;
        }
        final double tryRight = min(rightBound, x + i * hStep);
        if (!overlapsAt(Offset(tryRight, y))) {
          x = tryRight;
          resolved = true;
          break;
        }
      }
      if (!resolved) {
        // 在新x附近再尝试一次垂直小步避让
        final double topBound = 0.0;
        final double bottomBound = max(0, screenSize.height - menuSize.height);
        final double vStep =
            max(4.w, (parentItemHeight > 0 ? parentItemHeight : 24.h) / 2);
        for (int i = 1; i <= 20; i++) {
          final double tryDown = y + i * vStep;
          if (tryDown <= bottomBound && !overlapsAt(Offset(x, tryDown))) {
            y = tryDown;
            resolved = true;
            break;
          }
          final double tryUp = y - i * vStep;
          if (tryUp >= topBound && !overlapsAt(Offset(x, tryUp))) {
            y = tryUp;
            resolved = true;
            break;
          }
        }
      }
    }

    // 最终边界保护
    y = y.clamp(0.0, max(0, screenSize.height - menuSize.height));
    x = x.clamp(0.0, max(0, screenSize.width - menuSize.width));

    return Offset(x, y);
  }
}

// ============================================================================
// UI组件
// ============================================================================

/// 菜单覆盖层 - 全屏透明层+菜单内容
class _MenuOverlay extends StatelessWidget {
  final Offset position;
  final List<MyMenuElement> menuElements;
  final MyMenuPopStyle animationStyle;
  final MyMenuStyle style;
  final VoidCallback onClose;
  final Function(MyMenuItem) onItemSelected;
  final ValueChanged<Rect> onLayoutRect;

  const _MenuOverlay({
    required this.position,
    required this.menuElements,
    required this.animationStyle,
    required this.style,
    required this.onClose,
    required this.onItemSelected,
    required this.onLayoutRect,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 🔧 关键修复：将全局坐标转换为 Overlay 的本地坐标
        // 使用 rootOverlay 确保在 Dialog/BottomSheet 内也能正常显示
        final overlayBox =
            Overlay.of(context, rootOverlay: true).context.findRenderObject()
                as RenderBox;
        final localPosition = overlayBox.globalToLocal(position);

        // 在实际渲染时重新计算位置，使用本地坐标
        final menuSize = _MenuSizeCalculator.calculate(menuElements, style);
        final adjustedPosition = _MenuPositionCalculator.calculate(
          context,
          localPosition, // 使用转换后的本地坐标
          menuSize,
        );
        // 当前菜单的矩形区域（Overlay 本地坐标）
        final Rect menuRect = Rect.fromLTWH(
          adjustedPosition.dx,
          adjustedPosition.dy,
          menuSize.width,
          menuSize.height,
        );
        // 将主菜单矩形上报至管理器，供后续子菜单避让
        onLayoutRect(menuRect);

        return Stack(
          children: [
            // 全屏透明点击层 - 使用Listener处理右键点击以允许事件传播
            Positioned.fill(
              child: Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: (event) {
                  final Offset lp = event.localPosition;
                  final bool outside = !menuRect.contains(lp);

                  // 右键：点在菜单外 → 关旧开新（保持原行为）
                  if (event.buttons == 2 && outside) {
                    MyMenu.show(
                      context,
                      event.position, // 全局坐标
                      menuElements,
                      animationStyle: animationStyle,
                      style: style,
                    );
                    return;
                  }

                  // 左键：点在菜单外 → 按下即关闭（避免 onTap 的延迟）
                  if (event.buttons == 1 && outside) {
                    onClose();
                    return;
                  }

                  // 其它情况（或点在菜单内）不处理，交由子组件
                },
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onClose, // 左键点击空白处关闭
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
            // 菜单内容
            Positioned(
              left: adjustedPosition.dx,
              top: adjustedPosition.dy,
              child: GestureDetector(
                onTap: () {}, // 防止点击菜单时关闭
                child: _AnimatedMenuWrapper(
                  animationStyle: animationStyle,
                  child: _MenuContent(
                    menuElements: menuElements,
                    onItemSelected: onItemSelected,
                    style: style,
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

/// 动画包装器 - 负责菜单弹出动画
class _AnimatedMenuWrapper extends StatefulWidget {
  final Widget child;
  final MyMenuPopStyle animationStyle;

  const _AnimatedMenuWrapper({
    required this.child,
    required this.animationStyle,
  });

  @override
  State<_AnimatedMenuWrapper> createState() => _AnimatedMenuWrapperState();
}

class _AnimatedMenuWrapperState extends State<_AnimatedMenuWrapper>
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
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    switch (widget.animationStyle) {
      case MyMenuPopStyle.scale:
        return Tween<double>(begin: 0.8, end: 1.0).animate(curve);
      case MyMenuPopStyle.fade:
      case MyMenuPopStyle.slideFromTop:
      case MyMenuPopStyle.slideFromRight:
        return Tween<double>(begin: 0.0, end: 1.0).animate(curve);
    }
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
          scale: _animation,
          child: widget.child,
        );
      case MyMenuPopStyle.fade:
        return FadeTransition(
          opacity: _animation,
          child: widget.child,
        );
      case MyMenuPopStyle.slideFromTop:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.1),
            end: Offset.zero,
          ).animate(_animation),
          child: widget.child,
        );
      case MyMenuPopStyle.slideFromRight:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.1, 0),
            end: Offset.zero,
          ).animate(_animation),
          child: widget.child,
        );
    }
  }
}

/// 菜单内容 - 菜单的主体UI
class _MenuContent extends StatelessWidget {
  final List<MyMenuElement> menuElements;
  final Function(MyMenuItem) onItemSelected;
  final MyMenuStyle style;
  final int level;

  const _MenuContent({
    required this.menuElements,
    required this.onItemSelected,
    required this.style,
    this.level = 0,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<OverlayEntry>>(
      valueListenable: MyMenu._activeSubMenus,
      builder: (context, _, __) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(style.borderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2 * style.shadowRatio),
                blurRadius: 10.r * style.shadowRatio,
                spreadRadius: 2.r * style.shadowRatio,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(style.borderRadius),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: style.blurSigma,
                sigmaY: style.blurSigma,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(style.borderRadius),
                  border: Border.all(
                    color:
                        Colors.grey.withValues(alpha: 0.3 * style.shadowRatio),
                    width: style.borderWidth * style.shadowRatio,
                  ),
                ),
                child: IntrinsicWidth(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: menuElements.map((element) {
                      if (element is MyMenuItem) {
                        return _MenuItemWidget(
                          item: element,
                          onItemSelected: onItemSelected,
                          style: style,
                          level: level,
                        );
                      } else if (element is MyMenuDivider) {
                        return element.build(context);
                      }
                      return const SizedBox.shrink();
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 菜单项组件
class _MenuItemWidget extends StatefulWidget {
  final MyMenuItem item;
  final Function(MyMenuItem) onItemSelected;
  final MyMenuStyle style;
  final int level;

  const _MenuItemWidget({
    required this.item,
    required this.onItemSelected,
    required this.style,
    required this.level,
  });

  @override
  State<_MenuItemWidget> createState() => _MenuItemWidgetState();
}

class _MenuItemWidgetState extends State<_MenuItemWidget> {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        // 改为“按下即触发”，提升选择速度；子菜单项保持不触发
        onTap: null,
        onTapDown: widget.item.hasSubMenu
            ? null
            : (_) => widget.onItemSelected(widget.item),
        onHover: (isHovering) {
          if (isHovering) {
            _handleHover(context);
          }
        },
        highlightColor: widget.style.focusColor.withValues(alpha: 0.1),
        splashColor: widget.style.focusColor.withValues(alpha: 0.05),
        hoverColor: widget.style.focusColor.withValues(alpha: 0.05),
        child: MouseRegion(
          onEnter: (_) => _handleHover(context),
          child: SizedBox(
            // 关键：统一行高，避免计算高度与实际渲染不一致导致“上弹”时出现空隙
            height: widget.style.itemHeight,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.item.icon != null) ...[
                    Icon(
                      widget.item.icon,
                      color: Colors.black87,
                      size: 18.sp,
                    ),
                    SizedBox(width: 8.w),
                  ],
                  Expanded(
                    child: Text(
                      widget.item.text ?? '',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: widget.style.fontSize,
                      ),
                      maxLines: 1,
                    ),
                  ),
                  if (widget.item.hasSubMenu)
                    Icon(
                      Icons.arrow_right,
                      color: Colors.black87,
                      size: 18.sp,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 处理悬停事件
  void _handleHover(BuildContext context) {
    if (widget.item.hasSubMenu) {
      _showSubMenu(context);
    } else {
      _closeSubMenusAfterLevel(widget.level);
    }
  }

  /// 显示子菜单
  void _showSubMenu(BuildContext context) {
    // 移除当前级别之后的所有子菜单
    _closeSubMenusAfterLevel(widget.level);

    // 🔧 关键修复：使用 Overlay 作为 ancestor 进行坐标转换
    // 使用 rootOverlay 确保在 Dialog/BottomSheet 内也能正常显示
    final overlayBox =
        Overlay.of(context, rootOverlay: true).context.findRenderObject()
            as RenderBox;
    final itemBox = context.findRenderObject() as RenderBox;

    // 获取菜单项在 Overlay 坐标系中的位置
    final itemPositionInOverlay =
        itemBox.localToGlobal(Offset.zero, ancestor: overlayBox);

    final menuSize = _MenuSizeCalculator.calculate(
      widget.item.subItems!,
      widget.style,
      rowHeightOverride: itemBox.size.height,
    );

    // 子菜单相邻但不重叠
    final subMenuPosition = Offset(
      itemPositionInOverlay.dx + itemBox.size.width,
      itemPositionInOverlay.dy,
    );

    // 已有菜单矩形用于避让
    final state = MyMenu._stateManager;
    final List<Rect> avoidRects = [
      if (state.mainMenuRect != null) state.mainMenuRect!,
      ...state.activeMenuRects.value,
    ];

    // 父菜单容器的左边界：优先取最近一个已存在的菜单矩形，否则取主菜单矩形
    final Rect? parentRectForLeft = state.activeMenuRects.value.isNotEmpty
        ? state.activeMenuRects.value.last
        : state.mainMenuRect;

    final adjustedPosition = _MenuPositionCalculator.calculate(
      context,
      subMenuPosition,
      menuSize,
      isSubMenu: true,
      parentMenuSize: itemBox.size, // 传入父菜单项尺寸，用于更精准对齐
      alignedY: itemPositionInOverlay.dy,
      itemHeightHint: widget.style.itemHeight,
      avoidRects: avoidRects,
      parentMenuLeft: parentRectForLeft?.left,
    );

    // 创建子菜单覆盖层（不再做额外边框修正，直接使用条目顶部对齐）
    final Rect subRect = Rect.fromLTWH(
      adjustedPosition.dx,
      adjustedPosition.dy,
      menuSize.width,
      menuSize.height,
    );

    final subMenuEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: adjustedPosition.dx,
        top: adjustedPosition.dy,
        child: _AnimatedMenuWrapper(
          animationStyle: MyMenuPopStyle.scale,
          child: _MenuContent(
            menuElements: widget.item.subItems!,
            onItemSelected: widget.onItemSelected,
            style: widget.style,
            level: widget.level + 1,
          ),
        ),
      ),
    );

    // 使用 rootOverlay 确保在 Dialog/BottomSheet 内也能正常显示
    Overlay.of(context, rootOverlay: true).insert(subMenuEntry);
    MyMenu._activeSubMenus.value = [
      ...MyMenu._activeSubMenus.value,
      subMenuEntry,
    ];
    state.activeMenuRects.value = [
      ...state.activeMenuRects.value,
      subRect,
    ];
  }

  /// 关闭指定级别之后的所有子菜单
  void _closeSubMenusAfterLevel(int level) {
    final activeSubMenus = MyMenu._activeSubMenus;
    final updatedList = List<OverlayEntry>.from(activeSubMenus.value);

    while (updatedList.length > level) {
      final lastEntry = updatedList.removeLast();
      lastEntry.remove();
    }

    // 同步移除对应的矩形
    final rects = MyMenu._stateManager.activeMenuRects;
    final updatedRects = List<Rect>.from(rects.value);
    while (updatedRects.length > level) {
      updatedRects.removeLast();
    }
    rects.value = updatedRects;

    activeSubMenus.value = updatedList;
  }
}
